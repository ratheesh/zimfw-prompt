# vim:et sts=2 sw=2 ft=zsh
#
# Copyright (c) 2025 Ratheesh<ratheeshreddy@gmail.com>. All Rights Reserved.
#
# My Custom theme that displays relevant, and contextual information.
#
# A simplified fork of the original sorin theme from
# Based on : https://github.com/zimfw/sorin
# Async Reference:http://github.com/sorin-ionescu/prezto/blob/master/modules/prompt/functions/prompt_sorin_setup
#

#
# 16 Terminal Colors
# -- ---------------
#  0 black
#  1 red
#  2 green
#  3 yellow
#  4 blue
#  5 magenta
#  6 cyan
#  7 white
#  8 bright black
#  9 bright red
# 10 bright green
# 11 bright yellow
# 12 bright blue
# 13 bright magenta
# 14 bright cyan
# 15 bright white
#
#

autoload -Uz async && async

# Add zimfw/git-info functions to fpath and autoload
# fpath=("${ZIM_HOME:-${HOME}/.zim}/modules/git-info/functions" $fpath)
autoload -Uz git-info git-action coalesce

if (( $+commands[tput] )); then
  italic=$(tput sitm)         # enter italics
  ritm=$(tput ritm)           # exit italics only (cheaper than a full sgr0 reset)
  reset=$(tput sgr0)          # reset all attributes
  terminfo_down_sc=$terminfo[cud1]$terminfo[cuu1]$terminfo[sc]$terminfo[cud1]
else
  italic='' ritm='' reset='' terminfo_down_sc=''
fi

# Format a git action name (from zimfw/git-info's git-action) into a prompt string.
function _fmt_git_action() {
    emulate -L zsh
    local action
    action=$(git-action 2>/dev/null) || return
    local s="%F{8}🙤 %F{172} " e="%F{8}🙦 "
    case $action in
        rebase-i)   print "${s}%F{27}%B>%b%f%F{162}R%F{27}%B>%b%{$italic%}%F{1}rebase-i%{$ritm%}${e}" ;;
        rebase-m)   print "${s}%F{1}%{$italic%}rebase-merge%{$ritm%}${e}" ;;
        rebase)     print "${s}%F{27}%B>%f%F{162}R%F{27}%B>%b%{$italic%}%F{1}rebase%{$ritm%}${e}" ;;
        am)         print "${s}%F{1}%{$italic%}apply%{$ritm%}${e}" ;;
        am/rebase)  print "${s}%F{1}%{$italic%}apply/rebase%{$ritm%}${e}" ;;
        merge)      print "${s}%F{1}%{$italic%}merge%{$ritm%}${e}" ;;
        cherry)     print "${s}%F{1}%{$italic%}cherry-pick%{$ritm%}${e}" ;;
        cherry-seq) print "${s}%F{1}%{$italic%}cherry-pick-sequence%{$ritm%}${e}" ;;
        revert)     print "${s}%F{1}%{$italic%}revert%{$ritm%}${e}" ;;
        revert-seq) print "${s}%F{1}%{$italic%}revert-sequence%{$ritm%}${e}" ;;
        bisect)     print "${s}%F{27}%B<%b%f%F{162}B%F{27}%B>%b%{$italic%}%F{1}bisect${e}" ;;
    esac
}

# Render the tag pointing at HEAD (if any) as a prompt fragment.
# $1 = bracket color (defaults to 60). Always invoked from the async worker,
# so its git fork stays off the synchronous prompt path.
function _fmt_tag() {
    emulate -L zsh
    local tag bracket=${1:-60}
    tag=$(git describe --exact-match --tags HEAD 2>/dev/null) || return
    [[ -n $tag ]] || return
    print -rn -- "%{$reset%}%F{${bracket}}⸨%{$italic%}%F{1}󱈤 %{$ritm%}%f%F{66}${tag}%F{${bracket}}⸩%f"
}

# zimfw/git-info configuration
zstyle ':zim:git-info' verbose yes
zstyle ':zim:git-info:clean'             format '%F{27}✔ %f'
zstyle ':zim:git-info:dirty'             format '%F{9}✘ %f'
zstyle ':zim:git-info:diverged'          format '%B%F{9}󰃻 %f%b'
zstyle ':zim:git-info:stashed'           format '%F{7}%S%F{63}%B %f%b'
zstyle ':zim:git-info:ahead'             format '%F{7}%A%F{34}󰁞 %f'
zstyle ':zim:git-info:behind'            format '%F{7}%B%F{198}󰁆 %f'
zstyle ':zim:git-info:indexed'           format '%F{7}%i%F{2}󱇬 %f'
zstyle ':zim:git-info:unindexed'         format '%F{7}%I%F{202}✱ %f'
zstyle ':zim:git-info:untracked'         format '%F{7}%u%F{8}󰋖%f'
zstyle ':zim:git-info:action'            format '%F{8}🙤 %F{172}%s%F{8}🙦 '
zstyle ':zim:git-info:action:rebase-i'   format "%F{27}%B>%b%F{162}R%F{27}%B>%b%{$italic%}%F{1}rebase-i%{$reset%}%f"
zstyle ':zim:git-info:action:rebase-m'   format "%{$italic%}%F{1}rebase-merge%{$reset%}%f"
zstyle ':zim:git-info:action:rebase'     format "%F{27}%B>%b%F{162}R%F{27}%B>%b%{$italic%}%F{1}rebase%{$reset%}%f"
zstyle ':zim:git-info:action:am'         format "%{$italic%}%F{1}apply%{$reset%}%f"
zstyle ':zim:git-info:action:am/rebase'  format "%{$italic%}%F{1}apply%F{27}%B/%b%F{1}rebase%{$reset%}%f"
zstyle ':zim:git-info:action:merge'      format "%F{27}%B>%b%F{162}󰽜 %F{27}%B<%b%f%{$italic%}%F{1}merge%{$reset%}%f"
zstyle ':zim:git-info:action:cherry'     format "%{$italic%}%F{1}cherry-pick%{$reset%}%f"
zstyle ':zim:git-info:action:cherry-seq' format "%{$italic%}%F{1}cherry-pick-sequence%{$reset%}%f"
zstyle ':zim:git-info:action:revert'     format "%{$italic%}%F{1}revert%{$reset%}%f"
zstyle ':zim:git-info:action:revert-seq' format "%{$italic%}%F{1}revert-sequence%{$reset%}%f"
zstyle ':zim:git-info:action:bisect'     format "%F{27}%B<%b%F{162}B%F{27}%B>%b%f%{$italic%}%F{1}bisect%{$reset%}%f"
zstyle ':zim:git-info:keys' format \
    'pre_branch'  '%C%D%V%s' \
    'post_branch' '%S%A%B%i%I%u'

# ❰ ❱ ❮ ❯
function _prompt_chars() {
  emulate -L zsh
  case ${KEYMAP} in
    vicmd) print -n '%B%F{167}❮%F{250}❮%F{29}❮%b';;
    *) print -n '%B%F{29}❯%F{250}❯%F{167}❯%b';;
  esac
}

function _virtualenv_info() {
  emulate -L zsh
  print -n "${VIRTUAL_ENV:+" %F{60}⸨%F{198}󰌠 %{$italic%}%F{179}${VIRTUAL_ENV:t}%f%{$reset%}%F{60}⸩%f"}"
}

function _left_prompt_info() {
  emulate -L zsh
  print -n "   $(_prompt_mode)$(_virtualenv_info)${_left_git_info}$(_prompt_dockerinfo)%(?::%B%F{197} 󱞦%f%b)"
}

function _prompt_mode() {
  emulate -L zsh
  case ${KEYMAP} in
    vicmd)
      print -n "%F{8}🙟 %F{95}%B%{$italic%}normal%{$ritm%}%b%F{8}🙝 %f"
      ;;
    main|viins)
      print -n "%F{8}🙟 %F{103}%B%{$italic%}insert%{$ritm%}%b%F{8}🙝 %f"
      ;;
    vivis)
      print -n "%F{8}🙟 %F{126}%B%{$italic%}visual%{$ritm%}%b%F{8}🙝 %f"
      ;;
    vivli)
      print -n "%F{8}🙟 %F{126}%B%{$italic%}v-line%{$ritm%}%b%F{8}🙝 %f"
      ;;
    *) # print -n "UNKNOWN -> $KEYMAP"
  esac
}

function _prompt_keymap_select() {
  zle reset-prompt
  zle -R
}
autoload -Uz add-zle-hook-widget
add-zle-hook-widget -Uz keymap-select _prompt_keymap_select

function _prompt_dockerinfo() {
  emulate -L zsh
  [[ -f /.dockerenv ]] && print -n " %F{11} %f"
}

typeset -g VIRTUAL_ENV_DISABLE_PROMPT=1
typeset -g _left_git_info='' prompt_info='' _cur_git_root='' prompt_git_async_init=0

setopt nopromptbang prompt{cr,percent,sp,subst}
setopt transientrprompt

zstyle ':zim:duration-info' threshold 2.0
zstyle ':zim:duration-info' format '%F{8}⌠%F{4}󱎫 %F{7}%d%F{8}⌡%f'

autoload -Uz add-zsh-hook

# OSC 133 shell integration
function _prompt_osc133_precmd() {
  printf '\e]133;A\e\\'
}
add-zsh-hook precmd _prompt_osc133_precmd

function _prompt_duration_preexec() { (( $+functions[duration-info-preexec] )) && duration-info-preexec "$@" }
function _prompt_duration_precmd() { (( $+functions[duration-info-precmd] )) && duration-info-precmd }
add-zsh-hook preexec _prompt_duration_preexec
add-zsh-hook precmd _prompt_duration_precmd


function prompt_git_async_tasks() {
  emulate -L zsh

  if (( !prompt_git_async_init )); then
    async_start_worker prompt_git -n || return
    async_register_callback prompt_git prompt_git_async_callback
    typeset -g prompt_git_async_init=1
  fi

  # Kill the old process of slow commands if it is still running.
  async_flush_jobs prompt_git

  # Compute slow commands in the background.
  async_job prompt_git prompt_async_git "$PWD"
}

# Runs in the async worker. Produces BOTH prompt fragments in a single pass so
# the synchronous prompt never forks git, and emits them as "<pwd>\x1f<left>\x1e<right>"
# (the leading pwd lets the callback discard results for a stale working directory).
function prompt_async_git {
    emulate -L zsh
    local req_pwd="$1"
    # builtin cd already ignores any user cd function, so no unset needed.
    builtin cd -q "$1" 2>/dev/null || return

    git-info || return

    local branch_name="${$(git symbolic-ref HEAD 2>/dev/null)#refs/heads/}"
    local git_dir current_commit_hash position commit
    local rtag ltag is_worktree branch lbranch
    git_dir=$(git-dir 2>/dev/null)

    # A linked worktree's git dir lives under .../worktrees/<name>.
    [[ -n $branch_name && $git_dir == */worktrees/* ]] && is_worktree="%F{5} %f"

    # --- right prompt: full git status ---
    rtag="$(_fmt_tag 60)"
    if [[ -n $branch_name ]]; then
        branch="%F{8}🙧 %F{172} %B${is_worktree}%f%b%{$italic%}%F{37}%25<…<${branch_name}%<<%F{142}${rtag}%{$reset%}%F{8}🙥 %f"
    else
        position="$(git describe --contains --all HEAD 2>/dev/null)"
        current_commit_hash="$(git rev-parse --short HEAD 2>/dev/null)"
        if [[ -n $git_dir && -n $position ]]; then
            position="%F{8}ǁ%F{196} %F{5}%{$italic%}%25<…<${position}%<<%{$ritm%}%F{8}ǁ%f"
        elif [[ -n $git_dir ]]; then
            commit=" %F{8}ǁ%F{196}%F{7}%25<…<${current_commit_hash}%<<%F{8}ǁ%f"
        fi
    fi
    local right="${git_info[pre_branch]}$(coalesce $branch $position $commit)${git_info[post_branch]}"

    # --- left prompt: only show the branch for long names (or worktrees), plus
    # any in-progress action. Short branches live in the right prompt only. ---
    if [[ -n $branch_name ]] && { (( ${#branch_name} >= 25 )) || [[ -n $is_worktree ]]; }; then
        ltag="$(_fmt_tag 97)"
        lbranch="%F{8}🙧 %F{172} %f${is_worktree}%{$italic%}%F{37}%50<…<${branch_name}%<<%F{142}${ltag}%{$reset%}%F{8}🙥 %f"
    fi
    local left="${lbranch}$(_fmt_git_action)"

    # RS (0x1e) never appears in prompt content and survives the async layer's
    # (q)-quoting intact, so it is a safe field separator.
    print -rn -- "${req_pwd}"$'\x1f'"${left}"$'\x1e'"${right}"
}

# Called when new data is ready to be read from the pipe.
# $1 = job name, $2 = exit code, $3 = stdout, $4 = exec time, $5 = stderr
function prompt_git_async_callback() {
  emulate -L zsh

  case $1 in
    prompt_async_git)
      # Ignore failed jobs and results computed for a directory that is no longer current.
      [[ $2 -eq 0 && ${3%%$'\x1f'*} == "$PWD" ]] || return
      local body=${3#*$'\x1f'}
      _left_git_info="${body%%$'\x1e'*}"
      prompt_info="${body#*$'\x1e'}"
      zle && zle reset-prompt
      ;;

    "[async]")
      # Code is 1 for corrupted worker output and 2 for dead worker.
      if [[ $2 -eq 2 ]]; then
        # Our worker died unexpectedly; clean it up so it is restarted.
        async_stop_worker prompt_git 2>/dev/null
        typeset -g prompt_git_async_init=0
      fi
      ;;
  esac
}

function prompt_precmd() {
  emulate -L zsh

  (( $+functions[git-dir] )) || return

  # Exactly one git fork on the synchronous path; all status work is async.
  local new_git_root="$(git-dir 2> /dev/null)"
  if [[ -n $new_git_root ]]; then
    # Entering a different repo: clear stale fragments so the previous repo's
    # branch/status is never shown until the worker reports back.
    if [[ $new_git_root != $_cur_git_root ]]; then
      _cur_git_root=$new_git_root
      _left_git_info='' prompt_info=''
    fi
    prompt_git_async_tasks
  else
    _cur_git_root='' _left_git_info='' prompt_info=''
    # Drop any in-flight job from the repo we just left.
    (( prompt_git_async_init )) && async_flush_jobs prompt_git
  fi
}

autoload -Uz add-zsh-hook && add-zsh-hook precmd prompt_precmd

# Clear to end of line and mark command execution start
function _prompt_preexec() {
  printf '\e]133;C\e\\'
  printf '%s' "$terminfo[el]"
}
add-zsh-hook preexec _prompt_preexec

# OSC 133;B — marks end of prompt / start of user input (zero-width in PS1)
typeset -g _p133b=$'\e]133;B\e\\'

# Define prompts.
# PS1='${SSH_TTY:+"%F{9}%n%F{7}@%F{3}%m "}%F{60}⌠%f%F{4}%2~%F{60}⌡%f%(!. %F{1}#.)$(_prompt_ratheeshvimode)%f '
PROMPT='%{$terminfo_down_sc$(_left_prompt_info) \
%{$reset%}$reset$terminfo[rc]%}${SSH_TTY:+"%F{8}⌠%f%{$italic%}%F{108}%n%{$reset%}\
%B%F{248}@%b%F{168}%m%F{8}⌡%B%F{180}~%f%b"}%F{8}⌠%F{60}${${${(%):-%30<…<%2~%<<}//\//%B%F{168\}/%b%{$italic%\}\
%F{31\}}//\~/🏠}%{$reset%}%F{8}⌡%f%(!. %F{1}#%f.)%(1j.%F{8}-%B%F{172}%j%b%F{8}-%f.)$(_prompt_chars)%f %{${_p133b}%}'

# 󱞥 󱞲 󱞱 󱞦 ⌂ 󰋖 ❓⁇ ？
# RPS1='${VIRTUAL_ENV:+"%F{3}(${VIRTUAL_ENV:t})"}${VIM:+" %F{6}V"}%(?:: %F{1}✘ %?)'
RPROMPT='%(?::%B%F{197}󱞦%b %F{93}»%F{245}%?%F{93}« %f)${duration_info}${prompt_info}'

SPROMPT='$(tput sitm)%F{5}zsh$(tput sgr0)%F{1}:%F{242} Correct %F{1}%R%f to %F{22}%r%f [nyae]？'

# Not sure if this is the right place to set this?
if [[ -x "$(command -v tput)" ]]; then
  export SUDO_PROMPT="$(tput setaf 3) $(tput setaf 160)$(tput sitm)$(tput bold)sudo$(tput sgr0)$(tput setaf 3):$(tput sgr0)$(tput setaf 242)Password$(tput setaf 93)($(tput setaf 3)󱕵$(tput setaf 93))$(tput setaf 242) for $(tput setaf 4)󰀄 $(tput setaf 5)%u$(tput sgr0)$(tput setaf 2)$(tput bold)？$(tput sgr0)"
fi

# End of File
