---
name: defold-build
description: Downloads Defold bob.jar and runs smoke test builds. Use when asked to build, test build, or verify Defold project compiles.
---

# Defold Build Skill

Downloads the latest stable Defold bob.jar and runs smoke test builds.

## Requirements

- Java 25+ (`java -version` to verify)

## Workflow

### 1. Check Java Version

```bash
java -version
```

Ensure version 25 or higher.

### 2. Download bob.jar

Run the appropriate script for the platform:

**Windows (PowerShell):**
```powershell
scripts/download-bob.ps1
```

**Linux/macOS (Bash):**
```bash
scripts/download-bob.sh
```

### 3. Run Smoke Test Build

After bob.jar is downloaded, run:

```bash
java -jar .internal/bob.jar --platform x86_64-win32 --variant debug --archive build
```

#### Platform Options

| OS | Platform Flag |
|----|---------------|
| Windows 64-bit | `x86_64-win32` |
| macOS x64 | `x86_64-macos` |
| macOS ARM | `arm64-macos` |
| Linux 64-bit | `x86_64-linux` |
| HTML5 | `js-web` |
| Android | `armv7-android` or `arm64-android` |
| iOS | `arm64-ios` |

#### Variant Options

- `debug` - Debug build with symbols
- `release` - Optimized release build

## Full Example (Windows)

```powershell
# Download bob.jar if needed
& ".agents/skills/defold-build/scripts/download-bob.ps1"

# Run smoke test
java -jar .internal/bob.jar --platform x86_64-win32 --variant debug --archive build
```

## Full Example (Linux/macOS)

```bash
# Download bob.jar if needed
bash .agents/skills/defold-build/scripts/download-bob.sh

# Run smoke test
java -jar .internal/bob.jar --platform x86_64-linux --variant debug --archive build
```

## Troubleshooting

- **Java not found**: Install Java 25+ and ensure it's in PATH
- **Build fails**: Check output logs for errors
- **bob.jar corrupted**: Delete `.internal/bob.jar` and re-download
