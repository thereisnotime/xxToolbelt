#!/usr/bin/env rust-script

use std::env;

fn main() {
    let args: Vec<String> = env::args().collect();
    println!("{:?}", args);
}