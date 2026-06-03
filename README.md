# zimfw-prompt

A feature-rich Zsh prompt theme for the [Zimfw](https://github.com/zimfw/zimfw) framework.

## Features

- **Async Git status** via `zsh-async` — the synchronous prompt does at most one
  `git-dir` fork; branch, ahead/behind, dirty/staged/untracked, stash count,
  tags, detached-HEAD position and worktree detection are all computed in a
  background worker and rendered when ready.
- **Vi-mode indicator** — INSERT / NORMAL / VISUAL / V-LINE, updated live on
  keymap changes.
- **Command duration** for long-running commands (via `duration-info`).
- **SSH and Docker awareness** — shows `user@host` over SSH and a marker inside
  containers.
- **Python virtualenv** segment.
- **OSC 133** shell-integration marks (prompt/command/output regions) for
  terminals such as WezTerm and VS Code, plus exit-status reporting.
- **Selective history** — genuine command-not-found entries are not recorded,
  while `HIST_IGNORE_SPACE` / `HIST_IGNORE_DUPS` are still honored.
- Custom `SPROMPT` (spell-correction) and `SUDO_PROMPT`.

## Requirements

- Zsh with a terminal that supports `%F{0-15}` colors and a Nerd Font (the
  theme uses Unicode/Nerd-Font glyphs).
- Zimfw modules: **`zsh-async`**, **`git-info`**, **`duration-info`**.

## Installation

Add to your `~/.zimrc`, ensuring the dependencies are listed first:

```zsh
zmodule zsh-users/zsh-async --source async.zsh
zmodule git-info
zmodule duration-info
zmodule <your-namespace>/zimfw-prompt
```

Then rebuild and restart your shell:

```zsh
zimfw build
exec zsh
```

## Customization

Git status formatting is driven by `zstyle ':zim:git-info:*'` definitions near
the top of `zimfw-prompt.zsh-theme`; the duration threshold/format lives under
`zstyle ':zim:duration-info'`. Edit those format strings to restyle without
touching the prompt logic. See `CLAUDE.md` for an architecture overview.

## License

MIT — see [LICENSE](LICENSE).
