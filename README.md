# vfox-gcloud

Google Cloud SDK (gcloud CLI) plugin for [vfox](https://github.com/version-fox/vfox) and [mise](https://github.com/jdx/mise).

## Installation

### With mise

```bash
mise use -g vfox:gcloud@latest
```

### With vfox

```bash
vfox add gcloud
vfox install gcloud@latest
```

## Usage

### Install a specific version

```bash
# With mise
mise use gcloud@450.0.0

# With vfox
vfox install gcloud@450.0.0
```

### List available versions

```bash
# With mise
mise ls-remote gcloud

# With vfox
vfox search gcloud
```

### Windows Python archive

On Windows x86_64, the plugin uses Google's bundled-Python archive by default.
The interpreter remains private to gcloud and is not added to `PATH`. To use the
smaller unbundled archive instead, set the `bundled_python` tool option to
`"false"`:

```toml
[tools]
gcloud = { version = "latest", bundled_python = "false" }
```

Set `CLOUDSDK_PYTHON` to select the Python interpreter gcloud should use with
the unbundled archive. If it is unset, Google's installer may provision a
supported interpreter. This option only affects Windows x86_64 because other
platforms do not provide both archive variants.

### macOS Python

gcloud's installer wants one exact Python minor version (for example 3.14 for
gcloud 584.0.0), and on macOS it installs that Python system-wide with `sudo`
when it cannot find one. The password prompt is not visible during a mise
install, and macOS sudo prompts do not time out, so the install would hang.

The plugin looks for a matching interpreter — `CLOUDSDK_PYTHON`,
`/Library/Frameworks/Python.framework`, Homebrew, `/usr/local/bin`, then `PATH`
— and passes it to the installer as `CLOUDSDK_PYTHON`. If none is found, it
runs the installer with `--install-python false` and warns instead. gcloud still
works, but to get the virtual environment it sets up, install the version it
asks for (for example `brew install python@3.14` or `mise use -g python@3.14`)
or set `CLOUDSDK_PYTHON`, then reinstall gcloud.

## Post-Installation

After installation, you may need to initialize gcloud:

```bash
gcloud init
```

### Installing Additional Components

You can install additional SDK components:

```bash
gcloud components install kubectl
gcloud components install gke-gcloud-auth-plugin
gcloud components install cloud-sql-proxy
```

### Default Cloud SDK Components

You can define a set of Cloud SDK components to be installed automatically every
time a new gcloud version is installed. Create a file named
`.default-cloud-sdk-components` with one component ID per line.

The plugin searches for this file in the following locations (in order):

1. `$CLOUDSDK_CONFIG/.default-cloud-sdk-components` (defaults to `~/.config/gcloud/` on Unix or `%APPDATA%\gcloud\` on Windows)
2. `$HOME/.default-cloud-sdk-components`

Example `~/.default-cloud-sdk-components`:

```
alpha
beta
cloud-firestore-emulator
gke-gcloud-auth-plugin
```

## Supported Platforms

- Linux (x86_64, ARM)
- macOS (x86_64, ARM/Apple Silicon)
- Windows (x86_64)

## Environment Variables

This plugin sets the following environment variables:

| Variable | Description |
|----------|-------------|
| `PATH` | Includes the gcloud SDK bin directory |
| `CLOUDSDK_ROOT_DIR` | Points to the gcloud SDK installation directory |

## License

MIT
