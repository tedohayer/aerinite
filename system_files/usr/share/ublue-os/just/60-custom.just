# Aerinite recipes (base-main's justfile imports this file if it exists)

# Turn the update notifications ("Update ready", "out of date") on or off (on by default)
toggle-update-notifications:
    #!/usr/bin/bash
    units=(aerinite-update-notify.path aerinite-update-age.timer)
    if [ "$(systemctl --user is-enabled aerinite-update-notify.path)" = masked ]; then
        systemctl --user unmask "${units[@]}"
        systemctl --user start "${units[@]}"
        echo "Update notifications: on"
    else
        systemctl --user mask --now "${units[@]}"
        echo "Update notifications: off"
    fi

# Set how often the system image updates automatically: daily (default), weekly or monthly
update-schedule SCHEDULE="prompt":
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh
    dropin=/etc/systemd/system/rpm-ostreed-automatic.timer.d/update-schedule.conf
    current=daily
    [ -f "$dropin" ] && current=$(sed -n 's/^# schedule: //p' "$dropin")
    schedule={{ SCHEDULE }}
    if [ "$schedule" = prompt ]; then
        echo "Automatic updates run: ${bold}${current}${normal}"
        schedule=$(ugum choose daily weekly monthly)
    fi
    case "$schedule" in
        daily) sudo rm -f "$dropin" ;;
        weekly | monthly)
            # Replace the timer's triggers (daily at 4:00 and 1h after boot);
            # Persistent=true still catches up on a missed run at boot. The
            # file must sort after ublue's override.conf, which adds the 4:00.
            calendar="Sun *-*-* 04:00:00"
            [ "$schedule" = monthly ] && calendar="*-*-01 04:00:00"
            sudo mkdir -p "${dropin%/*}"
            printf '# schedule: %s\n[Timer]\nOnBootSec=\nOnUnitInactiveSec=\nOnCalendar=\nOnCalendar=%s\n' \
                "$schedule" "$calendar" | sudo tee "$dropin" >/dev/null
            ;;
        *) echo "Usage: ujust update-schedule [daily|weekly|monthly]" >&2; exit 1 ;;
    esac
    sudo systemctl daemon-reload
    sudo systemctl restart rpm-ostreed-automatic.timer
    echo "Automatic updates: $schedule"
    systemctl list-timers --no-pager rpm-ostreed-automatic.timer
