package canbus

import (
	"github.com/jcw/flow"
	_ "github.com/jcw/flow/gadgets"
)

func ExampleSocketCan() {
	c := flow.NewCircuit()
	c.Add("d", "Delay")
	// c.Add("s", "SocketCan")
	c.Add("s", "CanBridge")
	c.Connect("d.Out", "s.In", 0)
	c.Feed("d.Delay", "3s")
	c.Feed("d.In", flow.Tag{"456", []byte("abc{123}")})
	c.Run()
}
