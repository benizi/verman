# VerMan

Version Manager for multiple languages.

# Supported languages

* Node.JS
* Go
* Erlang
* Ruby

# Installation

PATH=verman/bin/ or source()'ed usage are both supported.

# Usage

## PATH usage (no shell integration)

Example for Erlang:

In .bash_profile or .zshenv:

```sh
export VERMAN_BIN=$HOME/git/verman
export VERMAN_ROOT=/opt
```

```sh
verman erlang install R16
verman erlang use --default R16
verman erlang use R16 erl -v
```
