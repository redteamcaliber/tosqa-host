// Tosqa: process config, env vars, cmdline args, then start up as needed.
package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/jcw/flow"
	_ "github.com/jcw/jeebus/gadgets"
	_ "github.com/tosqa/tosqa-host/gadgets"
)

var (
	config   = flag.String("c", "./config.txt", "name of configuration file to use")
	describe = flag.Bool("d", false, "describe the main circuit used as Tosqa server")
)

// these defaults can be overridden via a file or with environment variables
const defaults = `
# do not change, as the following defaults are hard-coded in devmode.coffee
# use a "./config.txt" file to override these, or use environment variables
APP_DIR     = ./app
BASE_DIR    = ./base
GADGETS_DIR = ./gadgets
# the following defaults can be whatever is convenient for this application
DATA_DIR    = ./data
HTTP_PORT   = :3333
MQTT_PORT   = :1883
SETUP_FILE  = ./setup.json
`

func main() {
	flag.Parse() // required, to set up the proper glog configuration
	flow.LoadConfig(defaults, *config)
	flow.DontPanic()

	// register more definitions from a JSON-formatted setup file, if specified
	if s := flow.Config["SETUP_FILE"]; s != "" {
		if err := flow.AddToRegistry(s); err != nil {
			panic(err)
		}
	}

	// if a registered circuit name is given on the command line, run it
	if flag.NArg() > 0 {
		if factory, ok := flow.Registry[flag.Arg(0)]; ok {
			c := factory()
			if *describe {
				flow.PrintDescription(c)
				return
			}
			c.Run()
			return
		}
		fmt.Fprintln(os.Stderr, "Unknown command:", flag.Arg(0))
		os.Exit(1)
	}

	fmt.Printf("Starting webserver for http://%s/\n", flow.Config["HTTP_PORT"])

	// normal startup: save config info in database and start the webserver
	c := flow.NewCircuit()

	// database setup, save current config settings, register init gadget
	c.Add("db", "LevelDB")
	c.Feed("db.In", flow.Tag{"<clear>", "/config/"})
	c.Feed("db.In", flow.Tag{"/config/appName", "Tosqa"})
	c.Feed("db.In", flow.Tag{"/config/configFile", *config})
	for k, v := range flow.Config {
		c.Feed("db.In", flow.Tag{"/config/" + k, v})
	}
	c.Feed("db.In", flow.Tag{"<register>", "/gadget/init"})

	// wait for db to finish, then dispatch to the "init" gadget, if found
	c.Add("wait", "Waiter")
	c.Add("disp", "Dispatcher")
	c.Connect("db.Out", "wait.Gate", 0)
	c.Connect("wait.Out", "disp.In", 0)
	c.Feed("wait.In", flow.Tag{"<dispatch>", "init"})

	// webserver setup
	c.Add("http", "HTTPServer")
	c.Feed("http.Handlers", flow.Tag{"/", flow.Config["APP_DIR"]})
	c.Feed("http.Handlers", flow.Tag{"/base/", flow.Config["BASE_DIR"]})
	c.Feed("http.Handlers", flow.Tag{"/ws", "<websocket>"})

	// start the ball rolling, keep running forever
	c.Add("forever", "Forever")

	if *describe {
		flow.PrintDescription(c)
		return
	}

	c.Run()
}
