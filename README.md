# install-energyplus

GitHub Action to install energyplus.

This is a composite action and it runs on your chosen runner.

## Inputs

- **`energyplus-version`** (required): EnergyPlus major.minor.patch version (e.g., `9.2.0`)
- **`energyplus-sha`** (required): EnergyPlus version SHA (e.g., `921312fa1d`)
- **`energyplus-tag`** (optional): EnergyPlus release tag. If not specified, defaults to `v{energyplus-version}`. Use this when the release tag differs from the standard format (e.g., `v24.2.0a` instead of `v24.2.0`)
- **`energyplus-platform`** (optional): Platform string for the installer filename (e.g., `Linux-Ubuntu22.04`, `Darwin-macOS12.1`). If not specified, automatically determined based on version, OS, and architecture. **Note:** EnergyPlus release asset naming is not fully consistent across versions, especially for macOS. It is recommended to set this explicitly for macOS, particularly on arm64. Auto-detection defaults:
  - **Linux**: `Linux` (≤9.3.0), `Linux-Ubuntu18.04` (9.4.0-23.1.0), `Linux-Ubuntu22.04` (≥23.2.0)
  - **macOS x86_64**: `Darwin` (≤9.3.0), `Darwin-macOS10.15` (9.4.0-23.1.0), `Darwin-macOS12.1` (≥23.2.0)
  - **macOS arm64**: `Darwin-macOS12.1` (≤23.2.0), `Darwin-macOS13` (≥24.1.0)
  - **Windows**: `Windows` (all versions)
- **`energyplus-arch`** (optional): Architecture string for the installer filename (e.g., `x86_64`, `arm64`). If not specified, automatically detected from system architecture using `uname -m`

## Usage

### Standard installation

```yaml
- uses: Elementa-Engineering/install-energyplus@main
  with:
    energyplus-version: 9.2.0
    energyplus-sha: 921312fa1d
```

### Installation with custom tag (e.g., for version 24.2.0 with tag v24.2.0a)

```yaml
- uses: Elementa-Engineering/install-energyplus@main
  with:
    energyplus-version: 24.2.0
    energyplus-sha: 94a887817b
    energyplus-tag: v24.2.0a
```

### Installation on macOS arm64

EnergyPlus asset naming varies across versions on macOS arm64. It is recommended to explicitly set the platform:

```yaml
- uses: Elementa-Engineering/install-energyplus@main
  with:
    energyplus-version: 22.1.0
    energyplus-sha: ed759b17ee
    energyplus-platform: Darwin-macOS12.1
    energyplus-arch: arm64
```

### Installation with custom platform override

If the auto-detected platform string doesn't match the actual installer filename, you can override it. Check the [EnergyPlus releases](https://github.com/NatLabRockies/EnergyPlus/releases) for exact asset names.

```yaml
- uses: Elementa-Engineering/install-energyplus@main
  with:
    energyplus-version: 23.2.0
    energyplus-sha: <appropriate-sha>
    energyplus-platform: Linux-Ubuntu20.04  # Override auto-detection
```
