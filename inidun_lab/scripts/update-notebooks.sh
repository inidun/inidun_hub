#!/usr/bin/env bash

GIT_REPOSITORY_URL=
PROJECT_NAME=
INSTALL_ITEMS=("notebooks" "resources" "__paths__.py")
TARGET_FOLDER=${HOME}/work

mkdir -p $TARGET_FOLDER

main() {
    parse_opts $@
    run
}

run() {

    echo "Updating ${GIT_REPOSITORY_URL}..."

    rm -rf /tmp/${PROJECT_NAME}
    rm -rf "${TARGET_FOLDER}/${PROJECT_NAME}"

    # rm -rf !("notebooks"|"repository")
    # shopt -s extglob

    pushd .

    cd /tmp

    git clone ${GIT_REPOSITORY_URL}

    echo "Installing: $INSTALL_ITEMS"
    for item in ${INSTALL_ITEMS[@]} ; do
        if [ -e "${TARGET_FOLDER}/${PROJECT_NAME}/${item}" ] ; then
            rm -rf ${TARGET_FOLDER}/${PROJECT_NAME}/${item}
        fi
        mv /tmp/${PROJECT_NAME}/${item} ${TARGET_FOLDER}/${PROJECT_NAME}/
    done

    popd

    if [ ! -L "${TARGET_FOLDER}/${PROJECT_NAME}/data" ] ; then
        ln -s "${TARGET_FOLDER}/data" "${TARGET_FOLDER}/${PROJECT_NAME}/data"
    fi

}

usage() {
    cat << EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] -r git-repo-url install-item [...install-item]

Script description here.

Available options:

-h, --help            Print this help and exit
-f, --flag            Some flag description
-r, --repository-url  URL to repository
EOF
  exit
}

parse_opts() {

    while :; do
        case "${1-}" in
        -h | --help) usage ;;
        # -f | --flag) flag=1 ;; # example flag
        -r | --repository-url) # example named parameter
            GIT_REPOSITORY_URL="${2-}" ;
            PROJECT_NAME=`basename "${GIT_REPOSITORY_URL}"` ;
            PROJECT_NAME="${PROJECT_NAME%.*}" ;
            shift
            ;;
        -?*) die "Unknown option: $1" ;;
        *) break ;;
        esac
        shift
    done

    INSTALL_ITEMS=($*)

    [[ -z "${GIT_REPOSITORY_URL}" ]] && usage
    [[ -z "${PROJECT_NAME}" ]] && usage
    [[ ${#INSTALL_ITEMS[@]} -eq 0 ]] && usage

    return 0
}

main $@
