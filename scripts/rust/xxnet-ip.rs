#!/usr/bin/env rust-script
//! ```cargo
//! [dependencies]
//! reqwest = { version = "0.12", features = ["json"] }
//! tokio = { version = "1", features = ["full"] }
//! ```

use std::collections::HashMap;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let resp = fetch_ip().await?;
    println!("{:#?}", resp);
    Ok(())
}

async fn fetch_ip() -> Result<HashMap<String, String>, reqwest::Error> {
    let response = reqwest::get("https://httpbin.org/ip").await?;
    let json = response.json::<HashMap<String, String>>().await?;
    Ok(json)
}
