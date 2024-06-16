#!/usr/bin/env rdmd
module print_args;

import std.stdio;

void main(string[] args)
{
    foreach (arg; args)
    {
        writeln(arg);
    }
}
