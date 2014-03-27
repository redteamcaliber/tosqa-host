package gcode

import (
	"github.com/jcw/flow"
)

func ExampleGcodeScanner() {
	c := flow.NewCircuit()
	c.Add("s", "GcodeScanner")
	c.Feed("s.In", "G01 X2.3 Y04.5 Z-6.7 ;gcode example")
	c.Run()
	// Output:
	// Lost flow.Tag: {<comment> gcode example}
	// Lost map[string]float64: map[G1:1 X:2.3 Y:4.5 Z:-6.7]
}

func ExampleGcodeParser() {
	c := flow.NewCircuit()
	c.Add("s", "GcodeScanner")
	c.Add("p", "GcodeParser")
	c.Connect("s.Out", "p.In", 0)
	c.Feed("s.In", "G01 X2.3 Y04.5 Z-6.7 ;gcode example")
	c.Run()
	// Output:
	// Lost flow.Tag: {<comment> gcode example}
	// Lost map[string]float64: map[X:2.3 Y:4.5 Z:-6.7]
	// Lost []string: [G1]
}

func ExampleGcodeInterp() {
	c := flow.NewCircuit()
	c.Add("s", "GcodeScanner")
	c.Add("p", "GcodeParser")
	c.Add("i", "GcodeInterp")
	c.Connect("s.Out", "p.In", 0)
	c.Connect("p.Out", "i.In", 0)
	c.Feed("i.Cfg", flow.Tag{"<perMm>", []float64{1000, 1000, 1000, 12345}})
	c.Feed("s.In", "G00 X6.139 Y11.245 Z8.100")
	c.Feed("s.In", "G01 Z-2.000 F600 S10000  ")
	c.Feed("s.In", "G01 Y78.716 F1000        ")
	c.Feed("s.In", "G01 X6.261 Y79.810       ")
	c.Feed("s.In", "G01 X6.625 Y80.904       ")
	c.Feed("s.In", "G01 X86.765 Y35.118      ")
	c.Feed("s.In", "G01 X87.118 Y35.588      ")
	c.Feed("s.In", "G00 Z8.000               ")
	c.Feed("s.In", "G00 X14.059 Y64.059      ")
	c.Feed("s.In", "G01 Z-26.000 F600        ")
	c.Feed("s.In", "G01 X85.941 F1000        ")
	c.Feed("s.In", "G00 Z8.000               ")
	c.Feed("s.In", "G00 X14.059 Y25.941      ")
	c.Feed("s.In", "G01 Z-26.000 F600        ")
	c.Feed("s.In", "G01 X86.754 F1000        ")
	c.Feed("s.In", "G00 Z8.000               ")
	c.Feed("s.In", "M30                      ")
	c.Run()
	// Output:
	// Lost flow.Tag: {<perMm> [1000 1000 1000 12345]}
	// Lost []int: [6139 11245 8100 12345]
	// Lost flow.Tag: {S 10000}
	// Lost []int: [0 0 -10100 600]
	// Lost []int: [0 67470 0 1000]
	// Lost []int: [121 1094 0 1000]
	// Lost []int: [363 1093 0 1000]
	// Lost []int: [80140 -45785 0 1000]
	// Lost []int: [352 469 0 1000]
	// Lost []int: [0 0 10000 12345]
	// Lost []int: [-73059 28470 0 12345]
	// Lost []int: [0 0 -34000 600]
	// Lost []int: [71882 0 0 1000]
	// Lost []int: [0 0 34000 12345]
	// Lost []int: [-71882 -38117 0 12345]
	// Lost []int: [0 0 -34000 600]
	// Lost []int: [72695 0 0 1000]
	// Lost []int: [0 0 34000 12345]
	// Lost flow.Tag: {M30 <nil>}
}

func ExampleGcodeInterp_2() {
	c := flow.NewCircuit()
	c.Add("s", "GcodeScanner")
	c.Add("p", "GcodeParser")
	c.Add("i", "GcodeInterp")
	c.Connect("s.Out", "p.In", 0)
	c.Connect("p.Out", "i.In", 0)
	c.Feed("i.Cfg", flow.Tag{"<perMm>", []float64{1, 1, 1, 1000}})
	c.Feed("s.In", "G0 X1 Y-2 Z4")
	c.Run()
	// Output:
	// Lost flow.Tag: {<perMm> [1 1 1 1000]}
	// Lost []int: [1 -2 4 1000]
}

func ExampleStepGen() {
	c := flow.NewCircuit()
	c.Add("s", "GcodeScanner")
	c.Add("p", "GcodeParser")
	c.Add("i", "GcodeInterp")
	c.Add("g", "StepGen")
	c.Connect("s.Out", "p.In", 0)
	c.Connect("p.Out", "i.In", 0)
	c.Connect("i.Out", "g.In", 0)
	c.Feed("i.Cfg", flow.Tag{"<perMm>", []float64{1, 1, 1, 1000}})
	c.Feed("s.In", "G0 X1 Y-2 Z4")
	c.Run()
	// Output:
	// Lost int: 3
	// Lost int: -2
	// Lost int: 3
	// Lost int: 1
	// Lost int: 3
	// Lost int: -2
	// Lost int: 3
}
