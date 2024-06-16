# Golang Scripts

## Requirements

Pre-requisites:

- Golang

I recommend using [asdf](https://asdf-vm.com/guide/getting-started.html) to manage your Golang versions. You can install Golang with asdf via:

```bash
# Add Golang plugin and install Golang
asdf plugin add golang https://github.com/asdf-community/asdf-golang.git
asdf install golang latest
asdf global golang latest
# Add  . ~/.asdf/plugins/golang/set-env.zsh to your .zshrc or .bashrc file
```

## Examples

### xxtemplate-go.go

This script will print the arugments provided to it.
