# Contributing to xxToolbelt

Thanks for your interest in contributing to xxToolbelt! Everyone is welcome to contribute.

## Ways to Contribute

### Add Scripts

The easiest way to contribute is by adding useful scripts:

1. Fork the repository
2. Add your script to the appropriate language folder under `scripts/`
3. Make sure your script:
   - Starts with `xx` prefix (e.g., `xxmyscript.sh`)
   - Has a shebang line (e.g., `#!/usr/bin/env bash`)
   - Is executable (`chmod +x`)
   - Includes a brief description comment at the top
4. Submit a pull request

### Add Language Support

Want to add support for a new language?

1. Create a new folder under `scripts/` (e.g., `scripts/kotlin/`)
2. Add the file extension to `XXTOOLBELT_SCRIPTS_WHITELIST` in `xxtoolbelt.sh`
3. Add a sample script and README
4. Submit a pull request

### Create a Belt

Belts are external toolbelt repositories. You can:

1. Create your own belt repository following the belt structure
2. Share it with the community
3. Open an issue to have it listed in the documentation

### Report Issues

- Found a bug? Open an issue with steps to reproduce
- Have a feature idea? Open an issue to discuss it first

### Testing

Help us test on different environments:

- Different shells (bash, zsh, fish)
- Different terminals
- Different operating systems (Linux, macOS, BSD)
- Different architectures

## Development Setup

```bash
# Clone the repository
git clone git@github.com:thereisnotime/xxToolbelt.git ~/.xxtoolbelt

# Source the script
source ~/.xxtoolbelt/xxtoolbelt.sh

# Sync scripts
xxtb -s

# Enable debug mode for development
xxtb -d
```

## Code Style

- Use tabs for indentation in shell scripts
- Use descriptive variable names with `XXTOOLBELT_` prefix for globals
- Add comments for non-obvious code
- Keep functions focused and small

## Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes
4. Test your changes
5. Commit with a clear message
6. Push to your fork
7. Open a pull request

## Questions?

Open an issue if you have questions or need help getting started.
