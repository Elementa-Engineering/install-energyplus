# install-energyplus

GitHub Action to install energyplus.

This is a composite action and it runs on your chosen runner.

## Inputs

- **`energyplus-version`** (required): EnergyPlus major.minor.patch version (default: `9.2.0`)
- **`energyplus-sha`** (required): EnergyPlus version SHA (default: `921312fa1d`)
- **`energyplus-install`** (required): EnergyPlus major-minor-patch version (default: `9-2-0`)
- **`energyplus-tag`** (optional): EnergyPlus release tag. If not specified, defaults to `v{energyplus-version}`. Use this when the release tag differs from the standard format (e.g., `v24.2.0a` instead of `v24.2.0`)

## Usage

### Standard installation

```yaml
- uses: Elementa-Engineering/install-energyplus@main
  with:
    energyplus-version: 9.2.0
    energyplus-sha: 921312fa1d
    energyplus-install: 9-2-0
```

### Installation with custom tag (e.g., for version 24.2.0 with tag v24.2.0a)

```yaml
- uses: Elementa-Engineering/install-energyplus@main
  with:
    energyplus-version: 24.2.0
    energyplus-sha: <appropriate-sha>
    energyplus-install: 24-2-0
    energyplus-tag: v24.2.0a
```

