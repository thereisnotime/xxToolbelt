#!/usr/bin/env rdmd
import std.stdio;
import std.getopt;

struct globalFlags
{
    string logLevel = "INFO";
    bool debugEnabled;
}

globalFlags gflags;

const progHelp = "./mycli get|set [OPTIONS]";

int subcmdSet(string[] args)
{
    string name;
    bool isAdmin;
    auto opts = getopt(
        args,
        std.getopt.config.required,  // To make --name or -n as required field
        "n|name", "Name", &name,
        "admin", "Set Admin privileges", &isAdmin
    );

    if (opts.helpWanted)
    {
        defaultGetoptPrinter("./mycli set -n <Name>", opts.options);
        return 1;
    }
    // Subcommand implementation
    writef("Set name as %s", name);
    if (isAdmin)
        write("(admin)");
    writeln();
    return 0;
}

int subcmdGet(string[] args)
{
    string name;
    auto opts = getopt(
        args,
        std.getopt.config.required,
        "n|name", "Name", &name
    );

    if (opts.helpWanted)
    {
        defaultGetoptPrinter("./mycli get --n <Name>", opts.options);
        return 1;
    }
    // Subcommand implementation
    writefln("Name is %s", name);
    return 0;
}


int main(string[] args)
{
    auto globalOpts = getopt(
        args,
        std.getopt.config.passThrough,
        "l|log-level", "Log Level", &gflags.logLevel,
        "debug", "Debug mode", &gflags.debugEnabled
    );

    if (args.length < 2)
    {
        if (!globalOpts.helpWanted)
            writeln("subcommand not specified");

        defaultGetoptPrinter(progHelp, globalOpts.options);
        return 1;
    }

    // -h is already parsed during Global options parsing. Reinsert to args
    // So that subcommands will work as usual
    if (globalOpts.helpWanted)
        args ~= "-h";

    auto subcmds = [
        "set": &subcmdSet,
        "get": &subcmdGet,
    ];

    auto func = (args[1] in subcmds);

    if (func is null)
    {
        writeln("Unknown sub-command");
        defaultGetoptPrinter(progHelp, globalOpts.options);
        return 1;
    }
    return (*func)(args);
}