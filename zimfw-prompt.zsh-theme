# vim:et sts=2 sw=2 ft=zsh
#
# A Custom theme that displays relevant, contextual information.
#
# A simplified fork of the original sorin theme from
# Based on : https://github.com/zimfw/sorin
# Async Reference:http://github.com/sorin-ionescu/prezto/blob/master/modules/prompt/functions/prompt_sorin_setup
#
# Requires the `git-info` zmodule to be included in the .zimrc file.

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
    vicmd) print -n '%B%F{166}❰%F{250}❰%F{28}❰%b' ;;
    *) print -n '%B%F{28}❱%F{250}❱%F{166}❱%b' ;;
  esac
}

function _prompt_mode() {
  case ${KEYMAP} in
    vicmd)
      print -n '%B%F{8}    --NORMAL--%f%b'
      ;;
    main|viins)
      print -n '%B%F{8}    --INSERT--%f%b'
      ;;
    vivis)
      print -n '%B%F{8}    --VISUAL--%f%b'
      ;;
    vivli)
      print -n '%B%F{8}    --V-LINE--%f%b'
      ;;
    *) # print -n "UNKNOWN -> $KEYMAP"
  esac
}

function _prompt_ratheesh_keymap_select() {
  zle reset-prompt
  zle -R
}
if autoload -Uz is-at-least && is-at-least 5.3; then
  autoload -Uz add-zle-hook-widget && \
    add-zle-hook-widget -Uz keymap-select _prompt_ratheesh_keymap_select
else
  zle -N zle-keymap-select _prompt_ratheesh_keymap_select
fi

function _prompt_dockerinfo() {
  [[ -f /.dockerenv ]] && print -n "%B%F{11} %f%b"
}

typeset -g VIRTUAL_ENV_DISABLE_PROMPT=1

setopt nopromptbang prompt{cr,percent,sp,subst}
setopt transientrprompt

zstyle ':zim:duration-info' threshold 2.0
zstyle ':zim:duration-info' format ' %F{8}⌠%F{126}⏲ %F{92}%d%F{8}⌡%f'

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
  cd -q "$1"
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
        typeset -g prompt_prezto_async_init=0
      fi
      ;;
  esac
}

function prompt_precmd() {
  emulate -L zsh
  setopt noxtrace noksharrays localoptions

  if (( $+functions[git-dir] )); then
    local new_git_root="$(git-dir 2> /dev/null)"
    if [[ $new_git_root != $_ratheesh_cur_git_root ]];then
      prompt_info=' '
      _ratheesh_cur_git_root=$new_git_root
    fi
    [[ -n $new_git_root ]] && prompt_info="%F{129}«%F{63}󱓍 %F{239}%{$italic%}%25>…>$(git symbolic-ref -q --short HEAD 2>/dev/null)%>>%{$reset%}%F{129}»%f %B%F{103} %f%b"
  fi
  prompt_git_async_tasks
}

autoload -Uz add-zsh-hook && add-zsh-hook precmd prompt_precmd

# Clear to the end of the line before execution
function preexec () { print -rn -- $terminfo[el]; }

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
# PS1='${SSH_TTY:+"%F{9}%n%F{7}@%F{3}%m "}%F{60}⌠%f%F{4}%2~%F{60}⌡%f%(!. %B%F{1}#%b.)$(_prompt_ratheeshvimode)%f '
PS1='%{$terminfo_down_sc$(_prompt_mode)$reset$terminfo[rc]%}\
%(1j.%B%F{1}[%b%B%F{3}%j%F{1}]%f%b.)${SSH_TTY:+"%F{60}⌠%f%{$italic%}%F{67}%n%{$reset%}\
%B%F{247}@%b%F{131}%m%F{60}⌡%B%F{162}~%f%b"}%F{60}⌠%F{102}${${${(%):-%30<...<%2~%<<}//\//%B%F{63\}/%b%{$italic%\}\
%F{173\}}//\~/%B⌂%b}%b%{$reset%}%F{60}⌡%f%b%(!. %B%F{1}#%f%b.)%(?::%B%F{161}•%f%b)$(_prompt_chars)%f '

# RPS1='${VIRTUAL_ENV:+"%F{3}(${VIRTUAL_ENV:t})"}${VIM:+" %B%F{6}V%b"}%(?:: %F{1}✘ %?)'
RPS1='%(?::%B%F{9}󱞦%f%b)${duration_info}${VIRTUAL_ENV:+"%F{8} (%B%F{63} %b%{$italic%}%F{179}${VIRTUAL_ENV:t}%f%{$reset%}%F{8})%f"}${prompt_info}$(_prompt_dockerinfo) '

SPROMPT='zsh: Correct %F{2}%R%f to %F{2}%r%f [nyae]? '

# End of File
