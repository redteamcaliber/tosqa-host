package main

import (
	"log"
	"os"

	"github.com/jcw/jeebus"
)

func main() {
	if len(os.Args) <= 1 {
		log.Fatalf("usage: tosqa-host <cmd> ... (try 'tosqa-host run')")
	}

	switch os.Args[1] {

	case "reinitdb":
		reinitdb()

	case "see":
		topics := "#"
		if len(os.Args) > 2 {
			topics = os.Args[2]
		}
		for m := range jeebus.ConnectToServer(topics) {
			log.Println(m.T, string(m.P.([]byte)), m.R)
		}

	default:
		log.Fatal("unknown sub-command: tosqa ", os.Args[1], " ...")
	}
}

func reinitdb() {
}
