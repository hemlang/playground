# Hemlock Playground

A browser-based IDE for writing, running, and debugging Hemlock code.

## Quick Start

```bash
# Start the server
hemlock grove.hml

# Open http://localhost:8080 in your browser
```

## Features

- **Code Editor** - Syntax-highlighted textarea with tab support
- **Code Execution** - Run Hemlock code in a sandboxed environment
- **Example Programs** - Pre-built examples (Hello World, Fibonacci, FizzBuzz, Async, JSON)
- **Real-time Feedback** - Execution time, exit codes, and error messages

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Browser                                                    │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Playground (HTML + JavaScript)                       │  │
│  └─────────────────────────────────────────────────────┬─┘  │
│                                          HTTP POST /execute │
└──────────────────────────────────────────────────────────┼──┘
                                                           │
                                                           ▼
┌─────────────────────────────────────────────────────────────┐
│  Grove Server (grove.hml)                                   │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  HTTP API: /, /health, /version, /execute              ││
│  └─────────────────────────────────────────────────────────┘│
│                           │                                 │
│                           ▼                                 │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  hemlock --sandbox <temp_file>                         ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## API Endpoints

### `GET /`
Serves the playground HTML interface.

### `GET /health`
```json
{ "status": "ok", "hemlock_version": "1.6.4" }
```

### `GET /version`
```json
{
  "api_version": "1.0.0",
  "hemlock_version": "1.6.4",
  "max_execution_time": 10,
  "max_output_size": 65536
}
```

### `POST /execute`
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

## Configuration

Environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `GROVE_PORT` | 8080 | Server port |
| `HEMLOCK_PATH` | hemlock | Path to hemlock binary |

## Security

Code execution uses Hemlock's `--sandbox` mode which restricts:
- File system access
- Network operations
- System calls

Additional protections:
- 10 second execution timeout
- 64KB output limit
- 100KB code size limit

## Development

```bash
# Run examples locally
hemlock examples/hello.hml
hemlock examples/fibonacci.hml

# Run tests
hemlock test/test_examples.hml
```

## Project Structure

```
playground/
├── grove.hml           # Backend HTTP server
├── playground.html     # Frontend IDE
├── examples/           # Example programs
│   ├── hello.hml
│   ├── fibonacci.hml
│   ├── fizzbuzz.hml
│   ├── async.hml
│   └── json.hml
├── test/
│   └── test_examples.hml
└── package.json
```

## License

MIT
