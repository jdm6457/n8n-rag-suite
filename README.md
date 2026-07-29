# Local On-Device n8n RAG Suite

A fully self-hosted, air-gapped retrieval-augmented generation (RAG) system and AI Engineering Copilot built for **n8n workflows, node documentation, and intelligence assistant automation**.

This suite continuously ingests public n8n templates and official documentation, vectorizes content via local GPU-accelerated embeddings, and enables dual-tool RAG retrieval using Qdrant and Ollama.

---

## 🎯 Overview & Key Capabilities

Standard cloud LLMs frequently hallucinate n8n node schemas, expression syntax, and API parameters. Additionally, passing internal enterprise workflow logic or credential structures to public SaaS models introduces compliance and security risks.

This suite provides an end-to-end, locally hosted intelligence pipeline designed to generate, debug, and automate n8n workflows with zero external API dependencies.

* **100% Privacy & Air-Gapped Security**: All ingestion, vectorization, and model inference execute locally on host hardware. No workflow data or prompt context leaves your environment.
* **Schema-Accurate Dual RAG Retrieval**: Ingests and vectorizes public templates (~749k vector points) and official n8n documentation (14,610 section vector points across 1,445 files) to eliminate hallucinations and supply real-world workflow patterns.
* **Zero Operational API Cost**: Powered by local Ollama acceleration (`nomic-embed-text` for 768-dim embeddings and `qwen2.5:7b-instruct` for orchestration/generation).
* **Rich Metadata Enrichment**: Every vector chunk is enriched with high-precision developer metadata scalars (e.g., code block flags, target node package names, secret security warnings, AI node detection) enabling hyper-targeted Qdrant payload filters.
* **Automated Data Hygiene & Deduplication**: Built-in regex filters strip sensitive API keys/secrets prior to vector storage, an automated HTTP pre-sync purge keeps vector stores strictly deduplicated, workflow execution logs are automatically pruned, and daily GitHub SHA checks prevent redundant doc re-indexing.

---

## 🚀 Current Project Status

**Phases 1, 2, and 3 are 100% complete and operational!**

* **Phase 1 (Template Catalog Sync)**: Ingested over 749,000+ deduplicated vector points from the n8n community workflow template catalog into Qdrant (`n8n_templates`). Includes automated idempotent pre-sync purges and secret detection filters.
* **Phase 2 (Doc Sync & Automated Maintenance)**: Ingested official n8n documentation into 14,610 clean, section-level vector points in Qdrant (`n8n_docs`). Operates on an automated daily 3 AM schedule with a ~10ms smart GitHub Commit SHA change-detection guard.
* **Phase 3 (On-Device RAG Assistant)**: Fully deployed local AI Agent with dynamic tool routing across both vector stores (`n8n_docs_retriever` & `n8n_templates_retriever`).

---

## 🏗️ System Architecture

```text
┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│   n8n Engine   │───> │ Host Ollama GPU│───> │    Qdrant DB   │
│  (Docker App)  │     │ (nomic-embed)  │     │   (Port 6333)  │
└────────────────┘     └────────────────┘     └────────────────┘
```

* **Orchestration**: n8n (`docker.n8n.io/n8nio/n8n:latest`)
* **Vector Database**: Qdrant (`qdrant/qdrant:latest`)
* **Embeddings Engine**: Host Ollama with CUDA GPU Acceleration (`nomic-embed-text`)
* **Inference Engine**: Host Ollama (`qwen2.5:7b-instruct`)

---

## 📂 Repository Structure

```text
n8n-rag-suite/
├── README.md
├── docker-compose.yml
├── .env.example
├── .gitignore
├── scripts/
│   └── export-qdrant-snapshot.sh
└── workflows/
    ├── n8n-template-catalog-vector-sync.json
    ├── n8n-docs-vector-sync.json
    └── n8n-rag-chat-assistant.json
```

---

## 📊 Vector Metadata Schemas & Filtering Capabilities

Both vector collections are configured with custom developer metadata payloads mapped directly via n8n's **Default Data Loader** sub-node running in `JSON` mode with `Text Splitting: None`. This ensures custom chunking logic is preserved while enabling advanced Qdrant payload filters.

### 📚 `n8n_docs` Collection Schema (~14,610 Points)

| Metadata Key | Type | Description / Example |
| :--- | :--- | :--- |
| `category` | String | Documentation section category (e.g., `"integrations"`, `"build"`, `"connect"`) |
| `file_path` | String | Relative GitHub file path (e.g., `"docs/integrations/builtin/core-nodes/n8n-nodes-base.httprequest/README.md"`) |
| `title` | String | Page title parsed from frontmatter or document heading |
| `section_heading` | String | Clean heading text for the specific chunk (e.g., `"Import curl command"`) |
| `target_node` | String | Resolved node package identifier (e.g., `"n8n-nodes-base.httprequest"`, `"n8n-nodes-base.code"`) |
| `has_code_block` | Boolean | `true` if chunk contains Markdown code fence block (` ``` `) |
| `has_json_example` | Boolean | `true` if chunk contains raw JSON structures or examples |
| `has_n8n_expression`| Boolean | `true` if chunk contains n8n syntax (`{{ ... }}` or `$json`/`$input`) |
| `has_javascript` | Boolean | `true` if chunk contains JavaScript syntax or code blocks |
| `has_python` | Boolean | `true` if chunk contains Python code blocks |
| `is_node_doc` | Boolean | `true` if chunk belongs to node/integration documentation |
| `chunk_char_length` | Integer | Total character count of the chunk body |
| `chunk_index` | Integer | Sequential index of the section chunk within its source file |

*Example Qdrant Payload Filter:*
```json
{
  "filter": {
    "must": [
      { "key": "metadata.target_node", "match": { "value": "n8n-nodes-base.code" } },
      { "key": "metadata.has_javascript", "match": { "value": true } }
    ]
  }
}
```

---

### 📦 `n8n_templates` Collection Schema (~749,000 Points)

| Metadata Key | Type | Description / Example |
| :--- | :--- | :--- |
| `template_id` | Integer | Official n8n community template ID (e.g., `1924`) |
| `name` | String | Title / name of the workflow template |
| `description` | String | Detailed functional description and use-case summary |
| `categories` | Array | Category tags assigned to template (e.g., `["AI", "Sales"]`) |
| `nodeTypes` | Array | List of unique n8n node types used in the workflow (e.g., `["n8n-nodes-base.code"]`) |
| `node_count` | Integer | Total number of nodes comprising the workflow canvas |
| `trigger_types` | Array | List of trigger node types powering workflow execution (e.g., `["n8n-nodes-base.scheduleTrigger"]`) |
| `has_ai_nodes` | Boolean | `true` if workflow utilizes AI/LangChain/Ollama/VectorStore nodes |
| `has_security_warning` | Boolean | `true` if regex audit flagged potential unencrypted keys, tokens, or raw secrets |
| `views` | Integer | Total view counter on the n8n community template catalog |
| `created_at` | String | ISO creation timestamp string (e.g., `"2025-04-12T14:20:00.000Z"`) |
| `template_url` | String | Direct web link to template on n8n.io (`[https://n8n.io/workflows/](https://n8n.io/workflows/)...`) |

*Example Qdrant Payload Filter:*
```json
{
  "filter": {
    "must": [
      { "key": "metadata.has_ai_nodes", "match": { "value": true } },
      { "key": "metadata.has_security_warning", "match": { "value": false } }
    ]
  }
}
```

---

## ⚡ Quick Start & Host Prerequisites

### 1. Host Requirements
* Docker & Docker Compose
* Host Ollama installed natively with GPU acceleration
* Pulled Ollama Models:
  ```bash
  ollama pull nomic-embed-text
  ollama pull qwen2.5:7b-instruct
  ```

### 2. Configure Host Ollama Service
Ensure Ollama is bound to `0.0.0.0:11434` to accept container requests from the n8n Docker network:

```bash
sudo systemctl edit ollama.service
```

Ensure the systemd override matches:
```ini
[Service]
User=john
Group=john
Environment="OLLAMA_MODELS=/home/john/.ollama/models"
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_ORIGINS=*"
```

Reload and restart Ollama:
```bash
sudo systemctl daemon-reload && sudo systemctl restart ollama
```

### 3. Deploy the Docker Stack
```bash
cp .env.example .env
docker compose up -d
```

---

## 📦 Database Seeding (Instant Vector Seed)

To bypass running a multi-hour catalog embedding sweep, seed your local Qdrant database instantly using the official pre-indexed, deduplicated vector snapshot hosted on Hugging Face Datasets (~749k points):

1. **Download Compressed Snapshot**:
   ```bash
   wget https://huggingface.co/datasets/jdm6457/n8n-rag-suite-snapshot/resolve/main/n8n_templates_749k.snapshot.gz
   ```

2. **Decompress Archive**:
   ```bash
   gunzip n8n_templates_749k.snapshot.gz
   ```

3. **Restore to Local Qdrant**:
   ```bash
   curl -X POST http://localhost:6333/collections/n8n_templates/snapshots/upload \
     -H 'Content-Type: multipart/form-data' \
     -F 'snapshot=@n8n_templates_749k.snapshot'
   ```

4. **Verify Seed**:
   ```bash
   curl -s http://localhost:6333/collections/n8n_templates | jq '{status: .result.status, points_count: .result.points_count}'
   ```

---

## 🧩 Suite Components & Workflows

### 📦 Phase 1: Community Template Catalog Vector Sync
* **Workflow File**: `workflows/n8n-template-catalog-vector-sync.json`
* **Target Collection**: `n8n_templates` (~749,000 vectors)
* **Description**: Parses, chunks, and embeds the n8n community workflow template repository.
  * **Security Audit & Sanitization**: Strips 4-byte surrogate pairs/emojis, orphan surrogates, control characters, and scans sticky notes, system prompts, descriptions, and node parameters against 7 secret regex patterns (`has_security_warning`).
  * **Metadata Extraction**: Maps 12 rich metadata fields including `nodeTypes`, `trigger_types`, `has_ai_nodes`, `views`, and direct `template_url` references.
  * **Deduplicated Overwrites**: Executes an automated pre-sync purge (`Purge Existing Template Vectors` node) to overwrite old vector chunks by `template_id` prior to upserting fresh dense embeddings. Mapped through **Default Data Loader** in `JSON` mode with `Text Splitting: None`.

### 📚 Phase 2: Official Documentation Vector Sync
* **Workflow File**: `workflows/n8n-docs-vector-sync.json`
* **Target Collection**: `n8n_docs` (14,610 section vectors across 1,445 files, ~105 MB footprint)
* **Description**: Recursively fetches Markdown files from `n8n-io/n8n-docs` using GitHub's Git Trees API (`recursive=1`). Runs on a daily schedule at **3:00 AM** and checks the latest repository commit SHA against a stored Qdrant state point (`00000000-0000-0000-0000-000000000000`).
  * **Smart Change Detection**: If the latest commit SHA matches stored memory, execution terminates in ~10ms without hitting Qdrant or Ollama.
  * **Section Chunker & Package Resolution**: The `Markdown Section Chunker` node splits pages by heading tags (`#`, `##`, `###`), extracts target node package names (resolving `README.md` parent directories and sub-pages), and detects developer feature flags (`has_code_block`, `has_javascript`, etc.).
  * **Data Loader Integration**: Connects via **Default Data Loader** (`JSON` mode, `Text Splitting: None`) to preserve pre-chunked section integrity and map all 12 metadata scalars directly into Qdrant payloads.

### 🤖 Phase 3: On-Device RAG Chat Assistant
* **Workflow File**: `workflows/n8n-rag-chat-assistant.json`
* **Description**: A local, conversational AI Assistant powered by an n8n AI Agent and `qwen2.5:7b-instruct`. Uses `Window Buffer Memory` for context retention and features dual **Vector Store Tools** for domain-specific retrieval:
  * **`n8n_docs_retriever`**: Directs environment setup, expression syntax, queue mode, and core architecture queries to official documentation vectors.
  * **`n8n_templates_retriever`**: Directs requests for sample JSON structures, flow patterns, and real-world node configurations to template vectors.
  * **Hybrid Synthesis**: Seamlessly queries both vector stores sequentially for complex prompts requiring theory and implementation examples.

---

## 🛠️ Maintenance Scripts & Database Hygiene

### Export Local Qdrant Snapshot
To create and download a fresh baseline `.snapshot` file of the `n8n_templates` collection locally:

```bash
./scripts/export-qdrant-snapshot.sh
```

### Execution Log Auto-Pruning
n8n execution logs are automatically purged every 7 days (168 hours) to maintain database performance and prevent disk bloat:
* Configured via environment variables in `.env`:
  ```env
  EXECUTIONS_DATA_PRUNE=true
  EXECUTIONS_DATA_MAX_AGE=168
  ```

---

## 💻 Ubuntu Workstation Sleep & Lid Override (Always-On Server Mode)

If running this suite on an Ubuntu workstation laptop with the lid closed while connected to AC power:

```bash
# 1. Disable GNOME Desktop Lid Suspend
gsettings set org.gnome.settings-daemon.plugins.power lid-close-ac-action 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power lid-close-battery-action 'nothing'

# 2. Update systemd-logind configuration
sudo nano /etc/systemd/logind.conf
# Set: HandleLidSwitch=ignore & HandleLidSwitchExternalPower=ignore

# 3. Restart logind service
sudo systemctl restart systemd-logind
```

---

## 🛠️ Troubleshooting & Local Networking

* **Docker vs Host Networking**: When n8n runs inside Docker and Ollama/Qdrant run on the host system, configure connections using `[http://host.docker.internal:11434](http://host.docker.internal:11434)` or `[http://host.docker.internal:6333](http://host.docker.internal:6333)` inside the n8n UI credentials instead of `localhost`.
* **Collection Dimensions**: Ensure Qdrant collection settings match the 768-dimension vector output of `nomic-embed-text`.
* **Data Loader Configuration**: When ingesting custom pre-chunked items from Code nodes, always set **Default Data Loader** to `Type of Data: JSON`, `Mode: Load Specific Data`, `Data: {{ $json.pageContent }}`, and `Text Splitting: None` to avoid sub-fragmenting chunks.

---

## 🗺️ 12-Phase Master Roadmap

| Phase | Module / Enhancement | Status | Description |
| :--- | :--- | :--- | :--- |
| **Phase 1** | **Template Catalog Vector Sync** | 🟢 Complete | Seeding ~749k community workflow vectors into Qdrant (`n8n_templates`). |
| **Phase 2** | **Doc Sync & SHA Maintenance** | 🟢 Complete | Seeding 14.6k doc section vectors with automated 3 AM SHA change-detection (`n8n_docs`). |
| **Phase 3** | **On-Device RAG Chat Assistant** | 🟢 Complete | Local AI Agent with dynamic dual-tool routing using `qwen2.5:7b-instruct`. |
| **Phase 4** | **Hybrid Search & Sparse Vectors** | 🟡 Planned | Integrate BM25 sparse vectors into Qdrant for combined dense/sparse retrieval. |
| **Phase 5** | **Cross-Encoder Reranking** | 🟡 Planned | Add local `bge-reranker-large` post-retrieval node to score chunk relevancy. |
| **Phase 6** | **Model Context Protocol (MCP)** | 🟡 Planned | Expose RAG tools as an MCP server for external IDEs (Claude Desktop, Cursor, VS Code). |
| **Phase 7** | **Text-to-Workflow Generator** | 🟡 Planned | Generate valid, importable n8n workflow canvas JSON directly from user prompts. |
| **Phase 8** | **Code Linter & Security Auditor** | 🟡 Planned | Scan Code nodes for syntax issues, deprecated APIs, and unencrypted secrets. |
| **Phase 9** | **Self-Healing Execution Agent** | 🟡 Planned | Ingest n8n execution failure logs and automatically suggest parameter fixes. |
| **Phase 10**| **Custom Web/UI Frontend** | 🟡 Planned | Connect n8n Chat Trigger to external interfaces (Open WebUI, Slack, Webhooks). |
| **Phase 11**| **Automated Template Sync** | 🟡 Planned | Implement daily automated repository change-detection for template vectors. |
| **Phase 12**| **Continuous RAG Benchmarking** | 🟡 Planned | Automated evaluation suite to track retrieval precision, recall, and accuracy. |