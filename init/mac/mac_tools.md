# Mac Dev Setup

> **Fresh Mac one-liner** (installs Homebrew, clones the repo to `~/alanlaird.github.io`, runs setup):
> ```sh
> bash -c "$(curl -fsSL https://alan.laird.net/init/mac/bootstrap.sh)"
> ```
> Override the clone location with `INIT_DIR=/some/path bash -c "$(curl ...)"`.
>
> **Already have the repo?** Run `init/mac/setup.sh` from the repo root.
> **Just brew packages?** `brew bundle --file=init/mac/Brewfile`.

---

# brew

## AI CLIs
```text
brew install --cask claude-code      # Claude CLI (Anthropic)
brew install --cask gemini           # Gemini CLI (Google)
brew install --cask cursor           # Cursor AI code editor (includes CLI — enable via Cursor > Install 'cursor' command)
```

## Casks (GUI apps)
```
brew install --cask iterm2           # feature-rich terminal emulator
brew install --cask ghostty          # modern GPU-accelerated terminal
brew install --cask tableplus        # database GUI
```

## CLI tools
```
brew install git
brew install gh                      # GitHub CLI
brew install ripgrep                 # fast grep (rg)
brew install fd                      # fast find
brew install bat                     # cat with syntax highlighting
brew install eza                     # modern ls with colors/icons
brew install fzf                     # fuzzy finder
brew install jq                      # JSON processor
brew install yq                      # YAML processor
brew install htop                    # interactive process viewer
brew install ncdu                    # disk usage analyzer
brew install tldr                    # simplified man pages
brew install mise                    # dev tool version manager (node, python, ruby, etc.)
brew install httpie                  # user-friendly HTTP client
brew install mkcert                  # local HTTPS certificates
```
---

# Ghostty

Ghostty config lives at `~/.config/ghostty/config`. A starter config is provided at `tools/mac/ghostty.config` — copy it into place:

```sh
mkdir -p ~/.config/ghostty
cp tools/mac/ghostty.config ~/.config/ghostty/config
```

Key settings to customize:
- `font-family` — set to your chosen Nerd Font (see Fonts section below)
- `theme` — Ghostty ships with many built-in themes; run `ghostty +list-themes` to browse
- `background-opacity` — adjust to taste, pairs well with `background-blur-radius`

---

# Shell: pure zsh + brew-managed plugins

macOS ships with zsh as the default shell. Instead of running a framework like oh-my-zsh, this setup uses a small tracked `~/.zshrc` (symlinked from `tools/mac/zshrc`) that sources brew-installed plugins directly. Startup is ~50ms vs ~300ms with omz, and the config is fully visible and version-controlled.

`setup.sh` handles install + symlinks. The sections below explain what the resulting setup does and how to customize it.

## Plugins (all from brew)

| Plugin | Purpose |
|---|---|
| `zsh-autosuggestions` | suggests commands as you type based on history |
| `zsh-syntax-highlighting` | colors valid commands green, invalid red (must source last) |
| `zoxide` | `z <dir>` jumps to frecent directories; `zi` for interactive fzf picker |
| `fzf` | `Ctrl+R` fuzzy history, `Ctrl+T` file picker, `Alt+C` cd |
| `powerlevel10k` | fast informative prompt |

The load order in `zshrc` matters — `zsh-syntax-highlighting` **must** come after everything else, or it won't highlight other plugins' widgets.

## Prompt theme: Powerlevel10k

Already sourced by `zshrc`. After the first install, run:

```sh
p10k configure
```

This writes `~/.p10k.zsh`, which `zshrc` sources if present. Keep `~/.p10k.zsh` outside the repo unless you want the same prompt on every machine.

## Machine-specific overrides

`zshrc` sources `~/.zshrc.local` at the end if it exists. Put per-machine env vars, secrets, or work-laptop-only config there — it's not tracked in git.

```sh
# example ~/.zshrc.local
export GITHUB_TOKEN=ghp_xxx
export AWS_PROFILE=work
```

## Migrating from oh-my-zsh on an existing mac

If you ran the old setup.sh on this machine before, clean up before re-running:

```sh
# back up existing zshrc, then re-run setup.sh to symlink the new one
mv ~/.zshrc ~/.zshrc.omz-backup

# optional: nuke omz entirely (the new zshrc doesn't reference it)
uninstall_oh_my_zsh   # provided by the omz install
# or just: rm -rf ~/.oh-my-zsh

./setup.sh
```

The `.omz-backup` is worth keeping for a day or two in case you had local customizations to lift over into `~/.zshrc.local`.

## Fonts

Powerlevel10k and most omz themes require a **Nerd Font** to render glyphs, arrows, and icons correctly. After installing, set the font in your terminal's preferences.

| Font | Notes |
|---|---|
| `font-meslo-lg-nerd-font` | Default recommendation from p10k setup wizard |
| `font-jetbrains-mono-nerd-font` | Clean, modern, popular for dev |
| `font-fira-code-nerd-font` | Ligatures (`->`, `=>`, `!=`), highly readable |
| `font-hack-nerd-font` | Minimal and crisp at small sizes |
| `font-caskaydia-cove-nerd-font` | Cascadia Code patched by Nerd Fonts, ligatures |

```sh
# install all at once (all are in the Brewfile)
brew install --cask font-meslo-lg-nerd-font font-jetbrains-mono-nerd-font \
  font-fira-code-nerd-font font-hack-nerd-font font-caskaydia-cove-nerd-font
```

Set your chosen font in **iTerm2**: Preferences → Profiles → Text → Font  
Set your chosen font in **Ghostty**: add `font-family = "JetBrainsMono Nerd Font"` to `~/.config/ghostty/config`

## Aliases

Aliases live in `tools/mac/aliases.sh` and are symlinked to `~/.aliases.sh` by `setup.sh`. The new `zshrc` sources `~/.aliases.sh` automatically. Each alias only activates if the tool is installed, so the file is safe to source on any machine.

Covers: modern CLI replacements (`eza`, `bat`, `rg`, `fd`), git shortcuts, podman/docker, kubectl, oc, cloud CLIs, tofu, python, and general navigation.

---

# Python

## Global venv at `~/venv`

A single venv at `~` provides a clean, user-level Python environment for global tools (pip installs stay out of the system Python). Project directories can override it with `direnv`.

```sh
python3 -m venv ~/venv
```

Add to `~/.zshrc` to activate on every shell:

```sh
[ -f ~/venv/bin/activate ] && source ~/venv/bin/activate
```

## Per-project overrides with direnv

`direnv` watches for a `.envrc` file when you `cd` into a directory and automatically activates it, overriding the global venv.

```sh
brew install direnv
```

Add the hook to `~/.zshrc`:

```sh
eval "$(direnv hook zsh)"
```

In a project directory:

```sh
python3 -m venv .venv
echo 'source .venv/bin/activate' > .envrc
direnv allow
```

Now the project venv activates automatically when you enter the directory and deactivates when you leave — no manual `source` needed.

---

# Cloud Tools

## Google Cloud Platform (GCP)

```sh
brew install --cask gcloud-cli  # gcloud, gsutil, bq
```

After install:

```sh
gcloud init
gcloud auth application-default login
```

Useful components:

```sh
gcloud components install gke-gcloud-auth-plugin  # kubectl auth for GKE
gcloud components install cloud-sql-proxy          # local proxy to Cloud SQL
```

## Amazon Web Services (AWS)

```sh
brew install awscli          # AWS CLI v2
brew install aws-vault       # secure credential storage per profile
brew install aws-sam-cli     # local Lambda/SAM development
```

Configure credentials:

```sh
aws configure --profile myprofile
aws-vault add myprofile      # stores creds in macOS Keychain
aws-vault exec myprofile -- aws s3 ls
```

## OpenShift (OCP)

```sh
brew install openshift-cli   # oc CLI (superset of kubectl)
```

Login and context switching:

```sh
oc login https://api.cluster.example.com:6443 --token=<token>
oc project my-namespace
oc get pods
```

## Kubernetes (shared across providers)

```sh
brew install kubectl         # Kubernetes CLI
brew install kubectx         # fast context/namespace switching (kubectx, kubens)
brew install k9s             # terminal UI for cluster management
brew install helm            # package manager for Kubernetes
brew install kustomize       # Kubernetes config overlay tool
brew install stern           # multi-pod log tailing
```

## Terraform / Infrastructure as Code

```sh
brew install opentofu                 # open source Terraform fork (MPL 2.0, Linux Foundation) — use `tofu` command
brew install terragrunt      # thin wrapper for DRY Terraform configs
brew install tflint          # Terraform linter
```

## FedRAMP / Government Cloud Notes

| Provider | FedRAMP Product | CLI Tool |
|---|---|---|
| AWS | AWS GovCloud (US) | `awscli` with `--region us-gov-west-1` |
| GCP | Google Cloud for Government | `gcloud` with Assured Workloads org policy |
| Azure | Azure Government | `brew install azure-cli` → `az cloud set --name AzureUSGovernment` |
| Red Hat | OpenShift on GovCloud | `oc` CLI (above) |

For CAC/PIV smart card auth (common in government environments):

```sh
brew install --cask opensc-app    # smart card middleware
brew install --cask keybase   # optional: GPG key management
```

---

# Containers: Podman

Podman is the recommended container runtime for government and contractor environments. It is fully open source (Apache 2.0), developed by Red Hat, and has no telemetry or licensing restrictions. Its daemonless, rootless architecture aligns with least-privilege principles required by FedRAMP and RMF (Risk Management Framework) security controls — particularly AC-6 (Least Privilege) and CM-7 (Least Functionality). It is a drop-in OCI-compatible replacement for Docker and integrates natively with OpenShift and other Red Hat platforms common in government stacks.

## Install

```sh
brew install podman
brew install --cask podman-desktop  # optional GUI for managing containers and volumes
```

## First-time setup

Podman on Mac runs containers inside a lightweight Linux VM. Initialize and start it after install:

```sh
podman machine init
podman machine start
```

Podman Desktop can manage the machine lifecycle automatically — enable **Launch at Login** in its preferences to keep it available without manual intervention.

> **Note:** On Apple Silicon, `podman machine init` will install Rosetta 2 inside the Linux VM. This is expected — Podman uses it to run x86_64 container images on ARM hardware, which is faster than QEMU emulation. It does not affect your Mac host.

## Verify

```sh
podman run hello-world
```

## Optional: alias docker to podman

If your workflow or scripts use `docker` commands, Podman is compatible enough to alias:

```sh
echo 'alias docker=podman' >> ~/.zshrc
```
