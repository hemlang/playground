# Browser execution mode (Hemlock WASM)

This directory holds the assets that let `playground.html` run Hemlock code
entirely in the browser, with no Grove server. When the toolbar toggle is set
to **⬡ Browser**, the playground loads these files and executes code through the
Hemlock interpreter compiled to WebAssembly.

## Files

| File | Source | Committed? |
|------|--------|------------|
| `hemlock-api.js` | A clean JS wrapper around the WASM interpreter (`Hemlock.init`, `.eval`, contexts). Vendored from `hemlang/hemlock`. | ✅ yes |
| `pre.js` | Emscripten pre-init shim (sets up the `Module` global). Vendored from `hemlang/hemlock`. | ✅ yes |
| `hemlock.js` | Emscripten loader glue. **Generated** by `make wasm-interpreter`. | ✅ committed for convenience |
| `hemlock.wasm` | The interpreter compiled to WebAssembly (~3 MB). **Generated**. | ✅ committed for convenience |

## Regenerating the artifacts

From the playground root:

```bash
./build-wasm.sh
```

This needs the [Emscripten SDK](https://emscripten.org/docs/getting_started/downloads.html)
(`emcc` on `PATH`). It will clone `hemlang/hemlock` if it isn't already next to
this repo, run `make wasm-interpreter`, and copy the four files above into here.

## How the playground uses these

`playground.html` configures an Emscripten `Module` with:

- `locateFile` pointing back at this directory (the HTML lives one level up, so
  Emscripten would otherwise look for `hemlock.wasm` at the site root),
- `print` / `printErr` handlers that capture interpreter output, and
- initialization deferred to `onRuntimeInitialized` so the JS API only binds
  once the wasm exports are live.

It then calls `Hemlock.init({ Module })` and runs source via `hemlock.eval(...)`.

## Limitations in the browser

The WASM interpreter is single-threaded and sandboxed by the browser, so some
features are unavailable: FFI, OpenSSL crypto, `fork`/`exec`, and threading
(`spawn`/channels). `Check` and `Format` in the playground are server-backed and
are disabled in browser mode.
