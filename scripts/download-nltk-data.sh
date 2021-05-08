#!/bin/bash

DOWNLOAD_URL=https://raw.githubusercontent.com/nltk/nltk_data/gh-pages/packages

NLTK_DATA=${NLTK_DATA:-/data/lib/nltk_data}

declare -a FOLDERS=("chunkers" "grammars" "misc" "sentiment" "taggers" "corpora" "help" "models" "stemmers" "tokenizers")

function download_package {

    local folder=$1
    local package=$2

    local tarball=${package}.zip
    local url=${DOWNLOAD_URL}/${folder}/${tarball}

    cd $NLTK_DATA/${folder}

    rm -rf ${tarball}
    wget -q -O ${tarball} ${url}

    unzip -oqq ${tarball}

    rm -rf ${tarball}

    echo "info: ${package} downloaded"
}

function main {

    for folder in "${FOLDERS[@]}" ; do
        mkdir -p $NLTK_DATA/$folder
    done

    pushd . > /dev/null
    download_package "tokenizers" "punkt"
    download_package "corpora" "stopwords"
    download_package "help" "tagsets"
    popd > /dev/null
}

main
