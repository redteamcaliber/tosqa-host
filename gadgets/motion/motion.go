// Motion and motion planning - the latter is wishful thinking for now.
package motion

import (
	"time"

	"github.com/jcw/flow"
)

func init() {
	flow.Registry["StepGen"] = func() flow.Circuitry { return &StepGen{} }
	flow.Registry["SinglePlanner"] = func() flow.Circuitry { return &SinglePlanner{} }
}

type StepGen struct {
	flow.Gadget
}

func (g *StepGen) Run() {
}

type SinglePlanner struct {
	flow.Gadget
	Param flow.Input
	In    flow.Input
	Out   flow.Output
}

func (g *SinglePlanner) Run() {
	var err error
	step := 5 * time.Millisecond
	for m := range g.Param {
		t := m.(flow.Tag)
		switch t.Tag {
		case "step":
			step, err = time.ParseDuration(t.Msg.(string))
			flow.Check(err)
		}
	}
	g.Out.Send(step)
	for m := range g.In {
		g.Out.Send(m)
	}
}
