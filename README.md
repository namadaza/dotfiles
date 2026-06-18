# Update 6/16/2025

## Opencode Usage

`npx codeburn`

## Opencode Auth Keys

`cat ~/.local/share/opencode/auth.json`

# vimconfig

# Update 11/5/2025

Set this up to hold configurations for commonly used tools, as well as bash scripts to map updates to relevant config locations.

- aerospace -- window tiling
- cursor -- code editor
- ghostty -- terminal
- hunk -- git diff viewer (`hunk diff --watch`, `hunk show`)
- nvim -- LazyVim-based Neovim config
- sketchybar -- menu bar replacement

## Hunk Installation

[Repo](https://github.com/modem-dev/hunk). Hunk reads from `~/.config/hunk/config.toml`. Run our setup script to copy this repo's config into place.

```
./scripts/hunk-update-config.sh
```

Common usage:

```
hunk diff --watch    # live diff viewer
hunk show <ref>      # show a specific commit/ref
```

## Neovim Installation

This repo stores the Neovim config under `nvim/`. It is based on the [LazyVim starter](https://github.com/LazyVim/starter), but unlike the upstream quickstart you should not clone directly into `~/.config/nvim`. Keep changes in this repo, then run the update script to copy them into place.

Prereqs: Neovim `>= 0.11.2`, plus `ripgrep` and `fd`.

```
brew install neovim ripgrep fd
brew upgrade neovim
```

Fresh LazyVim reset from upstream starter:

```
rm -rf nvim
git clone https://github.com/LazyVim/starter nvim
rm -rf nvim/.git
./scripts/nvim-update-config.sh
nvim
```

Normal update after editing this repo's `nvim/` files:

```
./scripts/nvim-update-config.sh
nvim
```

Preserved custom Harpoon mappings (leader is `<space>`):

```
<leader>a        harpoon: add current file
<leader>x        harpoon: open menu
<leader>1..4     harpoon: jump to slot
```

## Troubleshooting

### `tmux`: missing or unsuitable terminal: xterm-ghostty (over SSH)

When SSHing from Ghostty to a host that doesn't have Ghostty's terminfo installed, `tmux attach` (and other TUIs) fail with `missing or unsuitable terminal: xterm-ghostty`. The remote machine doesn't know the `xterm-ghostty` terminal type, so ncurses refuses to start.

The Ghostty config in this repo enables `shell-integration-features = ssh-terminfo,ssh-env`, which auto-installs the terminfo on each `ssh` from Ghostty. If you're on a machine without that config applied yet, install it manually by piping the local terminfo into `tic` on the remote:

```
infocmp -x | ssh <user>@<host> -- /usr/bin/tic -x -
```

This writes `~/.terminfo/78/xterm-ghostty` on the remote — a one-time install that persists for future sessions.

## Sketchybar Installation

Backup of [original](https://felixkratz.github.io/SketchyBar/setup).

```
brew tap FelixKratz/formulae
brew install sketchybar

mkdir -p ~/.config/sketchybar/plugins
cp $(brew --prefix)/share/sketchybar/examples/sketchybarrc ~/.config/sketchybar/sketchybarrc
cp -r $(brew --prefix)/share/sketchybar/examples/plugins/ ~/.config/sketchybar/plugins/
```

Then, run our set up script.

```
./scripts/sketchybar-update-config.sh
```

# Update 7/17/2025

No longer using Neovim, switched to using VSCode/Cursor. Use the profile stored in the root of this directory to quickly set up a vim-like experience, with file pinning from harpoon, periscope for grep searches, and similar key bindings.

# Old Neovim Setup

### Fresh Setup

- Download neovim `brew install neovim`
- Download a Nerd font (ie [FiraCode Nerd](https://www.nerdfonts.com/))
- Make sure terminal has Nerd font set
- Install ripgrep `brew install ripgrep`
- Install the tailwindcss-language-server `npm i -g tailwindcss-language-server`
- Install eslint `npm install -g eslint`
- Install prettier `npm install -g prettier`
- Install cspell `npm install -g cspell` | `<leader>ca` opens code actions for cspell

### Useful Commands

`:LspInfo`
Shows the currently active LSPs attached to the buffer.
