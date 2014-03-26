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
	// Lost flow.Tag: {G0 [6.139 11.245 8.1 1e+09]}
	// Lost flow.Tag: {S 10000}
	// Lost flow.Tag: {G1 [0 0 -2 600]}
	// Lost flow.Tag: {G1 [0 78.716 -2 1000]}
	// Lost flow.Tag: {G1 [6.261 79.81 -2 1000]}
	// Lost flow.Tag: {G1 [6.625 80.904 -2 1000]}
	// Lost flow.Tag: {G1 [86.765 35.118 -2 1000]}
	// Lost flow.Tag: {G1 [87.118 35.588 -2 1000]}
	// Lost flow.Tag: {G0 [87.118 35.588 8 1e+09]}
	// Lost flow.Tag: {G0 [14.059 64.059 -2 1e+09]}
	// Lost flow.Tag: {G1 [87.118 35.588 -26 600]}
	// Lost flow.Tag: {G1 [85.941 35.588 -26 1000]}
	// Lost flow.Tag: {G0 [85.941 35.588 8 1e+09]}
	// Lost flow.Tag: {G0 [14.059 25.941 -26 1e+09]}
	// Lost flow.Tag: {G1 [85.941 35.588 -26 600]}
	// Lost flow.Tag: {G1 [86.754 35.588 -26 1000]}
	// Lost flow.Tag: {G0 [86.754 35.588 8 1e+09]}
	// Lost flow.Tag: {M30 <nil>}
}
