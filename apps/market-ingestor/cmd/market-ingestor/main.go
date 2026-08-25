// ARCH-007 / ADR-0001: standalone Market Data process entrypoint
// (independent of trading-core merged wrapper).
package main

import (
	"github.com/Parsaeffatravesh/tragge/apps/market-ingestor/server"
)

func main() {
	server.Run()
}
