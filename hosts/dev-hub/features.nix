# Feature switches for this host. Flip one with `hub feature` (menu) or
# `hub feature on|off <name>`, then `hub switch`. One flag per line.
{
  keyboard = true; # Caps = Esc/Ctrl, Space layer (kanata)
  dev = true; # docker, direnv, compilers, editors' tooling
  lab = true; # disposable lab VMs on an isolated network
  hack = true; # `hack` boot profile: VPN kill switch, random MAC
  play = true; # Steam and games
  meetings = true; # noise-suppressed mic, OBS virtual camera
  minutes = true; # `minutes`: record a call, transcribe it locally
  snapshots = true; # hourly /home snapshots (snapper)
  power = true; # 80% charge cap, automatic power profiles
  phone = false; # KDE Connect: phone notifications, clipboard, files
  mail = false; # terminal mail (aerc) and unread count; needs secret `icloud`
  calendar = false; # iCloud calendar sync; needs secret `icloud`
  browser = true; # Zen with extensions and privacy settings from this repo
  ai = false; # local LLM (ollama); several GB
  backupExternal = false; # restic to a USB drive labelled `bak`
  backupHomelab = false; # daily restic to a homelab server; set hub.backup.homelab.repo first
  backupCloud = false; # daily restic to cloud storage; needs secrets `restic-cloud-*`
  freshRoot = false; # / is wiped at every boot; read modules/fresh-root.nix, run `hub passwd` first
  secureBoot = false; # Secure Boot + TPM unlock; see docs/INSTALL.md first
}
