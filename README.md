# Verman

Version Manager for multiple languages.

# Disclaimers

- This code is garbage.
- It's written in Perl.
- Those two items are not correllated.

It's written in Perl, because `perl` is installed literally everywhere.  I may
rewrite it in Python, because that's also (nowadays) installed everywhere.

It's garbage, because I tried to be too "cute" with the execution model.

# Supported languages

## Working

I use these somewhat regularly, and Verman works for my purposes.

* Elixir
* Erlang
* Go
* Node.JS (`node`)
* Ruby

## Experimental

* GHC
* Haskell (intended to support the "Haskell Platform")
* Rust

# Installation

1. Link `bin/verman` into a directory in your $PATH, or add the `bin` directory
   directly (wherever you've checked it out) to your $PATH.

2. Write your own shell wrappers if you want shell integration.

[E.g. mine](https://github.com/benizi/dotfiles/blob/80847fd245a42c3bca31c09cc1c5e295d740a75c/.zsh/.zshenv#L187-L213):

(And, yes, you want shell integration.  It's basically required until I figure
out how I want to handle default versions.)
