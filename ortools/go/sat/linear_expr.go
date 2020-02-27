package sat

type LinearExpr interface {

	/** Returns the number of elements in the interface. */
	NumElements() int

	/** Returns the ith variable. */
	Variable(index int) *IntVar

	/** Returns the ith coefficient. */
	Coefficient(index int) int
}
