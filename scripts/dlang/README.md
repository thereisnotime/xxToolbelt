# Dlang Scripts

## Requirements

Pre-requisites:

- [Dlang](https://dlang.org/)

## Notes

- When you have "-" in the name of the script, make sure to use module declaration instead of pure script. For example:

```d
import std.stdio;

void main(string[] args)
{
    foreach (arg; args)
    {
        writeln(arg);
    }
}

```

Should be:

```d
module print_args;

import std.stdio;

void main(string[] args)
{
    foreach (arg; args)
    {
        writeln(arg);
    }
}
```

## Examples

### xxtemplate-d.d

This script will print the arugments provided to it.
