# CSharp Scripts

CSharp has been "scriptivized" via [dotnet-script](https://github.com/dotnet-script/dotnet-script).

## Requirements

Pre-requisites:

- .NET for CSharp
- dotnet-script

I recommend using [asdf](https://asdf-vm.com/guide/getting-started.html) to manage your .NET versions. You can install CSharp with asdf via:

```bash
# Add dotnet plugin and install dotnet
asdf plugin add dotnet
asdf install dotnet latest
asdf global dotnet latest
# Add dotnet-script plugin and install dotnet-script
dotnet tool install --global dotnet-script --version 1.5.0
# I suggest adding DOTNET_CLI_TELEMETRY_OPTOUT=1 to your .bashrc or .zshrc file

```

## Examples

### xxtemplate-csharp.cs
