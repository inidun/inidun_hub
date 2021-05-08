#!/usr/bin/env bash

python -m nltk.downloader -d /usr/local/share/nltk_data stopwords punkt sentiwordnet

pip install --quiet spacy-lookups-data
python -m spacy download en_core_web_sm
python -m spacy download en_core_web_md
python -m spacy link en_core_web_sm en --force
