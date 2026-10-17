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
```

The template uses `#!/usr/bin/env node`, so whatever `node` is first on your PATH is used. If you want to pin a version in the shebang instead, link it somewhere stable and point the shebang there (on macOS `/usr/bin` is read-only, use `/usr/local/bin`):

```bash
sudo ln -s "$(asdf which node 22.2.0)" /usr/local/bin/node22
```

## Examples

### xxtemplate-node.js

This script will print the arugments provided to it.
