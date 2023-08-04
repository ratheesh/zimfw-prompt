# Copyright (c) 2023 Ratheesh <ratheeshreddy@gmail.com>
# Author: Ratheesh S
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Gets the Git special action (am, bisect, cherry, merge, rebase).
# Borrowed from vcs_info and edited.
function _git-action {
    local git_dir=$(git-dir 2>/dev/null)
    local action_dir
    for action_dir in \
        "${git_dir}/rebase-apply" \
            "${git_dir}/rebase" \
            "${git_dir}/../.dotest"
    do
        if [[ -d ${action_dir} ]]; then
            local apply_formatted
            local rebase_formatted
            apply_formatted='apply'
            rebase_formatted='>R>rebase'

            if [[ -f "${action_dir}/rebasing" ]]; then
                print ${rebase_formatted}
            elif [[ -f "${action_dir}/applying" ]]; then
                print ${apply_formatted}
            else
                print "${rebase_formatted}/${apply_formatted}"
            fi

            return 0
        fi
    done

    for action_dir in \
        "${git_dir}/rebase-merge/interactive" \
            "${git_dir}/.dotest-merge/interactive"
    do
        if [[ -f ${action_dir} ]]; then
            local rebase_interactive_formatted
            rebase_interactive_formatted='rebase-interactive'
            print ${rebase_interactive_formatted}
            return 0
        fi
    done

    for action_dir in \
        "${git_dir}/rebase-merge" \
            "${git_dir}/.dotest-merge"
    do
        if [[ -d ${action_dir} ]]; then
            local rebase_merge_formatted
            rebase_merge_formatted='rebase-merge'
            print ${rebase_merge_formatted}
            return 0
        fi
    done

    if [[ -f "${git_dir}/MERGE_HEAD" ]]; then
        local merge_formatted
        merge_formatted='>M<merge'
        print ${merge_formatted}
        return 0
    fi

    if [[ -f "${git_dir}/CHERRY_PICK_HEAD" ]]; then
        if [[ -d "${git_dir}/sequencer" ]]; then
            local cherry_pick_sequence_formatted
            cherry_pick_sequence_formatted='cherry-pick-sequence'
            print ${cherry_pick_sequence_formatted}
        else
            local cherry_pick_formatted
            cherry_pick_formatted='cherry-pick'
            print ${cherry_pick_formatted}
        fi

        return 0
    fi

    if [[ -f "${git_dir}/BISECT_LOG" ]]; then
        local bisect_formatted
        bisect_formatted='<B>bisect'
        print ${bisect_formatted}
        return 0
    fi

    return 1
}

# Prints the first non-empty string in the arguments array.
function coalesce {
    for arg in $argv; do
        print "$arg"
        return 0
    done
    return 1
}

function git_branch_name() {
    local branch_name="$(command git symbolic-ref -q --short HEAD 2> /dev/null)"
    [[ -n $branch_name ]] && print "$branch_name"
}

# useful symbols            ✔
function git_info() {
    local ahead=0 behind=0 untracked=0 modified=0 deleted=0 added=0 dirty=0
    local branch
    local pos position commit
    local ahead_and_behind_cmd ahead_and_behind
    local -a git_status
    local is_on_a_tag=false
    local git_dir=$(git-dir 2>/dev/null)
    local current_commit_hash="$(git rev-parse HEAD 2> /dev/null)"
    local branch_name="${$(git symbolic-ref HEAD 2> /dev/null)#refs/heads/}"
    #  ±

    # check if the current commit is at a tag point
    local tag_at_current_commit=$(git describe --exact-match --tags $current_commit_hash 2> /dev/null)
    if [[ -n $tag_at_current_commit ]]; then
        tag_at_current_commit="%F{60}(%b%{$italic%}%F{178}tag%{$reset%}%B%F{198}:%f%b%F{66}${tag_at_current_commit}%F{60})%f%b"
    fi

    if [[ -n $branch_name ]] && \
     branch=("%B%F{129}«%B%F{11}±%f%b%{$italic%}%F{241}${branch_name}%F{142}%b${tag_at_current_commit:-""}%{$reset%}%B%F{129}»%f%b")
    if [[ -z "${branch_name//}" ]]; then
        pos="$(git describe --contains --all HEAD 2> /dev/null)"
        [[ -n $git_dir ]] && position="%B%F{8}ǁ%b%F{196}%F{7}${pos}%B%F{8}ǁ%f%b"
    fi

    [[ -n $git_dir ]] && [[ -z "${branch_name//}" && -z "${pos//}" ]] && commit="%B%F{8}ǁ%F{196}%F{7}${current_commit_hash}%B%F{8}ǁ%f%b"

    ahead_and_behind_cmd='git rev-list --count --left-right HEAD...@{upstream}'
    # Get ahead and behind counts.
    ahead_and_behind="$(${(z)ahead_and_behind_cmd} 2> /dev/null)"
    ahead="$ahead_and_behind[(w)1]"
    behind="$ahead_and_behind[(w)2]"

    # Use porcelain status for easy parsing.
    status_cmd="git status --porcelain --ignore-submodules=all"

    # Get current status.
    while IFS=$'\n' read line; do
        # Count added, deleted, modified, renamed, unmerged, untracked, dirty.
        # T (type change) is undocumented, see http://git.io/FnpMGw.
        # For a table of scenarii, see http://i.imgur.com/2YLu1.png.
        [[ "$line" == ([ACDMT][\ MT]|[ACMT]D)\ * ]] && (( added++ ))
        [[ "$line" == [\ ACMRT]D\ * ]] && (( deleted++ ))
        [[ "$line" == ?[MT]\ * ]] && (( modified++ ))
        [[ "$line" == R?\ * ]] && (( renamed++ ))
        [[ "$line" == (AA|DD|U?|?U)\ * ]] && (( unmerged++ ))
        [[ "$line" == \?\?\ * ]] && (( untracked++ ))
        (( dirty++ ))
    done < <(${(z)status_cmd} 2> /dev/null)

    if [[ -n $git_dir ]];then
      (( dirty > 0 )) && git_status+=("%B%F{9}✘%f%b") || git_status+=("%B%F{27}✔%f%b")
    fi

    git_status+=($(_git-action))

    # if [[ -n $branch ]] && git_status+=(${branch})
    git_status+=($(coalesce $branch $position $commit))

    local -i stashed=$(command git stash list 2>/dev/null | wc -l)
    (( stashed > 0 )) && git_status+=("%F{7}${stashed}%B%F{63}S%f%b")

    (( ahead > 0 )) && git_status+=("%F{7}${ahead}%B%F{34}↑%f%b")
    (( behind > 0 )) && git_status+=("%F{7}${behind}%B%F{198}↓%f%b")
    (( added > 0 )) && git_status+=("%F{7}${added}%B%F{2}+%f%b")
    (( deleted > 0 )) && git_status+=("%F{7}${deleted}%B%F{1}x%f%b")
    (( modified > 0 )) && git_status+=("%F{7}${modified}%F{202}✱%f%b")
    (( renamed > 0 )) && git_status+=("%F{7}${renamed}%B%F{54}➜%f%b")
    (( unmerged > 0 )) && git_status+=("%F{7}${unmerged}%B%F{1}═%f%b")
    (( untracked > 0 )) && git_status+=("%F{7}${untracked}%B%F{162}??%f%b")

    print "$git_status"
}
# End of File
