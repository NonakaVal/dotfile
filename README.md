# Debian Dotfiles

Personal configuration files for Debian-based Linux systems. Organized for easy backup, sharing, and restoration across multiple machines.

## Repository Structure

```
dotfile/
├── install.sh              # Automated installation script
├── backup.sh               # Backup current configurations
├── README.md               # This file
├── LICENSE                 # MIT License
├── shell/                  # Shell configurations
│   └── bash/
│       ├── .bashrc
│       ├── .bash_aliases
│       ├── .bash_logout
│       └── .profile
├── desktop/                # Desktop environment configs
│   ├── i3/                 # i3 window manager
│   ├── i3blocks/           # Status bar
│   ├── kitty/              # Terminal emulator
│   ├── rofi/               # Launcher
│   ├── gtk-3.0/            # GTK theme
│   └── scripts/            # Desktop scripts
├── apps/                   # Application configs
│   ├── git/
│   │   └── .gitconfig
│   ├── aichat/
│   ├── fastfetch/
│   └── gnome-shortcuts-export.json
└── bin/                    # User scripts
    ├── gca
    ├── transcribe
    ├── transcribe-install.sh
    ├── vconvert
    └── whisper
```

## Quick Start

```bash
git clone https://github.com/NonakaVal/debian-dotfiles.git ~/dotfile
cd ~/dotfile
./install.sh all
```

## Usage

### Installation

The `install.sh` script allows selective installation of configuration components:

```bash
# Install everything
./install.sh all

# Install only specific components
./install.sh shell      # Shell configs only
./install.sh desktop    # Desktop configs only
./install.sh apps       # Application configs only
./install.sh bin        # User scripts only

# Skip backup of existing files
./install.sh all --no-backup

# Dry run - show what would be installed
./install.sh all --dry-run
```

### Backup

The `backup.sh` script backs up your current configurations:

```bash
# Backup everything
./backup.sh all

# Backup specific components
./backup.sh shell
./backup.sh desktop
./backup.sh apps
./backup.sh bin

# List all available backups
./backup.sh list

# Restore the most recent backup to repository
./backup.sh restore

# Use fixed backup directory name (useful for automation)
./backup.sh all --no-timestamp
```

## What's Included

### Shell Configuration
- **Bash** configurations with:
  - Custom prompt with color support
  - History management
  - Useful aliases for Flatpak and system utilities
  - Enhanced directory navigation

### Desktop Environment
- **i3** - Tiling window manager configuration
- **i3blocks** - Status bar with scripts for:
  - Volume and brightness control
  - Bluetooth status
  - Now playing info
- **Kitty** - Modern terminal emulator
- **Rofi** - Application launcher and menu system
- **GTK 3.0** - Theme configuration
- **Custom scripts** for:
  - Rofi window overview
  - Favorite apps launcher
  - File browser
  - Power menu

### Applications
- **Git** - Configuration with user details and SSH URL rewriting
- **aichat** - AI chat client configuration
- **fastfetch** - System information tool
- **Gnome shortcuts** - Exported keyboard shortcuts

### User Scripts
- **gca** - Git commit all helper
- **transcribe** - Audio transcription using Whisper AI
- **transcribe-install.sh** - Whisper installation script
- **vconvert** - Video conversion utility
- **whisper** - Whisper AI interface

## Manual Installation

If you prefer to manually link specific files:

```bash
# Shell configurations
ln -s ~/dotfile/shell/bash/.bashrc ~/.bashrc
ln -s ~/dotfile/shell/bash/.bash_aliases ~/.bash_aliases
ln -s ~/dotfile/shell/bash/.bash_logout ~/.bash_logout
ln -s ~/dotfile/shell/bash/.profile ~/.profile

# Git configuration
ln -s ~/dotfile/apps/git/.gitconfig ~/.gitconfig

# Desktop configurations
ln -s ~/dotfile/desktop/i3 ~/.config/i3
ln -s ~/dotfile/desktop/i3blocks ~/.config/i3blocks
ln -s ~/dotfile/desktop/kitty ~/.config/kitty
ln -s ~/dotfile/desktop/rofi ~/.config/rofi

# User scripts
ln -s ~/dotfile/bin/gca ~/.local/bin/gca
ln -s ~/dotfile/bin/transcribe ~/.local/bin/transcribe
# ... and so on for other scripts
```

## Workflow

### Setting Up a New Machine

1. Clone the repository
2. Run `./install.sh all`
3. Customize as needed
4. Commit and push changes

### Updating Your Dotfiles

```bash
# Make changes to your config files
# Then update the repository
cd ~/dotfile
./backup.sh all      # Back up current configs to repo structure
git add .
git commit -m "Update configs"
git push
```

### Syncing Across Multiple Machines

1. Pull latest changes on target machine
2. Run `./install.sh all`
3. Review and merge any conflicts

### Keeping Configs in Sync Without Git

1. Make changes locally
2. Run `./backup.sh all` to capture changes
3. Manually review and commit if needed

## Customization

### Adding New Configurations

1. Place the file in the appropriate directory:
   - Shell configs → `shell/bash/`
   - Desktop configs → `desktop/`
   - Application configs → `apps/`
   - User scripts → `bin/`

2. Update the installation script if necessary (or symlink manually)

3. Test with `./install.sh --dry-run`

### Adding New User Scripts

1. Add executable scripts to `bin/`
2. Make them executable: `chmod +x bin/your-script`
3. Run `./install.sh bin` to create symlinks

## System Requirements

- Debian-based Linux distribution
- Bash shell
- i3 window manager (for desktop configs)
- Kitty terminal (optional)
- Git

## Backup and Restore

The backup script automatically creates timestamped backups in `.backups/`:

```bash
# View backups
ls -lh .backups/

# Restore specific backup
BACKUP_DIR=".backups/home_backup_20260504_120000"
cp -r "$BACKUP_DIR"/shell/* shell/
cp -r "$BACKUP_DIR"/desktop/* desktop/
# ... etc
```

## Safety

- **Always back up** existing configurations before running the installation script
- Use `--dry-run` to preview changes
- Review `.backups/` directory for automatic backups created during installation
- Test changes on a non-critical system first

## Troubleshooting

### Symlinks Not Working
Ensure you have write permissions in your home directory and that `~/dotfile` path is correct.

### Scripts Not Executable
Run `chmod +x ~/dotfile/bin/*` to make scripts executable.

### Desktop Configs Not Loading
Restart your display manager or log out and log back in.

## Contributing

Feel free to fork this repository and customize it for your needs. If you find issues or have suggestions, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

Built with Debian Linux in mind. Inspired by the open-source dotfile community.
