// Copyright 2010-2018 Google LLC
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// This .i file exposes the linear programming and integer programming
// a java codelab yet, as of July 2014)
//
// The java API is pretty much identical to the C++ API, with methods
// systematically renamed to the Java-style "lowerCamelCase", and using
// the Java-style getProperty() instead of the C++ Property(), for getters.
//
// USAGE EXAMPLES (j/c/g and jt/c/g refer to java/com/google and javatests/...):
// - j/c/g/ortools/samples/LinearProgramming.java
// - j/c/g/ortools/samples/IntegerProgramming.java
// - jt/c/g/ortools/linearsolver/LinearSolverTest.java
//
// TODO(user): unit test all the APIs that are currently marked with 'no test'.

// %include "enums.swg"  // For native Java enum support.
%include "stdint.i"

%include "ortools/base/base.i"
%import "ortools/util/go/vector.i"
%include "ortools/util/go/proto.i"

//%go_import("github.com/golang/protobuf/proto")

// We need to forward-declare the proto here, so that the PROTO_* macros
// involving them work correctly. The order matters very much: this declaration
// needs to be before the %{ #include ".../linear_solver.h" %}.
namespace operations_research {
class MPModelProto;
class MPModelRequest;
class MPSolutionResponse;
}  // namespace operations_research

%{
#include "ortools/linear_solver/linear_solver.h"
#include "ortools/linear_solver/model_exporter.h"
%}

//%typemap(javaimports) SWIGTYPE %{
//import java.lang.reflect.*;
//%}

// Conversion of array of MPVariable or MPConstraint from/to C++ vectors.
CONVERT_VECTOR_WITH_CAST(operations_research::MPVariable, MPVariable, REINTERPRET_CAST,
    linearsolver);
CONVERT_VECTOR_WITH_CAST(operations_research::MPConstraint, MPConstraint, REINTERPRET_CAST,
    linearsolver);

// Support the proto-based APIs.
PROTO_INPUT(
    operations_research::MPModelProto,
    MPModelProto,
    input_model);
PROTO2_RETURN(
    operations_research::MPModelProto,
    MPModelProto);
PROTO_INPUT(
    operations_research::MPModelRequest,
    MPModelRequest,
    model_request);
PROTO_INPUT(
    operations_research::MPSolutionResponse,
    MPSolutionResponse,
    response);
PROTO2_RETURN(
    operations_research::MPSolutionResponse,
    MPSolutionResponse);


%ignoreall

%unignore operations_research;

// List of the classes exposed.
%rename (MPSolver) operations_research::MPSolver;
%rename (Solver) operations_research::MPSolver::MPSolver;
%unignore operations_research::MPSolver::~MPSolver;
%unignore operations_research::MPConstraint;
%unignore operations_research::MPVariable;
%unignore operations_research::MPObjective;
%unignore operations_research::MPSolverParameters;

// Expose the MPSolver::OptimizationProblemType enum.
%unignore operations_research::MPSolver::OptimizationProblemType;
%unignore operations_research::MPSolver::GLOP_LINEAR_PROGRAMMING;
%unignore operations_research::MPSolver::CLP_LINEAR_PROGRAMMING;
%unignore operations_research::MPSolver::GLPK_LINEAR_PROGRAMMING;
%unignore operations_research::MPSolver::SCIP_MIXED_INTEGER_PROGRAMMING;
%unignore operations_research::MPSolver::CBC_MIXED_INTEGER_PROGRAMMING;
%unignore operations_research::MPSolver::GLPK_MIXED_INTEGER_PROGRAMMING;
%unignore operations_research::MPSolver::BOP_INTEGER_PROGRAMMING;
%unignore operations_research::MPSolver::SAT_INTEGER_PROGRAMMING;
// These aren't unit tested, as they only run on machines with a Gurobi license.
%unignore operations_research::MPSolver::GUROBI_LINEAR_PROGRAMMING;
%unignore operations_research::MPSolver::GUROBI_MIXED_INTEGER_PROGRAMMING;
%unignore operations_research::MPSolver::CPLEX_LINEAR_PROGRAMMING;
%unignore operations_research::MPSolver::CPLEX_MIXED_INTEGER_PROGRAMMING;
%unignore operations_research::MPSolver::XPRESS_LINEAR_PROGRAMMING;
%unignore operations_research::MPSolver::XPRESS_MIXED_INTEGER_PROGRAMMING;


// Expose the MPSolver::ResultStatus enum.
%rename (ResultStatus1) operations_research::MPSolver::ResultStatus;
%rename (Optimal) operations_research::MPSolver::OPTIMAL;
%rename (Feasible) operations_research::MPSolver::FEASIBLE;  // no test
%rename (Infeasible) operations_research::MPSolver::INFEASIBLE;  // no test
%rename (Unbounded) operations_research::MPSolver::UNBOUNDED;  // no test
%rename (Abnormal) operations_research::MPSolver::ABNORMAL;  // no test
%rename (NotSolved) operations_research::MPSolver::NOT_SOLVED;  // no test

// Expose the MPSolver's basic API, with some non-trivial renames.
%rename (Objective) operations_research::MPSolver::MutableObjective;
// We intentionally don't expose MakeRowConstraint(LinearExpr), because this
// "natural language" API is specific to C++: other languages may add their own
// syntactic sugar on top of MPSolver instead of this.
%rename (MakeConstraint) operations_research::MPSolver::MakeRowConstraint(double, double);
%rename (MakeConstraint) operations_research::MPSolver::MakeRowConstraint();
%rename (MakeConstraint) operations_research::MPSolver::MakeRowConstraint(double, double, const std::string&);
%rename (MakeConstraint) operations_research::MPSolver::MakeRowConstraint(const std::string&);

// Expose the MPSolver's basic API, with trivial renames.
%rename (MakeBoolVar) operations_research::MPSolver::MakeBoolVar;  // no test
%rename (MakeIntVar) operations_research::MPSolver::MakeIntVar;
%rename (MakeNumVar) operations_research::MPSolver::MakeNumVar;
%rename (MakeVar) operations_research::MPSolver::MakeVar;  // no test
%rename (Solve) operations_research::MPSolver::Solve;
%rename (VerifySolution) operations_research::MPSolver::VerifySolution;
%rename (Reset) operations_research::MPSolver::Reset;  // no test
%rename (Infinity) operations_research::MPSolver::infinity;
%rename (SetTimeLimit) operations_research::MPSolver::set_time_limit;  // no test

// Proto-based API of the MPSolver. Use is encouraged.
// Note: the following proto-based methods aren't listed here, but are
// supported (that's because we re-implement them in java below):
// - loadModelFromProto
// - exportModelToProto
// - createSolutionResponseProto
// - solveWithProto
%unignore operations_research::MPSolver::LoadStatus;
%unignore operations_research::MPSolver::NO_ERROR;  // no test
%unignore operations_research::MPSolver::UNKNOWN_VARIABLE_ID;  // no test
// - loadSolutionFromProto;  // Use hand-written version.

// Expose some of the more advanced MPSolver API.
%rename (SupportsProblemType) operations_research::MPSolver::SupportsProblemType;  // no test
%rename (SetSolverSpecificParametersAsString)
    operations_research::MPSolver::SetSolverSpecificParametersAsString;  // no test
%rename (InterruptSolve) operations_research::MPSolver::InterruptSolve;  // no test
%rename (WallTime) operations_research::MPSolver::wall_time;
%rename (Clear) operations_research::MPSolver::Clear;  // no test
%unignore operations_research::MPSolver::constraints;
%unignore operations_research::MPSolver::variables;
%rename (NumVariables) operations_research::MPSolver::NumVariables;
%rename (NumConstraints) operations_research::MPSolver::NumConstraints;
%rename (EnableOutput) operations_research::MPSolver::EnableOutput;  // no test
%rename (SuppressOutput) operations_research::MPSolver::SuppressOutput;  // no test
%rename (LookupConstraintOrNull) operations_research::MPSolver::LookupConstraintOrNull;  // no test
%rename (LookupVariableOrNull) operations_research::MPSolver::LookupVariableOrNull;  // no test

// Expose very advanced parts of the MPSolver API. For expert users only.
%rename (ComputeConstraintActivities) operations_research::MPSolver::ComputeConstraintActivities;
%rename (ComputeExactConditionNumber) operations_research::MPSolver::ComputeExactConditionNumber;
%rename (Nodes) operations_research::MPSolver::nodes;
%rename (Iterations) operations_research::MPSolver::iterations;
%unignore operations_research::MPSolver::BasisStatus;  // no test
%unignore operations_research::MPSolver::FREE;  // no test
%unignore operations_research::MPSolver::AT_LOWER_BOUND;
%unignore operations_research::MPSolver::AT_UPPER_BOUND;  // no test
%unignore operations_research::MPSolver::FIXED_VALUE;  // no test
%unignore operations_research::MPSolver::BASIC;
%unignore operations_research::MPSolver::SetStartingLpBasis;

// MPVariable: writer API.
%rename (SetInteger) operations_research::MPVariable::SetInteger;
%rename (SetLb) operations_research::MPVariable::SetLB;  // no test
%rename (SetUb) operations_research::MPVariable::SetUB;  // no test
%rename (SetBounds) operations_research::MPVariable::SetBounds;  // no test

// MPVariable: reader API.
%rename (SolutionValue) operations_research::MPVariable::solution_value;
%rename (Lb) operations_research::MPVariable::lb;  // no test
%rename (Ub) operations_research::MPVariable::ub;  // no test
%rename (Name) operations_research::MPVariable::name;  // no test
%rename (BasisStatus) operations_research::MPVariable::basis_status;
%rename (ReducedCost) operations_research::MPVariable::reduced_cost;  // For experts only.
%rename (Index) operations_research::MPVariable::index;  // no test

// MPConstraint: writer API.
%rename (SetCoefficient) operations_research::MPConstraint::SetCoefficient;
%rename (SetLb) operations_research::MPConstraint::SetLB;  // no test
%rename (SetUb) operations_research::MPConstraint::SetUB;  // no test
%rename (SetBounds) operations_research::MPConstraint::SetBounds;  // no test
%rename (SetIsLazy) operations_research::MPConstraint::set_is_lazy;

// MPConstraint: reader API.
%rename (GetCoefficient) operations_research::MPConstraint::GetCoefficient;
%rename (Lb) operations_research::MPConstraint::lb;  // no test
%rename (Ub) operations_research::MPConstraint::ub;  // no test
%rename (Name) operations_research::MPConstraint::name;
%rename (BasisStatus) operations_research::MPConstraint::basis_status;
%rename (DualValue) operations_research::MPConstraint::dual_value;  // For experts only.
%rename (IsLazy) operations_research::MPConstraint::is_lazy;  // For experts only.
%rename (Index) operations_research::MPConstraint::index;

// MPObjective: writer API.
%rename (SetCoefficient) operations_research::MPObjective::SetCoefficient;
%rename (SetMinimization) operations_research::MPObjective::SetMinimization;  // no test
%rename (SetMaximization) operations_research::MPObjective::SetMaximization;
%rename (SetOptimizationDirection) operations_research::MPObjective::SetOptimizationDirection;
%rename (Clear) operations_research::MPObjective::Clear;  // no test
%rename (SetOffset) operations_research::MPObjective::SetOffset;

// MPObjective: reader API.
%rename (Value) operations_research::MPObjective::Value;
%rename (GetCoefficient) operations_research::MPObjective::GetCoefficient;
%rename (Minimization) operations_research::MPObjective::minimization;
%rename (Maximization) operations_research::MPObjective::maximization;
%rename (Offset) operations_research::MPObjective::offset;
%rename (BestBound) operations_research::MPObjective::BestBound;

// MPSolverParameters API. For expert users only.
// TODO(user): unit test all of it.

%unignore operations_research::MPSolverParameters;  // no test
%unignore operations_research::MPSolverParameters::MPSolverParameters;  // no test

// Expose the MPSolverParameters::DoubleParam enum.
%unignore operations_research::MPSolverParameters::DoubleParam;  // no test
%unignore operations_research::MPSolverParameters::RELATIVE_MIP_GAP;  // no test
%unignore operations_research::MPSolverParameters::PRIMAL_TOLERANCE;  // no test
%unignore operations_research::MPSolverParameters::DUAL_TOLERANCE;  // no test
%rename (GetDoubleParam) operations_research::MPSolverParameters::GetDoubleParam;  // no test
%rename (SetDoubleParam) operations_research::MPSolverParameters::SetDoubleParam;  // no test
%unignore operations_research::MPSolverParameters::kDefaultRelativeMipGap;  // no test
%unignore operations_research::MPSolverParameters::kDefaultPrimalTolerance;  // no test
%unignore operations_research::MPSolverParameters::kDefaultDualTolerance;  // no test

// Expose the MPSolverParameters::IntegerParam enum.
%unignore operations_research::MPSolverParameters::IntegerParam;  // no test
%unignore operations_research::MPSolverParameters::PRESOLVE;  // no test
%unignore operations_research::MPSolverParameters::LP_ALGORITHM;  // no test
%unignore operations_research::MPSolverParameters::INCREMENTALITY;  // no test
%unignore operations_research::MPSolverParameters::SCALING;  // no test
%rename (GetIntegerParam) operations_research::MPSolverParameters::GetIntegerParam;  // no test
%rename (SetIntegerParam) operations_research::MPSolverParameters::SetIntegerParam;  // no test

// Expose the MPSolverParameters::PresolveValues enum.
%unignore operations_research::MPSolverParameters::PresolveValues;  // no test
%unignore operations_research::MPSolverParameters::PRESOLVE_OFF;  // no test
%unignore operations_research::MPSolverParameters::PRESOLVE_ON;  // no test
%unignore operations_research::MPSolverParameters::kDefaultPresolve;  // no test

// Expose the MPSolverParameters::LpAlgorithmValues enum.
%unignore operations_research::MPSolverParameters::LpAlgorithmValues;  // no test
%unignore operations_research::MPSolverParameters::DUAL;  // no test
%unignore operations_research::MPSolverParameters::PRIMAL;  // no test
%unignore operations_research::MPSolverParameters::BARRIER;  // no test

// Expose the MPSolverParameters::IncrementalityValues enum.
%unignore operations_research::MPSolverParameters::IncrementalityValues;  // no test
%unignore operations_research::MPSolverParameters::INCREMENTALITY_OFF;  // no test
%unignore operations_research::MPSolverParameters::INCREMENTALITY_ON;  // no test
%unignore operations_research::MPSolverParameters::kDefaultIncrementality;  // no test

// Expose the MPSolverParameters::ScalingValues enum.
%unignore operations_research::MPSolverParameters::ScalingValues;  // no test
%unignore operations_research::MPSolverParameters::SCALING_OFF;  // no test
%unignore operations_research::MPSolverParameters::SCALING_ON;  // no test

// Expose the model exporters.
%unignore operations_research::MPModelExportOptions;
%unignore operations_research::MPModelExportOptions::MPModelExportOptions;
//%typemap(javaclassmodifiers) operations_research::MPModelExportOptions
//    "public final class";
%rename (Obfuscate) operations_research::MPModelExportOptions::obfuscate;
%rename (LogInvalidNames) operations_research::MPModelExportOptions::log_invalid_names;
%rename (ShowUnusedVariables) operations_research::MPModelExportOptions::show_unused_variables;
%rename (MaxLineLength) operations_research::MPModelExportOptions::max_line_length;

%include "ortools/linear_solver/linear_solver.h"
%include "ortools/linear_solver/model_exporter.h"

%unignoreall
