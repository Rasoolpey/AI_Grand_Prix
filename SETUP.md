# 🛠️ AI Grand Prix — Pre-Workshop Setup Guide

Follow these steps **before the workshop day**. This should take about 15–30 minutes on a fresh machine.

If you run into problems, bring your laptop on the day and we'll help you get sorted.

---

## What You Need

| Tool | Version | Why |
|---|---|---|
| MATLAB | R2024a or later | Runs the race simulator |
| MATLAB MCP Server | Latest | Lets the AI agent control MATLAB |
| Python | 3.11 or 3.12 | Required by the MCP server |
| Claude Desktop | Latest | Your AI engineering agent |
| Git | Any recent | Clone the project repo |

---

## Step 1 — Check MATLAB

Open MATLAB and run:

```matlab
version
```

You need **R2024a or later**. If you have an older version, contact your institution's IT/MathWorks licence administrator.

### Required Toolboxes

Check these are installed via **Home → Add-Ons → Manage Add-Ons**:

- ✅ No specific toolboxes required for Phase 1 (just base MATLAB)
- *Optional for later phases: Robotics System Toolbox, Navigation Toolbox*

---

## Step 2 — Install Python

The MATLAB MCP server requires Python **3.11 or 3.12**.

### Check if you already have it

Open a terminal (PowerShell on Windows, Terminal on Mac) and run:

```powershell
python --version
```

If you see `Python 3.11.x` or `Python 3.12.x`, you're done.

### Install Python (if needed)

Download from [python.org/downloads](https://www.python.org/downloads/) — choose **3.12 (latest stable)**.

> ⚠️ **Windows users**: During installation, tick **"Add Python to PATH"** before clicking Install.

After installation, close and reopen your terminal and verify:

```powershell
python --version
```

---

## Step 3 — Install the MATLAB MCP Server

The official MATLAB MCP server is published by MathWorks at:  
📦 **[github.com/matlab/matlab-mcp-server](https://github.com/matlab/matlab-mcp-server)**

### 3a. Clone the MCP server

```powershell
git clone https://github.com/matlab/matlab-mcp-server.git
cd matlab-mcp-server
```

> 💡 **Where to clone?** Somewhere permanent on your machine, e.g. `C:\Tools\matlab-mcp-server` (Windows) or `~/Tools/matlab-mcp-server` (Mac/Linux). You'll need the path in Step 5.

### 3b. Set up the Python environment

Inside the cloned folder, create and activate a virtual environment:

**Windows (PowerShell):**
```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -e .
```

**Mac/Linux:**
```bash
python -m venv .venv
source .venv/bin/activate
pip install -e .
```

> If `pip install -e .` fails, check the `README.md` inside the MCP server repo for up-to-date instructions — the exact setup may vary between releases.

### 3c. Note your Python executable path

After activating the venv, run:

**Windows:**
```powershell
where python
```

**Mac/Linux:**
```bash
which python
```

Copy this full path — you'll need it in Step 5. It will look something like:

- Windows: `C:\Tools\matlab-mcp-server\.venv\Scripts\python.exe`
- Mac/Linux: `/Users/yourname/Tools/matlab-mcp-server/.venv/bin/python`

---

## Step 4 — Install Claude Desktop

Download the latest Claude Desktop from: **[claude.ai/download](https://claude.ai/download)**

Install and sign in with a free Anthropic account.

> 🔑 A free account works for the workshop. Claude Pro gives higher rate limits but is not required.

---

## Step 5 — Configure Claude Desktop to Connect to MATLAB

This is the key step that gives your AI agent the ability to run MATLAB code.

### 5a. Find your config file

Open your Claude Desktop configuration file:

- **Windows:** `%APPDATA%\Claude\claude_desktop_config.json`  
  (paste `%APPDATA%\Claude\` into File Explorer's address bar)
- **Mac:** `~/Library/Application Support/Claude/claude_desktop_config.json`

If the file doesn't exist yet, create it.

### 5b. Paste in the MCP configuration

We've provided a ready-to-use config in this repo at `mcp/claude_desktop_config.json`.

Open it and **copy its contents** into your `claude_desktop_config.json` file, updating the two paths:

```json
{
  "mcpServers": {
    "matlab": {
      "command": "C:\\Tools\\matlab-mcp-server\\.venv\\Scripts\\python.exe",
      "args": [
        "C:\\Tools\\matlab-mcp-server\\matlab_mcp\\server.py"
      ],
      "env": {
        "MATLAB_PATH": "C:\\Program Files\\MATLAB\\R2024a"
      }
    }
  }
}
```

**Update these three paths to match your machine:**

| Placeholder | Replace with |
|---|---|
| `C:\\Tools\\matlab-mcp-server\\.venv\\Scripts\\python.exe` | Your Python path from Step 3c |
| `C:\\Tools\\matlab-mcp-server\\matlab_mcp\\server.py` | Path to `server.py` in your cloned MCP server |
| `C:\\Program Files\\MATLAB\\R2024a` | Your actual MATLAB installation path |

> ⚠️ **Windows users**: Use double backslashes `\\` in JSON, or forward slashes `/` — both work.

> 🍎 **Mac example:**
> ```json
> {
>   "mcpServers": {
>     "matlab": {
>       "command": "/Users/yourname/Tools/matlab-mcp-server/.venv/bin/python",
>       "args": ["/Users/yourname/Tools/matlab-mcp-server/matlab_mcp/server.py"],
>       "env": {
>         "MATLAB_PATH": "/Applications/MATLAB_R2024a.app"
>       }
>     }
>   }
> }
> ```

### 5c. Restart Claude Desktop

After saving the config file, **fully quit and restart** Claude Desktop.

---

## Step 6 — Clone the Workshop Repo

```powershell
git clone https://github.com/<YOUR_INSTRUCTOR_WILL_PROVIDE_THIS>/AI_Grand_Prix.git
cd AI_Grand_Prix
```

> The instructor will share the exact repository URL at or before the workshop.

---

## Step 7 — Verify Everything Works

### 7a. Start MATLAB

Make sure MATLAB is open and running before testing the agent connection.

### 7b. Test in Claude Desktop

Open Claude Desktop and type:

```
Run the testMCP.m script in MATLAB to verify the connection is working.
```

You should see output like:

```
MCP connection OK — MATLAB is ready for the AI Grand Prix!
MATLAB version: 9.13.0.2553474 (R2024b)
```

If this works — **you're all set!** 🎉

### 7c. Test the practice race

Ask Claude:

```
Run practiceRace in MATLAB and tell me the result.
```

If the baseline controller completes a lap, everything is working correctly.

---

## Troubleshooting

### Claude Desktop doesn't show MATLAB tools

- Confirm the config file is at the correct path
- Check for JSON syntax errors (use [jsonlint.com](https://jsonlint.com) to validate)
- Make sure MATLAB is open before starting Claude
- Try fully quitting (not just closing) Claude Desktop and restarting

### Python / MCP server errors

- Confirm your virtual environment is activated when running the install
- Check the MCP server's own `README.md` at [github.com/matlab/matlab-mcp-server](https://github.com/matlab/matlab-mcp-server) for the latest setup steps
- On Windows, ensure Python was added to PATH during installation

### MATLAB path errors

- Confirm `MATLAB_PATH` in the config points to the root of your MATLAB installation (the folder that contains `bin/`)
- On Windows: typically `C:\Program Files\MATLAB\R2024a`
- On Mac: typically `/Applications/MATLAB_R2024a.app`

### Permission errors on Windows (PowerShell)

If you see `cannot be loaded because running scripts is disabled`, run:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## Alternative Agents (Optional)

Claude Desktop is the recommended agent for this workshop. If you prefer:

- **Cursor IDE**: Use the config at `mcp/cursor_mcp.json`
- **Antigravity IDE (Gemini)**: Configure using the same MCP server — see your IDE's MCP settings panel
- **VS Code + Roo Code**: Add the MCP server via the Roo Code extension settings

Configuration examples for these alternatives are in the `mcp/` folder.

---

## Pre-Workshop Checklist

Before the workshop day, confirm:

- [ ] MATLAB R2024a+ opens without errors
- [ ] Python 3.11 or 3.12 installed and accessible from terminal
- [ ] `matlab-mcp-server` cloned and Python venv set up
- [ ] Claude Desktop installed and signed in
- [ ] `claude_desktop_config.json` updated with your paths
- [ ] `testMCP.m` runs successfully via Claude
- [ ] Workshop repo cloned
- [ ] `practiceRace` runs at least the baseline lap

If any step fails, bring your laptop — we'll sort it out on the day.
