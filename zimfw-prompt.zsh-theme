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

git_info

# ❰ ❱ ❮ ❯
function _prompt_chars() {
  case ${KEYMAP} in
    vicmd) print -n '%F{166}❮%F{250}❮%F{28}❮';;
    *) print -n '%F{28}❯%F{250}❯%F{166}❯';;
  esac
}

function _left_prompt_info() {
  print -n "   %(?:%F{27}%f:%F{161}%f) $(_prompt_mode) $(get_left_gitprompt_info)$(_prompt_dockerinfo)"
}

function _prompt_mode() {
  case ${KEYMAP} in
    vicmd)
      print -n "%F{8}🙟 %F{95}%BNORMAL%b%F{8}🙝 %f"
      ;;
    main|viins)
      print -n "%F{8}🙟 %F{103}%BINSERT%b%F{8}🙝 %f"
      ;;
    vivis)
      print -n "%F{8}🙟 %F{126}%BVISUAL%b%F{8}🙝 %f"
      ;;
    vivli)
      print -n "%F{8}🙟 %F{126}%BV-LINE%b%F{8}🙝 %f"
      ;;
    *) # print -n "UNKNOWN -> $KEYMAP"
  esac
}

function _prompt_keymap_select() {
  zle reset-prompt
  zle -R
}
if autoload -Uz is-at-least && is-at-least 5.3; then
  autoload -Uz add-zle-hook-widget && \
    add-zle-hook-widget -Uz keymap-select _prompt_keymap_select
else
  zle -N zle-keymap-select _prompt_keymap_select
fi

function _prompt_dockerinfo() {
  [[ -f /.dockerenv ]] && print -n "%F{11} %f"
}

typeset -g VIRTUAL_ENV_DISABLE_PROMPT=1

setopt nopromptbang prompt{cr,percent,sp,subst}
setopt transientrprompt

zstyle ':zim:duration-info' threshold 2.0
zstyle ':zim:duration-info' format '%F{8}⌠%F{126}⏲ %F{92}%d%F{8}⌡%f'

autoload -Uz add-zsh-hook
add-zsh-hook preexec duration-info-preexec
add-zsh-hook precmd duration-info-precmd


function prompt_git_async_tasks() {
  emulate -L zsh

  if (( !${prompt_async_init:-0} )); then
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
  if (( $+functions[git_info] )); then
    git_info
  fi
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
      old_prompt_info=${prompt_info}
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
      # prompt_info="%F{129}«%F{63}󱓍 %F{239}%{$italic%}%25>…>$(git symbolic-ref -q --short HEAD 2>/dev/null)%>>%{$reset%}%F{129}»%f %B%F{103} %f%b"
      # prompt_info="%B%F{129}󰓦 %f%b%B%F{105}«%B%F{172} %f%b%{$italic%}%F{243}%25>…>${$(git symbolic-ref HEAD 2> /dev/null)#refs/heads/}%>>%F{142}%b${tag_at_current_commit:-""}%{$reset%}%B%F{105}»%f%b"
      prompt_info=$(transient_prompt_info)
      prompt_git_async_tasks
    else
      unset prompt_info
    fi
  fi
}

autoload -Uz add-zsh-hook && add-zsh-hook precmd prompt_precmd

# Clear to the end of the line before execution
function preexec () {
  OSC133_START="\e]133;A\e\\"
  printf "$OSC133_START%s" "$terminfo[el]";
}

if (( $+commands[tput] ));then
  bold=$(tput bold)
  italic=$(tput sitm)
  reset=$(tput sgr0)
else
  bold=''
  italic=''
  reset=''
fi
terminfo_down_sc=$terminfo[cud1]$terminfo[cuu1]$terminfo[sc]$terminfo[cud1]

# Define prompts.
# PS1='${SSH_TTY:+"%F{9}%n%F{7}@%F{3}%m "}%F{60}⌠%f%F{4}%2~%F{60}⌡%f%(!. %F{1}#.)$(_prompt_ratheeshvimode)%f '
PS1='%{$terminfo_down_sc$(_left_prompt_info)${VIRTUAL_ENV:+"%F{8}(%F{198}󰌠 %{$italic%}%F{179}${VIRTUAL_ENV:t}%f%{$reset%}%F{8})%f"} \
%{$reset%}$reset$terminfo[rc]%}${SSH_TTY:+"%F{60}⌠%f%{$italic%}%F{67}%n%{$reset%}\
%F{247}@%F{131}%m%F{60}⌡%F{162}~%f"}%F{60}⌠%F{102}${${${(%):-%30<...<%2~%<<}//\//%F{63\}/%{$italic%\}\
%F{173\}}//\~/⌂}%{$reset%}%F{60}⌡%f%(!. %F{1}#%f.)%(1j.%F{8}-%B%F{172}%j%b%F{8}-%f.)$(_prompt_chars)%f '

# RPS1='${VIRTUAL_ENV:+"%F{3}(${VIRTUAL_ENV:t})"}${VIM:+" %F{6}V"}%(?:: %F{1}✘ %?)'
RPS1='%(?::%F{9}󱞦 %F{8}»%F{1}%?%F{8}« %f)${duration_info}${prompt_info}'

SPROMPT='zsh: Correct %F{2}%R%f to %F{2}%r%f [nyae]? '

# End of File
