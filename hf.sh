#!/bin/bash

export REPO_NAME="Qwen/Qwen2.5-0.5B"
export DIR_NAME=$(echo "$REPO_NAME" | cut -d '/' -f 2)
export URL_LIST_FILE=$(echo "${DIR_NAME}" | awk '{print tolower($0)}')
export URL_LIST_FILE="$URL_LIST_FILE".txt

echo "Dir name: $DIR_NAME"
echo "URL_LIST_FILE: $URL_LIST_FILE"

python -c """
from huggingface_hub import list_repo_files
import os

repo_name = os.getenv('REPO_NAME')
url_list_file = os.getenv('URL_LIST_FILE')

files = list_repo_files(repo_name)
with open(url_list_file, 'w') as f:
    for file in files:
        url = f'https://huggingface.co/{repo_name}/resolve/main/{file}?download=true'
        f.write(f'{url}\n')
        f.write(f'  out={file}\n\n')  # ← critical: tells aria2c what to name the file
"""

printf "Listing files to download...\n\n"
cat hf-files.txt

echo "Initiating download.."
aria2c_args=(
  -x 8
  -s 20
  -k 1M
  -c
  -V true
  -i "$URL_LIST_FILE"
  -d "$DIR_NAME"
  --console-log-level error
  --download-result full
  --summary-interval 30
)
aria2c "${aria2c_args[@]}"
