# Nodejs Scripts

## Requirements

Pre-requisites:

- Nodejs

I recommend using [asdf](https://asdf-vm.com/guide/getting-started.html) to manage your Nodejs versions. You can install Nodejs with asdf via:

```bash
# Add Nodejs plugin and install Nodejs
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf install nodejs 22.2.0
asdf global nodejs 22.2.0
# You can link to a specific version just for the scripts in the shebang or use the global version like this
sudo ln -s $(asdf which node 22.2.0) /usr/bin/node
```

## Examples

### xxtemplate-node.js

This script will print the arugments provided to it.
