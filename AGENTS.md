# AGENTS.md - Defold Poki AUDS Extension

## Build/Test
- **Defold project** – use Defold Editor (`Project > Build`) or `bob.jar` for CLI builds
- No automated tests; manual testing via `example/example.script`

## Architecture
- `poki_auds/auds.lua` – main Lua module exposing CRUD API for Poki AUDS
- `poki_auds/remote_config.editor_script` – Defold Editor script for managing remote config
- `example/` – sample project demonstrating usage
- Config lives in `game.project` under `[poki_auds]` section

## Code Style
- **Language**: Lua 5.1 (Defold runtime)
- **Module pattern**: return table `M` with public functions
- **Annotations**: use `---@class`, `---@param`, `---@return` (LuaCATS style)
- **Naming**: `snake_case` for functions/variables; constants as `UPPER_SNAKE_CASE`
- **Error handling**: validate args with `assert()`; async callbacks receive `(self, success, result, resp)`
- **No external deps** – only Defold built-ins (`http`, `json`, `sys`, `timer`)
- Keep secrets out of code; use `remote_config.secret` file (gitignored)
- **Paradigm**: do not use metatables or imitate classes. Use functional, data-based structures only.
- **Defensive checks**: Do NOT assume data is missing or constantly re-check field existence in tables. If YOU set a field, it EXISTS. Similarly, do NOT check for standard Lua API availability (e.g., `io` and `io.open` always exist in Defold Lua). Avoid unnecessary defensive programming.
- **Defold file formats**:
  - Lua / Defold scripts: `.lua`, `.script`, `.gui_script`, `.render_script`, `.editor_script`.
  - Metadata assets are Defold Protobuf: `.collection`, `.go`, `.sprite`, `.tilemap`, `.tilesource`, `.atlas`, `.font`, `.particlefx`, `.sound`, `.label`, `.gui`, `.model`, `.mesh`, `.material`, `.collisionobject`, `.texture_profiles`, `.display_profiles`, `.appmanifest`, `.manifest`.
  - Shaders: `.vp`, `.fp`, `.glsl` are GLSL shaders.
  - Configuration: `game.project` is INI file.
- **Whitespace**:
  - Empty lines must be truly empty (no spaces/tabs).
  - Avoid trailing whitespace.
- **Git commit messages**: use the format `Short description in a single sentence`, in English language ONLY.

## Local build / smoke-test via bob.jar

**Use the `defold-build` skill** for downloading bob.jar and running smoke test builds.

Requirements: Java 25+ (`java -version`)

Defold manual: `https://defold.com/manuals/bob/`

Quick reference (if bob.jar already downloaded):

```bash
java -jar .internal/bob.jar --platform x86_64-win32 --variant debug --archive build
```
