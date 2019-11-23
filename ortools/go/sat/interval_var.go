package sat

import (
	"or-tools/ortools/go/sat/gen"
)

type intervalVar struct {
	modelProto *gen.CpModelProto
	varIndex   int
	VarProto   *gen.IntervalConstraintProto
}

type DomainTrack struct {
}

var domains = make(map[int]bool, 0)

// Scheduling support.

/**
 * Creates an interval variable from start, size, and end.
 *
 * An interval variable is a constraint, that is itself used in other constraints like
 * NoOverlap.
 *
 * Internally, it ensures that {@code start + size == end}.
 */
func (m *cpModel) NewIntervalVar(start IntVar, sizeIndex int, end IntVar, name string) *intervalVar {

	varProto := gen.IntervalConstraintProto{
		Start: int32(start.Index()),
		Size:  int32(m.IndexFromConstant(sizeIndex)),
		End:   int32(end.Index()),
	}

	intervalVar := &intervalVar{
		modelProto: m.proto,
		varIndex:   m.ConstraintCount(),
		VarProto:   &varProto,
	}

	cp := gen.ConstraintProto{
		Name:               name,
		EnforcementLiteral: nil,
		Constraint: &gen.ConstraintProto_Interval{
			Interval: &varProto,
		},
	}

	m.proto.Constraints = append(m.proto.Constraints, &cp)

	return intervalVar

}

func (m *cpModel) NewFixedInterval(startIndex int, sizeIndex int, name string) *intervalVar {

	varProto := gen.IntervalConstraintProto{
		Start: int32(m.IndexFromConstant(startIndex)),
		Size:  int32(sizeIndex),
		End:   int32(m.IndexFromConstant(startIndex + sizeIndex)),
	}

	intervalVar := &intervalVar{
		modelProto: m.proto,
		varIndex:   m.ConstraintCount(),
		VarProto:   &varProto,
	}

	cp := gen.ConstraintProto{
		Name:               name,
		EnforcementLiteral: nil,
		Constraint: &gen.ConstraintProto_Interval{
			Interval: &varProto,
		},
	}

	m.proto.Constraints = append(m.proto.Constraints, &cp)

	return intervalVar

}

func (m *cpModel) IndexFromConstant(constant int) int {

	variableCount := m.VariableCount()

	ivp := &gen.IntegerVariableProto{
		Name:   "SOME NAME",
		Domain: []int64{int64(constant), int64(constant)},
	}

	if !domains[constant] {
		m.proto.Variables = append(m.proto.Variables, ivp)
		domains[constant] = true
	}

	return variableCount

}

func (m *cpModel) VariableCount() int {
	return len(m.proto.Variables)
}

func (m *cpModel) ConstraintCount() int {
	return len(m.proto.Constraints)
}

func (i *intervalVar) String() string {
	return i.modelProto.GetConstraints()[i.varIndex].String()
}

func (i *intervalVar) Name() string {
	return i.modelProto.GetConstraints()[i.varIndex].GetName()
}

func (i *intervalVar) Index() int {
	return i.varIndex
}
