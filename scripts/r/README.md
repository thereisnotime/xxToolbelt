# R Scripts

## Requirements

Pre-requisites:

- R + Rscript

I recommend using [asdf](https://asdf-vm.com/guide/getting-started.html) to manage your R versions. You can install R with asdf via:

```bash
# Pre-requisites
sudo apt-get install build-essential libcurl3-dev libreadline-dev gfortran
sudo apt-get install liblzma-dev liblzma5 libbz2-1.0 libbz2-dev
sudo apt-get install xorg-dev libbz2-dev liblzma-dev libpcre2-dev
# Add R plugin and install R
asdf plugin-add r https://github.com/asdf-community/asdf-r.git
asdf install r latest
asdf global r latest
```

## Examples

### xxtemplate-r.r

This script will print the arugments provided to it.
