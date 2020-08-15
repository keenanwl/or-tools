package sat

type Difference struct {
	Left  LinearExpr
	Right LinearExpr
}

func NewDifference(left LinearExpr, right LinearExpr) *Difference {
	return &Difference{
		Left:  left,
		Right: right,
	}
}

func (d *Difference) NumElements() int {
	return d.Left.NumElements() + d.Right.NumElements()
}

func (d *Difference) Variable(index int) *IntVar {

	if index < d.Left.NumElements() {
		return d.Left.Variable(index)
	}

	return d.Right.Variable(index - d.Left.NumElements())

}

func (d *Difference) Coefficient(index int) int {

	if index < d.Left.NumElements() {
		return d.Left.Coefficient(index)
	}

	return d.Right.Coefficient(index - d.Left.NumElements())

}
