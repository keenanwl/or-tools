package sat

import (
	"or-tools/ortools/go/gen"
)

type intervalVar struct {
	modelProto *gen.CpModelProto
	varIndex   int
	VarProto   *gen.IntervalConstraintProto
}

// Scheduling support.

/**
 * Creates an interval variable from start, size, and end.
 *
 * An interval variable is a constraint, that is itself used in other constraints like
 * NoOverlap.
 *
 * Internally, it ensures that {@code start + size == end}.
 */
func (m *cpModel) NewIntervalVar(startIndex intVar, sizeIndex int, endIndex intVar, name string) *intervalVar {

	varProto := gen.IntervalConstraintProto{
		Start: int32(startIndex.Index()),
		End:   int32(endIndex.Index()),
		Size:  int32(sizeIndex),
	}

	intervalVar := &intervalVar{
		modelProto: m.proto,
		varIndex:   len(m.proto.GetConstraints()),
		VarProto:   &varProto,
	}

	cp := &gen.ConstraintProto_Interval{
		Interval: &varProto,
	}

	cpp := gen.ConstraintProto{
		Name:               name,
		EnforcementLiteral: nil,
		Constraint:         cp,
	}

	m.proto.Constraints = append(m.proto.Constraints, &cpp)

	return intervalVar

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
