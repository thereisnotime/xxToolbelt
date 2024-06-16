# Rust Scripts

Rust has been "scriptivized" via [rust-script](https://rust-script.org/).

## Requirements

Pre-requisites:

- Rust + Cargo
- rust-script
- all dependencies of the scripts

```bash
sudo apt-get intall -y cargo
cargo install rust-script
```

## Dependencies

To include dependencies in the script, take a look at `xxnet-ip` for an example.

## Examples

### xxnet-ip.rs

This script will do a GET request to fetch the current machine's external IP and print it.

Pre-requisites (in this folder):

```bash
sudo apt-get install -y libssl-dev
cargo init
cargo add reqwest
cargo add tokio
```

### xxtemplate-rust.rs

This script will print the arugments provided to it.
