# Backend Network Setup for Physical Device

## Issue
The backend is currently only accessible from localhost. To connect from your physical device, you need to:

## Solution

### 1. Stop the current backend (if running)
Press `Ctrl+C` in the terminal where uvicorn is running.

### 2. Restart backend with network access
```bash
cd backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The `--host 0.0.0.0` flag makes the server accessible from any network interface.

### 3. Update app configuration
The app's base URL has been updated to: `http://192.168.8.9:8000/api`

### 4. Verify connection
- Make sure your phone and computer are on the same WiFi network
- Test by opening `http://192.168.8.9:8000/health` in your phone's browser
- You should see: `{"status":"healthy"}`

## Alternative: Use different IPs for different devices

You can create a configuration file or use environment variables to switch between:
- **Emulator**: `http://10.0.2.2:8000/api`
- **Physical Device**: `http://192.168.8.9:8000/api`
- **iOS Simulator**: `http://localhost:8000/api`

## Security Note
For production, don't use `--host 0.0.0.0` without proper firewall rules and authentication.




