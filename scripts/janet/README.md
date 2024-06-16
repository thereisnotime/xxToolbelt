# Janet Scripts

## Requirements

Pre-requisites:

- Janet

I recommend using [asdf](https://asdf-vm.com/guide/getting-started.html) to manage your Janet versions. You can install Nodejs with asdf via:

```bash
# Install prerequisites
sudo apt-get install -y curl tar build-essential meson ninja-build
# Add Janet plugin and install Janet
asdf plugin add janet
asdf install janet latest
asdf global janet latest
```

## Examples

### xxtemplate-janet.janet

This script will print the arugments provided to it.
