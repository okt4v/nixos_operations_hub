# NixOS operations hub

Flake for the user's machines. Lives at `~/tec/nix` on an installed host (`hub.dir`).

## Layout

- `flake.nix` — every directory in `hosts/` is a `nixosConfiguration`
- `hosts/<host>/default.nix` — imports from `modules/`, host quirks; `features.nix` — on/off flags (`hub feature`); `hardware.nix` generated
- `modules/` — system modules, one concern each (core, desktop, keyboard, dev, lab, play, network, snapshots, backup, secrets, boot, power, meetings, minutes, mail, phone, fresh-root, ai, hack, disk, home-manager)
- `home/` — Home Manager (shell, desktop, dev, apps, dirs, palette, calendar, finance)
- `config/` — dotfiles, **linked live** into `~/.config` (edit + reload, no rebuild). Exception: `config/kanata` needs a rebuild
- `bin/` — scripts, live on PATH; `hub` is a fuzzy menu over the `justfile`
- `templates/` — project templates for `hub new`; `secrets/` — sops secrets; `docs/INSTALL.md`

## Conventions

- Repo folders and files use full names. Only the **home directory layout** uses short names (`doc dev dl tpl med ent hkng dat tec fin vlt`, see `home/dirs.nix`)
- A host's optional parts are flags in `hosts/<host>/features.nix` (one `name = true; # description` per line; `bin/feature` edits it with sed, so keep that shape). `hosts/<host>/default.nix` turns a flag into a module import or an option. New optional feature: a flag there, a module in `modules/`, a row in the GUIDE table
- Other options: `hub.dir`, `hub.disk`, `hub.net.trusted`, `hub.focus.sites`, `hub.backup.*.repo`
- Project libraries go in the project's devshell (`templates/`), never in system packages
- Colours come from `config/palette/<name>` (eight values; `theme apply` regenerates the per-app files); do not hardcode them elsewhere in `config/`
- New script: add to `bin/`, add a recipe to `justfile` if it is an operation, keep it shellcheck-clean
- New mode: `config/mode/<name>.sh` with `up()` / `down()`; helpers `on`, `pp`, `dnd`, `running` come from `bin/mode`
- `docs/GUIDE.md` is the user guide: update it in the same change whenever a command, key binding, mode, template or workflow changes
- Commit every change (and push to `origin`); never list an AI as author or co-author
- `ponytail:` comments mark deliberate shortcuts and their upgrade path

## Commands

- `hub switch` / `hub test` / `hub rollback` / `hub update`
- `hub feature [list|on|off <name>]` — feature flags of this host
- `hub status` (overview), `hub doctor` (open setup steps), `hub health` (problems), `hub diff` (what a switch would change)
- `widgets list|on|off <name>|show|hide|pos top|bottom` — wallpaper dashboard; state in `config/eww/widgets.conf`
- `pj` jump to a project, `pj -s <plan|wip|paused|done>` set its status, `pj -l` list
- `hub check` — evaluates all hosts and shellchecks `bin/` and sway scripts
- `hub vm [host]` — boot a host in a throwaway VM (ssh -p 2222 oktav@localhost, password `test`); the repo is shared at `hub.dir`. The session locks after 10 idle minutes
- New files must be `git add`ed before nix sees them
