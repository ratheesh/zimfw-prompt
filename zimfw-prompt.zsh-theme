# vim:et sts=2 sw=2 ft=zsh
#
# A Custom theme that displays relevant, contextual information.
#
# A simplified fork of the original sorin theme from
# Based on : https://github.com/zimfw/sorin
# Async Reference:http://github.com/sorin-ionescu/prezto/blob/master/modules/prompt/functions/prompt_sorin_setup
# Reference: zshusers/zsh-autosuggestions
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
git_info.zsh

function _prompt_chars() {
  case ${KEYMAP} in
    vicmd) print -n '%B%F{166}❮%F{250}❮%F{28}❮%b' ;;
    *) print -n '%B%F{28}❯%F{250}❯%F{166}❯%b' ;;
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
    *) print -n "UNKNOWN"
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

function _zsh_git_prompt_async_request() {
    typeset -g _ZSH_GIT_PROMPT_ASYNC_FD _ZSH_GIT_PROMPT_ASYNC_PID

    # If we've got a pending request, cancel it
    if [[ -n "$_ZSH_GIT_PROMPT_ASYNC_FD" ]] && { true <&$_ZSH_GIT_PROMPT_ASYNC_FD } 2>/dev/null; then

        # Close the file descriptor and remove the handler
        exec {_ZSH_GIT_PROMPT_ASYNC_FD}<&-
        zle -F $_ZSH_GIT_PROMPT_ASYNC_FD

        # Zsh will make a new process group for the child process only if job
        # control is enabled (MONITOR option)
        if [[ -o MONITOR ]]; then
            # Send the signal to the process group to kill any processes that may
            # have been forked by the suggestion strategy
            kill -TERM -$_ZSH_GIT_PROMPT_ASYNC_PID 2>/dev/null
        else
            # Kill just the child process since it wasn't placed in a new process
            # group. If the suggestion strategy forked any child processes they may
            # be orphaned and left behind.
            kill -TERM $_ZSH_GIT_PROMPT_ASYNC_PID 2>/dev/null
        fi
    fi

    # Fork a process to fetch the git status and open a pipe to read from it
    exec {_ZSH_GIT_PROMPT_ASYNC_FD}< <(
        # Tell parent process our pid
        echo $sysparams[pid]
        git_info
    )

    # There's a weird bug here where ^C stops working unless we force a fork
    # See https://github.com/zsh-users/zsh-autosuggestions/issues/364
    command true

    # Read the pid from the child process
    read _ZSH_GIT_PROMPT_ASYNC_PID <&$_ZSH_GIT_PROMPT_ASYNC_FD

    # When the fd is readable, call the response handler
    zle -F "$_ZSH_GIT_PROMPT_ASYNC_FD" _zsh_git_prompt_callback
}

# Called when new data is ready to be read from the pipe
# First arg will be fd ready for reading
# Second arg will be passed in case of error
function _zsh_git_prompt_callback() {
    emulate -L zsh

    if [[ -z "$2" || "$2" == "hup" ]]; then
        # Read output from fd
        prompt_info="$(cat <&$1)"

        # if [[ "${old_prompt_info}" != "${prompt_info}" ]];then
        zle reset-prompt
        zle -R
        old_prompt_info=${prompt_info}
        # fi

        # Close the fd
        exec {1}<&-
    fi

    # Always remove the handler
    zle -F "$1"

    # Unset global FD variable to prevent closing user created FDs in the precmd hook
    unset _ZSH_GIT_PROMPT_ASYNC_FD
}

function prompt_precmd() {
    setopt noxtrace noksharrays localoptions

    if (( $+functions[git-dir] )); then
        local new_git_root="$(git-dir 2> /dev/null)"
        if [[ $new_git_root != $_ratheesh_cur_git_root ]];then
          prompt_info=''
          _ratheesh_cur_git_root=$new_git_root
        fi
        [[ -n $new_git_root ]] && prompt_info="%F{129}«%B%F{11}±%b%F{239}%{$italic%}$(git symbolic-ref -q --short HEAD 2>/dev/null)%{$reset%}%F{129}»%f%B%F{33}…… %f%b"
    fi
    _zsh_git_prompt_async_request
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
${SSH_TTY:+"%F{60}⌠%f%{$italic%}%F{67}%n%{$reset%}%B%F{247}@%b%F{131}%m%F{60}⌡%B%F{162}~%f%b"}\
%F{60}⌠%F{102}${${${(%):-%30<...<%2~%<<}//\//%B%F{63\}/%b%{$italic%\}%F{173\}}//\~/%B⌂%b}%b%{$reset%}%F{60}⌡%f%b\
%(!. %B%F{1}#%f%b.)%(1j.%F{8}-%F{93}%j%F{8}-%f.)$(_prompt_chars)%f '

# RPS1='${VIRTUAL_ENV:+"%F{3}(${VIRTUAL_ENV:t})"}${VIM:+" %B%F{6}V%b"}%(?:: %F{1}✘ %?)'
RPS1='%(?::%B%F{9}⏎%f%b) ${VIRTUAL_ENV:+"%F{8}(%{$italic%}%B%F{63}venv%b%{$reset%}%F{196}:%f%F{179}${VIRTUAL_ENV:t}%f%F{8})%f"}${prompt_info}'

SPROMPT='zsh: Correct %F{2}%R%f to %F{2}%r%f [nyae]? '

# End of File
