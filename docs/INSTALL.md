# Installing ophub NixOS

Everything below uses `dev-hub` and `/dev/nvme0n1`; substitute your host and disk.

## 0. Before wiping (same-laptop reinstall)

Copy to an external drive **and open the copies on another device**:

- [ ] `~` (documents, projects, media); move LaTeX templates from `~/docs/templates/latex` to `~/tpl/latex` on the way
- [ ] `~/.ssh/` (the key is also your git signing key)
- [ ] `~/.config/sops/age/keys.txt` if you already ran `hub sec`
- [ ] the KeePassXC database
- [ ] the Zen profile (`~/.zen`), Steam saves, `~/.config/opcan-gh-token`
- [ ] this repo, pushed to a remote

## 1. Installer USB

```sh
hub iso                                   # builds iso/*.iso
hub flash                                 # writes it to a USB stick (asks which)
```

Or download the ISO from the latest CI run on GitHub (*Actions → ci → Artifacts*).

On a machine without NixOS (another Linux, macOS), run `./bin/build-iso` from the repo instead.
It uses Nix if installed (Linux), otherwise Docker; on Apple Silicon the Docker build is emulated and slow.

Boot it. The stick carries this flake at `/etc/hub` and accepts your SSH key.

## 2a. Whole disk (default)

**Wipes the disk.** The installer starts by itself on boot (run it again with `hub-install`):
it opens `nmtui` if there is no internet, then asks for the host, the disk, a typed `yes`
and the disk passphrase, installs, puts this repo at `~/tec/nix`, and reboots. Ctrl+C drops to a shell.

**New machine:** choose *new host (this machine)* and give it a name. The installer makes
`hosts/<name>/` as a copy of dev-hub with this machine's `hardware.nix`. After first login,
remove the E16 quirks from its `default.nix` and commit the new folder.

Or from another machine on the network: `hub install dev-hub <ip>`.

## 2b. Dual boot (keep Windows)

1. In Windows: *Disk Management → Shrink volume* to free at least 50 GB. Turn off BitLocker
   first (or have its recovery key) and turn off *Fast Startup*.
2. Boot the stick, choose the host and the disk, then **free space next to Windows**.

The installer adds two partitions in the largest free space: `nixos-boot` (1 GB, holds the
kernels, since Windows' own EFI partition is usually only 100 MB) and the encrypted `nixos-crypt`.
It sets `hub.dualBoot` in the host file; Windows' EFI partition is mounted at `/efi`, never
formatted. Windows shows up in the boot menu by itself. (Secure Boot via lanzaboote is not set up
for this layout.)

## 3. First boot

Disk passphrase, then you are logged in. First password is `changeme`.

```sh
passwd
cd ~/tec/nix                               # put there by hub-install; otherwise git clone it there first
git remote set-url origin git@github.com:okt4v/nixos_operations_hub.git   # push over ssh
hub switch
```

Restore `~/.ssh`, the KeePassXC database and your data. Until `~/.ssh/id_ed25519.pub`
exists, `git commit` fails because commits are signed.

## 4. One-time setup, in this order

| What | How |
|---|---|
| KeePassXC | Not started automatically: open it with `Super+Ctrl+P` when you need it. Open your database. For the SSH key entry: *SSH Agent → add key to agent when database is opened*. Then delete the private key from `~/.ssh`, keep the `.pub`. |
| Vault | `hub vault open`: choose a passphrase, store the printed master key in KeePassXC. Optional: an entry with attributes `hub` = `vault` unlocks it without asking. Restore `~/fin` into `~/vlt/fin`. |
| Secrets | `hub sec`: creates your age key (back it up in KeePassXC) and opens `secrets/secrets.yaml`. Add `restic:` and `icloud:` when you enable those features. |
| Tailscale | `sudo tailscale up` |
| Mullvad | `mullvad account login <number>` |
| Features | `hub feature`: switch on or off what this machine should have |
| Trusted wifi | `hub.net.trusted = [ "ssid" ];` in `hosts/dev-hub/default.nix` |
| Calendar, mail | secret `icloud` (app-specific password), `hub feature on calendar` and/or `mail`, `hub switch`; for the calendar once `vdirsyncer discover` |
| Git identities | `~/.config/git/work` and `~/.config/git/school`, each a `[user]` section |
| Backups | label the drive's filesystem `bak`, `hub feature on backupExternal`, `hub switch`, `hub bak`, `hub drill` |
| Monitors | `hub mon`, arrange, `hub mon save <name>` |
| Wallpaper | `ln -s <image> ~/med/img/wall/current` |
| Local LLM | `hub feature on ai`, `hub switch`, `ollama pull llama3.2:3b` |
| Lab images | put base images at `~/tec/vm/<name>.qcow2`, then `hub lab up <name>` |

## 5. Secure Boot and TPM unlock (optional, real hardware only)

1. Firmware setup: put Secure Boot into *Setup Mode*.
2. `sudo sbctl create-keys`
3. `hub feature on secureBoot`, `hub switch`
4. `sudo sbctl enroll-keys --microsoft`, reboot, enable Secure Boot in firmware
5. `sudo sbctl status` shows *Secure Boot: enabled*
6. `sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 --tpm2-with-pin=yes /dev/nvme0n1p2`

The passphrase keeps working as a fallback. Do not remove it.

## 6. Remote unlock (optional, machines on a cable)

`hub feature on remoteUnlock`, `hub switch`. At boot, `ssh -p 2222 root@<machine>` asks for the
disk passphrase. The installer already created the boot-time host key; on a machine installed
before, `hub doctor` prints the command. Wifi is not up that early.

## Adding a host

1. Easiest: boot the machine from the hub ISO and choose *new host (this machine)*. It writes
   `hosts/<name>/` (default.nix, features.nix, hardware.nix) and installs it.
2. By hand: `mkdir hosts/<name>` with a `default.nix` that imports `./hardware.nix` and
   `(import ../../modules/workstation.nix (import ./features.nix))` (a desktop; copy dev-hub's
   `features.nix`), or only `core.nix`, `disk.nix`, `secrets.nix` for a server, and sets `hub.disk`.
   `hardware.nix`: `nixos-generate-config --no-filesystems --show-hardware-config` on the machine.
3. Or from here: `hub install <name> <ip>`; later `hub deploy <name>`. Try it first with `hub vm <name>`.
