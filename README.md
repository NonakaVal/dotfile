# Debian Dotfiles

Personal configuration files for Debian 13 (trixie) with GNOME desktop.

## System Profile

| Component | Value |
|-----------|-------|
| OS | Debian 13.4 (trixie) |
| Kernel | 6.12.86+deb13-amd64 |
| GPU | NVIDIA GTX 1660 SUPER (driver 550.163) |
| Desktop | GNOME (x11) |
| Shell | Bash 5.x |
| RAM | 16GB |

## Repository Structure

```
dotfile/
├── install.sh              # Symlink installer (run as user)
├── backup.sh               # Backup current configs to repo
├── scripts/
│   ├── provision.sh        # Post-reboot provisioning (run as root)
│   ├── nvidia-setup.sh     # NVIDIA driver installer
│   ├── packages-apt.list   # APT packages
│   ├── packages-flatpak.list # Flatpak apps
│   ├── packages-cargo.list # Rust tools
│   ├── packages-npm.list   # npm global packages
│   └── packages-pip.list   # Python packages
├── shell/bash/
│   ├── .bashrc
│   ├── .bash_aliases
│   ├── .bash_logout
│   └── .profile
├── desktop/
│   ├── gnome/              # GNOME configs (dconf, extensions)
│   ├── i3/                 # i3 wm (alternative)
│   ├── i3blocks/
│   ├── kitty/
│   ├── rofi/
│   ├── gtk-3.0/
│   └── scripts/
├── apps/
│   ├── git/.gitconfig
│   ├── aichat/
│   ├── fastfetch/
│   ├── opencode-config/
│   ├── opencode/
│   └── agents/
└── bin/                    # User scripts
```

## Post-Reboot Setup

After a fresh Debian install, run in order:

```bash
# 1. Clone repo
git clone https://github.com/NonakaVal/debian-dotfiles.git ~/Documentos/Github/dotfile

# 2. Provision system (as root)
sudo bash ~/Documentos/Github/dotfile/scripts/provision.sh
# Or non-interactive:
sudo bash ~/Documentos/Github/dotfile/scripts/provision.sh essential

# 3. Install dotfiles symlinks (as user)
cd ~/Documentos/Github/dotfile && ./install.sh all

# 4. Reboot if NVIDIA driver was installed
sudo reboot

# 5. After reboot
source ~/.bashrc
nvm install --lts
```

## Provisioning Menu

`scripts/provision.sh` offers interactive selection:

| Option | Description |
|--------|-------------|
| `1` system-update | apt update + upgrade |
| `2` nvidia | NVIDIA driver (GTX 1660 SUPER) |
| `3` apt-core | Essential APT packages |
| `4` flathub | Configure Flathub remote |
| `5` flatpaks | Install Flatpak apps (selectable) |
| `6` gnome | GNOME tweaks + extensions |
| `7` i3 | i3 wm (alternative desktop) |
| `8` node | Node.js via nvm |
| `9` cargo | Rust tools (aichat, basalt) |
| `A` docker | Docker |
| `B` pip | Python packages (whisper) |
| `C` npm-global | npm packages (opencode) |
| `D` dotfiles | Run install.sh symlinks |

Shortcuts: `all` = everything, `essential` = update + nvidia + apt + flathub + gnome + dotfiles

## Install Commands

```bash
# Install all dotfile symlinks
./install.sh all

# Individual components
./install.sh shell          # Bash configs
./install.sh desktop        # GNOME + i3/kitty/rofi
./install.sh gnome          # GNOME dconf + extensions only
./install.sh apps           # Git, aichat, fastfetch
./install.sh bin            # User scripts
./install.sh opencode-config
./install.sh opencode
./install.sh agents

# Save current GNOME state to repo
./install.sh save-gnome

# Options
./install.sh all --dry-run
./install.sh all --no-backup
```

## What's Included

### Shell
- Bash with custom prompt, history, aliases
- PATH setup: cargo, gems, nvm, bun, opencode
- AI helper functions (aif, aihelp, ailogs, addlog)
- Flatpak aliases for all installed apps

### GNOME Desktop
- 21 enabled extensions (dash-to-panel, tiling-shell, vitals, etc.)
- dconf settings dump for full restore
- GTK 3.0 theme config

### i3 (alternative)
- i3 wm with i3blocks status bar
- Rofi launcher with powermenu and file browser
- Kitty terminal config
- Volume/brightness/bluetooth scripts

### Applications
- **Git** - SSH URL rewriting, LFS
- **aichat** - AI chat CLI (Rust, via cargo)
- **fastfetch** - System info on terminal open
- **opencode** - AI coding assistant

### User Scripts
- `gca` - Git commit all helper
- `transcribe` / `whisper` - Audio transcription
- `snippet-holder` - Snippet manager

## Customization

### Adding Flatpak Apps

1. Install the app: `flatpak install flathub <app_id>`
2. Add alias to `shell/bash/.bash_aliases`
3. Add entry to `scripts/packages-flatpak.list`
4. Run `./install.sh shell`

### Saving GNOME Changes

After tweaking GNOME settings:

```bash
./install.sh save-gnome
git add desktop/gnome/
git commit -m "Update GNOME settings"
```

### Updating Package Lists

Edit the files in `scripts/packages-*.list` and re-run provision.

## License

MIT
