package motion

import (
	"github.com/jcw/flow"
)

func ExampleSinglePlanner() {
	c := flow.NewCircuit()
	c.Add("p", "SinglePlanner")
	c.Feed("p.Param", flow.Tag{"step", "10ms"})
	c.Feed("p.In", []float64{0, 0, 0, 0})
	c.Feed("p.In", []float64{0, 100, 0, 500})
	c.Feed("p.In", []float64{100, 100, 0, 500})
	c.Feed("p.In", []float64{200, 200, 100, 500})
	c.Feed("p.In", []float64{0, 0, 0, 1000})
	c.Feed("p.In", []float64{0, 0, 0, 0})
	c.Run()
	// Output:
	// Lost time.Duration: 10ms
	// Lost []float64: [0 0 0 0]
	// Lost []float64: [0 100 0 500]
	// Lost []float64: [100 100 0 500]
	// Lost []float64: [200 200 100 500]
	// Lost []float64: [0 0 0 1000]
	// Lost []float64: [0 0 0 0]
}
