export PATH="$PATH:$HOME/.local/bin/"
export PATH="$HOME/.opencode/bin:$PATH"

export ZSH_CACHE_DIR="$HOME/.cache/zsh"
mkdir -p "$ZSH_CACHE_DIR/completions"

source ~/antigen.zsh

antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle git
antigen bundle command-not-found

# plugins
antigen bundle andreacasarin/zsh-ask-opencode@main

# Syntax highlighting bundle.
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-completions

# antigen theme reobin/typewritten
antigen bundle reobin/typewritten@main

export TYPEWRITTEN_PROMPT_LAYOUT="singleline_verbose"
export TYPEWRITTEN_SYMBOL="$"
export TYPEWRITTEN_COLOR_MAPPINGS="primary:cyan;info_neutral_1:white"
export TYPEWRITTEN_RELATIVE_PATH="adaptive"
export TYPEWRITTEN_CURSOR="beam"
export TYPEWRITTEN_DISABLE_RETURN_CODE="true"

antigen apply

# OpenCode V2 completions. The mskadu antigen plugin calls the removed
# `opencode completion zsh` subcommand, which errors on every new shell.
_opencode_bin="${commands[opencode]:-$HOME/.opencode/bin/opencode}"
if [[ -x "${_opencode_bin}" ]]; then
    _opencode_cache="${ZSH_CACHE_DIR}/completions/_opencode"
    if [[ ! -s "${_opencode_cache}" ]] \
        || [[ "$(head -n 1 "${_opencode_cache}" 2>/dev/null)" != '#compdef opencode' ]] \
        || [[ "${_opencode_bin}" -nt "${_opencode_cache}" ]]; then
        "${_opencode_bin}" --completions zsh >| "${_opencode_cache}"
    fi
    fpath=("${ZSH_CACHE_DIR}/completions" ${fpath})
    autoload -Uz _opencode
    if (( $+functions[compdef] )); then
        compdef _opencode opencode
    fi
fi
unset _opencode_bin _opencode_cache

alias oc='opencode'
