package sat

import (
	"fmt"
	"testing"

	"or-tools/ortools/go/sat/gen"
)

func TestCpModel_Schedule_NoOverlap(t *testing.T) {

	model := NewCpModel()
	var horizon int64 = 21

	// Task 0, duration 2.
	start0 := model.NewIntVar(0, horizon, "start0")
	duration0 := 2
	end0 := model.NewIntVar(0, horizon, "end0")
	task0 := model.NewIntervalVar(*start0, duration0, *end0, "task0")

	//  Task 1, duration 4.
	start1 := model.NewIntVar(0, horizon, "start1")
	duration1 := 4
	end1 := model.NewIntVar(0, horizon, "end1")
	task1 := model.NewIntervalVar(*start1, duration1, *end1, "task1")

	// Task 2, duration 3.
	start2 := model.NewIntVar(0, horizon, "start2")
	duration2 := 3
	end2 := model.NewIntVar(0, horizon, "end2")
	task2 := model.NewIntervalVar(*start2, duration2, *end2, "task2")

	// Weekends.
	weekend0 := model.NewFixedInterval(5, 2, "weekend0")
	weekend1 := model.NewFixedInterval(12, 2, "weekend1")
	weekend2 := model.NewFixedInterval(19, 2, "weekend2")

	// No Overlap constraint. This constraint enforces that no two intervals can overlap.
	// In this example, as we use 3 fixed intervals that span over weekends, this constraint makes
	// sure that all tasks are executed on weekdays.
	model.AddNoOverlap([]intervalVar{*task0, *task1, *task2, *weekend0, *weekend1, *weekend2})

	// Makespan objective.
	obj := model.NewIntVar(0, horizon, "makespan")
	model.AddMaxEquality(*obj, []IntVar{*end0, *end1, *end2})
	model.Minimize(obj)

	solver := cpSolver{}
	status := solver.Solve(*model)

	if status.Status != gen.CpSolverStatus_OPTIMAL {
		t.Fatalf("expecting solver status to be optimal, got %s", status.Status)
	}

	if len(model.Validate()) > 0 {
		t.Fatalf("expecting model to validate, got %s", model.Validate())
	}

	if status.ObjectiveValue != 11 {
		t.Fatalf("expecting objective value to be 11, got %v", status.ObjectiveValue)
	}

	if status.Solution[start0.Index()] != 0 {
		t.Fatalf("expecting task 0 to start at 0, got %v", status.Solution[start0.Index()])
	}

	if status.Solution[start1.Index()] != 7 {
		t.Fatalf("expecting task 1 to start at 7, got %v", status.Solution[start1.Index()])
	}

	if status.Solution[start2.Index()] != 2 {
		t.Fatalf("expecting task 2 to start at 2, got %v", status.Solution[start2.Index()])
	}

	fmt.Printf("Optimal Schedule Length: %v\n", status.ObjectiveValue)
	fmt.Printf("Task 0 starts at %v\n", status.Solution[start0.Index()])
	fmt.Printf("Task 1 starts at %v\n", status.Solution[start1.Index()])
	fmt.Printf("Task 2 starts at %v\n", status.Solution[start2.Index()])

}
