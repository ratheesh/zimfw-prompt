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
  bold=$(tput bold)
  italic=$(tput sitm)
  reset=$(tput sgr0)
  terminfo_down_sc=$terminfo[cud1]$terminfo[cuu1]$terminfo[sc]$terminfo[cud1]
else
  bold=''
  italic=''
  reset=''
fi

# Format a git action name (from zimfw/git-info's git-action) into a prompt string.
function _fmt_git_action() {
    local action
    action=$(git-action 2>/dev/null) || return
    local s="%F{8}🙤 %F{172} " e="%F{8}🙦 "
    case $action in
        rebase-i)   print "${s}%F{27}%B>%b%f%F{162}R%F{27}%B>%b%{$italic%}%F{1}rebase-i%{$reset%}${e}" ;;
        rebase-m)   print "${s}%F{1}%{$italic%}rebase-merge%{$reset%}${e}" ;;
        rebase)     print "${s}%F{27}%B>%f%F{162}R%F{27}%B>%b%{$italic%}%F{1}rebase%{$reset%}${e}" ;;
        am)         print "${s}%F{1}%{$italic%}apply%{$reset%}${e}" ;;
        am/rebase)  print "${s}%F{1}%{$italic%}apply/rebase%{$reset%}${e}" ;;
        merge)      print "${s}%F{1}%{$italic%}merge%{$reset%}${e}" ;;
        cherry)     print "${s}%F{1}%{$italic%}cherry-pick%{$reset%}${e}" ;;
        cherry-seq) print "${s}%F{1}%{$italic%}cherry-pick-sequence%{$reset%}${e}" ;;
        revert)     print "${s}%F{1}%{$italic%}revert%{$reset%}${e}" ;;
        revert-seq) print "${s}%F{1}%{$italic%}revert-sequence%{$reset%}${e}" ;;
        bisect)     print "${s}%F{27}%B<%b%f%F{162}B%F{27}%B>%b%{$italic%}%F{1}bisect${e}" ;;
    esac
}

function get_left_gitprompt_info() {
    local branch_name is_worktree branch git_dir current_commit_hash tag_at_current_commit
    git_dir=$(git-dir 2>/dev/null)
    branch_name="$(command git symbolic-ref -q --short HEAD 2> /dev/null)"
    current_commit_hash="$(git rev-parse --short HEAD 2>/dev/null)"
    tag_at_current_commit=$(git describe --exact-match --tags $current_commit_hash 2> /dev/null)
    if [[ -n $tag_at_current_commit ]]; then
        tag_at_current_commit="%{$reset%}%F{97}⸨%b%{$italic%}%F{1}󱈤 %{$reset%}%f%b%F{66}${tag_at_current_commit}%F{97}⸩%f%b"
    fi

    # [[ -f "$PWD/$(git rev-parse --show-cdup)/.git" ]] && is_worktree="%F{5} %f"

    if [[ -n $branch_name ]]; then
      branch=("%F{8}🙧 %F{172} %f${is_worktree:-""}%{$italic%}%F{37}%50<…<${branch_name}%<<%F{142}${tag_at_current_commit:-""}%{$reset%}%F{8}🙥 %f")
      if [[ ${#branch_name} -lt 25 ]];then
        [[ -n $is_worktree ]] && print -n "${branch:-""}" || print -n "${branch:+""}"
      else
        print -n "${branch:-""}"
      fi
    fi
    print -n "$(_fmt_git_action)"
}

function transient_prompt_info() {
    local prompt_info branch pos position commit
    local git_dir=$(git-dir 2>/dev/null)
    local current_commit_hash="$(git rev-parse --short HEAD 2> /dev/null)"
    local branch_name="${$(git symbolic-ref HEAD 2> /dev/null)#refs/heads/}"

    local tag_at_current_commit=$(git describe --exact-match --tags $current_commit_hash 2> /dev/null)
    if [[ -n $tag_at_current_commit ]]; then
        tag_at_current_commit="%{$reset%}%F{60}⸨%b%{$italic%}%F{1}󱈤 %{$reset%}%f%b%F{66}${tag_at_current_commit}%F{60}⸩%f%b"
    fi

    if [[ -n $branch_name ]]; then
        branch=("%B%F{105}«%B%F{172} %f%b%{$italic%}%F{243}%25<…<${$(git symbolic-ref HEAD 2> /dev/null)#refs/heads/}%<<%F{142}%b${tag_at_current_commit:-""}%{$reset%}%B%F{105}»%f%b")
    fi

    if [[ -z "$branch_name" ]]; then
        pos="$(git describe --contains --all HEAD 2> /dev/null)"
        [[ -n $git_dir ]] && position="%B%F{8}ǁ%b%F{196} %F{5}%{$italic%}%25<…<${pos}%<<%{$reset%}%B%F{8}ǁ%f%b"
        [[ -n $git_dir ]] && [[ -z "$branch_name" && -z "$pos" ]] && commit=" %B%F{8}ǁ%F{196}%F{7}%25<…<${current_commit_hash}%<<%B%F{8}ǁ%f%b"
    fi

    prompt_info="%B%F{129}󰓦 %f%b%B%F{105}"
    prompt_info+=($(coalesce $branch $position $commit))

    print -n "$prompt_info"
}

# Initialize italic/reset early so zstyle action formats (double-quoted) can embed them
if (( $+commands[tput] )); then
  italic=$(tput sitm)
  reset=$(tput sgr0)
else
  italic=''
  reset=''
fi

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
  case ${KEYMAP} in
    vicmd) print -n '%B%F{167}❮%F{251}❮%F{29}❮%b';;
    *) print -n '%B%F{29}❯%F{251}❯%F{167}❯%b';;
  esac
}

function _left_prompt_info() {
  print -n "   $(_prompt_mode)%(?::%B%F{197}󱞱%f%b) ${_left_git_info}$(_prompt_dockerinfo)"
}

function _prompt_mode() {
  case ${KEYMAP} in
    vicmd)
      print -n "%F{8}🙟 %F{95}%B%{$italic%}normal%{$reset%}%b%F{8}🙝 %f"
      ;;
    main|viins)
      print -n "%F{8}🙟 %F{103}%B%{$italic%}insert%{$reset%}%b%F{8}🙝 %f"
      ;;
    vivis)
      print -n "%F{8}🙟 %F{126}%B%{$italic%}visual%{$reset%}%b%F{8}🙝 %f"
      ;;
    vivli)
      print -n "%F{8}🙟 %F{126}%B%{$italic%}v-line%{$reset%}%b%F{8}🙝 %f"
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
  [[ -f /.dockerenv ]] && print -n "%F{11} %f"
}

typeset -g VIRTUAL_ENV_DISABLE_PROMPT=1
typeset -g _left_git_info=''

setopt nopromptbang prompt{cr,percent,sp,subst}
setopt transientrprompt

zstyle ':zim:duration-info' threshold 2.0
zstyle ':zim:duration-info' format '%F{102}⌠%F{4}󱎫 %F{252}%d%F{102}⌡%f'

autoload -Uz add-zsh-hook
function _prompt_duration_preexec() { (( $+functions[duration-info-preexec] )) && duration-info-preexec "$@" }
function _prompt_duration_precmd() { (( $+functions[duration-info-precmd] )) && duration-info-precmd }
add-zsh-hook preexec _prompt_duration_preexec
add-zsh-hook precmd _prompt_duration_precmd


function prompt_git_async_tasks() {
  emulate -L zsh

  if (( !${prompt_git_async_init:-0} )); then
    async_start_worker prompt_git -n
    async_register_callback prompt_git prompt_git_async_callback
    typeset -g prompt_git_async_init=1
  fi

  # Kill the old process of slow commands if it is still running.
  async_flush_jobs prompt_git

  # Compute slow commands in the background.
  async_job prompt_git prompt_async_git "$PWD"
}

function prompt_async_git {
    emulate -L zsh
    if (( $+functions[cd] )); then
        unset -f cd
    fi
    builtin cd -q "$1"

    git-info || return

    local branch_name="${$(git symbolic-ref HEAD 2>/dev/null)#refs/heads/}"
    local current_commit_hash="$(git rev-parse --short HEAD 2>/dev/null)"
    local git_dir=$(git-dir 2>/dev/null)

    local tag_at_current_commit=$(git describe --exact-match --tags $current_commit_hash 2>/dev/null)
    if [[ -n $tag_at_current_commit ]]; then
        tag_at_current_commit="%{$reset%}%F{60}⸨%{$italic%}%F{1}󱈤 %{$reset%}%f%F{66}${tag_at_current_commit}%F{60}⸩%f"
    fi

    local is_worktree branch position commit
    [[ -n $branch_name ]] && [[ -f "$PWD/$(git rev-parse --show-cdup)/.git" ]] && is_worktree="%F{5} %f"

    if [[ -n $branch_name ]]; then
      branch=("%F{8}🙧 %F{172} %B${is_worktree:-""}%f%b%{$italic%}%F{37}%25<…<${branch_name}%<<%F{142}${tag_at_current_commit:-""}%{$reset%}%F{8}🙥 %f")
    else
        position="$(git describe --contains --all HEAD 2>/dev/null)"
        [[ -n $git_dir ]] && position="%F{8}ǁ%F{196} %F{5}%{$italic%}%25<…<${position}%<<%{$reset%}%F{8}ǁ%f"
        [[ -n $git_dir && -z $branch_name && -z $position ]] && commit=" %F{8}ǁ%F{196}%F{7}%25<…<%F{7}${current_commit_hash}%<<%F{8}ǁ%f"
    fi
    print -n "${git_info[pre_branch]}$(coalesce $branch $position $commit)${git_info[post_branch]}"
}

# Called when new data is ready to be read from the pipe
# First arg will be fd ready for reading
# Second arg will be passed in case of error
function prompt_git_async_callback() {
  emulate -L zsh

  case $1 in
    prompt_async_git)
      prompt_info=$3
      zle reset-prompt
      zle -R
      ;;

    "[async]")
      # Code is 1 for corrupted worker output and 2 for dead worker.
      if [[ $2 -eq 2 ]]; then
        # Our worker died unexpectedly.
        typeset -g prompt_git_async_init=0
      fi
      ;;
  esac
}

function prompt_precmd() {
  emulate -L zsh
  setopt noxtrace noksharrays localoptions

  if (( $+functions[git-dir] )); then
    local new_git_root="$(git-dir 2> /dev/null)"
    if [[ -n $new_git_root ]];then
      [[ $new_git_root != $_cur_git_root ]] && _cur_git_root=$new_git_root
      _left_git_info=$(get_left_gitprompt_info)
      prompt_info=$(transient_prompt_info)
      prompt_git_async_tasks
    else
      unset prompt_info
      _left_git_info=''
    fi
  fi
}

autoload -Uz add-zsh-hook && add-zsh-hook precmd prompt_precmd

# Clear to the end of the line before execution
function _prompt_preexec() {
  local OSC133_START="\e]133;A\e\\"
  printf "$OSC133_START%s" "$terminfo[el]";
}
add-zsh-hook preexec _prompt_preexec

# Define prompts.
# PS1='${SSH_TTY:+"%F{9}%n%F{7}@%F{3}%m "}%F{60}⌠%f%F{4}%2~%F{60}⌡%f%(!. %F{1}#.)$(_prompt_ratheeshvimode)%f '
PS1='%{$terminfo_down_sc$(_left_prompt_info)${VIRTUAL_ENV:+"%F{60}⸨%F{198}󰌠 %{$italic%}%F{179}${VIRTUAL_ENV:t}%f%{$reset%}%F{60}⸩%f"} \
%{$reset%}$reset$terminfo[rc]%}${SSH_TTY:+"%F{102}⌠%f%{$italic%}%F{67}%n%{$reset%}\
%F{247}@%F{131}%m%F{102}⌡%F{162}~%f"}%F{102}⌠%F{241}${${${(%):-%30<…<%2~%<<}//\//%B%F{31\}/%b%{$italic%\}\
%F{168\}}//\~/🏠}%{$reset%}%F{102}⌡%f%(!. %F{1}#%f.)%(1j.%F{8}-%B%F{172}%j%b%F{8}-%f.)$(_prompt_chars)%f '

# 󱞥 󱞲 ⌂ 󰋖 ❓⁇ ？
# RPS1='${VIRTUAL_ENV:+"%F{3}(${VIRTUAL_ENV:t})"}${VIM:+" %F{6}V"}%(?:: %F{1}✘ %?)'
RPS1='%(?::%B%F{197}󱞲%b %F{93}»%F{245}%?%F{93}« %f)${duration_info}${prompt_info}'

SPROMPT='$(tput sitm)%F{5}zsh$(tput sgr0)%F{1}:%F{242} Correct %F{1}%R%f to %F{22}%r%f [nyae]？'

# Not sure if this is the right place to set this?
if [[ -x "$(command -v tput)" ]]; then
  export SUDO_PROMPT="$(tput setaf 3) $(tput setaf 160)$(tput sitm)$(tput bold)sudo$(tput sgr0)$(tput setaf 3):$(tput sgr0)$(tput setaf 242)Password$(tput setaf 93)($(tput setaf 3)󱕵$(tput setaf 93))$(tput setaf 242) for $(tput setaf 4)󰀄 $(tput setaf 5)%u$(tput sgr0)$(tput setaf 2)$(tput bold)？$(tput sgr0)"
fi

# End of File
