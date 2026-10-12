export PATH="$PATH:$HOME/.local/bin/"

export ZSH_CACHE_DIR="$HOME/.cache/zsh"
mkdir -p "$ZSH_CACHE_DIR/completions"

source ~/antigen.zsh

antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle git
antigen bundle command-not-found

# plugins
antigen bundle mskadu/zsh-opencode-plugin@main
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