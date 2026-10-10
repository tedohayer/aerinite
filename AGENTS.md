# AGENTS.md

Aerinite is a bootc image: Universal Blue `base-main` + niri + Noctalia, published
as `ghcr.io/tedohayer/aerinite`. It's alpha and built for the maintainer's personal
use. The goal is a stable platform with minimal changes, not a growing feature set.

## Principles

- **Minimal.** Don't add packages, services, or config without asking first, including
  "small" helpers. If something needs a dependency, say what and why.
- **Unopinionated.** Ship defaults the user can override from `$HOME`; never break an
  existing workflow to get a nicer default.
- **It's Fedora, not a distro.** `ID` stays `fedora`; prefer upstream Fedora/ublue
  packages over COPRs, and COPRs over building things ourselves.
- **Finished, not growing.** Don't propose new features or tweaks unprompted. Fixes,
  upkeep and removals are welcome; additions need a reason.
- Write "Aerinite" in prose; identifiers, paths and image names stay lowercase.
- American English everywhere: code, comments, docs and commit messages.
- Branding is blue (`#007bd8` on `#2d333b`), after the mineral.

## Layout

| Path | What |
|---|---|
| `Containerfile` | Thin wrapper: base image + `build_files/build.sh` + `bootc container lint` |
| `build_files/build.sh` | Packages, repos, os-release branding, services, initramfs |
| `system_files/` | Files copied to `/` verbatim, laid out at their installed paths |
| `installer/` | Anaconda installer container, `iso.yaml` and kickstart for the ISO |
| `assets/` | Logo, installer art, README screenshot (not part of the image) |
| `cosign.pub` | Image signing public key. The private key never enters the repo |

Config belongs in `system_files/`, not in heredocs inside `build.sh`.

## Branches

- `main` is the stable channel: `latest`, `44`, `44-YYYYMMDD[.N]`.
- `beta` is for larger changes before they reach `latest`, like a new Fedora release
  (currently Fedora 45 with oo7 replacing gnome-keyring). It publishes `beta` and
  `beta-45-YYYYMMDD[.N]` as prereleases, and never touches `latest` or the Fedora
  major tag.
- `beta` is `main` plus its own changes. Make shared changes (CI, docs, config) on
  `main`, then merge `main` into `beta`. Promote by merging `beta` into `main`.

## CI

- `build.yml` runs on push to `main` or `beta`, daily, and on manual dispatch. The
  daily run rebuilds `main` only if the `base-main` digest changed (always on Sunday),
  and dispatches `beta` the same way once its base image exists. A `beta` push whose
  base isn't published yet skips the build with a notice. Builds rechunk, sign with
  `SIGNING_SECRET`, and create a GitHub release.
- Add `[skip ci]` to commits that don't need a rebuild, such as workflow-only changes.
- Pushes that touch only `README.md`, `AGENTS.md` or `assets/` don't build. Neither
  does a push whose tree is unchanged; use `gh workflow run build.yml`.
- `build-disk.yml` is manual and builds the ISO and qcow2 from the published `:latest`,
  so publish the image first, then build disks.
- Pin actions by commit SHA.

## Testing

- `just build` builds locally; `just build-iso` builds the installer (needs sudo).
- For installer/first-boot changes, test the CI ISO in a QEMU VM (UEFI): install
  completes, home dir exists, the secrets service unlocks at login (gnome-keyring on
  `main`, oo7 on `beta`), `systemctl --failed` is empty, and the origin is
  `ostree-image-signed:docker://ghcr.io/tedohayer/aerinite:latest` (or `:beta`).

## Commits

- Short messages, no AI attribution trailers.
- Never force-push, delete releases/images/issues, or touch secrets without being asked.
