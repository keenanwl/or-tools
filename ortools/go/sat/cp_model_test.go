package sat

import (
	"fmt"
	"testing"
)

// TODO us assert and cmp libs
//import "gotest.tools/assert"
//import "gotest.tools/assert/cmp"

func TestCpModel_Schedule(t *testing.T) {

	cpModel := NewCpModel()

	startVar := cpModel.NewIntVar(0, 100, "start")
	endVar := cpModel.NewIntVar(0, 100, "end")

	duration := 1
	intervalVar := cpModel.NewIntervalVar(*startVar, duration, *endVar, "interval")

	fmt.Println("VALIDATE", cpModel.Validate())
	fmt.Println("MODEL", cpModel.proto.String())
	fmt.Printf("start = %s, duration = %v, end = %s, interval = %s", startVar, duration, endVar, intervalVar)

	solver := cpSolver{}
	out := solver.Solve(*cpModel)
	fmt.Println(out)

}

func TestCpModel_Validate(t *testing.T) {
	cpModel := NewCpModel()

	name := "model1"
	cpModel.SetName(name)
	if name != cpModel.Name() {
		t.Errorf("name %s != %s", name, cpModel.Name())
	}

	var1 := cpModel.NewIntVar(0, 10, "var1")

	if var1 == nil {
		t.Errorf("var1 is nil")
	}

	var2 := cpModel.NewIntVar(10, 15, "var2")

	if var2 == nil {
		t.Errorf("var2 is nil")
	}

	result := cpModel.Validate()

	solver := cpSolver{}
	out := solver.Solve(*cpModel)
	fmt.Println(out)

	t.Log(result)
}
