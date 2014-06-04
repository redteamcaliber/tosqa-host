package canbus

import (
	"bufio"
	"bytes"
	"encoding/hex"
	"fmt"
	"net"
	"strings"

	"github.com/jcw/flow"
)

func init() {
	flow.Registry["SocketCan"] = func() flow.Circuitry { return &SocketCan{} }
	flow.Registry["CanBridge"] = func() flow.Circuitry { return &CanBridge{} }
	flow.Registry["CanSerial"] = func() flow.Circuitry { return &CanSerial{} }
}

type SocketCan struct {
	flow.Gadget
	In  flow.Input
	Out flow.Output
	Err flow.Output
}

func (g *SocketCan) Run() {
	sock, err := net.Dial("tcp", "192.168.1.138:29536")
	flow.Check(err)

	b := [100]byte{}

	n, err := sock.Read(b[:])
	flow.Check(err)

	greeting := string(b[:n])
	if greeting != "< hi >" {
		panic("socketcan? " + greeting)
	}

	go func() {
		sock.Write([]byte("< open can0 >"))
		sock.Write([]byte("< rawmode >"))
		for m := range g.In {
			t := m.(flow.Tag)
			d := t.Msg.([]byte)
			// TODO: simplify this mess
			v := []string{}
			for i := range d {
				v = append(v, hex.EncodeToString(d[i:i+1]))
			}
			h := strings.Join(v, " ")
			fmt.Fprintf(sock, "< send %s %d %s >", t.Tag, len(d), h)
		}
		sock.Close()
	}()

	scanner := bufio.NewScanner(sock)
	scanner.Split(scanAngles)

	for scanner.Scan() {
		msg := scanner.Text()
		if strings.HasPrefix(msg, "< frame ") {
			s := strings.Split(msg, " ")
			data, err := hex.DecodeString(s[4])
			flow.Check(err)
			g.Out.Send(flow.Tag{s[2], data})
		} else if msg != "< ok >" {
			g.Err.Send(msg)
		}
	}
}

func scanAngles(data []byte, atEOF bool) (advance int, token []byte, err error) {
	if !atEOF || len(data) > 0 {
		if i := bytes.IndexByte(data, '>'); i >= 0 {
			return i + 1, data[0 : i+1], nil
		}
	}
	return 0, nil, nil
}

type CanBridge struct {
	flow.Gadget
	In  flow.Input
	Out flow.Output
	Err flow.Output
}

func (g *CanBridge) Run() {
	sock, err := net.Dial("tcp", "192.168.1.20:3531")
	flow.Check(err)

	go func() {
		for m := range g.In {
			t := m.(flow.Tag)
			fmt.Fprintf(sock, "S%s#%X\n", t.Tag, t.Msg.([]byte))
		}
		sock.Close()
	}()

	scanner := bufio.NewScanner(sock)

	for scanner.Scan() {
		msg := scanner.Text()
		if strings.HasPrefix(msg, "S") {
			s := strings.Split(msg, "#")
			data, err := hex.DecodeString(s[1])
			flow.Check(err)
			g.Out.Send(flow.Tag{s[0][1:], data})
		} else {
			g.Err.Send(scanner.Text())
		}
	}
}

type CanSerial struct {
	flow.Gadget
	In     flow.Input
	Out    flow.Output
	Err    flow.Output
	SerIn  flow.Input
	SerOut flow.Output
}

func (g *CanSerial) Run() {
	go func() {
		for m := range g.In {
			t := m.(flow.Tag)
			g.SerOut.Send(fmt.Sprintf("S%s#%X\n", t.Tag, t.Msg.([]byte)))
		}
	}()

	for m := range g.SerIn {
		msg := m.(string)
		if strings.HasPrefix(msg, "S") {
			s := strings.Split(msg, "#")
			data, err := hex.DecodeString(s[1])
			flow.Check(err)
			g.Out.Send(flow.Tag{s[0][1:], data})
		} else {
			g.Err.Send(msg)
		}
	}
}
