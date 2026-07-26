# Local On-Device n8n RAG Suite

A fully self-hosted, air-gapped retrieval-augmented generation (RAG) system and AI Engineering Copilot built for **n8n workflows, node documentation, and intelligence assistant automation**.

This suite continuously ingests public n8n templates and official documentation, vectorizes content via local GPU-accelerated embeddings, and enables dual-tool RAG retrieval using Qdrant and Ollama.

---

## 🎯 Overview & Key Capabilities

Standard cloud LLMs frequently hallucinate n8n node schemas, expression syntax, and API parameters. Additionally, passing internal enterprise workflow logic or credential structures to public SaaS models introduces compliance and security risks.

This suite provides an end-to-end, locally hosted intelligence pipeline designed to generate, debug, and automate n8n workflows with zero external API dependencies.

* **100% Privacy & Air-Gapped Security**: All ingestion, vectorization, and model inference execute locally on host hardware. No workflow data or prompt context leaves your environment.
* **Schema-Accurate Dual RAG Retrieval**: Ingests and vectorizes public templates (~242k vector points) and official n8n documentation (~148k vector points) to eliminate hallucinations and supply real-world workflow patterns.
* **Zero Operational API Cost**: Powered by local Ollama acceleration (`nomic-embed-text` for 768-dim embeddings and `qwen2.5:7b-instruct` for orchestration/generation).
* **Automated Data Hygiene & Maintenance**: Built-in regex filters strip sensitive API keys/secrets prior to vector storage, workflow execution logs are automatically pruned, and daily GitHub SHA checks prevent redundant re-indexing.

---

## 🚀 Current Project Status

**Phases 1, 2, and 3 are 100% complete and operational!**

* **Phase 1 (Template Catalog Sync)**: Ingested over 240,000+ vector points from the n8n community workflow template catalog into Qdrant (`n8n_templates`).
* **Phase 2 (Doc Sync & Automated Maintenance)**: Ingested official n8n documentation (~148,000+ vectors) into Qdrant (`n8n_docs`) with an automated daily 3 AM schedule and smart GitHub Commit SHA change-detection.
* **Phase 3 (On-Device RAG Assistant)**: Fully deployed local AI Agent with dynamic tool routing across both vector stores (`n8n_docs_retriever` & `n8n_templates_retriever`).

---

## 🏗️ System Architecture

```text
┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│   n8n Engine   │───> │ Host Ollama GPU│───> │   Qdrant DB    │
│  (Docker App)  │     │ (nomic-embed)  │     │  (Port 6333)   │
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

## 🧩 Suite Components & Workflows

### 📦 Phase 1: Community Template Catalog Vector Sync
* **Workflow File**: `workflows/n8n-template-catalog-vector-sync.json`
* **Target Collection**: `n8n_templates` (~242,000 vectors)
* **Description**: Parses, chunks, and embeds the n8n community workflow template repository. Conducts automated secret detection audits, cleans invalid unicode control sequences, and upserts dense vector embeddings.

### 📚 Phase 2: Official Documentation Vector Sync
* **Workflow File**: `workflows/n8n-docs-vector-sync.json`
* **Target Collection**: `n8n_docs` (~148,000 vectors)
* **Description**: Recursively fetches Markdown files from `n8n-io/n8n-docs`. Runs on a daily schedule at **3:00 AM** and queries the GitHub API for the latest commit SHA.
  * **Smart Change Detection**: If the latest commit SHA matches stored memory, execution terminates in ~10ms without hitting Qdrant or Ollama.
  * **Auto-Update**: If documentation changes are detected on GitHub, the workflow automatically wipes the old collection and re-indexes the documentation.

### 🤖 Phase 3: On-Device RAG Chat Assistant
* **Workflow File**: `workflows/n8n-rag-chat-assistant.json`
* **Description**: A local, conversational AI Assistant powered by an n8n AI Agent and `qwen2.5:7b-instruct`. Uses `Window Buffer Memory` for context retention and features dual **Vector Store Tools** for domain-specific retrieval:
  * **`n8n_docs_retriever`**: Directs environment setup, expression syntax, queue mode, and core architecture queries to official documentation.
  * **`n8n_templates_retriever`**: Directs requests for sample JSON structures, flow patterns, and real-world node configurations to template vectors.
  * **Hybrid Synthesis**: Seamlessly queries both vector stores sequentially for complex prompts requiring theory and implementation examples.

---

## 📦 Database Seeding Options

You can populate your local Qdrant vector database using either of the following two options:

### Option A: Instant Vector Seed (Skip Ingestion Sweep)
Instead of performing the multi-hour initial catalog embedding sweep, seed your local Qdrant database instantly using the official pre-indexed vector snapshot (~242k points):

1. **Download Snapshot from Release v1.0.0** (`-L` ensures `curl` follows the GitHub S3 redirect):
   ```bash
   curl -L -O [https://github.com/jdm6457/n8n-rag-suite/releases/download/v1.0.0/n8n_templates-5566120412088090-2026-07-24-01-41-17.snapshot](https://github.com/jdm6457/n8n-rag-suite/releases/download/v1.0.0/n8n_templates-5566120412088090-2026-07-24-01-41-17.snapshot)
   ```

2. **Restore to Local Qdrant**:
   ```bash
   curl -X POST http://localhost:6333/collections/n8n_templates/snapshots/upload \
     -H 'Content-Type: multipart/form-data' \
     -F 'snapshot=@n8n_templates-5566120412088090-2026-07-24-01-41-17.snapshot'
   ```

3. **Verify Seed**:
   ```bash
   curl -s http://localhost:6333/collections/n8n_templates | jq '.result.points_count'
   ```

---

### Option B: Fresh Ingestion via n8n Workflows
1. Import `workflows/n8n-template-catalog-vector-sync.json` and execute manually to generate fresh embeddings for `n8n_templates`.
2. Import `workflows/n8n-docs-vector-sync.json` and execute manually once to populate `n8n_docs` and lock in the initial GitHub commit SHA. Toggle its status to **Active** for automated daily maintenance.

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

* **Docker vs Host Networking**: When n8n runs inside Docker and Ollama/Qdrant run on the host system, configure connections using `http://host.docker.internal:11434` or `http://host.docker.internal:6333` inside the n8n UI credentials instead of `localhost`.
* **Collection Dimensions**: Ensure Qdrant collection settings match the 768-dimension vector output of `nomic-embed-text`.

---

## 🗺️ 12-Phase Master Roadmap

| Phase | Module / Enhancement | Status | Description |
| :--- | :--- | :--- | :--- |
| **Phase 1** | **Template Catalog Vector Sync** | 🟢 Complete | Seeding ~242k community workflow vectors into Qdrant (`n8n_templates`). |
| **Phase 2** | **Doc Sync & SHA Maintenance** | 🟢 Complete | Seeding ~148k doc vectors with automated 3 AM SHA change-detection (`n8n_docs`). |
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