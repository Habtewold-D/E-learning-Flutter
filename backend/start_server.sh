#!/bin/bash
# Script to start the backend server with network access

cd "$(dirname "$0")"
source venv/bin/activate

echo "Starting backend server on 0.0.0.0:8000..."
echo "This will make it accessible from your phone on the same network"
echo "Your IP: $(hostname -I | awk '{print $1}')"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

