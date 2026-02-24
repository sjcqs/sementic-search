# sementic-search

Free, local semantic search for Claude Code — no API fees, no cloud subscriptions.

Love Claude Code but miss Cursor's semantic search? This project gives you that capability using entirely open source, locally-run tools. Your code never leaves your machine.

## How It Works

Traditional search (`grep`, `ripgrep`) finds exact string matches. Semantic search understands *meaning* — it knows that "user authentication" and "verify login credentials" are conceptually related. This project wires together three open source components to bring that to Claude Code:

| Component | Role |
|-----------|------|
| [Ollama](https://ollama.ai) | Runs embedding models locally (free) |
| [Milvus](https://milvus.io) | Vector database for storing/querying embeddings (free, local via Docker) |
| [claude-context](https://github.com/zilliztech/claude-context) | MCP server bridging Claude Code to Milvus + Ollama |

On macOS with Apple Silicon, [Colima](https://github.com/abiosoft/colima) replaces Docker Desktop as the container runtime.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- [Homebrew](https://brew.sh/)
- [direnv](https://direnv.net/) (`brew install direnv`)

Everything else is installed during setup.

## Quick Start

```sh
# 1. Clone and enter the repo
git clone <repo-url> && cd sementic-search

# 2. Run one-time setup (installs deps, pulls model, creates config)
scripts/semsearch-init.sh

# 3. Activate environment variables
direnv allow

# 4. Start all services (Ollama, Colima, Milvus)
scripts/semsearch-start.sh

# 5. Add the MCP server to Claude Code
scripts/semsearch-claude-install.sh

# 6. (Optional) Add commands to your PATH
scripts/semsearch-link.sh
```

After installing, restart Claude Code so it picks up the new MCP server.

## Usage

With services running, ask Claude Code to index a codebase by path:

> "Index the codebase at /path/to/my/project"

Then search semantically:

> "Search for health check endpoint implementation"

The search understands context. In a Kubernetes codebase, "verify user permissions" returns results about container authentication, device access control, and secret management — even though none of those files contain the exact phrase.

### Semantic Search vs Traditional Search

**Traditional** (`grep`/`rg`): Multiple queries, manual pattern iteration, incomplete picture.

```
health.*check|healthcheck|health_check  → 0 results
healthz|readiness|liveness              → 2 files
health                                  → 9 files to review manually
```

**Semantic** (one query): Comprehensive results that understand context — device health monitoring, gRPC streaming health APIs, plugin architecture.

## Scripts

All scripts live in `scripts/` and support `--help`.

| Script | Description |
|--------|-------------|
| `semsearch-init.sh` | One-time setup: checks prereqs, pulls embedding model, downloads Milvus, creates `.envrc` |
| `semsearch-claude-install.sh` | Add (or `--remove`) the claude-context MCP server in Claude Code |
| `semsearch-start.sh` | Start all services (Ollama, Colima, Milvus) |
| `semsearch-stop.sh` | Stop services |
| `semsearch-restart.sh` | Restart services |
| `semsearch-link.sh` | Symlink scripts to `~/bin` for global access |
| `milvus-start.sh` | Start Milvus only |
| `milvus-stop.sh` | Stop Milvus only |
| `milvus-restart.sh` | Restart Milvus only |

### Common Options

```sh
semsearch-start.sh --no-ollama     # Skip Ollama (if it's already running)
semsearch-stop.sh --colima         # Also stop the Colima VM
semsearch-stop.sh --keep-ollama    # Keep Ollama running
semsearch-link.sh --dir /usr/local/bin  # Custom symlink directory
semsearch-link.sh --remove         # Remove symlinks
semsearch-init.sh --force          # Overwrite existing config files
semsearch-claude-install.sh        # Add MCP server to Claude Code
semsearch-claude-install.sh --remove  # Remove MCP server from Claude Code
```

## Configuration

Environment variables (set in `.envrc` or exported manually):

| Variable | Default | Description |
|----------|---------|-------------|
| `EMBEDDING_PROVIDER` | `Ollama` | Embedding provider |
| `EMBEDDING_MODEL` | `nomic-embed-text:v1.5` | Ollama model for embeddings |
| `MILVUS_ADDRESS` | `http://localhost:19530` | Milvus endpoint |
| `EMBEDDING_BATCH_SIZE` | `10` | Batch size for local embedding |
| `COLIMA_CPU` | `4` | CPUs allocated to Colima |
| `COLIMA_MEMORY` | `8` | Memory (GB) for Colima |
| `COLIMA_DISK` | `100` | Disk (GB) for Colima |

## Service Endpoints

| Service | URL |
|---------|-----|
| Ollama | http://localhost:11434 |
| Milvus gRPC | localhost:19530 |
| Milvus WebUI | http://127.0.0.1:9091/webui/ |

## Performance Tips

- **Index incrementally** — don't index massive monorepos at once. Index specific components or packages. Each path creates its own collection.
- **Change detection is automatic** — claude-context uses Merkle trees (`~/.context/merkle/`) to track file changes. Only modified files are re-indexed.
- **Collections are independent** — `/project/alpha` and `/project/beta` update separately, keeping re-indexing fast.

## Gotcha: Embedding Dimensions

claude-context hardcodes embedding dimensions based on the provider. `nomic-embed-text:v1.5` produces 768-dimensional embeddings, which matches the expected default. If you swap to a different model (e.g., via LM Studio), you may hit silent dimension mismatch failures.

## Cost Comparison

| Approach | Embeddings | Vector DB | Collections |
|----------|-----------|-----------|-------------|
| Cloud (OpenAI + Zilliz) | $0.02–$0.13/M tokens | Free tier (2 collections), then $99/mo | Limited |
| **Local (this project)** | **$0** | **$0** | **Unlimited** |

## Resources

- [Milvus docs](https://milvus.io/docs) — LF AI & Data graduated project
- [Zilliz Cloud](https://zilliz.com/cloud) — Managed Milvus with free tier
- [claude-context](https://github.com/zilliztech/claude-context) — MCP server for semantic search
- [Ollama embedding models](https://ollama.ai/library?type=embedding)
- [Colima](https://github.com/abiosoft/colima) — Container runtime for macOS
- [Semantic Code Search in Claude Code — The Missing Feature](https://medium.com/@jldavern/semantic-code-search-in-claude-code-the-missing-feature-32b22d62f6a2) — Blog post walkthrough
