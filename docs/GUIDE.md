# ophub NixOS: user guide

How to use an ophub NixOS machine (ophub = operations hub) installed from this repo. Installing is in [INSTALL.md](INSTALL.md).

`Super` is the Windows key. Every key binding on the machine is searchable with `Alt+Ctrl+K`
(or `hub keys`); that list is read from the live config, so it is the reference. This guide
only names the bindings you need daily.

## The three commands to remember

| Command | What it does |
|---|---|
| `hub` | Fuzzy menu of every operation, with a preview of what each one runs. `hub <recipe>` runs one directly; `h` and `ophub` are aliases. |
| `pj` | Jump to a project (`Super+P`). |
| `mode` | Switch context (`Super+O`). |

| `hub feature` | Switch features on and off. |

If something looks wrong: `hub status` (overview), `hub health` (problems), `hub doctor`
(one-time setup steps still open, plus: disk space, unpushed repo changes, programs in
`~/.local/bin` that hide the Nix ones).

## Changing the system

The repo lives at `~/tec/nix`.

- **Dotfiles** in `config/` and **scripts** in `bin/` are linked live. Edit, reload the program
  (`Super+Shift+C` for sway), done. No rebuild. Exception: `config/kanata` needs `hub switch`.
- **Everything else** (`modules/`, `home/`, `hosts/`): edit, then `hub switch`.
  `hub test` activates until the next reboot only; `hub rollback` returns to the previous generation.
- `hub diff` shows which packages a switch would change. `hub check` evaluates all hosts and lints the scripts.
- **CI** (GitHub Actions) runs the same check on every push. On `main` it also builds the installer ISO
  (download it from the run's *Artifacts*) and runs `hub test-install` in all three layouts.
- New files must be `git add`ed before nix sees them.
- **Updates:** a weekly timer prepares an update on the branch `upd` and notifies you. `hub update` applies it.
- `hub gc` deletes old generations (keeps 5). `hub search <words>` searches nixpkgs. `, <program>` runs a program once without installing it.
- `hub vm [host]` boots a host's config in a throwaway VM window (password `test`). `Super+Shift+Escape` gives your shortcuts back to the host.

## Features

Everything optional is a flag in `hosts/<host>/features.nix`, one per line.

- `hub feature` opens a menu: Tab marks, Enter toggles, then it offers to run `hub switch`.
- `hub feature list` shows every feature, its state and what it is.
- `hub feature on|off <name>` sets one; apply with `hub switch`.

| Feature | What you get |
|---|---|
| `keyboard` | Caps = Esc/Ctrl and the Space layer |
| `dev` | Docker, direnv, compilers, editor tooling |
| `lab`, `hack` | Lab VMs; the `hack` boot profile |
| `play` | Steam and games |
| `meetings`, `minutes` | Noise-suppressed mic and OBS; call recording with transcript |
| `snapshots`, `power` | `/home` snapshots; charge cap and power profiles |
| `firmware` | `hub firmware`: BIOS and device firmware updates |
| `oom` | A runaway process is stopped before the machine freezes |
| `batteryAlert` | Notifications for low battery and charger changes |
| `nightlight` | Warmer screen after sunset (`Super+Shift+N` toggles) |
| `timezone` | The clock follows your location |
| `boxes` | distrobox: other Linux distributions as containers sharing your home |
| `phone` | KDE Connect |
| `mail`, `calendar` | Terminal mail; iCloud calendar. Both need the secret `icloud` |
| `browser` | Zen with extensions and privacy settings from the repo |
| `ai` | Local LLM |
| `backupExternal`, `backupHomelab`, `backupCloud` | The three backup targets |
| `freshRoot` | `/` is wiped at every boot (see Safety) |
| `secureBoot` | Secure Boot and TPM unlock (read INSTALL.md section 5 first) |
| `remoteUnlock` | at boot, unlock the disk over SSH: `ssh -p 2222 root@<machine>` (wired network only) |

A feature that needs a secret cannot be built before `hub sec` has created the secrets file
and the secret is in it.

## Look

Black and amber, square corners, one monospace font. `theme` is the theme manager: one palette
of eight colours for every app (sway, waybar, kitty, tmux, fuzzel, mako, eww, fastfetch, GTK, nvim).
Palettes: dark (default), light, nord, gruvbox, catppuccin, solarized. Pick one by click in the
**settings window** (`Super+Shift+W` or `settings`), or `theme <name>`; `theme` alone toggles dark
and light. Each palette is a file in `config/palette/`: edit it and run `theme apply`; a new file is a
new palette.
`fastfetch` shows the ophub logo in the accent colour.

## Desktop

| Key | Action |
|---|---|
| `Super+Return` | Terminal |
| `Super+Space` | App launcher |
| `Super+Shift+Space` | `menu`: everything that is not "start an app" (see below) |
| `Super+Q` | Close window |
| `Super+H/J/K/L` | Focus; with `Shift`: move |
| `Super+1…` | Workspace; `Super+Tab` cycles |
| `Super+F` / `Super+Shift+F` | Fullscreen / floating |
| `Super+R` / `Super+Shift+R` | Resize / move mode (`Esc` leaves) |
| `Super+C` | Clipboard history |
| `Super+T` | Toggle the dark and light palette, everywhere, instantly |
| `Super+Shift+W` | Settings window: palette and wallpaper widgets by click |
| `Alt+Ctrl+L` | Lock |

**The menu** (`Super+Shift+Space`) has these sections: windows, projects, modes, widgets, hosts,
services, notes, links, snip, card, minutes, mail, grab, qr, focus, clipboard, calc, emoji, pw,
audio, wifi, bluetooth, vpn, night, wall, kill, pass, theme, power. The less obvious ones:

- `links` opens a bookmark from `config/links`; `snip` copies a text snippet from `config/snippets`.
- `qr` shows the clipboard as a QR code, to get a link onto your phone (`qr <text>` in a terminal).
- `pw` puts a new 24-character password in the clipboard, for one paste.
- `vpn` connects, disconnects or picks a country; `wall` picks the wallpaper from `~/med/img/wall`;
  `kill` stops a process, heaviest first.

**Scratchpads** toggle a floating window and start the app on first use:
`` Super+` `` terminal, `Super+Ctrl+N` note, `Super+Ctrl+C` calculator, `Super+Ctrl+A` agenda,
`Super+Ctrl+P` KeePassXC, `Super+Ctrl+M` music, `Super+Ctrl+E` mail.

**Screenshots:** `Print` region → annotate → clipboard; `Super+Print` region → file;
`Shift+Print` whole screen → file. Files land in `~/med/img/shot`.
**Recording:** `Super+F9` screen, `Super+Shift+F9` region; the same key stops it. Files land in `~/med/vid/rec`.

**Screen grab** (`Super+G`): select a region and get its `text` (OCR), `tex` (formula → LaTeX),
`qr` payload or `color` in the clipboard.

**Keyboard layer:** Caps is Esc when tapped, Ctrl when held. Hold Space and press:
`h j k l` arrows, `u i o p` Home/PgDn/PgUp/End, `n` Backspace, `m` Delete,
`a s d f` → `{ [ ] }`, `g` → `\`, `q` → `|`, `w` → `~`, `e` → `@`.

**Monitors:** `hub mon` opens a drag-and-drop arranger; `hub mon save <name>` stores the layout
as a profile that is applied automatically when those monitors are connected.

**Wallpaper widgets**: agenda, tasks, focus, projects, system, net, markets, weather, music,
inbox, month, services. They show only on empty workspaces. Switch them, the whole dashboard and
its position by click in the settings window (`Super+Shift+W`), from the menu (`widgets`), or with
`widgets on|off <name>`, `widgets show|hide`, `widgets pos top|bottom`.
Location for the weather: `config/eww/weather.conf`.

## Modes

`mode <name>` enters a mode, `mode -` leaves it, `mode` alone asks. The bar shows the current
one. Entering a mode first runs the previous mode's clean-up.

| Mode | For |
|---|---|
| `dev` | Editor on 1, browser on 2 |
| `school` | Notes, references, cards |
| `work` | Separate browser profile, work identity, personal noise off |
| `fin` | Vault open, quotes, ledger |
| `ops` | Homelab: host picker, deploy recipes |
| `hack` | Switches to the `hack` system profile (VPN kill switch, random MAC), lab network up, works in `~/hkng` |
| `meet` / `present` | Nothing pops up, the screen stays on |
| `game` | Full power, no interruptions |
| `battery` | Stretch a charge |
| `travel` | Untrusted networks: VPN forced, no local sharing, quick lock |

A mode is one file, `config/mode/<name>.sh`, with an `up()` and a `down()` function. Add a file to add a mode.

## Projects

- `hub new <template> <name>` creates `~/dev/active/<name>` with its own devshell, direnv and git.
  Templates: `py`, `quant`, `node`, `c`, `go`, `rust`, `pen`, `tex`.
  Libraries belong in the project's `flake.nix`, never in the system.
- `pj [query]` opens or resumes the project's tmux session (nvim plus a shell) and starts time tracking.
- `pj -s [plan|wip|paused|done]` sets the status of the project you are in; `pj -l` lists all. Done projects sort last.
  `done` moves the project to `~/dev/finished`; any other status on a finished project moves it back to `~/dev/active`.
- `pj -n` opens the notes of the project you are in (`~/doc/notes/projects/<name>.md`).
- `hub svc up|down` runs the project's services (Postgres, Redis, …) declared in its `devenv.nix`.
- `hub agent <name> [command]` runs a coding agent in its own git worktree, jailed: it can write only there and cannot see your home, SSH keys, vault or secrets.
- `hub report` shows the week's tracked time by mode and project.
- Commits are SSH-signed, and a pre-commit hook blocks commits that contain secrets.
  Folders `~/dev/work`, `~/doc/work` and `~/doc/school` use their own git identity.
- In nvim: `<leader>hh` hub menu, `<leader>hs` project status, `:Hub <recipe>`, `:Ask <question>`.

Shell: `Ctrl+R` searches history (atuin), `cd <fragment>` jumps to a known directory when the
path does not exist, `mkcd`, `x <archive>` extracts. Tab completes options and arguments of
most commands (carapace) in a fuzzy menu. `ls`/`la` list with lsd (git status column). Aliases: `g` git, `lg` lazygit, `v` nvim,
`t` task, `nd` nix develop, `del` moves files to the trash instead of deleting (`trash-restore` undoes).

## Notes, tasks, focus

- `Super+N` captures one line into `~/doc/notes/inbox.md`. Start it with `t ` and it becomes a task instead.
- `hub triage` empties that inbox line by line: make it a task, move it to today's note, delete or keep.
- `hub review` writes the weekly review note (tracked time, finished tasks, commits per project,
  open projects) into `~/doc/notes/weekly/` and opens it.
- `remind 25m "call back"` or `remind 17:30 "leave"` notifies you later; `remind list` shows what is
  pending. Reminders do not survive a logout.
- **Dictation** (feature `minutes`): `Super+F11` starts listening, again stops, and what you said
  is typed into the focused window. Local; it shares the speech model with meeting notes.
- `Super+Ctrl+D` opens today's daily note; `note find` searches all notes. `~/doc/notes` is also an Obsidian vault.
- `focus [minutes] [subject]` starts a focus block: notifications held, distracting sites blocked,
  time logged. `focus stop` ends it early. The blocked sites are `hub.focus.sites` in the host file.
- Calendar (feature `calendar`): `Super+Ctrl+A`; the next event shows in the bar.
- **Mail** (feature `mail`): `Super+Ctrl+E` or `email` opens aerc; the bar shows the unread count.
  Accounts are in `config/aerc/accounts.conf`.
- **Flashcards:** copy the answer (a selection, or a formula with `grab tex`), press `Super+Ctrl+F`
  and type the question. Cards collect in `~/doc/school/cards.tsv`; in Anki use File → Import.
- **Meeting notes** (feature `minutes`): `Super+F10` starts recording your microphone and what you
  hear; press it again to stop. The transcript lands in `~/doc/notes/meetings/`, with a summary on
  top when the feature `ai` is on. The first run downloads the speech model (about 470 MB).
- **Phone** (feature `phone`): pair from the tray icon. Notifications, clipboard and files then
  move between phone and laptop. It is stopped on untrusted wifi.

## LaTeX

- `hub new tex` picks one of your templates (every folder in `~/tpl/latex` is one) and creates the document in `~/doc/school|work|personal`.
- `fig <name>` draws a figure in Inkscape and puts the `\includegraphics` line in the clipboard.
- `hub untex <file.pdf>` turns a PDF or scan back into LaTeX source. The first run downloads several GB of models.

## Money

- `hub vault open|close|status`: the separately encrypted directory `~/vlt`. `~/fin` points into it. It closes on lock and suspend.
- `hub fava` opens the vault and the accounting dashboard (ledger in `~/fin/ledger`).
- `hub mkt` prints quotes for `config/market/watchlist`; `hub mkt hist <symbol>` stores daily history as parquet in `~/dat/mkt`.
- `hub new quant <name>` creates a research project (polars, duckdb, numba, jupyter).

## Safety

- `/home` is snapshotted automatically. Old versions of a file are under `/home/.snapshots/<n>/snapshot/`.
- `hub bak` runs every enabled backup now. Backups are off until you switch on `backupExternal`,
  `backupHomelab` or `backupCloud`. The cloud target reads its repository and credentials from the
  secrets `restic-cloud-repo` and `restic-cloud-env` (see `modules/backup.nix`).
- `hub drill` restores a random file from a snapshot and from each backup and compares it.
- `hub sec` edits the encrypted secrets.
- **Fresh root** (feature `freshRoot`, off by default): `/` becomes a RAM disk that starts empty at
  every boot, so nothing undeclared piles up. `/home`, `/nix`, logs and the directories listed in
  `modules/fresh-root.nix` (service state, VPN account, host keys) survive. Before switching it on,
  run `hub passwd` and use that instead of `passwd` from then on, or the password resets to the
  initial one at reboot. It takes effect at the next reboot; switching it off and rebooting brings
  the ordinary root back with its state.
- `hub disk` shows what is using your home; `hub firmware` installs firmware updates.
- `hub charge` charges to 100% once; otherwise the battery stops at 80%.

## Lab and homelab

- `hub lab up|down|reset <name>`, `hub lab list`: disposable VMs from base images in `~/tec/vm/<name>.qcow2`,
  on an isolated network that cannot reach the LAN. `reset` returns one to its base state.
- `hub probe` shows which homelab services are up. List them in `config/homelab/services`
  (a name and a URL per line). One that is down shows in the bar's health indicator and in the
  `services` widget.
- `hp` picks a machine from the tailnet or SSH config and opens SSH with a resumed tmux session.
- `hub deploy <host>` rebuilds a remote host from here; `hub install <host> <ip>` installs one. `hub iso` (or `bin/build-iso` on a machine without NixOS) builds the installer into `iso/`, `hub flash` writes it to a USB stick; on boot it starts `hub-install`, a menu-driven installer (whole disk, free space or one partition next to Windows; see docs/INSTALL.md). `hub test-install [whole|dual|replace]` installs a test host with it in a VM (~10 min; `dual` into free space next to a fake Windows, `replace` over one of its partitions).
- `hub net` shows wifi, address, VPN and tailnet state.
- `ask <question>` queries the local model (needs `hub.ai.enable`); it reads stdin too: `git diff | ask "review this"`.

## Home directory

| Folder | Contents |
|---|---|
| `doc` | `personal`, `work`, `school`, `notes` |
| `dev` | `active`, `work`, `finished`, `practice`, `testing` |
| `dl` | Downloads |
| `tpl` | Templates (`latex`) |
| `med` | `img/shot`, `img/wall`, `vid/rec` |
| `ent` | `games` |
| `hkng` | Security work |
| `dat` | `bak`, `arc`, `mkt` |
| `tec` | `nix` (this repo), `vm`, `lab`, `sftw` |
| `fin` → `vlt/fin` | Finance, inside the vault |
