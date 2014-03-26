package gcode

import (
	"github.com/jcw/flow"
)

func ExampleGcodeScanner() {
	c := flow.NewCircuit()
	c.Add("gp", "GcodeScanner")
	c.Feed("gp.In", "G01 X2.3 Y04.5 Z-6.7 ;gcode example")
	c.Run()
	// Output:
	// Lost map[string]float64: map[G1:1 X:2.3 Y:4.5 Z:-6.7]
	// Lost flow.Tag: {<comment> gcode example}
}
