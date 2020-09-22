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

// TODO(user): Refactor this file to adhere to the SWIG style guide.


//%include "enumsimple.swg"
%include "exception.i"

%include "ortools/base/base.i"
%include "ortools/util/go/tuple_set.i"
%include "ortools/util/go/vector.i"
%include "ortools/util/go/proto.i"

//%include "ortools/util/go/sorted_interval_list.i"

%go_import("github.com/golang/protobuf/proto")

// Remove swig warnings
%warnfilter(473) operations_research::DecisionBuilder;
%warnfilter(314); // Surpress warnings "'keyword' is a Go keyword, renaming to 'Xkeyword'"
// TODO(user): Remove this warnfilter.

// We need to forward-declare the proto here, so that PROTO_INPUT involving it
// works correctly. The order matters very much: this declaration needs to be
// before the %{ #include ".../constraint_solver.h" %}.
namespace operations_research {
class ConstraintSolverParameters;
class RegularLimitParameters;
class SortedDisjointIntervalList;
}  // namespace operations_research

// Include the files we want to wrap a first time.
%{
#include "ortools/constraint_solver/constraint_solver.h"
#include "ortools/constraint_solver/constraint_solveri.h"
// #include "ortools/constraint_solver/java/javawrapcp_util.h"
#include "ortools/constraint_solver/search_limit.pb.h"
#include "ortools/constraint_solver/solver_parameters.pb.h"

// Supporting structure for the PROTECT_FROM_FAILURE macro.
#include "setjmp.h"
struct FailureProtect {
  jmp_buf exception_buffer;
  void JumpBack() { longjmp(exception_buffer, 1); }
};

%}

// ############ BEGIN DUPLICATED CODE BLOCK ############
// IMPORTANT: keep this code block in sync with the .i
// files in ../python and ../csharp.

// Protect from failure.
%define PROTECT_FROM_FAILURE(Method, GetSolver)
%exception Method {
  operations_research::Solver* const solver = GetSolver;
  FailureProtect protect;
  solver->set_fail_intercept([&protect]() { protect.JumpBack(); });
  if (setjmp(protect.exception_buffer) == 0) {
    $action
    solver->clear_fail_intercept();
  } else {
    solver->clear_fail_intercept();
    _swig_gopanic("CP solver failure");
    return;
  }
}
%enddef

namespace operations_research {
PROTECT_FROM_FAILURE(IntExpr::SetValue(int64 v), arg1->solver());
PROTECT_FROM_FAILURE(IntExpr::SetMin(int64 v), arg1->solver());
PROTECT_FROM_FAILURE(IntExpr::SetMax(int64 v), arg1->solver());
PROTECT_FROM_FAILURE(IntExpr::SetRange(int64 l, int64 u), arg1->solver());
PROTECT_FROM_FAILURE(IntVar::RemoveValue(int64 v), arg1->solver());
PROTECT_FROM_FAILURE(IntVar::RemoveValues(const std::vector<int64>& values),
                     arg1->solver());
PROTECT_FROM_FAILURE(IntervalVar::SetStartMin(int64 m), arg1->solver());
PROTECT_FROM_FAILURE(IntervalVar::SetStartMax(int64 m), arg1->solver());
PROTECT_FROM_FAILURE(IntervalVar::SetStartRange(int64 mi, int64 ma),
                     arg1->solver());
PROTECT_FROM_FAILURE(IntervalVar::SetDurationMin(int64 m), arg1->solver());
PROTECT_FROM_FAILURE(IntervalVar::SetDurationMax(int64 m), arg1->solver());
PROTECT_FROM_FAILURE(IntervalVar::SetDurationRange(int64 mi, int64 ma),
                     arg1->solver());
PROTECT_FROM_FAILURE(IntervalVar::SetEndMin(int64 m), arg1->solver());
PROTECT_FROM_FAILURE(IntervalVar::SetEndMax(int64 m), arg1->solver());
PROTECT_FROM_FAILURE(IntervalVar::SetEndRange(int64 mi, int64 ma),
                     arg1->solver());
PROTECT_FROM_FAILURE(IntervalVar::SetPerformed(bool val), arg1->solver());
PROTECT_FROM_FAILURE(Solver::AddConstraint(Constraint* const c), arg1);
PROTECT_FROM_FAILURE(Solver::Fail(), arg1);
#undef PROTECT_FROM_FAILURE
}  // namespace operations_research

// ############ END DUPLICATED CODE BLOCK ############

// TupleSet depends on the previous typemaps
%include "ortools/util/go/tuple_set.i"

%{
#include <setjmp.h>
#include <vector>
//#include "ortools/constraint_solver/routing_types.h"
#include "ortools/base/integral_types.h"
#include "ortools/constraint_solver/constraint_solver.h"
#include "ortools/constraint_solver/constraint_solveri.h"
%}

// Use to correctly wrap Solver::MakeScheduleOrPostpone.
%apply int64 * INOUT { int64 *const marker };
// Use to correctly wrap arguments otherwise SWIG will wrap them as
// SWIGTYPE_p_long_long opaque pointer.
%apply int64 * OUTPUT { int64 *l, int64 *u, int64 *value };

// Types in Proxy class (e.g. Solver.java) e.g.:
// Solver::f(jstype $javainput, ...) {Solver_f_SWIG(javain, ...);}
#define VAR_ARGS(X...) X
// Methods taking parameters
%define DEFINE_ARGS_TO_R_CALLBACK(
  TYPE,
  GO_TYPE, GO_METHOD, GO_SIGN,
  LAMBDA_RETURN, JNI_METHOD, LAMBDA_PARAM, LAMBDA_CALL)
  %typemap(in) TYPE %{
    $1 = [$input]LAMBDA_PARAM -> LAMBDA_RETURN {
        return (CAST_DELEGATE$input)LAMBDA_CALL;
    };
  %}
  // These 4 typemaps tell SWIG which JNI and Java types to use.
  %typemap(ctype) TYPE "jobject" // Type used in the JNI C.
  %typemap(imtype) TYPE "GO_TYPE" // Type used in the JNI.java.
  %typemap(gotype) TYPE "GO_TYPE" // Type used in the Proxy class.
 // %typemap(goin) TYPE "$goinput" // passing the Callback to JNI java class.
%enddef

// Method taking no parameters
//%define DEFINE_VOID_TO_R_CALLBACK(
//  TYPE,
//  GO_TYPE, GO_METHOD, GO_SIGN,
//  LAMBDA_RETURN, JNI_METHOD)
//  %typemap(in) TYPE %{
//	  $1 = [$input]() -> std::string {
//	    std::string result;
//	    return result.assign((*(char* (*)()) $input)());
//	  };
//  %}
  // These 4 typemaps tell SWIG which JNI and Java types to use.
//  %typemap(ctype) TYPE "jobject" // Type used in the JNI C.
//  %typemap(imtype) TYPE "GO_TYPE" // Type used in the JNI.java.
//  %typemap(gotype) TYPE "GO_TYPE" // Type used in the Proxy class.
//  %typemap(goin) TYPE "$goinput" // passing the Callback to JNI java class.
//%enddef

// Method taking no parameters and returning a string
%define DEFINE_VOID_TO_STRING_CALLBACK(
  TYPE,
  GO_TYPE, GO_METHOD, GO_SIGN)
  %typemap(in) TYPE %{
      $1 = [$input]() -> std::string {
        std::string result;
        return result.assign((*(char* (*)()) $input)());
      };
  %}
  // These 4 typemaps tell SWIG which JNI and Java types to use.
  %typemap(ctype) TYPE "jobject" // Type used in the JNI C.
  %typemap(imtype) TYPE "GO_TYPE" // Type used in the JNI.java.
  %typemap(gotype) TYPE "GO_TYPE" // Type used in the Proxy class.
  //%typemap(goin) TYPE "$goinput" // passing the Callback to JNI java class.
%enddef

%{
#include <memory> // std::make_shared<GlobalRefGuard>
%}


#undef VAR_ARGS
#undef DEFINE_SOLVER_TO_VOID_CALLBACK
#undef DEFINE_ARGS_TO_R_CALLBACK
#undef DEFINE_VOID_TO_R_CALLBACK
#undef DEFINE_VOID_TO_STRING_CALLBACK

// Renaming
namespace operations_research {

// This method causes issues with our std::vector<int64> wrapping. It's not really
// part of the public API anyway.
%ignore ToInt64Vector;

// Decision
%feature("director") Decision;
%unignore Decision;
%rename (apply) Decision::Apply;
%rename (refute) Decision::Refute;

// DecisionBuilder
%feature("director") DecisionBuilder;
%unignore DecisionBuilder;
%rename (nextWrap) DecisionBuilder::Next;

// DecisionVisitor
%feature("director") DecisionVisitor;
%unignore DecisionVisitor;
%rename (VisitRankFirstInterval) DecisionVisitor::VisitRankFirstInterval;
%rename (VisitRankLastInterval) DecisionVisitor::VisitRankLastInterval;
%rename (VisitScheduleOrExpedite) DecisionVisitor::VisitScheduleOrExpedite;
%rename (VisitScheduleOrPostpone) DecisionVisitor::VisitScheduleOrPostpone;
%rename (VisitSetVariableValue) DecisionVisitor::VisitSetVariableValue;
%rename (VisitSplitVariableDomain) DecisionVisitor::VisitSplitVariableDomain;
%rename (VisitUnknownDecision) DecisionVisitor::VisitUnknownDecision;

// ModelVisitor
%unignore ModelVisitor;
%rename (BeginVisitConstraint) ModelVisitor::BeginVisitConstraint;
%rename (BeginVisitExtension) ModelVisitor::BeginVisitExtension;
%rename (BeginVisitIntegerExpression) ModelVisitor::BeginVisitIntegerExpression;
%rename (BeginVisitModel) ModelVisitor::BeginVisitModel;
%rename (EndVisitConstraint) ModelVisitor::EndVisitConstraint;
%rename (EndVisitExtension) ModelVisitor::EndVisitExtension;
%rename (EndVisitIntegerExpression) ModelVisitor::EndVisitIntegerExpression;
%rename (EndVisitModel) ModelVisitor::EndVisitModel;
%rename (VisitIntegerArgument) ModelVisitor::VisitIntegerArgument;
%rename (VisitIntegerArrayArgument) ModelVisitor::VisitIntegerArrayArgument;
%rename (VisitIntegerExpressionArgument) ModelVisitor::VisitIntegerExpressionArgument;
%rename (VisitIntegerMatrixArgument) ModelVisitor::VisitIntegerMatrixArgument;
%rename (VisitIntegerVariableArrayArgument) ModelVisitor::VisitIntegerVariableArrayArgument;
%rename (VisitIntegerVariable) ModelVisitor::VisitIntegerVariable;
%rename (VisitIntervalArgument) ModelVisitor::VisitIntervalArgument;
%rename (VisitIntervalArrayArgument) ModelVisitor::VisitIntervalArrayArgument;
%rename (VisitIntervalVariable) ModelVisitor::VisitIntervalVariable;
%rename (VisitSequenceArgument) ModelVisitor::VisitSequenceArgument;
%rename (VisitSequenceArrayArgument) ModelVisitor::VisitSequenceArrayArgument;
%rename (VisitSequenceVariable) ModelVisitor::VisitSequenceVariable;

// SymmetryBreaker
%feature("director") SymmetryBreaker;
%unignore SymmetryBreaker;
%rename (AddIntegerVariableEqualValueClause) SymmetryBreaker::AddIntegerVariableEqualValueClause;
%rename (AddIntegerVariableGreaterOrEqualValueClause) SymmetryBreaker::AddIntegerVariableGreaterOrEqualValueClause;
%rename (AddIntegerVariableLessOrEqualValueClause) SymmetryBreaker::AddIntegerVariableLessOrEqualValueClause;

// ModelCache
%unignore ModelCache;
%rename (clear) ModelCache::Clear;
%rename (findExprConstantExpression) ModelCache::FindExprConstantExpression;
%rename (findExprExprConstantExpression) ModelCache::FindExprExprConstantExpression;
%rename (findExprExprConstraint) ModelCache::FindExprExprConstraint;
%rename (findExprExpression) ModelCache::FindExprExpression;
%rename (findExprExprExpression) ModelCache::FindExprExprExpression;
%rename (findVarArrayConstantArrayExpression) ModelCache::FindVarArrayConstantArrayExpression;
%rename (findVarArrayConstantExpression) ModelCache::FindVarArrayConstantExpression;
%rename (findVarArrayExpression) ModelCache::FindVarArrayExpression;
%rename (findVarConstantArrayExpression) ModelCache::FindVarConstantArrayExpression;
%rename (findVarConstantConstantConstraint) ModelCache::FindVarConstantConstantConstraint;
%rename (findVarConstantConstantExpression) ModelCache::FindVarConstantConstantExpression;
%rename (findVarConstantConstraint) ModelCache::FindVarConstantConstraint;
%rename (findVoidConstraint) ModelCache::FindVoidConstraint;
%rename (insertExprConstantExpression) ModelCache::InsertExprConstantExpression;
%rename (insertExprExprConstantExpression) ModelCache::InsertExprExprConstantExpression;
%rename (insertExprExprConstraint) ModelCache::InsertExprExprConstraint;
%rename (insertExprExpression) ModelCache::InsertExprExpression;
%rename (insertExprExprExpression) ModelCache::InsertExprExprExpression;
%rename (insertVarArrayConstantArrayExpression) ModelCache::InsertVarArrayConstantArrayExpression;
%rename (insertVarArrayConstantExpression) ModelCache::InsertVarArrayConstantExpression;
%rename (insertVarArrayExpression) ModelCache::InsertVarArrayExpression;
%rename (insertVarConstantArrayExpression) ModelCache::InsertVarConstantArrayExpression;
%rename (insertVarConstantConstantConstraint) ModelCache::InsertVarConstantConstantConstraint;
%rename (insertVarConstantConstantExpression) ModelCache::InsertVarConstantConstantExpression;
%rename (insertVarConstantConstraint) ModelCache::InsertVarConstantConstraint;
%rename (insertVoidConstraint) ModelCache::InsertVoidConstraint;

// RevPartialSequence
%unignore RevPartialSequence;
%rename (isRanked) RevPartialSequence::IsRanked;
%rename (numFirstRanked) RevPartialSequence::NumFirstRanked;
%rename (numLastRanked) RevPartialSequence::NumLastRanked;
%rename (rankFirst) RevPartialSequence::RankFirst;
%rename (rankLast) RevPartialSequence::RankLast;
%rename (size) RevPartialSequence::Size;

// UnsortedNullableRevBitset
// TODO(user): Remove from constraint_solveri.h (only use by table.cc)
%ignore UnsortedNullableRevBitset;

// Assignment
%unignore Assignment;
%rename (activate) Assignment::Activate;
%rename (activateObjective) Assignment::ActivateObjective;
%rename (activated) Assignment::Activated;
%rename (activatedObjective) Assignment::ActivatedObjective;
%rename (add) Assignment::Add;
%rename (addObjective) Assignment::AddObjective;
%rename (backwardSequence) Assignment::BackwardSequence;
%rename (clear) Assignment::Clear;
%rename (contains) Assignment::Contains;
%rename (copy) Assignment::Copy;
%rename (copyIntersection) Assignment::CopyIntersection;
%rename (deactivate) Assignment::Deactivate;
%rename (deactivateObjective) Assignment::DeactivateObjective;
%rename (durationMax) Assignment::DurationMax;
%rename (durationMin) Assignment::DurationMin;
%rename (durationValue) Assignment::DurationValue;
%rename (empty) Assignment::Empty;
%rename (endMax) Assignment::EndMax;
%rename (endMin) Assignment::EndMin;
%rename (endValue) Assignment::EndValue;
%rename (fastAdd) Assignment::FastAdd;
%rename (forwardSequence) Assignment::ForwardSequence;
%rename (hasObjective) Assignment::HasObjective;
%rename (intVarContainer) Assignment::IntVarContainer;
%rename (intervalVarContainer) Assignment::IntervalVarContainer;
%rename (load) Assignment::Load;
%ignore Assignment::Load(const AssignmentProto&);
%rename (mutableIntVarContainer) Assignment::MutableIntVarContainer;
%rename (mutableIntervalVarContainer) Assignment::MutableIntervalVarContainer;
%rename (mutableSequenceVarContainer) Assignment::MutableSequenceVarContainer;
%rename (numIntVars) Assignment::NumIntVars;
%rename (numIntervalVars) Assignment::NumIntervalVars;
%rename (numSequenceVars) Assignment::NumSequenceVars;
%rename (objective) Assignment::Objective;
%rename (objectiveBound) Assignment::ObjectiveBound;
%rename (objectiveMax) Assignment::ObjectiveMax;
%rename (objectiveMin) Assignment::ObjectiveMin;
%rename (objectiveValue) Assignment::ObjectiveValue;
%rename (performedMax) Assignment::PerformedMax;
%rename (performedMin) Assignment::PerformedMin;
%rename (performedValue) Assignment::PerformedValue;
%rename (restore) Assignment::Restore;
%rename (save) Assignment::Save;
%ignore Assignment::Save(AssignmentProto* const) const;
%rename (size) Assignment::Size;
%rename (sequenceVarContainer) Assignment::SequenceVarContainer;
%rename (setBackwardSequence) Assignment::SetBackwardSequence;
%rename (setDurationMax) Assignment::SetDurationMax;
%rename (setDurationMin) Assignment::SetDurationMin;
%rename (setDurationRange) Assignment::SetDurationRange;
%rename (setDurationValue) Assignment::SetDurationValue;
%rename (setEndMax) Assignment::SetEndMax;
%rename (setEndMin) Assignment::SetEndMin;
%rename (setEndRange) Assignment::SetEndRange;
%rename (setEndValue) Assignment::SetEndValue;
%rename (setForwardSequence) Assignment::SetForwardSequence;
%rename (setObjectiveMax) Assignment::SetObjectiveMax;
%rename (setObjectiveMin) Assignment::SetObjectiveMin;
%rename (setObjectiveRange) Assignment::SetObjectiveRange;
%rename (setObjectiveValue) Assignment::SetObjectiveValue;
%rename (setPerformedMax) Assignment::SetPerformedMax;
%rename (setPerformedMin) Assignment::SetPerformedMin;
%rename (setPerformedRange) Assignment::SetPerformedRange;
%rename (setPerformedValue) Assignment::SetPerformedValue;
%rename (setSequence) Assignment::SetSequence;
%rename (setStartMax) Assignment::SetStartMax;
%rename (setStartMin) Assignment::SetStartMin;
%rename (setStartRange) Assignment::SetStartRange;
%rename (setStartValue) Assignment::SetStartValue;
%rename (setUnperformed) Assignment::SetUnperformed;
%rename (size) Assignment::Size;
%rename (startMax) Assignment::StartMax;
%rename (startMin) Assignment::StartMin;
%rename (startValue) Assignment::StartValue;
%rename (store) Assignment::Store;
%rename (unperformed) Assignment::Unperformed;

// template AssignmentContainer<>
%ignore AssignmentContainer::MutableElementOrNull;
%ignore AssignmentContainer::ElementPtrOrNull;
%ignore AssignmentContainer::elements;
%rename (add) AssignmentContainer::Add;
%rename (addAtPosition) AssignmentContainer::AddAtPosition;
%rename (clear) AssignmentContainer::Clear;
%rename (element) AssignmentContainer::Element;
%rename (fastAdd) AssignmentContainer::FastAdd;
%rename (resize) AssignmentContainer::Resize;
%rename (empty) AssignmentContainer::Empty;
%rename (copy) AssignmentContainer::Copy;
%rename (copyIntersection) AssignmentContainer::CopyIntersection;
%rename (contains) AssignmentContainer::Contains;
%rename (mutableElement) AssignmentContainer::MutableElement;
%rename (size) AssignmentContainer::Size;
%rename (store) AssignmentContainer::Store;
%rename (restore) AssignmentContainer::Restore;

// AssignmentElement
%unignore AssignmentElement;
%rename (activate) AssignmentElement::Activate;
%rename (deactivate) AssignmentElement::Deactivate;
%rename (activated) AssignmentElement::Activated;

// IntVarElement
%unignore IntVarElement;
%ignore IntVarElement::LoadFromProto;
%ignore IntVarElement::WriteToProto;
%rename (reset) IntVarElement::Reset;
%rename (clone) IntVarElement::Clone;
%rename (copy) IntVarElement::Copy;
%rename (store) IntVarElement::Store;
%rename (restore) IntVarElement::Restore;
%rename (min) IntVarElement::Min;
%rename (setMin) IntVarElement::SetMin;
%rename (max) IntVarElement::Max;
%rename (setMax) IntVarElement::SetMax;
%rename (value) IntVarElement::Value;
%rename (setValue) IntVarElement::SetValue;
%rename (setRange) IntVarElement::SetRange;
%rename (var) IntVarElement::Var;

// IntervalVarElement
%unignore IntervalVarElement;
%ignore IntervalVarElement::LoadFromProto;
%ignore IntervalVarElement::WriteToProto;
%rename (clone) IntervalVarElement::Clone;
%rename (copy) IntervalVarElement::Copy;
%rename (durationMax) IntervalVarElement::DurationMax;
%rename (durationMin) IntervalVarElement::DurationMin;
%rename (durationValue) IntervalVarElement::DurationValue;
%rename (endMax) IntervalVarElement::EndMax;
%rename (endMin) IntervalVarElement::EndMin;
%rename (endValue) IntervalVarElement::EndValue;
%rename (performedMax) IntervalVarElement::PerformedMax;
%rename (performedMin) IntervalVarElement::PerformedMin;
%rename (performedValue) IntervalVarElement::PerformedValue;
%rename (reset) IntervalVarElement::Reset;
%rename (restore) IntervalVarElement::Restore;
%rename (setDurationMax) IntervalVarElement::SetDurationMax;
%rename (setDurationMin) IntervalVarElement::SetDurationMin;
%rename (setDurationRange) IntervalVarElement::SetDurationRange;
%rename (setDurationValue) IntervalVarElement::SetDurationValue;
%rename (setEndMax) IntervalVarElement::SetEndMax;
%rename (setEndMin) IntervalVarElement::SetEndMin;
%rename (setEndRange) IntervalVarElement::SetEndRange;
%rename (setEndValue) IntervalVarElement::SetEndValue;
%rename (setPerformedMax) IntervalVarElement::SetPerformedMax;
%rename (setPerformedMin) IntervalVarElement::SetPerformedMin;
%rename (setPerformedRange) IntervalVarElement::SetPerformedRange;
%rename (setPerformedValue) IntervalVarElement::SetPerformedValue;
%rename (setStartMax) IntervalVarElement::SetStartMax;
%rename (setStartMin) IntervalVarElement::SetStartMin;
%rename (setStartRange) IntervalVarElement::SetStartRange;
%rename (setStartValue) IntervalVarElement::SetStartValue;
%rename (startMax) IntervalVarElement::StartMax;
%rename (startMin) IntervalVarElement::StartMin;
%rename (startValue) IntervalVarElement::StartValue;
%rename (store) IntervalVarElement::Store;
%rename (var) IntervalVarElement::Var;

// SequenceVarElement
%unignore SequenceVarElement;
%ignore SequenceVarElement::LoadFromProto;
%ignore SequenceVarElement::WriteToProto;
%rename (BackwardSequence) SequenceVarElement::BackwardSequence;
%rename (Clone) SequenceVarElement::Clone;
%rename (Copy) SequenceVarElement::Copy;
%rename (ForwardSequence) SequenceVarElement::ForwardSequence;
%rename (Reset) SequenceVarElement::Reset;
%rename (Restore) SequenceVarElement::Restore;
%rename (SetBackwardSequence) SequenceVarElement::SetBackwardSequence;
%rename (SetForwardSequence) SequenceVarElement::SetForwardSequence;
%rename (SetSequence) SequenceVarElement::SetSequence;
%rename (SetUnperformed) SequenceVarElement::SetUnperformed;
%rename (Store) SequenceVarElement::Store;
%rename (Unperformed) SequenceVarElement::Unperformed;
%rename (Var) SequenceVarElement::Var;

// SolutionCollector
%unignore SolutionCollector;
%rename (Add) SolutionCollector::Add;
%rename (AddObjective) SolutionCollector::AddObjective;
%rename (BackwardSequence) SolutionCollector::BackwardSequence;
%rename (DurationValue) SolutionCollector::DurationValue;
%rename (EndValue) SolutionCollector::EndValue;
%rename (ForwardSequence) SolutionCollector::ForwardSequence;
%rename (ObjectiveValue) SolutionCollector::objective_value;
%rename (PerformedValue) SolutionCollector::PerformedValue;
%rename (SolutionCount) SolutionCollector::solution_count;
%rename (StartValue) SolutionCollector::StartValue;
%rename (Unperformed) SolutionCollector::Unperformed;
%rename (WallTime) SolutionCollector::wall_time;

// SolutionPool
%unignore SolutionPool;
%rename (getNextSolution) SolutionPool::GetNextSolution;
%rename (initialize) SolutionPool::Initialize;
%rename (registerNewSolution) SolutionPool::RegisterNewSolution;
%rename (syncNeeded) SolutionPool::SyncNeeded;

// Solver
%unignore Solver;

// note: SWIG does not support multiple %typemap(javacode) Type, so we have to
// define all Solver tweak here (ed and not in the macro DEFINE_CALLBACK_*)
%typemap(javacode) Solver %{
  /**
   * This exceptions signal that a failure has been raised in the C++ world.
   */
  public static class FailException extends Exception {
    public FailException() {
      super();
    }

    public FailException(String message) {
      super(message);
    }
  }

  public IntVar[] makeIntVarArray(int count, long min, long max) {
    IntVar[] array = new IntVar[count];
    for (int i = 0; i < count; ++i) {
      array[i] = makeIntVar(min, max);
    }
    return array;
  }

  public IntVar[] makeIntVarArray(int count, long min, long max, String name) {
    IntVar[] array = new IntVar[count];
    for (int i = 0; i < count; ++i) {
      String var_name = name + i;
      array[i] = makeIntVar(min, max, var_name);
    }
    return array;
  }

  public IntVar[] makeBoolVarArray(int count) {
    IntVar[] array = new IntVar[count];
    for (int i = 0; i < count; ++i) {
      array[i] = makeBoolVar();
    }
    return array;
  }

  public IntVar[] makeBoolVarArray(int count, String name) {
    IntVar[] array = new IntVar[count];
    for (int i = 0; i < count; ++i) {
      String var_name = name + i;
      array[i] = makeBoolVar(var_name);
    }
    return array;
  }

  public IntervalVar[] makeFixedDurationIntervalVarArray(int count,
                                                         long start_min,
                                                         long start_max,
                                                         long duration,
                                                         boolean optional) {
    IntervalVar[] array = new IntervalVar[count];
    for (int i = 0; i < count; ++i) {
      array[i] = makeFixedDurationIntervalVar(start_min,
                                              start_max,
                                              duration,
                                              optional,
                                              "");
    }
    return array;
  }

  public IntervalVar[] makeFixedDurationIntervalVarArray(int count,
                                                         long start_min,
                                                         long start_max,
                                                         long duration,
                                                         boolean optional,
                                                         String name) {
    IntervalVar[] array = new IntervalVar[count];
    for (int i = 0; i < count; ++i) {
      array[i] = makeFixedDurationIntervalVar(start_min,
                                              start_max,
                                              duration,
                                              optional,
                                              name + i);
    }
    return array;
  }
%}
%ignore Solver::SearchLogParameters;
%ignore Solver::ActiveSearch;
%ignore Solver::SetSearchContext;
%ignore Solver::SearchContext;
%ignore Solver::MakeSearchLog(SearchLogParameters parameters);
%ignore Solver::MakeIntVarArray;
%ignore Solver::MakeIntervalVarArray;
%ignore Solver::MakeBoolVarArray;
%ignore Solver::MakeFixedDurationIntervalVarArray;
%ignore Solver::SetBranchSelector;
%ignore Solver::MakeApplyBranchSelector;
%ignore Solver::MakeAtMost;
%ignore Solver::Now;
%ignore Solver::demon_profiler;
%ignore Solver::set_fail_intercept;

// LocalSearchPhaseParameters
%unignore LocalSearchPhaseParameters;

%unignore Solver::Solver;
%rename (AcceptedNeighbors) Solver::accepted_neighbors;
%rename (AddBacktrackAction) Solver::AddBacktrackAction;
%rename (AddCastConstraint) Solver::AddCastConstraint;
%rename (AddConstraint) Solver::AddConstraint;
%rename (AddLocalSearchMonitor) Solver::AddLocalSearchMonitor;
%rename (AddPropagationMonitor) Solver::AddPropagationMonitor;
%rename (Cache) Solver::Cache;
%rename (CastExpression) Solver::CastExpression;
%rename (CheckAssignment) Solver::CheckAssignment;
%rename (CheckConstraint) Solver::CheckConstraint;
%rename (CheckFail) Solver::CheckFail;
%rename (Compose) Solver::Compose;
%rename (ConcatenateOperators) Solver::ConcatenateOperators;
%rename (CurrentlyInSolve) Solver::CurrentlyInSolve;
%rename (DefaultSolverParameters) Solver::DefaultSolverParameters;
%rename (EndSearch) Solver::EndSearch;
%rename (ExportProfilingOverview) Solver::ExportProfilingOverview;
%rename (Fail) Solver::Fail;
%rename (FilteredNeighbors) Solver::filtered_neighbors;
%rename (FinishCurrentSearch) Solver::FinishCurrentSearch;
%rename (GetLocalSearchMonitor) Solver::GetLocalSearchMonitor;
%rename (GetPropagationMonitor) Solver::GetPropagationMonitor;
%rename (GetTime) Solver::GetTime;
%rename (HasName) Solver::HasName;
%rename (InstrumentsDemons) Solver::InstrumentsDemons;
%rename (InstrumentsVariables) Solver::InstrumentsVariables;
%rename (IsLocalSearchProfilingEnabled) Solver::IsLocalSearchProfilingEnabled;
%rename (IsProfilingEnabled) Solver::IsProfilingEnabled;
%rename (LocalSearchProfile) Solver::LocalSearchProfile;
%rename (MakeAbs) Solver::MakeAbs;
%rename (MakeAbsEquality) Solver::MakeAbsEquality;
%rename (MakeAllDifferent) Solver::MakeAllDifferent;
%rename (MakeAllDifferentExcept) Solver::MakeAllDifferentExcept;
%rename (MakeAllSolutionCollector) Solver::MakeAllSolutionCollector;
%rename (MakeAllowedAssignment) Solver::MakeAllowedAssignments;
%rename (MakeAssignVariableValue) Solver::MakeAssignVariableValue;
%rename (MakeAssignVariableValueOrFail) Solver::MakeAssignVariableValueOrFail;
%rename (MakeAssignVariablesValues) Solver::MakeAssignVariablesValues;
%rename (MakeAssignment) Solver::MakeAssignment;
%rename (MakeAtSolutionCallback) Solver::MakeAtSolutionCallback;
%rename (MakeBestValueSolutionCollector) Solver::MakeBestValueSolutionCollector;
%rename (MakeBetweenCt) Solver::MakeBetweenCt;
%rename (MakeBoolVar) Solver::MakeBoolVar;
%rename (MakeBranchesLimit) Solver::MakeBranchesLimit;
%rename (MakeCircuit) Solver::MakeCircuit;
%rename (MakeClosureDemon) Solver::MakeClosureDemon;
%rename (MakeConditionalExpression) Solver::MakeConditionalExpression;
%rename (MakeConstantRestart) Solver::MakeConstantRestart;
%rename (MakeConstraintAdder) Solver::MakeConstraintAdder;
%rename (MakeConstraintInitialPropagateCallback) Solver::MakeConstraintInitialPropagateCallback;
%rename (MakeConvexPiecewiseExpr) Solver::MakeConvexPiecewiseExpr;
%rename (MakeCount) Solver::MakeCount;
%rename (MakeCover) Solver::MakeCover;
%rename (MakeCumulative) Solver::MakeCumulative;
%rename (MakeCustomLimit) Solver::MakeCustomLimit;
%rename (MakeDecision) Solver::MakeDecision;
%rename (MakeDecisionBuilderFromAssignment) Solver::MakeDecisionBuilderFromAssignment;
%rename (MakeDefaultPhase) Solver::MakeDefaultPhase;
%rename (MakeDefaultRegularLimitParameters) Solver::MakeDefaultRegularLimitParameters;
%rename (MakeDefaultSolutionPool) Solver::MakeDefaultSolutionPool;
%rename (MakeDelayedConstraintInitialPropagateCallback) Solver::MakeDelayedConstraintInitialPropagateCallback;
%rename (MakeDelayedPathCumul) Solver::MakeDelayedPathCumul;
%rename (MakeDeviation) Solver::MakeDeviation;
%rename (MakeDifference) Solver::MakeDifference;
%rename (MakeDisjunctiveConstraint) Solver::MakeDisjunctiveConstraint;
%rename (MakeDistribute) Solver::MakeDistribute;
%rename (MakeDiv) Solver::MakeDiv;
%rename (MakeElement) Solver::MakeElement;
%rename (MakeElementEquality) Solver::MakeElementEquality;
%rename (MakeEnterSearchCallback) Solver::MakeEnterSearchCallback;
%rename (MakeEquality) Solver::MakeEquality;
%rename (MakeExitSearchCallback) Solver::MakeExitSearchCallback;
%rename (MakeFailDecision) Solver::MakeFailDecision;
%rename (MakeFailuresLimit) Solver::MakeFailuresLimit;
%rename (MakeFalseConstraint) Solver::MakeFalseConstraint;
%rename (MakeFirstSolutionCollector) Solver::MakeFirstSolutionCollector;
%rename (MakeFixedDurationEndSyncedOnEndIntervalVar) Solver::MakeFixedDurationEndSyncedOnEndIntervalVar;
%rename (MakeFixedDurationEndSyncedOnStartIntervalVar) Solver::MakeFixedDurationEndSyncedOnStartIntervalVar;
%rename (MakeFixedDurationIntervalVar) Solver::MakeFixedDurationIntervalVar;
%rename (MakeFixedDurationStartSyncedOnEndIntervalVar) Solver::MakeFixedDurationStartSyncedOnEndIntervalVar;
%rename (MakeFixedDurationStartSyncedOnStartIntervalVar) Solver::MakeFixedDurationStartSyncedOnStartIntervalVar;
%rename (MakeFixedInterval) Solver::MakeFixedInterval;
%rename (MakeGenericTabuSearch) Solver::MakeGenericTabuSearch;
%rename (MakeGreater) Solver::MakeGreater;
%rename (MakeGreaterOrEqual) Solver::MakeGreaterOrEqual;
%rename (MakeGuidedLocalSearch) Solver::MakeGuidedLocalSearch;
%rename (MakeIfThenElseCt) Solver::MakeIfThenElseCt;
%rename (MakeIndexExpression) Solver::MakeIndexExpression;
%rename (MakeIndexOfConstraint) Solver::MakeIndexOfConstraint;
%rename (MakeIndexOfFirstMaxValueConstraint) Solver::MakeIndexOfFirstMaxValueConstraint;
%rename (MakeIndexOfFirstMinValueConstraint) Solver::MakeIndexOfFirstMinValueConstraint;
%rename (MakeIntConst) Solver::MakeIntConst;
%rename (MakeIntVar) Solver::MakeIntVar;
%rename (MakeIntervalRelaxedMax) Solver::MakeIntervalRelaxedMax;
%rename (MakeIntervalRelaxedMin) Solver::MakeIntervalRelaxedMin;
%rename (MakeIntervalVar) Solver::MakeIntervalVar;
%rename (MakeIntervalVarRelation) Solver::MakeIntervalVarRelation;
%rename (MakeIntervalVarRelationWithDelay) Solver::MakeIntervalVarRelationWithDelay;
%rename (MakeInversePermutationConstraint) Solver::MakeInversePermutationConstraint;
%rename (MakeIsBetweenCt) Solver::MakeIsBetweenCt;
%rename (MakeIsBetweenVar) Solver::MakeIsBetweenVar;
%rename (MakeIsDifferentCstCt) Solver::MakeIsDifferentCstCt;
%rename (MakeIsDifferentCstCt) Solver::MakeIsDifferentCt;
%rename (MakeIsDifferentCstVar) Solver::MakeIsDifferentCstVar;
%rename (MakeIsDifferentCstVar) Solver::MakeIsDifferentVar;
%rename (MakeIsEqualCstCt) Solver::MakeIsEqualCstCt;
%rename (MakeIsEqualCstVar) Solver::MakeIsEqualCstVar;
%rename (MakeIsEqualVar) Solver::MakeIsEqualCt;
%rename (MakeIsEqualVar) Solver::MakeIsEqualVar;
%rename (MakeIsGreaterCstCt) Solver::MakeIsGreaterCstCt;
%rename (MakeIsGreaterCstVar) Solver::MakeIsGreaterCstVar;
%rename (MakeIsGreaterCt) Solver::MakeIsGreaterCt;
%rename (MakeIsGreaterOrEqualCstCt) Solver::MakeIsGreaterOrEqualCstCt;
%rename (MakeIsGreaterOrEqualCstVar) Solver::MakeIsGreaterOrEqualCstVar;
%rename (MakeIsGreaterOrEqualCt) Solver::MakeIsGreaterOrEqualCt;
%rename (MakeIsGreaterOrEqualVar) Solver::MakeIsGreaterOrEqualVar;
%rename (MakeIsGreaterVar) Solver::MakeIsGreaterVar;
%rename (MakeIsLessCstCt) Solver::MakeIsLessCstCt;
%rename (MakeIsLessCstVar) Solver::MakeIsLessCstVar;
%rename (MakeIsLessCt) Solver::MakeIsLessCt;
%rename (MakeIsLessOrEqualCstCt) Solver::MakeIsLessOrEqualCstCt;
%rename (MakeIsLessOrEqualCstVar) Solver::MakeIsLessOrEqualCstVar;
%rename (MakeIsLessOrEqualCt) Solver::MakeIsLessOrEqualCt;
%rename (MakeIsLessOrEqualVar) Solver::MakeIsLessOrEqualVar;
%rename (MakeIsLessVar) Solver::MakeIsLessVar;
%rename (MakeIsMemberCt) Solver::MakeIsMemberCt;
%rename (MakeIsMemberVar) Solver::MakeIsMemberVar;
%rename (MakeLastSolutionCollector) Solver::MakeLastSolutionCollector;
%rename (MakeLess) Solver::MakeLess;
%rename (MakeLessOrEqual) Solver::MakeLessOrEqual;
%rename (MakeLexicalLess) Solver::MakeLexicalLess;
%rename (MakeLexicalLessOrEqual) Solver::MakeLexicalLessOrEqual;
%rename (MakeLimit) Solver::MakeLimit;
%rename (MakeLocalSearchPhase) Solver::MakeLocalSearchPhase;
%rename (MakeLocalSearchPhaseParameters) Solver::MakeLocalSearchPhaseParameters;
%rename (MakeLubyRestart) Solver::MakeLubyRestart;
%rename (MakeMapDomain) Solver::MakeMapDomain;
%rename (MakeMax) Solver::MakeMax;
%rename (MakeMaxEquality) Solver::MakeMaxEquality;
%rename (MakeMaximize) Solver::MakeMaximize;
%rename (MakeMemberCt) Solver::MakeMemberCt;
%rename (MakeMin) Solver::MakeMin;
%rename (MakeMinEquality) Solver::MakeMinEquality;
%rename (MakeMinimize) Solver::MakeMinimize;
%rename (MakeMirrorInterval) Solver::MakeMirrorInterval;
%rename (MakeModulo) Solver::MakeModulo;
%rename (MakeMonotonicElement) Solver::MakeMonotonicElement;
%rename (MakeMoveTowardTargetOperator) Solver::MakeMoveTowardTargetOperator;
%rename (MakeNBestValueSolutionCollector) Solver::MakeNBestValueSolutionCollector;
%rename (MakeNeighborhoodLimit) Solver::MakeNeighborhoodLimit;
%rename (MakeNestedOptimize) Solver::MakeNestedOptimize;
%rename (MakeNoCycle) Solver::MakeNoCycle;
%rename (MakeNonEquality) Solver::MakeNonEquality;
%rename (MakeNonOverlappingBoxesConstraint) Solver::MakeNonOverlappingBoxesConstraint;
%rename (MakeNonOverlappingNonStrictBoxesConstraint) Solver::MakeNonOverlappingNonStrictBoxesConstraint;
%rename (MakeNotBetweenCt) Solver::MakeNotBetweenCt;
%rename (MakeNotMemberCt) Solver::MakeNotMemberCt;
%rename (MakeNullIntersect) Solver::MakeNullIntersect;
%rename (MakeNullIntersectExcept) Solver::MakeNullIntersectExcept;
%rename (MakeOperator) Solver::MakeOperator;
%rename (MakeOpposite) Solver::MakeOpposite;
%rename (MakeOptimize) Solver::MakeOptimize;
%rename (MakePack) Solver::MakePack;
%rename (MakePathConnected) Solver::MakePathConnected;
%rename (MakePathCumul) Solver::MakePathCumul;
%rename (MakePhase) Solver::MakePhase;
%rename (MakePower) Solver::MakePower;
%rename (MakePrintModelVisitor) Solver::MakePrintModelVisitor;
%rename (MakeProd) Solver::MakeProd;
%rename (MakeRandomLnsOperator) Solver::MakeRandomLnsOperator;
%rename (MakeRankFirstInterval) Solver::MakeRankFirstInterval;
%rename (MakeRankLastInterval) Solver::MakeRankLastInterval;
%rename (MakeRestoreAssignment) Solver::MakeRestoreAssignment;
%rename (MakeScalProd) Solver::MakeScalProd;
%rename (MakeScalProdEquality) Solver::MakeScalProdEquality;
%rename (MakeScalProdGreaterOrEqual) Solver::MakeScalProdGreaterOrEqual;
%rename (MakeScalProdLessOrEqual) Solver::MakeScalProdLessOrEqual;
%rename (MakeScheduleOrExpedite) Solver::MakeScheduleOrExpedite;
%rename (MakeScheduleOrPostpone) Solver::MakeScheduleOrPostpone;
%rename (MakeSearchLog) Solver::MakeSearchLog;
%rename (MakeSearchTrace) Solver::MakeSearchTrace;
%rename (MakeSemiContinuousExpr) Solver::MakeSemiContinuousExpr;
%rename (MakeSequenceVar) Solver::MakeSequenceVar;
%rename (MakeSimulatedAnnealing) Solver::MakeSimulatedAnnealing;
%rename (MakeSolutionsLimit) Solver::MakeSolutionsLimit;
%rename (MakeSolveOnce) Solver::MakeSolveOnce;
%rename (MakeSortingConstraint) Solver::MakeSortingConstraint;
%rename (MakeSplitVariableDomain) Solver::MakeSplitVariableDomain;
%rename (MakeSquare) Solver::MakeSquare;
%rename (MakeStatisticsModelVisitor) Solver::MakeStatisticsModelVisitor;
%rename (MakeStoreAssignment) Solver::MakeStoreAssignment;
%rename (MakeStrictDisjunctiveConstraint) Solver::MakeStrictDisjunctiveConstraint;
%rename (MakeSubCircuit) Solver::MakeSubCircuit;
%rename (MakeSum) Solver::MakeSum;
%rename (MakeSumEquality) Solver::MakeSumEquality;
%rename (MakeSumGreaterOrEqual) Solver::MakeSumGreaterOrEqual;
%rename (MakeSumLessOrEqual) Solver::MakeSumLessOrEqual;
%rename (MakeSumObjectiveFilter) Solver::MakeSumObjectiveFilter;
%rename (MakeSymmetryManager) Solver::MakeSymmetryManager;
%rename (MakeTabuSearch) Solver::MakeTabuSearch;
%rename (MakeTemporalDisjunction) Solver::MakeTemporalDisjunction;
%rename (MakeTimeLimit) Solver::MakeTimeLimit;
%rename (MakeTransitionConstraint) Solver::MakeTransitionConstraint;
%rename (MakeTreeMonitor) Solver::MakeTreeMonitor;
%rename (MakeTrueConstraint) Solver::MakeTrueConstraint;
%rename (MakeVariableDomainFilter) Solver::MakeVariableDomainFilter;
%rename (MakeVariableGreaterOrEqualValue) Solver::MakeVariableGreaterOrEqualValue;
%rename (MakeVariableLessOrEqualValue) Solver::MakeVariableLessOrEqualValue;
%rename (MakeWeightedMaximize) Solver::MakeWeightedMaximize;
%rename (MakeWeightedMinimize) Solver::MakeWeightedMinimize;
%rename (MakeWeightedOptimize) Solver::MakeWeightedOptimize;
%rename (MemoryUsage) Solver::MemoryUsage;
%rename (NameAllVariables) Solver::NameAllVariables;
%rename (NewSearch) Solver::NewSearch;
%rename (NextSolution) Solver::NextSolution;
%rename (PopState) Solver::PopState;
%rename (PushState) Solver::PushState;
%rename (Rand32) Solver::Rand32;
%rename (Rand64) Solver::Rand64;
%rename (RandomConcatenateOperators) Solver::RandomConcatenateOperators;
%rename (ReSeed) Solver::ReSeed;
%rename (RegisterDemon) Solver::RegisterDemon;
%rename (RegisterIntExpr) Solver::RegisterIntExpr;
%rename (RegisterIntVar) Solver::RegisterIntVar;
%rename (RegisterIntervalVar) Solver::RegisterIntervalVar;
%rename (RestartCurrentSearch) Solver::RestartCurrentSearch;
%rename (RestartSearch) Solver::RestartSearch;
%rename (SearchDepth) Solver::SearchDepth;
%rename (SearchLeftDepth) Solver::SearchLeftDepth;
%rename (ShouldFail) Solver::ShouldFail;
%rename (solve) Solver::Solve;
%rename (SolveAndCommit) Solver::SolveAndCommit;
%rename (SolveDepth) Solver::SolveDepth;
%rename (TopPeriodicCheck) Solver::TopPeriodicCheck;
%rename (TopProgressPercent) Solver::TopProgressPercent;
%rename (TryDecisions) Solver::Try;
%rename (UpdateLimits) Solver::UpdateLimits;
%rename (WallTime) Solver::wall_time;


// BaseIntExpr
%unignore BaseIntExpr;
%rename (CastToVar) BaseIntExpr::CastToVar;

// IntExpr
%unignore IntExpr;
%rename (IsVar) IntExpr::IsVar;
%rename (Range) IntExpr::Range;
%rename (Var) IntExpr::Var;
%rename (VarWithName) IntExpr::VarWithName;
%rename (WhenRange) IntExpr::WhenRange;

// IntVar
%unignore IntVar;
%rename (AddName) IntVar::AddName;
%rename (Contains) IntVar::Contains;
%rename (IsDifferent) IntVar::IsDifferent;
%rename (IsEqual) IntVar::IsEqual;
%rename (IsGreaterOrEqual) IntVar::IsGreaterOrEqual;
%rename (IsLessOrEqual) IntVar::IsLessOrEqual;
%rename (MakeDomainIterator) IntVar::MakeDomainIterator;
%rename (MakeHoleIterator) IntVar::MakeHoleIterator;
%rename (OldMax) IntVar::OldMax;
%rename (OldMin) IntVar::OldMin;
%rename (RemoveInterval) IntVar::RemoveInterval;
%rename (RemoveValue) IntVar::RemoveValue;
%rename (RemoveValues) IntVar::RemoveValues;
%rename (Size) IntVar::Size;
%rename (VarType) IntVar::VarType;
%rename (WhenBound) IntVar::WhenBound;
%rename (WhenDomain) IntVar::WhenDomain;

// IntVarIterator
%unignore IntVarIterator;
%rename (Init) IntVarIterator::Init;
%rename (Next) IntVarIterator::Next;
%rename (Ok) IntVarIterator::Ok;

// BooleanVar
%unignore BooleanVar;
%rename (BaseName) BooleanVar::BaseName;
%rename (IsDifferent) BooleanVar::IsDifferent;
%rename (IsEqual) BooleanVar::IsEqual;
%rename (IsGreaterOrEqual) BooleanVar::IsGreaterOrEqual;
%rename (IsLessOrEqual) BooleanVar::IsLessOrEqual;
%rename (MakeDomainIterator) BooleanVar::MakeDomainIterator;
%rename (MakeHoleIterator) BooleanVar::MakeHoleIterator;
%rename (RawValue) BooleanVar::RawValue;
%rename (RestoreValue) BooleanVar::RestoreValue;
%rename (Size) BooleanVar::Size;
%rename (VarType) BooleanVar::VarType;
%rename (WhenBound) BooleanVar::WhenBound;
%rename (WhenDomain) BooleanVar::WhenDomain;
%rename (WhenRange) BooleanVar::WhenRange;

// IntervalVar
%unignore IntervalVar;
%rename (CannotBePerformed) IntervalVar::CannotBePerformed;
%rename (DurationExpr) IntervalVar::DurationExpr;
%rename (DurationMax) IntervalVar::DurationMax;
%rename (DurationMin) IntervalVar::DurationMin;
%rename (EndExpr) IntervalVar::EndExpr;
%rename (EndMax) IntervalVar::EndMax;
%rename (EndMin) IntervalVar::EndMin;
%rename (IsPerformedBound) IntervalVar::IsPerformedBound;
%rename (MayBePerformed) IntervalVar::MayBePerformed;
%rename (MustBePerformed) IntervalVar::MustBePerformed;
%rename (OldDurationMax) IntervalVar::OldDurationMax;
%rename (OldDurationMin) IntervalVar::OldDurationMin;
%rename (OldEndMax) IntervalVar::OldEndMax;
%rename (OldEndMin) IntervalVar::OldEndMin;
%rename (OldStartMax) IntervalVar::OldStartMax;
%rename (OldStartMin) IntervalVar::OldStartMin;
%rename (PerformedExpr) IntervalVar::PerformedExpr;
%rename (SafeDurationExpr) IntervalVar::SafeDurationExpr;
%rename (SafeEndExpr) IntervalVar::SafeEndExpr;
%rename (SafeStartExpr) IntervalVar::SafeStartExpr;
%rename (SetDurationMax) IntervalVar::SetDurationMax;
%rename (SetDurationMin) IntervalVar::SetDurationMin;
%rename (SetDurationRange) IntervalVar::SetDurationRange;
%rename (SetEndMax) IntervalVar::SetEndMax;
%rename (SetEndMin) IntervalVar::SetEndMin;
%rename (SetEndRange) IntervalVar::SetEndRange;
%rename (SetPerformed) IntervalVar::SetPerformed;
%rename (SetStartMax) IntervalVar::SetStartMax;
%rename (SetStartMin) IntervalVar::SetStartMin;
%rename (SetStartRange) IntervalVar::SetStartRange;
%rename (StartExpr) IntervalVar::StartExpr;
%rename (StartMax) IntervalVar::StartMax;
%rename (StartMin) IntervalVar::StartMin;
%rename (WasPerformedBound) IntervalVar::WasPerformedBound;
%rename (WhenAnything) IntervalVar::WhenAnything;
%rename (WhenDurationBound) IntervalVar::WhenDurationBound;
%rename (WhenDurationRange) IntervalVar::WhenDurationRange;
%rename (WhenEndBound) IntervalVar::WhenEndBound;
%rename (WhenEndRange) IntervalVar::WhenEndRange;
%rename (WhenPerformedBound) IntervalVar::WhenPerformedBound;
%rename (WhenStartBound) IntervalVar::WhenStartBound;
%rename (WhenStartRange) IntervalVar::WhenStartRange;

// OptimizeVar
%unignore OptimizeVar;
%rename (ApplyBound) OptimizeVar::ApplyBound;
%rename (Print) OptimizeVar::Print;
%rename (Var) OptimizeVar::Var;

// SequenceVar
%unignore SequenceVar;
%ignore SequenceVar::ComputePossibleFirstsAndLasts;
%ignore SequenceVar::FillSequence;
%rename (RankFirst) SequenceVar::RankFirst;
%rename (RankLast) SequenceVar::RankLast;
%rename (RankNotFirst) SequenceVar::RankNotFirst;
%rename (RankNotLast) SequenceVar::RankNotLast;
%rename (RankSequence) SequenceVar::RankSequence;
%rename (Interval) SequenceVar::Interval;
%rename (Next) SequenceVar::Next;

// Constraint
%unignore Constraint;
%rename (InitialPropagate) Constraint::InitialPropagate;
%rename (IsCastConstraint) Constraint::IsCastConstraint;
%rename (PostAndPropagate) Constraint::PostAndPropagate;
%rename (Post) Constraint::Post;
%rename (Var) Constraint::Var;

// DisjunctiveConstraint
%unignore DisjunctiveConstraint;
%typemap(javaimports) DisjunctiveConstraint %{
// Used to wrap IndexEvaluator2
// see https://docs.oracle.com/javase/8/docs/api/java/util/function/LongBinaryOperator.html
import java.util.function.LongBinaryOperator;
%}
%rename (MakeSequenceVar) DisjunctiveConstraint::MakeSequenceVar;
%rename (SetTransitionTime) DisjunctiveConstraint::SetTransitionTime;
%rename (TransitionTime) DisjunctiveConstraint::TransitionTime;

// Pack
%unignore Pack;
%typemap(javaimports) Pack %{
// Used to wrap IndexEvaluator1
// see https://docs.oracle.com/javase/8/docs/api/java/util/function/LongUnaryOperator.html
import java.util.function.LongUnaryOperator;
// Used to wrap IndexEvaluator2
// see https://docs.oracle.com/javase/8/docs/api/java/util/function/LongBinaryOperator.html
import java.util.function.LongBinaryOperator;
%}
%rename (AddCountAssignedItemsDimension) Pack::AddCountAssignedItemsDimension;
%rename (AddCountUsedBinDimension) Pack::AddCountUsedBinDimension;
%rename (AddSumVariableWeightsLessOrEqualConstantDimension) Pack::AddSumVariableWeightsLessOrEqualConstantDimension;
%rename (AddWeightedSumEqualVarDimension) Pack::AddWeightedSumEqualVarDimension;
%rename (AddWeightedSumLessOrEqualConstantDimension) Pack::AddWeightedSumLessOrEqualConstantDimension;
%rename (AddWeightedSumOfAssignedDimension) Pack::AddWeightedSumOfAssignedDimension;
%rename (AssignAllPossibleToBin) Pack::AssignAllPossibleToBin;
%rename (AssignAllRemainingItems) Pack::AssignAllRemainingItems;
%rename (AssignFirstPossibleToBin) Pack::AssignFirstPossibleToBin;
%rename (Assign) Pack::Assign;
%rename (AssignVar) Pack::AssignVar;
%rename (ClearAll) Pack::ClearAll;
%rename (IsAssignedStatusKnown) Pack::IsAssignedStatusKnown;
%rename (IsPossible) Pack::IsPossible;
%rename (IsUndecided) Pack::IsUndecided;
%rename (OneDomain) Pack::OneDomain;
%rename (PropagateDelayed) Pack::PropagateDelayed;
%rename (Propagate) Pack::Propagate;
%rename (RemoveAllPossibleFromBin) Pack::RemoveAllPossibleFromBin;
%rename (SetAssigned) Pack::SetAssigned;
%rename (SetImpossible) Pack::SetImpossible;
%rename (SetUnassigned) Pack::SetUnassigned;
%rename (UnassignAllRemainingItems) Pack::UnassignAllRemainingItems;

// PropagationBaseObject
%unignore PropagationBaseObject;
%ignore PropagationBaseObject::ExecuteAll;
%ignore PropagationBaseObject::EnqueueAll;
%ignore PropagationBaseObject::set_action_on_fail;
%rename (BaseName) PropagationBaseObject::BaseName;
%rename (EnqueueDelayedDemon) PropagationBaseObject::EnqueueDelayedDemon;
%rename (EnqueueVar) PropagationBaseObject::EnqueueVar;
%rename (FreezeQueue) PropagationBaseObject::FreezeQueue;
%rename (HasName) PropagationBaseObject::HasName;
%rename (SetName) PropagationBaseObject::set_name;
%rename (UnfreezeQueue) PropagationBaseObject::UnfreezeQueue;

// SearchMonitor
%feature("director") SearchMonitor;
%unignore SearchMonitor;
%rename (AcceptDelta) SearchMonitor::AcceptDelta;
%rename (AcceptNeighbor) SearchMonitor::AcceptNeighbor;
%rename (AcceptSolution) SearchMonitor::AcceptSolution;
%rename (AfterDecision) SearchMonitor::AfterDecision;
%rename (ApplyDecision) SearchMonitor::ApplyDecision;
%rename (AtSolution) SearchMonitor::AtSolution;
%rename (BeginFail) SearchMonitor::BeginFail;
%rename (BeginInitialPropagation) SearchMonitor::BeginInitialPropagation;
%rename (BeginNextDecision) SearchMonitor::BeginNextDecision;
%rename (EndFail) SearchMonitor::EndFail;
%rename (EndInitialPropagation) SearchMonitor::EndInitialPropagation;
%rename (EndNextDecision) SearchMonitor::EndNextDecision;
%rename (EnterSearch) SearchMonitor::EnterSearch;
%rename (ExitSearch) SearchMonitor::ExitSearch;
%rename (FinishCurrentSearch) SearchMonitor::FinishCurrentSearch;
%rename (Install) SearchMonitor::Install;
%rename (LocalOptimum) SearchMonitor::LocalOptimum;
%rename (NoMoreSolutions) SearchMonitor::NoMoreSolutions;
%rename (PeriodicCheck) SearchMonitor::PeriodicCheck;
%rename (ProgressPercent) SearchMonitor::ProgressPercent;
%rename (RefuteDecision) SearchMonitor::RefuteDecision;
%rename (RestartCurrentSearch) SearchMonitor::RestartCurrentSearch;
%rename (RestartSearch) SearchMonitor::RestartSearch;

// SearchLimit
%unignore SearchLimit;
%rename (Check) SearchLimit::Check;
%rename (Copy) SearchLimit::Copy;
%rename (Init) SearchLimit::Init;
%rename (MakeClone) SearchLimit::MakeClone;

// RegularLimit
%unignore RegularLimit;
%ignore RegularLimit::duration_limit;
%ignore RegularLimit::AbsoluteSolverDeadline;

// SearchLog
%unignore SearchLog;
%typemap(javaimports) SearchLog %{
// Used to wrap DisplayCallback (std::function<std::string()>)
// see https://docs.oracle.com/javase/8/docs/api/java/util/function/Supplier.html
import java.util.function.Supplier;
%}
%rename (Maintain) SearchLog::Maintain;
%rename (OutputDecision) SearchLog::OutputDecision;

// LocalSearchMonitor
%unignore LocalSearchMonitor;
%rename (BeginAcceptNeighbor) LocalSearchMonitor::BeginAcceptNeighbor;
%rename (BeginFiltering) LocalSearchMonitor::BeginFiltering;
%rename (BeginFilterNeighbor) LocalSearchMonitor::BeginFilterNeighbor;
%rename (BeginMakeNextNeighbor) LocalSearchMonitor::BeginMakeNextNeighbor;
%rename (BeginOperatorStart) LocalSearchMonitor::BeginOperatorStart;
%rename (EndAcceptNeighbor) LocalSearchMonitor::EndAcceptNeighbor;
%rename (EndFiltering) LocalSearchMonitor::EndFiltering;
%rename (EndFilterNeighbor) LocalSearchMonitor::EndFilterNeighbor;
%rename (EndMakeNextNeighbor) LocalSearchMonitor::EndMakeNextNeighbor;
%rename (EndOperatorStart) LocalSearchMonitor::EndOperatorStart;

// PropagationMonitor
%unignore PropagationMonitor;
%rename (BeginConstraintInitialPropagation) PropagationMonitor::BeginConstraintInitialPropagation;
%rename (BeginDemonRun) PropagationMonitor::BeginDemonRun;
%rename (BeginNestedConstraintInitialPropagation) PropagationMonitor::BeginNestedConstraintInitialPropagation;
%rename (EndConstraintInitialPropagation) PropagationMonitor::EndConstraintInitialPropagation;
%rename (EndDemonRun) PropagationMonitor::EndDemonRun;
%rename (EndNestedConstraintInitialPropagation) PropagationMonitor::EndNestedConstraintInitialPropagation;
%rename (EndProcessingIntegerVariable) PropagationMonitor::EndProcessingIntegerVariable;
%rename (Install) PropagationMonitor::Install;
%rename (PopContext) PropagationMonitor::PopContext;
%rename (PushContext) PropagationMonitor::PushContext;
%rename (RankFirst) PropagationMonitor::RankFirst;
%rename (RankLast) PropagationMonitor::RankLast;
%rename (RankNotFirst) PropagationMonitor::RankNotFirst;
%rename (RankNotLast) PropagationMonitor::RankNotLast;
%rename (RankSequence) PropagationMonitor::RankSequence;
%rename (RegisterDemon) PropagationMonitor::RegisterDemon;
%rename (RemoveInterval) PropagationMonitor::RemoveInterval;
%rename (RemoveValue) PropagationMonitor::RemoveValue;
%rename (RemoveValues) PropagationMonitor::RemoveValues;
%rename (SetDurationMax) PropagationMonitor::SetDurationMax;
%rename (SetDurationMin) PropagationMonitor::SetDurationMin;
%rename (SetDurationRange) PropagationMonitor::SetDurationRange;
%rename (SetEndMax) PropagationMonitor::SetEndMax;
%rename (SetEndMin) PropagationMonitor::SetEndMin;
%rename (SetEndRange) PropagationMonitor::SetEndRange;
%rename (SetPerformed) PropagationMonitor::SetPerformed;
%rename (SetStartMax) PropagationMonitor::SetStartMax;
%rename (SetStartMin) PropagationMonitor::SetStartMin;
%rename (SetStartRange) PropagationMonitor::SetStartRange;
%rename (StartProcessingIntegerVariable) PropagationMonitor::StartProcessingIntegerVariable;

// IntVarLocalSearchHandler
%unignore IntVarLocalSearchHandler;
%ignore IntVarLocalSearchHandler::AddToAssignment;
%rename (OnAddVars) IntVarLocalSearchHandler::OnAddVars;
%rename (OnRevertChanges) IntVarLocalSearchHandler::OnRevertChanges;
%rename (ValueFromAssignment) IntVarLocalSearchHandler::ValueFromAssignment;

// SequenceVarLocalSearchHandler
%unignore SequenceVarLocalSearchHandler;
%ignore SequenceVarLocalSearchHandler::AddToAssignment;
%ignore SequenceVarLocalSearchHandler::ValueFromAssignment;
%rename (OnAddVars) SequenceVarLocalSearchHandler::OnAddVars;
%rename (OnRevertChanges) SequenceVarLocalSearchHandler::OnRevertChanges;

// LocalSearchOperator
%feature("director") LocalSearchOperator;
%unignore LocalSearchOperator;
%rename (NextNeighbor) LocalSearchOperator::MakeNextNeighbor;
%rename (Reset) LocalSearchOperator::Reset;
%rename (Start) LocalSearchOperator::Start;

// VarLocalSearchOperator<>
%unignore VarLocalSearchOperator;
%ignore VarLocalSearchOperator::Start;
%ignore VarLocalSearchOperator::ApplyChanges;
%ignore VarLocalSearchOperator::RevertChanges;
%ignore VarLocalSearchOperator::SkipUnchanged;
%rename (Size) VarLocalSearchOperator::Size;
%rename (Value) VarLocalSearchOperator::Value;
%rename (IsIncremental) VarLocalSearchOperator::IsIncremental;
%rename (OnStart) VarLocalSearchOperator::OnStart;
%rename (OldValue) VarLocalSearchOperator::OldValue;
%rename (SetValue) VarLocalSearchOperator::SetValue;
%rename (Var) VarLocalSearchOperator::Var;
%rename (Activated) VarLocalSearchOperator::Activated;
%rename (Activate) VarLocalSearchOperator::Activate;
%rename (Deactivate) VarLocalSearchOperator::Deactivate;
%rename (AddVars) VarLocalSearchOperator::AddVars;

// IntVarLocalSearchOperator
%feature("director") IntVarLocalSearchOperator;
%unignore IntVarLocalSearchOperator;
%ignore IntVarLocalSearchOperator::MakeNextNeighbor;
%rename (Size) IntVarLocalSearchOperator::Size;
%rename (OneNeighbor) IntVarLocalSearchOperator::MakeOneNeighbor;
%rename (Value) IntVarLocalSearchOperator::Value;
%rename (IsIncremental) IntVarLocalSearchOperator::IsIncremental;
%rename (OnStart) IntVarLocalSearchOperator::OnStart;
%rename (OldValue) IntVarLocalSearchOperator::OldValue;
%rename (SetValue) IntVarLocalSearchOperator::SetValue;
%rename (Var) IntVarLocalSearchOperator::Var;
%rename (Activated) IntVarLocalSearchOperator::Activated;
%rename (Activate) IntVarLocalSearchOperator::Activate;
%rename (Deactivate) IntVarLocalSearchOperator::Deactivate;
%rename (AddVars) IntVarLocalSearchOperator::AddVars;

// BaseLns
%feature("director") BaseLns;
%unignore BaseLns;
%rename (InitFragments) BaseLns::InitFragments;
%rename (NextFragment) BaseLns::NextFragment;
%feature ("nodirector") BaseLns::OnStart;
%feature ("nodirector") BaseLns::SkipUnchanged;
%feature ("nodirector") BaseLns::MakeOneNeighbor;
%rename (IsIncremental) BaseLns::IsIncremental;
%rename (AppendToFragment) BaseLns::AppendToFragment;
%rename(FragmentSize) BaseLns::FragmentSize;

// ChangeValue
%feature("director") ChangeValue;
%unignore ChangeValue;
%rename (ModifyValue) ChangeValue::ModifyValue;

// SequenceVarLocalSearchOperator
%feature("director") SequenceVarLocalSearchOperator;
%unignore SequenceVarLocalSearchOperator;
%ignore SequenceVarLocalSearchOperator::OldSequence;
%ignore SequenceVarLocalSearchOperator::Sequence;
%ignore SequenceVarLocalSearchOperator::SetBackwardSequence;
%ignore SequenceVarLocalSearchOperator::SetForwardSequence;
%rename (Start) SequenceVarLocalSearchOperator::Start;

// PathOperator
%feature("director") PathOperator;
%unignore PathOperator;
%typemap(javaimports) PathOperator %{
// Used to wrap start_empty_path_class see:
// https://docs.oracle.com/javase/8/docs/api/java/util/function/LongToIntFunction.html
import java.util.function.LongToIntFunction;
%}
%ignore PathOperator::Next;
%ignore PathOperator::Path;
%ignore PathOperator::SkipUnchanged;
%ignore PathOperator::number_of_nexts;
%rename (GetBaseNodeRestartPosition) PathOperator::GetBaseNodeRestartPosition;
%rename (InitPosition) PathOperator::InitPosition;
%rename (Neighbor) PathOperator::MakeNeighbor;
%rename (OnSamePathAsPreviousBase) PathOperator::OnSamePathAsPreviousBase;
%rename (RestartAtPathStartOnSynchronize) PathOperator::RestartAtPathStartOnSynchronize;
%rename (SetNextBaseToIncrement) PathOperator::SetNextBaseToIncrement;

// PathWithPreviousNodesOperator
%unignore PathWithPreviousNodesOperator;
%rename (IsPathStart) PathWithPreviousNodesOperator::IsPathStart;
%rename (Prev) PathWithPreviousNodesOperator::Prev;

// LocalSearchFilter
%feature("director") LocalSearchFilter;
%unignore LocalSearchFilter;
%rename (Accept) LocalSearchFilter::Accept;
%rename (GetAcceptedObjectiveValue) LocalSearchFilter::GetAcceptedObjectiveValue;
%rename (GetSynchronizedObjectiveValue) LocalSearchFilter::GetSynchronizedObjectiveValue;
%rename (IsIncremental) LocalSearchFilter::IsIncremental;
%rename (Synchronize) LocalSearchFilter::Synchronize;

// IntVarLocalSearchFilter
%feature("director") IntVarLocalSearchFilter;
%unignore IntVarLocalSearchFilter;
%typemap(javaimports) IntVarLocalSearchFilter %{
// Used to wrap ObjectiveWatcher
// see https://docs.oracle.com/javase/8/docs/api/java/util/function/LongConsumer.html
import java.util.function.LongConsumer;
%}
%ignore IntVarLocalSearchFilter::FindIndex;
%ignore IntVarLocalSearchFilter::IsVarSynced;
%feature("nodirector") IntVarLocalSearchFilter::Synchronize;  // Inherited.
%rename (AddVars) IntVarLocalSearchFilter::AddVars;  // Inherited.
%rename (InjectObjectiveValue) IntVarLocalSearchFilter::InjectObjectiveValue;
%rename (IsIncremental) IntVarLocalSearchFilter::IsIncremental;
%rename (OnSynchronize) IntVarLocalSearchFilter::OnSynchronize;
%rename (SetObjectiveWatcher) IntVarLocalSearchFilter::SetObjectiveWatcher;
%rename (Size) IntVarLocalSearchFilter::Size;
%rename (Start) IntVarLocalSearchFilter::Start;
%rename (Value) IntVarLocalSearchFilter::Value;
%rename (Var) IntVarLocalSearchFilter::Var;  // Inherited.
%extend IntVarLocalSearchFilter {
  int index(IntVar* const var) {
    int64 index = -1;
    $self->FindIndex(var, &index);
    return index;
  }
}

// Demon
%unignore Demon;
%rename (Run) Demon::Run;

%define CONVERT_VECTOR(CType, JavaType)
CONVERT_VECTOR_WITH_CAST(CType, JavaType, REINTERPRET_CAST,
    com/google/ortools/constraintsolver);
%enddef

CONVERT_VECTOR(operations_research::IntVar, IntVar);
CONVERT_VECTOR(operations_research::SearchMonitor, SearchMonitor);
CONVERT_VECTOR(operations_research::DecisionBuilder, DecisionBuilder);
CONVERT_VECTOR(operations_research::IntervalVar, IntervalVar);
CONVERT_VECTOR(operations_research::SequenceVar, SequenceVar);
CONVERT_VECTOR(operations_research::LocalSearchOperator, LocalSearchOperator);
CONVERT_VECTOR(operations_research::LocalSearchFilter, LocalSearchFilter);
CONVERT_VECTOR(operations_research::SymmetryBreaker, SymmetryBreaker);

#undef CONVERT_VECTOR


%define OVERLOAD_COPY_POINTER(Method, Type)
%typemap(gotype) Type "Type"
%typemap(imtype) Method "[]Type"
%typemap(goout) Method {

	// GO CODE HERE
	$1 = $input
}
%typemap(goin) PROTO_TYPE* INPUT, PROTO_TYPE& INPUT {
	// GOING TO BREAK
  const int size = $1.ByteSize();
  uint8* im = new uint8[size];
  $1.SerializeWithCachedSizesToArray(im);
  $result = (_goslice_){im, size};
}

%apply PROTO_TYPE& INPUT { const Method& param_name }
%apply PROTO_TYPE& INPUT { Method& param_name }
%apply PROTO_TYPE* INPUT { const Method* param_name }
%apply PROTO_TYPE* INPUT { Method* param_name }

%enddef

OVERLOAD_COPY_POINTER(operations_research::Solver::MakeEquality, IntVar);

}  // namespace operations_research

// Generic rename rules.
%rename (Bound) *::Bound;
%rename (Max) *::Max;
%rename (Min) *::Min;
%rename (SetMax) *::SetMax;
%rename (SetMin) *::SetMin;
%rename (SetRange) *::SetRange;
%rename (SetValue) *::SetValue;
%rename (SetValues) *::SetValues;
%rename (Value) *::Value;
%rename (Accept) *::Accept;
%rename (ToString) *::DebugString;

// Add needed import to mainJNI.java
%pragma(java) jniclassimports=%{
// Used to wrap std::function<std::string()>
// see https://docs.oracle.com/javase/8/docs/api/java/util/function/Supplier.html
import java.util.function.Supplier;

// Used to wrap std::function<bool()>
// see https://docs.oracle.com/javase/8/docs/api/java/util/function/BooleanSupplier.html
import java.util.function.BooleanSupplier;

// Used to wrap std::function<int(int64)>
// see https://docs.oracle.com/javase/8/docs/api/java/util/function/LongToIntFunction.html
import java.util.function.LongToIntFunction;

// Used to wrap std::function<int64(int64)>
// see https://docs.oracle.com/javase/8/docs/api/java/util/function/LongUnaryOperator.html
import java.util.function.LongUnaryOperator;

// Used to wrap std::function<int64(int64, int64)>
// see https://docs.oracle.com/javase/8/docs/api/java/util/function/LongBinaryOperator.html
import java.util.function.LongBinaryOperator;

// Used to wrap std::function<int64(int64, int64, int64)>
// note: Java does not provide TernaryOperator so we provide it
import com.google.ortools.constraintsolver.LongTernaryOperator;

// Used to wrap std::function<int64(int, int)>
// note: Java does not provide it, so we provide it.
import com.google.ortools.constraintsolver.IntIntToLongFunction;

// Used to wrap std::function<bool(int64)>
// see https://docs.oracle.com/javase/8/docs/api/java/util/function/LongPredicate.html
import java.util.function.LongPredicate;

// Used to wrap std::function<bool(int64, int64, int64)>
// note: Java does not provide TernaryPredicate so we provide it
import com.google.ortools.constraintsolver.LongTernaryPredicate;

// Used to wrap std::function<void(Solver*)>
// see https://docs.oracle.com/javase/8/docs/api/java/util/function/Consumer.html
import java.util.function.Consumer;

// Used to wrap std::function<void(int64)>
// see https://docs.oracle.com/javase/8/docs/api/java/util/function/LongConsumer.html
import java.util.function.LongConsumer;

// Used to wrap std::function<void()>
// see https://docs.oracle.com/javase/8/docs/api/java/lang/Runnable.html
import java.lang.Runnable;
%}


// Protobuf support
PROTO_INPUT(operations_research::ConstraintSolverParameters,
            ConstraintSolverParameters,
            parameters)
PROTO2_RETURN(operations_research::ConstraintSolverParameters,
              ConstraintSolverParameters)

PROTO_INPUT(operations_research::RegularLimitParameters,
            RegularLimitParameters,
            proto)
PROTO2_RETURN(operations_research::RegularLimitParameters,
              RegularLimitParameters)

namespace operations_research {

// Globals
// IMPORTANT(corentinl): Globals will be placed in main.java
// i.e. use `import com.[...].constraintsolver.main`
%ignore FillValues;
%rename (AreAllBooleans) AreAllBooleans;
%rename (AreAllBound) AreAllBound;
%rename (AreAllBoundTo) AreAllBoundTo;
%rename (MaxVarArray) MaxVarArray;
%rename (MinVarArray) MinVarArray;
%rename (PosIntDivDown) PosIntDivDown;
%rename (PosIntDivUp) PosIntDivUp;
%rename (SetAssignmentFromAssignment) SetAssignmentFromAssignment;
%rename (Zero) Zero;
}  // namespace operations_research

// Wrap cp includes
// TODO(user): Use ignoreall/unignoreall for this one. A lot of work.
//swiglint: disable include-h-allglobals
%include "ortools/constraint_solver/constraint_solver.h"
%include "ortools/constraint_solver/constraint_solveri.h"
//%include "ortools/constraint_solver/java/javawrapcp_util.h"

// Define templates instantiation after wrapping.
namespace operations_research {
%template(RevInteger) Rev<int>;
%template(RevLong) Rev<int64>;
%template(RevBool) Rev<bool>;
%template(AssignmentIntContainer) AssignmentContainer<IntVar, IntVarElement>;
%template(AssignmentIntervalContainer) AssignmentContainer<IntervalVar, IntervalVarElement>;
%template(AssignmentSequenceContainer) AssignmentContainer<SequenceVar, SequenceVarElement>;
}  // namespace operations_research
