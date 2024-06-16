# Ruby Scripts

## Requirements

Pre-requisites:

- Ruby

## Setup

I recommend using [asdf](https://asdf-vm.com/guide/getting-started.html) to manage your Ruby versions. You can install Ruby with asdf via:

```bash
# Install dependencies
sudo apt-get install git-core zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev
# Add Ruby plugin and install Ruby
asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
asdf install ruby 3.3.3
asdf global ruby 3.3.3
```

Now you can run your Ruby scripts.

## Examples

### xxtemplate-rb.rb

This script will print the arguments provided to it.
