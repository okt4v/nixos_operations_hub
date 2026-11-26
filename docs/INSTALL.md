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


On a machine without NixOS (another Linux, macOS), run `./bin/build-iso` from the repo instead.
It uses Nix if installed (Linux), otherwise Docker; on Apple Silicon the Docker build is emulated and slow.

Boot it. The stick carries this flake at `/etc/hub` and accepts your SSH key.

## 2. The installer

It starts by itself on boot, a menu program on the console (arrow keys, Space, Enter; Esc goes
back or quits). *Shell* on the first screen leaves it; `hub-install` starts it again. Nothing
on the disk changes before the summary at the end, which you confirm (by typing `yes` if it erases
anything). It asks, in order:

1. **Network**: a cable works by itself; for wifi it opens `nmtui`.
2. **Keyboard layout**: applies right away, so the passphrase is typed at boot exactly as here.
   Anything but German is written into the host file (`hub.keyboard`), and the `keyboard` feature
   (the kanata layer, made for the German layout) starts off.
3. **Host**: one from `hosts/`, or **a new host** for this machine: a name, then a checklist of
   its features (dev-hub's as the start) and one of apps to install (none ticked; `hub apps` later). It gets the shared desktop and this machine's `hardware.nix`;
   commit `hosts/<name>/` after the first login.
4. **Time zone**, e.g. `Europe/Vienna` (anything else is written into the host file).
5. **Disk**: each one with what is on it now (`ntfs 200G, EFI 0G, ...`). The stick itself is not offered.
6. **How much of it**:
   - **the whole disk**: erases everything on it.
   - **the free space** (when there is 30 GB or more): every partition stays; you choose how many GB to use.
   - **replace one partition** (e.g. an old D: drive or another Linux): only that one is erased.
   - **reinstall over the previous ophub NixOS**: replaces its two partitions, keeps the rest.
   The last three need an EFI partition on that disk (Windows installed in UEFI mode).
7. **Disk passphrase** (twice) and the **login password** for `oktav` (empty: `changeme`).
8. **Summary**, then it installs, with the output live in a box. On failure it shows the end of the
   log (`/tmp/hub-install.log`; on the installed system `/var/log/hub-install.log`).
9. **Header backup** (optional): saves the disk's encryption header to another USB stick as
   `ophub-<host>-luks-header.img`. If the header on the disk is ever damaged, the passphrase alone
   no longer opens it; with the file it does:
   `sudo cryptsetup luksHeaderRestore /dev/disk/by-partlabel/<partition> --header-backup-file <file>`.
   Keep it with your backups; it is useless without the passphrase. Later:
   `sudo cryptsetup luksHeaderBackup <partition> --header-backup-file <file>`.

It puts this repo at `~/tec/nix`; `git diff` there shows what the installer wrote into the host
file (disk, dual boot, time zone, keyboard).

Or from another machine on the network: `hub install dev-hub <ip>` (whole disk).

### Next to Windows

1. In Windows: *Disk Management → Shrink Volume* to free at least 50 GB. Have the BitLocker
   recovery key at hand (Windows may ask for it once) and turn off *Fast Startup*.
2. In the installer pick **the free space** (or **replace** a partition you no longer need).

The installer adds two partitions there: `nixos-boot` (1 GB, holds the kernels, since Windows'
own EFI partition is usually only 100 MB) and the encrypted `nixos-crypt`. It sets `hub.dualBoot`
in the host file; Windows' EFI partition is mounted at `/efi`, never formatted. Windows shows up in
the boot menu by itself. (Secure Boot via lanzaboote is not set up for this layout.)

## 3. First boot

Disk passphrase, then log in as `oktav` with the password you chose (or `changeme`).

```sh
passwd                                     # if it is still changeme
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
