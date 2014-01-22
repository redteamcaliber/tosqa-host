package main

import (
	"log"
	"os"

	"github.com/jcw/jeebus"
)

func main() {
	switch jeebus.SubCommand("tosqa") {

	case "reinitdb":
		reinitdb()

	default:
		log.Fatal("unknown sub-command: tosqa ", os.Args[1], " ...")
	}
}

func reinitdb() {
}
