package sat

///** A linear expression interface that can be parsed. */
//public interface LinearExpr {
///** Returns the number of elements in the interface. */
//int numElements();
//
///** Returns the ith variable. */
//IntVar getVariable(int index);
//
///** Returns the ith coefficient. */
//long getCoefficient(int index);
//
///** Creates a sum expression. */
//static LinearExpr sum(IntVar[] variables) {
//return new SumOfVariables(variables);
//}
//
///** Creates a scalar product. */
//static LinearExpr scalProd(IntVar[] variables, long[] coefficients) {
//return new ScalProd(variables, coefficients);
//}
//
///** Creates a scalar product. */
//static LinearExpr scalProd(IntVar[] variables, int[] coefficients) {
//long[] tmp = new long[coefficients.length];
//for (int i = 0; i < coefficients.length; ++i) {
//tmp[i] = coefficients[i];
//}
//return new ScalProd(variables, tmp);
//}
//
///** Creates a linear term (var * coefficient). */
//static LinearExpr term(IntVar variable, long coefficient) {
//return new ScalProd(new IntVar[] {variable}, new long[] {coefficient});
//}
//}

type LinearExpr interface {

	/** Returns the number of elements in the interface. */
	NumElements() int

	/** Returns the ith variable. */
	Variable(index int) *IntVar

	/** Returns the ith coefficient. */
	Coefficient(index int) int
}
