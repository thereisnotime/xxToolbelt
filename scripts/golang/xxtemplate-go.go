///usr/bin/true; exec /usr/bin/env go run "$0" "$@"
package main

import (
    "log"
    "os"
)
func main() {
    log.Println(os.Args)
}