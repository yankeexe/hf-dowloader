# 🤗 HuggingFace Downloader

Fast parallel downloader for HuggingFace repositories using aria2c.

## Usage

```bash
./hf.sh <repo_name> [OPTIONS]
```

## Examples

```bash
# Download a model
./hf.sh Qwen/Qwen2.5-0.5B

# Download a dataset
./hf.sh HuggingFaceFW/fineweb-2 -ds

# Download with custom settings
./hf.sh Qwen/Qwen2.5-0.5B -x 16 -s 10 -d ./models

# Interactive file selection
./hf.sh Qwen/Qwen2.5-0.5B -i

# Exclude specific file patterns
./hf.sh Qwen/Qwen2.5-0.5B --exclude "*.sh,*.md,*.yaml"
```

## Options

- `-ds` - Download as dataset (default: disabled)
- `-i` - Interactively select files to download (default: disabled)
- `-x <num>` - Connections per server (default: 8)
- `-s <num>` - Number of splits (default: 20)
- `-k <size>` - Min split size (default: 1M)
- `-V <true|false>` - Verify integrity (default: true)
- `-c <true|false>` - Continue downloading (default: true)
- `-d <dir>` - Download directory (default: repo_name)
- `--console-log-level <lvl>` - Console log level (default: error)
- `--download-result <res>` - Download result (default: full)
- `--summary-interval <sec>` - Summary interval (default: 10)
- `--exclude <patterns>` - Comma-separated glob patterns to exclude files (e.g., *.sh,*.md,*.yaml)
- `--token <token>` - HuggingFace token for private repos
- `-h, --help` - Show help

## Requirements

- aria2c
- Python with huggingface_hub
- fzf (for interactive mode)
