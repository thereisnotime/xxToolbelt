#!/usr/bin/env ts-node
// Get all command-line arguments
const args = process.argv.slice(2);

// Print each argument
args.forEach(arg => {
    console.log(arg);
});
