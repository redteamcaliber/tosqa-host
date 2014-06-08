package canbus

import (
	"bufio"
	"bytes"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net"
	"strconv"
	"strings"
	"time"

	"github.com/golang/glog"
	"github.com/jcw/flow"
	"github.com/jcw/jeebus/gadgets/database" // TODO: hacked direct db access
)

func init() {
	flow.Registry["SocketCan"] = func() flow.Circuitry { return &SocketCan{} }
	flow.Registry["CanBridge"] = func() flow.Circuitry { return &CanBridge{} }
	flow.Registry["CanSerial"] = func() flow.Circuitry { return &CanSerial{} }
	flow.Registry["BootMaster"] = func() flow.Circuitry { return &BootMaster{} }
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
			glog.V(2).Infof("S%s#%X", t.Tag, t.Msg.([]byte))
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
			out := flow.Tag{s[0][1:], data}
			glog.V(2).Infoln(out)
			g.Out.Send(out)
		} else {
			g.Err.Send(msg)
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

type BootMaster struct {
	flow.Gadget
	In  flow.Input
	Out flow.Output
}

func (g *BootMaster) Run() {
	for m := range g.In {
		tag := m.(flow.Tag)
		addr, err := strconv.ParseInt(tag.Tag, 16, 32)
		flow.Check(err)
		hwid := fmt.Sprintf("%02X", tag.Msg.([]byte))
		if addr&0x1FFFFF80 == 0x1F123480 && len(hwid) == 16 {
			node := g.issueId(int8(addr&0x7F), hwid)
			tag.Tag = fmt.Sprintf("%02X", 0x1F123400 + int(node))
			g.Out.Send(tag)
		}
	}
}

// in:  S1F123481#2CFB0E0E00003253
// out: S1F123401#2CFB0E0E00003253
// in:  S1F123481#0101
// out: code upload block 1
// in:  S1F123481#0102
// out: code upload block 2
// in:  S1F123481#0103
// in:  S1F123480#2CFB0E0E00003253
// in:  S101#FA00000000
// in:  S101#FA00000000

func (g *BootMaster) issueId(typ int8, hwid string) int8 {
	key := "/can/node/" + hwid
	var info struct {
		Type   int8      // node type reported in boot request, 0..127
		Node   int8      // assigned node ID, 1..127
		Issued time.Time // when was the node ID assigned
	}
	myCast(database.Get(key), &info)
	glog.Infoln("issueId", typ, hwid, info)
	if typ != 0 {
		info.Type = typ
	}
	if info.Node == 0 {
		info.Node = 11
	}
	info.Issued = time.Now()
	database.Put(key, info)
	return info.Node
}

func myCast(in, out interface{}) {
	data, err := json.Marshal(in)
	flow.Check(err)
	err = json.Unmarshal(data, out)
	flow.Check(err)
}
