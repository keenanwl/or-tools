package graph

import (
	"testing"

	genGraph "ortools/gen/ortools/go/graph"
)

func Test_MinCostFlow_solveMinCostFlow(t *testing.T) {

	minCostFlow := genGraph.NewMinCostFlow()
	numSources := 4
	numTargets := 4
	expectedCost := 275

	costs := [][]int{
		{90, 75, 75, 80},
		{35, 85, 55, 65},
		{125, 95, 90, 105},
		{45, 110, 95, 115},
	}

	for source := 0; source < numSources; source++ {
		for target := 0; target < numTargets; target++ {
			minCostFlow.AddArcWithCapacityAndUnitCost(source, numSources+target, 1, int64(costs[source][target]))
		}
	}

	for node := 0; node < numSources; node++ {
		minCostFlow.SetNodeSupply(node, 1)
		minCostFlow.SetNodeSupply(numSources+node, -1)
	}

	if minCostFlow.Solve() == genGraph.MinCostFlowBaseOPTIMAL {
		totalFlowCost := minCostFlow.GetOptimalCost()
		t.Logf("total flow = %v/%v\n", totalFlowCost, expectedCost)

		for i := 0; i < minCostFlow.GetNumArcs(); i++ {
			if minCostFlow.GetFlow(i) > 0 {
				t.Logf("From source %v to target %v: cost %v\n", minCostFlow.GetTail(i), minCostFlow.GetHead(i), minCostFlow.GetUnitCost(i))
			}
		}
	} else {
		t.Error("Optimal solution not found")
	}

}

func Test_SolverMaxFlow(t *testing.T) {

	tails := []int{0, 0, 0, 0, 1, 2, 3, 3, 4}
	heads := []int{1, 2, 3, 4, 3, 4, 4, 5, 5}
	capacities := []int{5, 8, 5, 3, 4, 5, 6, 6, 4}
	expectedTotalFlow := 10

	maxFlow := genGraph.NewMaxFlow()

	for i := 0; i < len(tails); i++ {
		maxFlow.AddArcWithCapacity(tails[i], heads[i], int64(capacities[i]))
	}

	if maxFlow.Solve(0, 5) == genGraph.MaxFlowOPTIMAL {
		t.Logf("Total flow %v / %v", maxFlow.GetOptimalFlow(), expectedTotalFlow)
		for i := 0; i < maxFlow.GetNumArcs(); i++ {
			t.Logf(
				"From source %v to target %v: %v / %v",
				maxFlow.GetTail(i),
				maxFlow.GetHead(i),
				maxFlow.GetFlow(i),
				maxFlow.GetCapacity(i),
			)
		}

	} else {
		t.Error("expected max flow solution to be optimal")
	}

}
