// The (very early) start of a G-code parser.
package gcode

import (
	"fmt"
	"strconv"
	"strings"

	"github.com/jcw/flow"
)

func init() {
	flow.Registry["GcodeScanner"] = func() flow.Circuitry { return &GcodeScanner{} }
}

// GcodeScanner process G-code text lines and parses them into commands.
type GcodeScanner struct {
	flow.Gadget
	In  flow.Input
	Out flow.Output
}

type gcodeWord struct {
}

// Start scanning lines and convert each one to a map of G-code "words".
func (g *GcodeScanner) Run() {
	for m := range g.In {
		if s, ok := m.(string); ok {
			words, comment := g.parse(s)
			if len(words) > 0 {
				g.Out.Send(words)
			}
			if len(comment) > 0 {
				g.Out.Send(flow.Tag{"<comment>", comment})
			}
		} else {
			g.Out.Send(m)
		}
	}
}

func (g *GcodeScanner) parse(s string) (words map[string]float64, comment string) {
	words = make(map[string]float64)
	i, n := 0, len(s)
	u := strings.ToUpper(s)

	// scan and skip the next number
	number := func() (string, float64) {
		// remove leading white space
		for i < n && s[i] == ' ' {
			i++
		}
		// collect digits, etc
		pos := i
		for i < n && strings.IndexByte("0123456789-.", s[i]) >= 0 {
			i++
		}
		// remove leading 0's, so that "G01" will end up as "G1"
		t := strings.TrimLeft(s[pos:i], "0")
		if len(t) == 0 {
			t = "0"
		}
		// return as string and as float
		f, _ := strconv.ParseFloat(t, 64)
		return t, f
	}

	for i < n {
		cmd := u[i]
		i++

		switch cmd {
		case ';', '(':
			comment = s[i:]
			return
		case 'G', 'M':
			t, f := number()
			words[fmt.Sprintf("%c%s", cmd, t)] = f
		default:
			if 'A' <= cmd && cmd <= 'Z' {
				_, f := number()
				words[fmt.Sprintf("%c", cmd)] = f
			}
		}
	}
	return
}
