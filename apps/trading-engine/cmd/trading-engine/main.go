// ENG-001: standalone Trading Engine process entrypoint (independent of trading-core).
package main

import (
	"github.com/Parsaeffatravesh/tragge/apps/trading-engine/server"
)

func main() {
	server.Run()
}
