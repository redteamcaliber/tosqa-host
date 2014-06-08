// Convenience package to wrap all the gadgets available in Tosqa.
package tosqa

import (
	// "github.com/jcw/flow"
	_ "github.com/jcw/flow/gadgets"
	_ "github.com/tosqa/tosqa-host/gadgets/canbus"
	_ "github.com/tosqa/tosqa-host/gadgets/gcode"
	_ "github.com/tosqa/tosqa-host/gadgets/motion"
)

var Version = "0.5.0"
