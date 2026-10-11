--!nonstrict
-- Bar widget: a traffic light for the booted bootc/rpm-ostree image.
--   green  = booted deployment is the default (nothing staged)
--   yellow = a newer deployment is staged, reboot to apply
--   red    = staged, and the booted image is older than max_age_days
-- Reads `rpm-ostree status --json`, which works unprivileged. Click to re-check.

-- The full status embeds every image manifest (100+ KB), so trim it with jq.
local STATUS_CMD = "rpm-ostree status --json"
  .. " | jq -c '{deployments: [.deployments[] | {booted, version, timestamp, checksum}]}'"

local DAY = 24 * 60 * 60

-- Nord aurora: nord14 / nord13 / nord11.
local COLORS = {
  green = "#a3be8c",
  yellow = "#ebcb8b",
  red = "#bf616a",
}

local maxAgeDays = tonumber(noctalia.getConfig("max_age_days")) or 28
local intervalMs = (tonumber(noctalia.getConfig("interval_minutes")) or 5) * 60 * 1000

local checking = false

local function versionOf(d)
  return d.version or (d.checksum and d.checksum:sub(1, 10)) or "unknown"
end

local function show(color, lines)
  barWidget.setGlyph("circle-filled")
  barWidget.setGlyphColor(COLORS[color] or "on_surface")
  barWidget.setTooltip(table.concat(lines, "\n"))
end

local function showError(message)
  barWidget.setGlyph("circle")
  barWidget.setGlyphColor("on_surface")
  barWidget.setTooltip(message)
end

local function apply(status)
  local deployments = type(status) == "table" and status.deployments
  if type(deployments) ~= "table" or #deployments == 0 then
    showError("No deployments in rpm-ostree status")
    return
  end

  local booted
  for _, d in ipairs(deployments) do
    if d.booted then
      booted = d
      break
    end
  end
  if not booted then
    showError("No booted deployment found")
    return
  end

  -- deployments[1] is what the next boot will use.
  local nextBoot = deployments[1]
  local pending = not nextBoot.booted
  local ageDays = booted.timestamp and math.floor((os.time() - booted.timestamp) / DAY) or 0

  if not pending then
    show("green", { "Up to date", `Running: {versionOf(booted)}` })
    return
  end

  local overdue = ageDays > maxAgeDays
  show(overdue and "red" or "yellow", {
    overdue and `Reboot overdue, running image is {ageDays} days old` or "Reboot to update",
    `Running: {versionOf(booted)}`,
    `Staged: {versionOf(nextBoot)}`,
  })
end

local function check()
  if checking then
    return
  end
  checking = true
  local started = noctalia.runAsync({ "bash", "-o", "pipefail", "-c", STATUS_CMD }, function(result)
    checking = false
    if result.exitCode ~= 0 then
      showError(noctalia.string.trim(result.stderr or "") ~= "" and noctalia.string.trim(result.stderr) or "rpm-ostree status failed")
      return
    end
    local parsed, err = noctalia.json.decode(result.stdout)
    if parsed == nil then
      showError(`Could not parse rpm-ostree output: {err or "invalid JSON"}`)
      return
    end
    apply(parsed)
  end, 30000)
  if not started then
    checking = false
    showError("Could not run rpm-ostree")
  end
end

function update()
  noctalia.setUpdateInterval(intervalMs)
  check()
end

function onClick()
  check()
end

barWidget.setGlyph("circle")
check()
