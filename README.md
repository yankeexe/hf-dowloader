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
```

## Options

- `-ds` - Download as dataset (default: model)
- `-x <num>` - Connections per server (default: 8)
- `-s <num>` - Number of splits (default: 20)
- `-k <size>` - Min split size (default: 1M)
- `-V <true|false>` - Verify integrity (default: true)
- `-c <true|false>` - Continue downloading (default: true)
- `-d <dir>` - Download directory (default: repo_name)
- `--console-log-level <lvl>` - Console log level (default: error)
- `--download-result <res>` - Download result (default: full)
- `--summary-interval <sec>` - Summary interval (default: 10)
- `-h, --help` - Show help

## Requirements

- aria2c
- Python with huggingface_hub
