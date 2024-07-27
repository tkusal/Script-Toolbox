#! /bin/bash
#
# Script for file transfer using rsync + ssh. Written by davidhcefx, 2021.4.2.

## Add host below; Format: <alias> <user@host> <port>
hosts=(
    "local" "david@127.0.0.1"       22
)

nb_column=3  # number of columns in hosts
host=
port=
alias_name=
direction=
src_path=
dst_path=


function yellow() {
    printf "\e[33m$1\e[0m"
}

function list_targets() {
    for ((i = 0; i < ${#hosts[@]}; i += $nb_column)); do
        echo -e "$(yellow "[${hosts[i]}]")\t${hosts[i + 1]} (${hosts[i + 2]})"
    done
    echo ""
}

# return idx of alias name, or -1 if failed
function find_idx_of_alias() {
    for ((i = 0; i < ${#hosts[@]}; i += $nb_column)); do
        if [[ ${hosts[i]} == "$1" ]]; then
            return $i
        fi
    done
    return 255
}

function select_target() {
    if [ -z "$alias_name" ]; then
        read -rep "$(yellow "Target: ")" alias_name
    fi
    find_idx_of_alias "$alias_name"
    idx=$?
    if (( idx >= ${#hosts[@]} )); then
        echo "Error: Alias name not found!"
        exit 1
    fi
    host="${hosts[idx + 1]}"
    port="${hosts[idx + 2]}"
}

# set direction from stdin if not set
function set_direction() {
    if [ -z "$direction" ]; then
        read -rep "$(yellow "Direction: [to|from] ")" direction
    fi
}

function prompt_for_local_path() {
    read -rep "$(yellow "Local file: ")" local_path
    local_path=$(sed "s:^~:$HOME:" <<< "$local_path")  # tilde expansion
}

function prompt_for_remote_path() {
    read -rep "$(yellow "Remote path (relative/absolute): ")" remote_path
}

# prefix each arg with ':' and store to $result
function prefix_each_with_colon() {
    result=()
    for arg in "$@"; do
        result+=(":$arg")
    done
}

# set src_path and dst_path from stdin or args (with user@host prefix)
function set_src_dst_paths() {
    if (( $# < 2 )); then
        case "$direction" in
        to)
            prompt_for_local_path
            if ! [ -e "$local_path" ]; then
                echo "Error: File not found!";
                exit 1;
            fi
            prompt_for_remote_path
            src_path="$local_path"
            dst_path="$host:$remote_path"
            ;;
        from)
            prompt_for_remote_path
            prompt_for_local_path
            src_path="$host:$remote_path"
            dst_path="$local_path"
            ;;
        *)
            exit 1
        esac
    else
        # from args
        src_path=("${@:1:(($#-1))}")
        shift $(($# - 1))
        dst_path="$1"

        case "$direction" in
        to)
            dst_path="$host:$dst_path"
            ;;
        from)
            prefix_each_with_colon "${src_path[@]}"
            src_path=("${result[@]}")
            src_path[0]="${host}${src_path[0]}"
            ;;
        *)
            exit 1
        esac
    fi
    # safety check
    if [[ $src_path == */ ]]; then
        echo -e "$(yellow Warning): Coping folder *contents* instead of the whole folder" \
            "might be dangerous! (eg. Overwrite all contents under home)\n"
    fi
}

function main() {
    list_targets
    select_target
    set_direction
    set_src_dst_paths "$@"

    echo -ne "[ ${src_path[@]} ] >>>\t[ $dst_path ] ?"
    read -rep " " _
    rsync -av --delete -e "ssh -p $port" "${src_path[@]}" "$dst_path"
}

# parse arguments if any
while getopts "ha:d:" opt; do
    case $opt in
    h) echo "Syntax: $(basename $0) [-a alias] [-d (to|from)] [src_path]... [dst_path]"
        echo -e "\tThe paths can be either relative or absolute."
        exit 0
        ;;
    a) alias_name="$OPTARG"
        ;;
    d) direction="$OPTARG"
        ;;
    *)
        exit 1
    esac
done
shift $((OPTIND - 1))
main "$@"