// Interface to the CAN bus, including the boot master.
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
	flow.Registry["MotionDemo"] = func() flow.Circuitry { return &MotionDemo{} }
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
	// flow.Check(err)
	if err != nil {
		glog.Warning("cannot connect to 192.168.1.20:3531")
		return
	}

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
	database.OpenDatabase()
	for m := range g.In {
		tag := m.(flow.Tag)
		addr, err := strconv.ParseInt(tag.Tag, 16, 32)
		flow.Check(err)
		hwid := fmt.Sprintf("%02X", tag.Msg.([]byte))
		if addr&0x1FFFFF80 == 0x1F123480 && len(hwid) == 16 {
			node := g.assignNodeId(int8(addr&0x7F), hwid)
			tag.Tag = fmt.Sprintf("%02X", 0x1F123400+int(node))
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

type CanNodeInfo struct {
	Type   int8      // node type reported in boot request, 0..127
	Node   int8      // assigned node ID, 1..127
	Issued time.Time // when was the node ID assigned
	Used   time.Time // when was the node ID requested
}

var activeNodes = map[string]CanNodeInfo{}
var activeHwids = []string{""} // first entry is not used

func (g *BootMaster) assignNodeId(typ int8, hwid string) int8 {
	key := "/can/node/" + hwid
	var info CanNodeInfo
	myCast(database.Get(key), &info)
	glog.Infoln("assignNodeId", typ, hwid)
	if typ != 0 {
		info.Type = typ
		info.Issued = time.Now()
		if _, ok := activeNodes[hwid]; ok {
			info.Node = activeNodes[hwid].Node
		} else {
			info.Node = int8(len(activeHwids)) // next ID
			activeHwids = append(activeHwids, hwid)
		}
	} else {
		info.Used = time.Now()
	}
	database.Put(key, info)
	activeNodes[hwid] = info
	for i, x := range activeNodes {
		fmt.Println(" ", i, x.Type, x.Node)
	}
	return info.Node
}

func myCast(in, out interface{}) {
	data, err := json.Marshal(in)
	flow.Check(err)
	err = json.Unmarshal(data, out)
	flow.Check(err)
}

type MotionDemo struct {
	flow.Gadget
	Addr flow.Input
	In   flow.Input
	Out  flow.Output
}

func (g *MotionDemo) Run() {
	addr := (<-g.Addr).(string)
	for _ = range g.In {
		g.emit(addr, "401F640001000100")
		g.emit(addr, "A00F9CFF01000100")
		g.emit(addr, "A00F640001000100")
		g.emit(addr, "401F9CFF01000100")
	}
}

func (g *MotionDemo) emit(addr, command string) {
	payload, err := hex.DecodeString(command)
	flow.Check(err)
	g.Out.Send(flow.Tag{addr, payload})
}
