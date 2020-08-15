package sat

import (
	"testing"

	"ortools/go/sat/gen"
)

// TODO us assert and cmp libs
//import "gotest.tools/assert"
//import "gotest.tools/assert/cmp"

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
	if len(result) > 0 {
		t.Errorf("CPModel is not valid: %v", result)
	}

	solver := CpSolver{}
	out := solver.Solve(*cpModel)
	if out.Status != gen.CpSolverStatus_OPTIMAL {
		t.Error("CP Model solution is not optimal")
	}

}
