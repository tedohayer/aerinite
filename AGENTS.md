# AGENTS.md

Aerinite is a bootc image: Universal Blue `base-main` + niri + Noctalia, published
as `ghcr.io/tedohayer/aerinite`.

## Principles

- **Minimal.** Don't add packages, services, or config without asking first, including
  "small" helpers. If something needs a dependency, say what and why.
- **Unopinionated.** Ship defaults the user can override from `$HOME`; never break an
  existing workflow to get a nicer default.
- **It's Fedora, not a distro.** `ID` stays `fedora`; prefer upstream Fedora/ublue
  packages over COPRs, and COPRs over building things ourselves.
- Write "Aerinite" in prose; identifiers, paths and image names stay lowercase.
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

## CI

- `build.yml` runs on push to `main`, daily (rebuilds only if the `base-main` digest
  changed; always on Sunday), and on manual dispatch. It rechunks, signs with
  `SIGNING_SECRET`, tags `latest`, `44`, `44-YYYYMMDD[.N]`, and creates a GitHub release.
- Pushes that touch only `README.md`, `AGENTS.md` or `assets/` don't build. Neither
  does a push whose tree is unchanged; use `gh workflow run build.yml`.
- `build-disk.yml` is manual and builds the ISO and qcow2 from the published `:latest`,
  so publish the image first, then build disks.
- Pin actions by commit SHA.

## Testing

- `just build` builds locally; `just build-iso` builds the installer (needs sudo).
- For installer/first-boot changes, test the CI ISO in a QEMU VM (UEFI): install
  completes, home dir exists, keyring unlocks, `systemctl --failed` is empty, and the
  origin is `ostree-image-signed:docker://ghcr.io/tedohayer/aerinite:latest`.

## Commits

- Short messages, no AI attribution trailers.
- Never force-push, delete releases/images/issues, or touch secrets without being asked.
