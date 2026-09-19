# MCP — Model Context Protocol for MATLAB

This folder contains configuration files for connecting an AI agent to MATLAB via the Model Context Protocol (MCP).

---

## What is MCP?

MCP is an open standard that allows AI applications (like Claude Desktop) to use **tools** — actions the agent can call to interact with external software.

Without MCP, an AI agent can only read and write text. With MCP + the MATLAB server, the agent can:

- **Read** files in your project
- **Write** MATLAB code to `controller.m`
- **Run** MATLAB scripts and functions
- **Read back** console output and results

This is the difference between an AI that *suggests* code you have to paste, and an AI that *actually runs* and *tests* the code itself.

---

## How It Works

```
You (student)
    │
    │  "Improve the corner speed in my controller"
    ▼
Claude Desktop
    │
    │  [tool call: read_file("student/controller.m")]
    │  [tool call: run_matlab("practiceRace")]
    │  [tool call: write_file("student/controller.m", improved_code)]
    │  [tool call: run_matlab("practiceRace")]   ← tests the change!
    ▼
MATLAB MCP Server
    │
    ├── Reads files from your project folder
    ├── Runs MATLAB scripts
    └── Returns output back to Claude
    │
    ▼
MATLAB (running on your machine)
```

---

## Configuration Files

| File | Use for |
|---|---|
| `claude_desktop_config.json` | Claude Desktop (recommended) |
| `cursor_mcp.json` | Cursor IDE |
| `test_mcp.m` | Verify the connection works |

---

## Setup Instructions

See [SETUP.md](../SETUP.md) for the complete setup guide.

---

## Security Note

The MCP server gives the AI agent the ability to **execute code on your machine**. This is intentional — it's the whole point.

For this workshop:
- The agent can read and write files in the project folder
- The agent can run MATLAB scripts
- The agent **should not** be given access to credentials, sensitive files, or system administration tools

Always review what the agent is doing when it uses tools. Claude Desktop shows you each tool call before or as it executes.
