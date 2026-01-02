# Hemlock Playground - Claude Guide

> Browser-based IDE for Hemlock with real-time LSP features and code execution

This document provides essential context for AI assistants working on the Hemlock Playground project.

## Project Overview

The Hemlock Playground is a web-based IDE that allows users to write, run, and debug Hemlock code directly in their browser. It consists of two main components:

1. **Grove** (Backend) - Hemlock server handling code execution and LSP bridging
2. **Playground** (Frontend) - Monaco-based editor with LSP integration

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Browser                                                        │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Playground (Monaco + monaco-languageclient)              │  │
│  └─────────────────┬────────────────────┬────────────────────┘  │
│                    │ WebSocket /lsp     │ HTTP POST /execute    │
└────────────────────┼────────────────────┼───────────────────────┘
                     │                    │
                     ▼                    ▼
┌─────────────────────────────────────────────────────────────────┐
│  Grove Server (runs on isolated VLAN)                           │
│  ┌─────────────────────────┐    ┌─────────────────────────────┐ │
│  │  WebSocket → TCP Bridge │    │  HTTP API                   │ │
│  │  /lsp                   │    │  /execute, /health          │ │
│  └───────────┬─────────────┘    └──────────────┬──────────────┘ │
│              │ TCP                             │ subprocess     │
│              ▼                                 ▼                │
│  ┌─────────────────────────┐    ┌─────────────────────────────┐ │
│  │  hemlock lsp --tcp 5007 │    │  hemlock --sandbox <file>   │ │
│  └─────────────────────────┘    └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
hemlang/playground/
├── CLAUDE.md           # This file - AI assistant guide
├── LICENSE             # MIT License
├── README.md           # User documentation (TODO)
├── package.json        # Hemlock package manifest
├── grove.hml           # Backend server (skeleton)
├── playground.html     # Frontend (Phase 1-2 complete)
├── examples/           # Example Hemlock programs
│   ├── hello.hml
│   ├── fibonacci.hml
│   ├── fizzbuzz.hml
│   ├── async.hml
│   └── json.hml
├── test/               # Test suite
│   └── test_examples.hml
└── .github/
    └── workflows/
        └── test.yml    # CI workflow
```

## Related Repositories

All repositories are under the `hemlang` organization:

| Repository | Description | Local Path |
|------------|-------------|------------|
| `hemlang/hemlock` | Interpreter, compiler, and LSP | `/home/user/hemlock` |
| `hemlang/hpm` | Package manager | `/home/user/hpm` |
| `hemlang/sprout` | Express-style web framework | `/home/user/sprout` |
| `hemlang/playground` | This project | `/home/user/playground` |

## Hemlock Language Quick Reference

### Key Syntax Rules

- **Semicolons required** - All statements end with `;`
- **Braces required** - No braceless if/while/for
- **Template strings** - Use backticks: `` `Hello ${name}` ``
- **print() takes 1 arg** - Use template strings for multiple values

### Common Patterns

```hemlock
// Variables
let x = 42;
let name = "Hemlock";

// Functions
fn add(a, b) {
    return a + b;
}

// Control flow
if (x > 0) {
    print("positive");
} else {
    print("non-positive");
}

// Loops
for (let i = 0; i < 10; i = i + 1) {
    print(i);
}

for (item in array) {
    print(item);
}

// Objects
let obj = { name: "test", value: 123 };
print(obj["name"]);  // Use bracket notation for safety

// Async
async fn fetch() {
    return "data";
}
let task = spawn(fetch);
let result = await task;
```

### Running Hemlock

```bash
# Run a file
hemlock script.hml

# Run with sandbox (restricted permissions)
hemlock --sandbox script.hml

# Start LSP server (stdio)
hemlock lsp --stdio

# Start LSP server (TCP)
hemlock lsp --tcp 5007

# Check version
hemlock --version
```

## Implementation Phases

### Phase 1: Basic Execution ✓
- [x] Grove skeleton with `/execute` endpoint design
- [x] HTML frontend with textarea + run button
- [x] Example programs

### Phase 2: Monaco Editor (In Progress)
- [x] Basic playground.html with Tokyo Night theme
- [ ] Replace textarea with Monaco Editor
- [ ] Add Hemlock syntax highlighting (Monarch grammar)

### Phase 3: LSP Integration
- [ ] Add WebSocket `/lsp` endpoint to Grove
- [ ] Implement WS ↔ TCP bridge with framing translation
- [ ] Start `hemlock lsp --tcp 5007` as companion process
- [ ] Wire up monaco-languageclient
- [ ] Verify diagnostics, hover, completion

### Phase 4: Polish
- [ ] Example snippets dropdown improvements
- [ ] UI/UX improvements
- [ ] Better error handling
- [ ] Rate limiting

## LSP Bridge Details

The LSP uses different framing over different transports:

- **TCP** (to hemlock lsp): `Content-Length: N\r\n\r\n<JSON payload>`
- **WebSocket** (to browser): Raw JSON-RPC messages (no headers)

Grove must translate between these:
- WS→TCP: Add `Content-Length` framing
- TCP→WS: Strip `Content-Length` framing

## API Endpoints

### POST /execute

```json
// Request
{ "code": "print(\"hello\");" }

// Response
{
    "success": true,
    "stdout": "hello\n",
    "stderr": "",
    "exit_code": 0,
    "execution_time_ms": 42,
    "timed_out": false,
    "truncated": false
}
```

### GET /health

```json
{ "status": "ok", "hemlock_version": "1.6.4" }
```

### GET /version

```json
{
    "api_version": "1.0.0",
    "hemlock_version": "1.6.4",
    "max_execution_time": 10,
    "max_output_size": 65536
}
```

### WebSocket /lsp

Raw JSON-RPC 2.0 messages following the LSP specification.

## Configuration

Grove accepts environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `GROVE_PORT` | 8080 | HTTP/WebSocket server port |
| `GROVE_LSP_PORT` | 5007 | Port for hemlock LSP (TCP) |
| `HEMLOCK_PATH` | hemlock | Path to hemlock binary |

## Security Model

Grove runs on an **isolated VLAN** - network isolation is the primary sandbox.

Built-in protections:
- `--sandbox` flag restricts dangerous operations
- Execution timeout (kill after N seconds)
- Output truncation (max 64KB)
- Code size limits (max 100KB)
- Temp file cleanup after each execution

## Testing

Run tests with:

```bash
# From hemlock directory
hemlock /path/to/playground/test/test_examples.hml

# Or use hpm
hpm test
```

## Dependencies

### Runtime
- Hemlock interpreter (v1.6.4+)
- libwebsockets (for std/http WebSocket support)

### Development
- hpm (Hemlock package manager)
- Git

## Known Issues

1. **libwebsockets not installed** - std/http module unavailable without it
2. **hpm network calls fail** - Cannot install packages via hpm without HTTP support
3. **Sandbox restrictions** - Some stdlib functions unavailable in sandbox mode

## Development Tips

1. **Test examples locally first**:
   ```bash
   hemlock --sandbox examples/hello.hml
   ```

2. **Use template strings for output**:
   ```hemlock
   print(`Value: ${x}`);  // Good
   print("Value: " + x);  // Also works but less readable
   ```

3. **Bracket notation for object access**:
   ```hemlock
   obj["field"]  // Returns null if missing
   obj.field     // Throws if missing
   ```

4. **Check LSP with TCP transport**:
   ```bash
   hemlock lsp --tcp 5007 &
   # Then connect with netcat or a TCP client
   ```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes with tests
4. Run `hpm test` to verify
5. Submit a pull request

## Resources

- [Hemlock CLAUDE.md](/home/user/hemlock/CLAUDE.md) - Language reference
- [Hemlock Docs](/home/user/hemlock/docs/) - Full documentation
- [Sprout CLAUDE.md](/home/user/sprout/CLAUDE.md) - Web framework guide
- [hpm README](/home/user/hpm/README.md) - Package manager docs
