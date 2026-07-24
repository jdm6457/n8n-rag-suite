#!/bin/bash

COLLECTION_NAME="n8n_templates"
QDRANT_URL="http://localhost:6333"

echo "Creating Qdrant snapshot for collection: ${COLLECTION_NAME}..."
RESPONSE=$(curl -s -X POST "${QDRANT_URL}/collections/${COLLECTION_NAME}/snapshots")

SNAPSHOT_NAME=$(echo "$RESPONSE" | jq -r '.result.name')

if [ "$SNAPSHOT_NAME" != "null" ] && [ -n "$SNAPSHOT_NAME" ]; then
  echo "Snapshot created: ${SNAPSHOT_NAME}"
  echo "Downloading snapshot file..."
  curl -O "${QDRANT_URL}/collections/${COLLECTION_NAME}/snapshots/${SNAPSHOT_NAME}"
  echo "Done! Saved ${SNAPSHOT_NAME} to current directory."
else
  echo "Error creating snapshot: ${RESPONSE}"
  exit 1
fi
