# vim:et sts=2 sw=2 ft=zsh
#
# A Custom theme that displays relevant, contextual information.
#
# A simplified fork of the original sorin theme from
# Based on : https://github.com/zimfw/sorin
# Async Reference://github.com/sorin-ionescu/prezto/blob/master/modules/prompt/functions/prompt_sorin_setup
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

ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim
fpath=($ZIM_HOME/modules/zimfw-prompt/functions $fpath[@])
async.zsh
# autoload -Uz async && async

function _prompt_ratheesh_vimode() {
  case ${KEYMAP} in
    vicmd) print -n '%B%F{166}❮%F{250}❮%F{28}❮%b' ;;
    *) print -n '%B%F{28}❯%F{250}❯%F{166}❯%b' ;;
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

typeset -g VIRTUAL_ENV_DISABLE_PROMPT=1

setopt nopromptbang prompt{cr,percent,sp,subst}
setopt transientrprompt

typeset -gA git_info
if (( ${+functions[git-info]} )); then
  # Set git-info parameters.
  zstyle ':zim:git-info' verbose yes
  zstyle ':zim:git-info:action' format ' %F{7}:%F{9}%s'
  zstyle ':zim:git-info:ahead' format ' %F{250}%A%F{13}%%B⬆%%b'
  zstyle ':zim:git-info:behind' format ' %F{250}%B%F{13}%%B⬇%%b'
  zstyle ':zim:git-info:branch' format '%F{8}(%F{33}±%F{243}%{$italic%}%b%{$reset%}%F{8})%f'
  zstyle ':zim:git-info:commit' format ' %F{3}%.7c'
  zstyle ':zim:git-info:indexed' format ' %F{250}%i%F{2}%%B✚%%b'
  zstyle ':zim:git-info:unindexed' format ' %F{250}%I%F{4}%%B✱%%b'
  zstyle ':zim:git-info:position' format ' %F{13}%p'
  zstyle ':zim:git-info:stashed' format ' %F{250}%S%F{6}%%BS%%b'
  zstyle ':zim:git-info:untracked' format ' %F{250}%u%F{7}%%BU%%b'
  zstyle ':zim:git-info:clean' format ' %F{28}✔ '
  zstyle ':zim:git-info:dirty' format ' %%B%F{9}✘ %%b'
  zstyle ':zim:git-info:keys' format \
    'status' '%C%D$(coalesce "%b" "%c" "%p")%s%A%B%S%i%I%u%f'

  # Add hook for calling git-info before each command.
  # autoload -Uz add-zsh-hook && add-zsh-hook precmd git-info
fi

function prompt_gitinfo_async_callback() {
  case $1 in
    prompt_async_git)
      _git_target=${3}

      if [[ -z "$_git_target" ]]; then
        # No git target detected, flush the git fragment and redisplay the prompt.
        if [[ -n "$_prompt_git" ]]; then
          _prompt_git=''
          zle && zle reset-prompt
          zle -R
        fi
      else
        # Git target detected, update the git fragment and redisplay the prompt.
        _prompt_git="${_git_target}"
        zle && zle reset-prompt
        zle -R
      fi
      ;;

    "[async]")
      if [[ $2 -eq 2 ]]; then
          async_flush_jobs prompt_gitinfo
          typeset -g prompt_async_init=0
      fi
      ;;
  esac
}

function prompt_async_git {
  cd -q "$1"
  if (( $+functions[git-info] )); then
    git-info
    print ${(e)git_info[status]}
  fi
}

function prompt_async_tasks()
{
  if (( !${prompt_async_init:-0} )); then
    async_start_worker prompt_gitinfo -n
    async_register_callback prompt_gitinfo prompt_gitinfo_async_callback
    typeset -g prompt_async_init=1
  fi

  # Kill the old process of slow commands if it is still running.
  async_flush_jobs prompt_gitinfo

  # Compute slow commands in the background.
  async_job prompt_gitinfo prompt_async_git "$PWD"
}

function prompt_precmd() {
  setopt LOCAL_OPTIONS
  unsetopt XTRACE KSH_ARRAYS

  if (( $+functions[git-dir] )); then
    local new_git_root="$(git-dir 2> /dev/null)"
    [[ -n $new_git_root ]] && _prompt_git="%F{8}(%B%F{33}±%b%F{239}%{$italic%}$(git symbolic-ref -q --short HEAD 2>/dev/null)%{$reset%}%F{8})%f%B%F{33} …… %f%b"
    if [[ $new_git_root != $_cur_git_root ]]; then
      _prompt_git=''
      _cur_git_root=$new_git_root
    fi
  fi

 # Run python info (this should be fast and not require any async)
  if (( $+functions[python-info] )); then
    python-info
  fi

  prompt_async_tasks
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

# Define prompts.
# PS1='${SSH_TTY:+"%F{9}%n%F{7}@%F{3}%m "}%F{60}⌠%f%F{4}%2~%F{60}⌡%f%(!. %B%F{1}#%b.)$(_prompt_ratheeshvimode)%f '
PS1='${SSH_TTY:+"%F{60}⌠%f%{$italic%}%F{67}%n%{$reset%}%B%F{247}@%b%F{131}%m%F{60}⌡%B%F{162}~%f%b"}\
%F{60}⌠%F{102}${${${(%):-%30<...<%2~%<<}//\//%B%F{63\}/%b%{$italic%\}%F{173\}}//\~/%B⌂%b}%b%{$reset%}%F{60}⌡%f%b\
%(!. %B%F{1}#%f%b.)%(1j.%F{8}-%F{93}%j%F{8}-%f.)$(_prompt_ratheesh_vimode)%f '

# RPS1='${VIRTUAL_ENV:+"%F{3}(${VIRTUAL_ENV:t})"}${VIM:+" %B%F{6}V%b"}%(?:: %F{1}✘ %?)'
RPS1='%(?::%B%F{9}⏎%f%b) ${VIRTUAL_ENV:+"%F{8}(%{$italic%}%B%F{63}venv%b%{$reset%}%F{196}:%f%F{179}${VIRTUAL_ENV:t}%f%F{8})%f"}${_prompt_git}'

SPROMPT='zsh: Correct %F{2}%R%f to %F{2}%r%f [nyae]? '

# End of File
