#!/usr/bin/env bash

repository_url=
repository_branch=
project_name=inidun
install_items=("notebooks" "resources" "__paths__.py")
target_folder=${HOME}/work

mkdir -p $target_folder

main() {
    parse_opts $@
    run
}

run() {

    echo "Updating ${repository_url}..."

    rm -rf /tmp/${project_name}
    rm -rf "${target_folder}/${project_name}"

    # rm -rf !("notebooks"|"repository")
    # shopt -s extglob

    pushd .

    cd /tmp

    git clone --branch ${repository_branch} ${repository_url}

    echo "Installing: $install_items"
    for item in ${install_items[@]} ; do
        if [ -e "${target_folder}/${project_name}/${item}" ] ; then
            rm -rf ${target_folder}/${project_name}/${item}
        fi
        mv /tmp/${project_name}/${item} ${target_folder}/${project_name}/
    done

    popd

    if [ ! -L "${target_folder}/${project_name}/data" ] ; then
        ln -s "${target_folder}/data" "${target_folder}/${project_name}/data"
    fi

}

usage() {
    cat << EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] -r git-repo-url install-item [...install-item]

Script description here.

Available options:

-h, --help            Print this help and exit
-r, --repository-url  URL to repository
-b, --branch          Specify repository branch
EOF
  exit
}

parse_opts() {

    while :; do
        case "${1-}" in
        -h | --help) usage ;;
        -r | --repository-url) # example named parameter
            repository_url="${2-}" ;
            project_name=`basename "${repository_url}"` ;
            project_name="${project_name%.*}" ;
            shift
            ;;
        -b | --branch) # branch
            repository_branch="${2-}" ;
            shift
            ;;
        -?*) die "Unknown option: $1" ;;
        *) break ;;
        esac
        shift
    done

    install_items=($*)

    [[ -z "${repository_branch}" ]] && usage
    [[ -z "${repository_url}" ]] && usage
    [[ -z "${project_name}" ]] && usage
    [[ ${#install_items[@]} -eq 0 ]] && usage

    return 0
}

main $@
