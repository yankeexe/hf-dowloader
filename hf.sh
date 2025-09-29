#!/bin/bash

show_help() {
  cat <<EOF
Usage: $(basename "$0") repo_name [OPTIONS]

Options:
  -ds <boolean>             Download as dataset (default: disabled)
  -i <boolean>              Interactively select files to download (default: disabled)
  -x <num>                  Connections per server (default: 8)
  -s <num>                  Number of splits (default: 20)
  -k <size>                 Min split size (default: 1M)
  -V <true|false>           Verify integrity (default: true)
  -c <true|false>           Continue downloading a partially downloaded file (default: true)
  -d <dir>                  Download directory (default: repo_name)
  --console-log-level <lvl> Console log level (default: error)
  --download-result <res>   Download result (default: full)
  --summary-interval <sec>  Summary interval (default: 10)
  -h, --help                Show this help
EOF
}

REPO_NAME="$1"
shift

if [[ "$REPO_NAME" == "-h" || "$REPO_NAME" == "--help" ]]; then
  show_help
  exit 0
fi

if [[ ! $REPO_NAME =~ ^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$ ]]; then
    echo "❌ FAIL: Repo name must be in the form 'namespace/repo_name'."
    exit 1
fi


while [[ $# -gt 0 ]]; do
  case "$1" in
    -ds) REPO_TYPE=dataset; shift 1 ;;
    -i) INTERACTIVE_MODE=true; shift 1 ;;
    -x) MAX_CONNECTION_PER_SERVER="$2"; shift 2 ;;
    -s) SPLIT="$2"; shift 2 ;;
    -k) MIN_SPLIT_SIZE="$2"; shift 2 ;;
    -c) CONTINUE_DOWNLOAD="$2"; shift 2 ;;
    -V) CHECK_INTEGRITY="$2"; shift 2 ;;
    -d) USER_DIR_PATH="$2"; shift 2 ;;
    --console-log-level) CONSOLE_LOG_LEVEL="$2"; shift 2 ;;
    --download-result) DOWNLOAD_RESULT="$2"; shift 2 ;;
    --summary-interval) SUMMARY_INTERVAL="$2"; shift 2 ;;
    -h|--help) show_help; exit 0 ;;
    *) break ;;
  esac
done

export REPO_TYPE="${REPO_TYPE:-model}"
export REPO_NAME="$REPO_NAME"
DIR_NAME=$(echo "$REPO_NAME" | cut -d '/' -f 2)
_URL_LIST_FILE=$(echo "${DIR_NAME}" | awk '{print tolower($0)}')
export URL_LIST_FILE=".$_URL_LIST_FILE".txt

# @NOTE: remove this to use vanilla hf API
python -c """
from huggingface_hub import list_repo_files
import os

repo_name = os.getenv('REPO_NAME')
url_list_file = os.getenv('URL_LIST_FILE')
is_dataset = os.getenv('REPO_TYPE') == 'dataset'

if is_dataset:
  base_url = 'https://huggingface.co/datasets/{repo_name}/resolve/main/{file}?download=true'
else:
  base_url = 'https://huggingface.co/{repo_name}/resolve/main/{file}?download=true'

files = list_repo_files(repo_name, repo_type='dataset' if is_dataset else 'model')
with open(url_list_file, 'w') as f:
    for file in files:
        url = base_url.format(repo_name=repo_name,file=file)
        f.write(f'{url}\n')
        f.write(f'  out={file}\n\n')  # ← critical: tells aria2c what to name the file
"""

handle_interaction(){
  OUTPUT_FILE=".selected_$URL_LIST_FILE.txt"
  selected=$(awk -F'out=' '/out=/{gsub(/^[ \t]+/, "", $2); print $2}' "$URL_LIST_FILE" | fzf --multi --prompt="Select files to download: ")

  if [[ -z "$selected" ]]; then
      echo "❌ No files selected."
      exit 0
  fi

  > "$OUTPUT_FILE"

  while read -r fname; do
      awk -v file="$fname" '
          $0 ~ "out="file"$" {print prev; print $0; print ""}
          {prev=$0}' "$URL_LIST_FILE" >> "$OUTPUT_FILE"
  done <<< "$selected"

  echo "Created $OUTPUT_FILE with the selected files."
}

if [[ -n "$INTERACTIVE_MODE" ]]; then
  handle_interaction
  URL_LIST_FILE="$OUTPUT_FILE"
fi

cat <<EOF

$(printf '%.0s#' {1..100})
⚡ Initiating download for: $REPO_NAME
💾 Saving to: $PWD/${USER_DIR_PATH:-$DIR_NAME}
$(printf '%.0s#' {1..100})

EOF


aria2c_args=(
  -x "${MAX_CONNECTION_PER_SERVER:-8}"
  -s "${SPLIT:-20}"
  -k "${MIN_SPLIT_SIZE:-1M}"
  -c "${CONTINUE_DOWNLOAD:-true}"
  -V "${CHECK_INTEGRITY:-true}"
  -i "$URL_LIST_FILE"
  -d "${USER_DIR_PATH:-$DIR_NAME}"
  --console-log-level "${CONSOLE_LOG_LEVEL:-error}"
  --download-result "${DOWNLOAD_RESULT:-full}"
  --summary-interval "${SUMMARY_INTERVAL:-10}"
)
aria2c "${aria2c_args[@]}"

# Clean up the URL files
rm "$URL_LIST_FILE"
if [[ -n "$INTERACTIVE_MODE" && -f "$OUTPUT_FILE" ]]; then
  rm "$OUTPUT_FILE"
fi
