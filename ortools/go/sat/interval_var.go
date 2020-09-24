package sat

import genSat "ortools/gen/ortools/go/sat"

type intervalVar struct {
	modelProto *genSat.CpModelProto
	varIndex   int
	VarProto   *genSat.IntervalConstraintProto
}

var domains = make(map[int]bool, 0)

// Creates an interval variable from start, size, and end.
//
// An interval variable is a constraint, that is itself used in other constraints like
// NoOverlap.
// Internally, it ensures that `start + size == end`.
func (m *CpModel) NewIntervalVar(start IntVar, sizeIndex int, end IntVar, name string) *intervalVar {

	varProto := genSat.IntervalConstraintProto{
		Start: int32(start.Index()),
		Size:  int32(m.IndexFromConstant(sizeIndex, name)),
		End:   int32(end.Index()),
	}

	intervalVar := &intervalVar{
		modelProto: m.proto,
		varIndex:   m.ConstraintCount(),
		VarProto:   &varProto,
	}

	cp := genSat.ConstraintProto{
		Name:               name,
		EnforcementLiteral: nil,
		Constraint: &genSat.ConstraintProto_Interval{
			Interval: &varProto,
		},
	}

	m.proto.Constraints = append(m.proto.Constraints, &cp)

	return intervalVar

}

func (m *CpModel) NewFixedInterval(startIndex int, sizeIndex int, name string) *intervalVar {

	varProto := genSat.IntervalConstraintProto{
		Start: int32(m.IndexFromConstant(startIndex, name)),
		Size:  int32(sizeIndex),
		End:   int32(m.IndexFromConstant(startIndex+sizeIndex, name)),
	}

	intervalVar := &intervalVar{
		modelProto: m.proto,
		varIndex:   m.ConstraintCount(),
		VarProto:   &varProto,
	}

	cp := genSat.ConstraintProto{
		Name:               name,
		EnforcementLiteral: nil,
		Constraint: &genSat.ConstraintProto_Interval{
			Interval: &varProto,
		},
	}

	m.proto.Constraints = append(m.proto.Constraints, &cp)

	return intervalVar

}

func (m *CpModel) IndexFromConstant(constant int, name string) int {

	variableCount := m.VariableCount()

	ivp := &genSat.IntegerVariableProto{
		Name:   name,
		Domain: []int64{int64(constant), int64(constant)},
	}

	if !domains[constant] {
		m.proto.Variables = append(m.proto.Variables, ivp)
		domains[constant] = true
	}

	return variableCount

}

func (m *CpModel) VariableCount() int {
	return len(m.proto.Variables)
}

func (m *CpModel) ConstraintCount() int {
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
