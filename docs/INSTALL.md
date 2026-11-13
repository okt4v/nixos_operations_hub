# Installing a host

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
hub iso                                   # builds result/iso/*.iso
sudo dd if=result/iso/<name>.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Boot it. Wifi: `nmtui`. The stick carries this flake at `/etc/hub` and accepts your SSH key.

## 2a. Whole disk (default)

**Wipes the disk.** You are asked for the disk passphrase.

```sh
sudo disko-install --flake /etc/hub#dev-hub --disk main /dev/nvme0n1
```

Or from another machine on the network: `hub install dev-hub <ip>`.

## 2b. Dual boot (keep Windows)

disko is not used. Shrink Windows first, then in the free space:

```sh
P=/dev/nvme0n1pN                           # the new, empty Linux partition
cryptsetup luksFormat $P && cryptsetup open $P crypt
mkfs.btrfs -L nixos /dev/mapper/crypt
mount /dev/mapper/crypt /mnt
for s in @ @home @nix @log @snapshots; do btrfs subvolume create /mnt/$s; done
umount /mnt
o=compress=zstd,noatime
mount -o $o,subvol=@ /dev/mapper/crypt /mnt
mkdir -p /mnt/{home,nix,var/log,boot}
mount -o $o,subvol=@home /dev/mapper/crypt /mnt/home
mkdir -p /mnt/home/.snapshots
mount -o $o,subvol=@snapshots /dev/mapper/crypt /mnt/home/.snapshots
mount -o $o,subvol=@nix /dev/mapper/crypt /mnt/nix
mount -o $o,subvol=@log /dev/mapper/crypt /mnt/var/log
mount /dev/nvme0n1p1 /mnt/boot              # the existing EFI partition
```

In `hosts/dev-hub/default.nix` replace the `../../modules/disk.nix` import and `hub.disk` with the
filesystems that `nixos-generate-config --root /mnt --show-hardware-config` prints, plus
`boot.initrd.luks.devices.crypt.device = "/dev/disk/by-uuid/<uuid of $P>";`, then:

```sh
nixos-install --flake /etc/hub#dev-hub
```

## 3. First boot

Disk passphrase, then you are logged in. First password is `changeme`.

```sh
passwd
git clone https://github.com/okt4v/nixos_operations_hub ~/tec/nix        # the path hub.dir points at; dotfiles are linked from here
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
| Trusted wifi | `hub.net.trusted = [ "ssid" ];` in `hosts/dev-hub/default.nix` |
| Calendar | secret `icloud` (app-specific password), `hub.cal.enable = true;`, `hub switch`, once `vdirsyncer discover` |
| Git identities | `~/.config/git/work` and `~/.config/git/school`, each a `[user]` section |
| Backups | label the drive's filesystem `bak`, `hub.backup.external.enable = true;`, `hub switch`, `hub bak`, `hub drill` |
| Monitors | `hub mon`, arrange, `hub mon save <name>` |
| Wallpaper | `ln -s <image> ~/med/img/wall/current` |
| Local LLM | `hub.ai.enable = true;`, `hub switch`, `ollama pull llama3.2:3b` |
| Lab images | put base images at `~/tec/vm/<name>.qcow2`, then `hub lab up <name>` |

## 5. Secure Boot and TPM unlock (optional, real hardware only)

1. Firmware setup: put Secure Boot into *Setup Mode*.
2. `sudo sbctl create-keys`
3. `hub.secureBoot.enable = true;` in the host file, `hub switch`
4. `sudo sbctl enroll-keys --microsoft`, reboot, enable Secure Boot in firmware
5. `sudo sbctl status` shows *Secure Boot: enabled*
6. `sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 --tpm2-with-pin=yes /dev/nvme0n1p2`

The passphrase keeps working as a fallback. Do not remove it.

## Adding a host

1. `mkdir hosts/<name>` with a `default.nix` that imports the modules it needs from `modules/`
   (a server: `core.nix`, `disk.nix`, `secrets.nix`) and sets `hub.disk`.
2. On the machine (booted from the hub ISO): `nixos-generate-config --no-filesystems --show-hardware-config` → `hosts/<name>/hardware.nix`.
3. `hub install <name> <ip>`; later `hub deploy <name>`. Try it first with `hub vm <name>`.
