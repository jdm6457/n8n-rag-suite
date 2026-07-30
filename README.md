# ⚡ n8n Air-Gapped Local RAG Suite

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![n8n](https://img.shields.io/badge/n8n-v1.x+-FF6D5A.svg)
![Qdrant](https://img.shields.io/badge/Qdrant-v1.7+-DC2626.svg)
![Ollama](https://img.shields.io/badge/Ollama-Local_LLM-000000.svg)
![Python](https://img.shields.io/badge/Python-3.10+-3776AB.svg)

> A fully self-hosted, air-gapped Retrieval-Augmented Generation (RAG) copilot engineered with n8n, Qdrant vector database, and local Ollama LLMs. Features automated documentation sync, ~10ms SHA cache guards, regex secret sanitization, and pre-indexed community template search (10k+ templates / ~749k vector points)—optimized for local execution within 8GB VRAM hardware boundaries.

---

## 📌 Architecture Overview

The suite operates entirely within local hardware boundaries to maintain total data sovereignty. It orchestrates a local AI agent using dynamic dual-tool routing across two specialized vector collections in Qdrant: official n8n documentation and community workflow templates.

```
                                 +------------------------------+
                                 |   n8n Chat Assistant Agent   |
                                 |    (qwen2.5:7b-instruct)     |
                                 +--------------+---------------+
                                                |
                                      [Dynamic Tool Router]
                                                |
                        +-----------------------+-----------------------+
                        |                                               |
                        v                                               v
          +---------------------------+                   +---------------------------+
          |  Tool 1: n8n Docs Search  |                   | Tool 2: Templates Search  |
          |  (Qdrant Vector Store)    |                   |  (Qdrant Vector Store)    |
          +-------------+-------------+                   +-------------+-------------+
                        ^                                               ^
                        |                                               |
              [10ms SHA Cache Guard]                           [7-Stage Regex]
                        |                                               |
           Upstream `n8n-docs` Repo                       10k+ Templates (~749k Vectors)
```

---

## 📂 Repository Structure

```
n8n-rag-suite/
├── docker-compose.yml                      # Containerized n8n & Qdrant orchestration with host Ollama bridge
├── workflows/
│   ├── n8n-template-catalog-vector-sync.json # Phase 1: Community template vector ingestion & hygiene
│   ├── n8n-docs-vector-sync.json           # Phase 2: Official docs sync & SHA cache guard
│   └── n8n-rag-chat-assistant.json        # Phase 3: On-device dual-tool RAG Chat Assistant
├── scripts/
│   ├── seed_qdrant.py                      # Automated vector dataset seeder from Hugging Face
│   └── requirements.txt                    # Python dependencies for dataset seeding
├── .env.example                            # Environment variable configuration template
├── LICENSE                                 # MIT open-source license
└── README.md                               # Documentation & system architecture guide
```

---

## 🛠️ System Phases & Roadmap

### Operational Production Phases `[STATUS: COMPLETED / PRODUCTION]`

* **Phase 1: Community Template Catalog Vector Sync & Data Hygiene** `[COMPLETED]`
  * Vectorized snapshot of 10k+ n8n community workflow templates (~749k vector points) stored in Qdrant (`n8n-template-catalog-vector-sync.json`).
  * Embedded **7-stage regex security sanitizer** within n8n workflow nodes to scrub API tokens, credentials, connection strings, bearer headers, and control characters prior to vector embedding.
  * Published a pre-indexed ~749k vector point dataset snapshot to [Hugging Face Datasets](https://huggingface.co/datasets/jdm6457/n8n-community-template-vectors) (`jdm6457/n8n-community-template-vectors`) for 1-click database seeding.

* **Phase 2: Official Documentation Sync & Automated Maintenance** `[COMPLETED]`
  * Automated sync pipeline pulling official upstream `n8n-docs` markdown content into Qdrant (`n8n-docs-vector-sync.json`).
  * Integrated **~10ms Smart GitHub SHA Guard** querying GitHub commit SHAs against local state to skip redundant re-indexing when documentation is unchanged.

* **Phase 3: On-Device AI RAG Chat Assistant (Dual-Tool Copilot)** `[COMPLETED]`
  * Local AI Agent running `qwen2.5:7b-instruct` via Ollama (`n8n-rag-chat-assistant.json`).
  * Calibrated system prompts and conversational memory window settings.
  * Dynamic dual-tool routing between official n8n documentation and the 10k+ community template vector catalog (~749k vector points) based on query intent.
  * Performance-optimized for 8GB VRAM environments (~28–35 tokens/sec generation speed).

---

### Future Enhancement Roadmap `[STATUS: PLANNED ROADMAP]`

* **Phase 4: Hybrid Search (Sparse + Dense Retrieval)** `[PLANNED]`: Integrating BM25 sparse keyword matching alongside Qdrant dense vector embeddings to improve exact-match node/parameter syntax lookups.
* **Phase 5: Cross-Encoder Reranking** `[PLANNED]`: Implementing a local re-scoring stage (`bge-reranker-large`) to re-rank vector search results before passing context to the LLM context window.
* **Phase 6: Model Context Protocol (MCP) Integration** `[PLANNED]`: Exposing the suite via standardized MCP server endpoints for integration with IDEs, local terminals, and desktop assistants.
* **Phase 7: Text-to-Workflow Scaffolding** `[PLANNED]`: Direct natural language generation and automated validation of deployable n8n workflow JSON schemas.
* **Phase 8: Automated Security & Compliance Auditing** `[PLANNED]`: Real-time static analysis of workflow nodes to flag unencrypted credentials, broad HTTP request parameters, or security violations.
* **Phase 9: Continuous RAG Benchmarking** `[PLANNED]`: Automated precision/recall benchmarking (Ragas/TruLens) to track retrieval accuracy and hallucination rates over time.
* **Phase 10: Multi-Model Fallback Orchestration** `[PLANNED]`: Dynamic request routing between small fast models (3B/7B) and larger quantized weights depending on query complexity.
* **Phase 11: Multi-Tenant Access & RBAC** `[PLANNED]`: Namespace payload filtering in Qdrant for isolation across multi-user or enterprise team environments.
* **Phase 12: Telemetry & Observability Framework** `[PLANNED]`: Local OpenTelemetry tracing and Prometheus metrics tracking execution latency, vector retrieval speeds, and VRAM utilization.

---

## ⚡ Hardware Benchmarks & VRAM Tuning (8GB VRAM)

Tested on local workstation hardware (Apple Silicon / NVIDIA RTX 8GB VRAM):

| Component | Specification / Metric |
| :--- | :--- |
| **LLM Model** | `qwen2.5:7b-instruct` (4-bit Q4_K_M quantization) |
| **Embedding Model** | `nomic-embed-text` (768-dim) |
| **SHA Guard Latency** | ~10ms (commit cache state check) |
| **Vector Retrieval** | <15ms average payload latency (Qdrant) |
| **Generation Speed** | ~28–35 tokens/sec |
| **Peak VRAM Usage** | ~5.8 GB (leaving headroom for host OS tasks) |

> 💡 **8GB VRAM Tuning Tip:** In the n8n Ollama node parameters, set the context window parameter (`num_ctx`) to **`8192`** or **`16384`**. This prevents out-of-memory (OOM) GPU allocation spikes when feeding multi-document vector payloads into the prompt template.

---

## 🚀 Quick Start & Deployment

### Prerequisites
* **Docker & Docker Compose**
* **Ollama** (Running natively on host OS with `qwen2.5:7b-instruct` and `nomic-embed-text`)
* **Python 3.10+** (For dataset seeding)

### 1. Launch Container Infrastructure

Deploy the stack using the root `docker-compose.yml`:

```yaml
networks:
  n8n-rag-network:
    driver: bridge

volumes:
  n8n_storage:
  qdrant_storage:

services:
  # --------------------------------------------------
  # 1. Qdrant Vector Database
  # --------------------------------------------------
  qdrant:
    image: qdrant/qdrant:latest
    container_name: n8n_qdrant
    restart: unless-stopped
    ports:
      - "${QDRANT_PORT}:6333"
      - "6334:6334"
    volumes:
      - qdrant_storage:/qdrant/storage
    networks:
      - n8n-rag-network
    healthcheck:
      test: ["CMD-SHELL", "timeout 1s bash -c 'cat < /dev/null > /dev/tcp/127.0.0.1/6333' || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 5

  # --------------------------------------------------
  # 2. n8n Automation Engine
  # --------------------------------------------------
  n8n:
    image: docker.n8n.io/n8nio/n8n:latest
    container_name: n8n_app
    env_file:
      - .env
    restart: unless-stopped
    ports:
      - "${N8N_PORT}:5678"
    environment:
      - N8N_HOST=localhost
      - N8N_PORT=${N8N_PORT}
      - N8N_PROTOCOL=http
      - NODE_ENV=production
      - WEBHOOK_URL=http://localhost:${N8N_PORT}/
      - GENERIC_TIMEZONE=${TIMEZONE}
      - N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=${N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS}
    volumes:
      - n8n_storage:/home/node/.n8n
    networks:
      - n8n-rag-network
    extra_hosts:
      - "host.docker.internal:host-gateway"
    depends_on:
      qdrant:
        condition: service_healthy
```

Start the containers:
```bash
docker compose up -d
```

### 2. Environment Configuration

Copy `.env.example` to `.env` and configure your local settings:
```env
N8N_PORT=5678
QDRANT_PORT=6333
TIMEZONE=America/New_York
N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
N8N_ENCRYPTION_KEY=your_secure_encryption_key
```

### 3. Seed Pre-Indexed Community Vector Dataset

Pull and load the pre-computed template vector dataset snapshot (~749k vector points across 10k+ templates) directly from [Hugging Face Datasets](https://huggingface.co/datasets/jdm6457/n8n-community-template-vectors):

```bash
pip install -r scripts/requirements.txt
python3 scripts/seed_qdrant.py --dataset jdm6457/n8n-community-template-vectors
```

### 4. Import Workflows into n8n

* Open your n8n web UI (`http://localhost:5678`).
* Navigate to **Workflows** $\rightarrow$ **Import from File**.
* Import the three core suite JSON workflows in sequence:
  1. `workflows/n8n-template-catalog-vector-sync.json` (Phase 1 Template Sync & Hygiene)
  2. `workflows/n8n-docs-vector-sync.json` (Phase 2 Official Docs Sync & SHA Guard)
  3. `workflows/n8n-rag-chat-assistant.json` (Phase 3 AI Assistant Agent)

---

## 🛡️ Security & Data Hygiene (Phase 1 Detail)

Prior to vector embedding, all raw community templates pass through a 7-stage regex sanitizer node in n8n to ensure zero credential exfiltration:

```javascript
// 7-Stage Regex Sanitizer Code Snippet (n8n Code Node)
const sanitizeContent = (rawText) => {
  return rawText
    .replace(/(sk-[a-zA-Z0-9]{32,})/g, '[REDACTED_API_KEY]')
    .replace(/(Bearer\s+[a-zA-Z0-9\.\-_]+)/gi, '[REDACTED_TOKEN]')
    .replace(/(postgres:\/\/|mysql:\/\/|mongodb\+srv:\/\/)[^\s]+/gi, '[REDACTED_URI]')
    .replace(/("password":\s*")[^"]+(")/gi, '$1[REDACTED_PASSWORD]$2')
    .replace(/("secret":\s*")[^"]+(")/gi, '$1[REDACTED_SECRET]$2')
    .replace(/("private_key":\s*")[^"]+(")/gi, '$1[REDACTED_KEY]$2')
    .replace(/[\x00-\x1F\x7F]/g, ''); // Control characters
};
```

---

## 📜 License

Distributed under the **MIT License**. Built and maintained by [John Moorhead](https://github.com/jdm6457) — Active CCIE #6457 & Principal Enterprise Architect.