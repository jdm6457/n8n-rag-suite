# Local On-Device n8n RAG Suite

A fully self-hosted, air-gapped retrieval-augmented generation (RAG) system built for **n8n workflows, node documentation, and intelligence assistant automation**.

This suite continuously ingests public n8n templates and documentation, vectorizes content via local GPU-accelerated embeddings, and enables grouped RAG retrieval using Qdrant and Ollama.

---

## 🏗 System Architecture

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

## 📁 Repository Structure

```text
n8n-rag-suite/
├── docker-compose.yml
├── .env.example
├── README.md
├── workflows/
│   ├── 01-sync-n8n-templates-to-qdrant.json
│   ├── 02-sync-n8n-docs-to-qdrant.json
│   └── 03-local-rag-chat-assistant.json
└── scripts/
    └── export-qdrant-snapshot.sh
```

---

## ⚡ Quick Start & Deployment

### 1. Prerequisites
* Docker & Docker Compose
* Host Ollama installed natively with GPU acceleration
* Pulled Ollama Models:
  ```bash
  ollama pull nomic-embed-text
  ollama pull qwen2.5:7b-instruct
  ```

### 2. Configure Host Ollama Service
Ensure Ollama is bound to `0.0.0.0:11434` to accept container requests:

```bash
sudo systemctl edit ollama.service
```

Ensure the override matches:
```ini
[Service]
User=john
Group=john
Environment="OLLAMA_MODELS=/home/john/.ollama/models"
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_ORIGINS=*"
```

Reload and start:
```bash
sudo systemctl daemon-reload && sudo systemctl restart ollama
```

### 3. Deploy the Docker Stack
```bash
cp .env.example .env
docker compose up -d
```

---

## 📦 Instant Vector Seed (Skip Full Ingestion Sweep)

Instead of performing the multi-hour initial catalog embedding sweep, you can seed your Qdrant database instantly using a pre-indexed vector snapshot (~240k points):

1. **Download Snapshot**:
   Download the latest `.snapshot` file from the [Releases page](../../releases).

2. **Restore to Local Qdrant**:
   ```bash
   curl -X POST http://localhost:6333/collections/n8n_templates/snapshots/upload \
     -H 'Content-Type: multipart/form-data' \
     -F 'snapshot=@n8n_templates-latest.snapshot'
   ```

3. **Verify Seed**:
   ```bash
   curl -s http://localhost:6333/collections/n8n_templates | jq '.result.points_count'
   ```

---

## 🔄 Workflow 01: Daily Incremental Template Sync

* **File**: `workflows/01-sync-n8n-templates-to-qdrant.json`
* **Schedule**: Daily at 02:00 AM local time
* **Function**: Fetches Pages 1–2 of the n8n template API, cleans invalid unicode/hex control sequences, conducts automated secret detection audits, and upserts updated vectors to Qdrant.

---

## 💻 Ubuntu Desktop Sleep & Lid Override (Always-On Server Mode)

If running this suite on an Ubuntu workstation laptop with the lid closed while plugged into AC power:

```bash
# 1. Disable GNOME Desktop Lid Suspend
gsettings set org.gnome.settings-daemon.plugins.power lid-close-ac-action 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power lid-close-battery-action 'nothing'

# 2. Update systemd-logind
sudo nano /etc/systemd/logind.conf
# Set: HandleLidSwitch=ignore & HandleLidSwitchExternalPower=ignore
sudo systemctl restart systemd-logind
```

---

## 🧹 Database Maintenance & Log Auto-Pruning

n8n execution logs are automatically purged every 7 days (168 hours) to maintain database performance:
* Set via `EXECUTIONS_DATA_PRUNE=true` and `EXECUTIONS_DATA_MAX_AGE=168` in `.env`.