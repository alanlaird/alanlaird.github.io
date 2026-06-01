#!/usr/bin/env sh
# aliases.sh — portable aliases based on installed tools
# Source from ~/.zshrc or ~/.bashrc:
#   source ~/path/to/aliases.sh

_has() { command -v "$1" >/dev/null 2>&1; }

# ── Modern CLI replacements ──────────────────────────────────────────────────
#if _has eza; then
#  alias ls='eza --icons'
#  alias ll='eza -lah --icons'
#  alias lt='eza --tree --icons --level=2'
#fi

if _has bat; then
  alias cat='bat'
  alias less='bat --paging=always'
fi

if _has rg; then
  alias grep='rg'
fi

if _has fd; then
  alias find='fd'
fi

if _has htop; then
  alias top='htop'
fi

if _has tldr; then
  alias man='tldr'
fi

# ── Git ──────────────────────────────────────────────────────────────────────
if _has git; then
  alias g='git'
  alias gs='git status'
  alias gd='git diff'
  alias gl='git log --oneline --graph --decorate'
  alias gp='git pull'
  alias gP='git push'
  alias gc='git commit'
  alias gco='git checkout'
  alias gb='git branch'
fi

if _has gh; then
  alias prs='gh pr list'
  alias issues='gh issue list'
fi

# ── Containers ───────────────────────────────────────────────────────────────
if _has podman; then
  alias docker='podman'
  alias pm='podman'
  alias pps='podman ps'
  alias ppa='podman ps -a'
  alias plog='podman logs -f'
fi

# ── Kubernetes ───────────────────────────────────────────────────────────────
if _has kubectl; then
  alias k='kubectl'
  alias kgp='kubectl get pods'
  alias kgs='kubectl get svc'
  alias kgn='kubectl get nodes'
  alias kdp='kubectl describe pod'
  alias klog='kubectl logs -f'
  alias kex='kubectl exec -it'
  alias kns='kubectl config set-context --current --namespace'
fi

if _has k9s; then
  alias k9='k9s'
fi

# ── OpenShift ────────────────────────────────────────────────────────────────
if _has oc; then
  alias ocp='oc'
  alias ocgp='oc get pods'
  alias oclog='oc logs -f'
  alias ocex='oc exec -it'
fi

# ── Cloud CLIs ───────────────────────────────────────────────────────────────
if _has gcloud; then
  alias gc-auth='gcloud auth application-default login'
  alias gc-proj='gcloud config set project'
fi

if _has aws; then
  alias aws-id='aws sts get-caller-identity'
fi

if _has aws-vault; then
  alias av='aws-vault exec'
fi

# ── IaC ──────────────────────────────────────────────────────────────────────
if _has tofu; then
  alias tf='tofu'
  alias tfi='tofu init'
  alias tfp='tofu plan'
  alias tfa='tofu apply'
  alias tfd='tofu destroy'
fi

# ── Python ───────────────────────────────────────────────────────────────────
if _has python3; then
  alias py='python3'
  alias pip='pip3'
  alias venv='python3 -m venv'
fi

# ── Utilities ────────────────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias q='exit'
alias c='clear'
alias path='echo $PATH | tr ":" "\n"'
alias reload='source ~/.zshrc 2>/dev/null || source ~/.bashrc'
alias myip='curl -s ifconfig.me'
alias ports='lsof -iTCP -sTCP:LISTEN -n -P'
