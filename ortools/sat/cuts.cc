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

#include "ortools/sat/cuts.h"

#include <algorithm>
#include <cmath>
#include <functional>
#include <memory>
#include <utility>
#include <vector>

#include "ortools/algorithms/knapsack_solver_for_cuts.h"
#include "ortools/base/integral_types.h"
#include "ortools/base/stl_util.h"
#include "ortools/sat/integer.h"
#include "ortools/sat/linear_constraint.h"
#include "ortools/util/time_limit.h"

namespace operations_research {
namespace sat {

namespace {

// Minimum amount of violation of the cut constraint by the solution. This
// is needed to avoid numerical issues and adding cuts with minor effect.
const double kMinCutViolation = 1e-4;

// Returns a constraint that disallow all given variables to be at their current
// upper bound. The arguments must form a non-trival constraint of the form
// sum terms (coeff * var) <= upper_bound.
LinearConstraint GenerateKnapsackCutForCover(
    const std::vector<IntegerVariable>& vars,
    const std::vector<IntegerValue>& coeffs, const IntegerValue upper_bound,
    const IntegerTrail& integer_trail) {
  CHECK_EQ(vars.size(), coeffs.size());
  CHECK_GT(vars.size(), 0);
  LinearConstraint cut;
  IntegerValue cut_upper_bound = IntegerValue(0);
  IntegerValue max_coeff = coeffs[0];
  // slack = \sum_{i}(coeffs[i] * upper_bound[i]) - upper_bound.
  IntegerValue slack = -upper_bound;
  for (int i = 0; i < vars.size(); ++i) {
    const IntegerValue var_upper_bound =
        integer_trail.LevelZeroUpperBound(vars[i]);
    cut_upper_bound += var_upper_bound;
    cut.vars.push_back(vars[i]);
    cut.coeffs.push_back(IntegerValue(1));
    max_coeff = std::max(max_coeff, coeffs[i]);
    slack += coeffs[i] * var_upper_bound;
  }
  CHECK_GT(slack, 0.0) << "Invalid cover for knapsack cut.";
  cut_upper_bound -= CeilRatio(slack, max_coeff);
  cut.lb = kMinIntegerValue;
  cut.ub = cut_upper_bound;
  VLOG(2) << "Generated Knapsack Constraint:" << cut.DebugString();
  return cut;
}

bool SolutionSatisfiesConstraint(
    const LinearConstraint& constraint,
    const gtl::ITIVector<IntegerVariable, double>& lp_values) {
  const double activity = ComputeActivity(constraint, lp_values);
  const double tolerance = 1e-6;
  return (activity <= constraint.ub.value() + tolerance &&
          activity >= constraint.lb.value() - tolerance)
             ? true
             : false;
}

bool SmallRangeAndAllCoefficientsMagnitudeAreTheSame(
    const LinearConstraint& constraint, IntegerTrail* integer_trail) {
  if (constraint.vars.empty()) return true;

  const int64 magnitude = std::abs(constraint.coeffs[0].value());
  for (int i = 1; i < constraint.coeffs.size(); ++i) {
    const IntegerVariable var = constraint.vars[i];
    if (integer_trail->LevelZeroUpperBound(var) -
            integer_trail->LevelZeroLowerBound(var) >
        1) {
      return false;
    }
    if (std::abs(constraint.coeffs[i].value()) != magnitude) {
      return false;
    }
  }
  return true;
}

bool AllVarsTakeIntegerValue(
    const std::vector<IntegerVariable> vars,
    const gtl::ITIVector<IntegerVariable, double>& lp_values) {
  for (IntegerVariable var : vars) {
    if (std::abs(lp_values[var] - std::round(lp_values[var])) > 1e-6) {
      return false;
    }
  }
  return true;
}

// Returns smallest cover size for the given constraint taking into account
// level zero bounds. Smallest Cover size is computed as follows.
// 1. Compute the upper bound if all variables are shifted to have zero lower
//    bound.
// 2. Sort all terms (coefficient * shifted upper bound) in non decreasing
//    order.
// 3. Add terms in cover until term sum is smaller or equal to upper bound.
// 4. Add the last item which violates the upper bound. This forms the smallest
//    cover. Return the size of this cover.
int GetSmallestCoverSize(const LinearConstraint& constraint,
                         const IntegerTrail& integer_trail) {
  IntegerValue ub = constraint.ub;
  std::vector<IntegerValue> sorted_terms;
  for (int i = 0; i < constraint.vars.size(); ++i) {
    const IntegerValue coeff = constraint.coeffs[i];
    const IntegerVariable var = constraint.vars[i];
    const IntegerValue var_ub = integer_trail.LevelZeroUpperBound(var);
    const IntegerValue var_lb = integer_trail.LevelZeroLowerBound(var);
    ub -= var_lb * coeff;
    sorted_terms.push_back(coeff * (var_ub - var_lb));
  }
  std::sort(sorted_terms.begin(), sorted_terms.end(),
            std::greater<IntegerValue>());
  int smallest_cover_size = 0;
  IntegerValue sorted_term_sum = IntegerValue(0);
  while (sorted_term_sum <= ub &&
         smallest_cover_size < constraint.vars.size()) {
    sorted_term_sum += sorted_terms[smallest_cover_size++];
  }
  return smallest_cover_size;
}

bool ConstraintIsEligibleForLifting(const LinearConstraint& constraint,
                                    const IntegerTrail& integer_trail) {
  for (const IntegerVariable var : constraint.vars) {
    if (integer_trail.LevelZeroLowerBound(var) != IntegerValue(0) ||
        integer_trail.LevelZeroUpperBound(var) != IntegerValue(1)) {
      return false;
    }
  }
  return true;
}
}  // namespace

bool LiftKnapsackCut(
    const LinearConstraint& constraint,
    const gtl::ITIVector<IntegerVariable, double>& lp_values,
    const std::vector<IntegerValue>& cut_vars_original_coefficients,
    const IntegerTrail& integer_trail, TimeLimit* time_limit,
    LinearConstraint* cut) {
  std::set<IntegerVariable> vars_in_cut;
  for (IntegerVariable var : cut->vars) {
    vars_in_cut.insert(var);
  }

  std::vector<std::pair<IntegerValue, IntegerVariable>> non_zero_vars;
  std::vector<std::pair<IntegerValue, IntegerVariable>> zero_vars;
  for (int i = 0; i < constraint.vars.size(); ++i) {
    const IntegerVariable var = constraint.vars[i];
    if (integer_trail.LevelZeroLowerBound(var) != IntegerValue(0) ||
        integer_trail.LevelZeroUpperBound(var) != IntegerValue(1)) {
      continue;
    }
    if (vars_in_cut.find(var) != vars_in_cut.end()) continue;
    const IntegerValue coeff = constraint.coeffs[i];
    if (lp_values[var] <= 1e-6) {
      zero_vars.push_back({coeff, var});
    } else {
      non_zero_vars.push_back({coeff, var});
    }
  }

  // Decide lifting sequence (nonzeros, zeros in nonincreasing order
  // of coefficient ).
  std::sort(non_zero_vars.rbegin(), non_zero_vars.rend());
  std::sort(zero_vars.rbegin(), zero_vars.rend());

  std::vector<std::pair<IntegerValue, IntegerVariable>> lifting_sequence(
      std::move(non_zero_vars));

  lifting_sequence.insert(lifting_sequence.end(), zero_vars.begin(),
                          zero_vars.end());

  // Form Knapsack.
  std::vector<double> lifting_profits;
  std::vector<double> lifting_weights;
  for (int i = 0; i < cut->vars.size(); ++i) {
    lifting_profits.push_back(cut->coeffs[i].value());
    lifting_weights.push_back(cut_vars_original_coefficients[i].value());
  }

  // Lift the cut.
  bool is_lifted = false;
  bool is_solution_optimal = false;
  KnapsackSolverForCuts knapsack_solver("Knapsack cut lifter");
  for (auto entry : lifting_sequence) {
    is_solution_optimal = false;
    const IntegerValue var_original_coeff = entry.first;
    const IntegerVariable var = entry.second;
    const IntegerValue lifting_capacity = constraint.ub - entry.first;
    if (lifting_capacity <= IntegerValue(0)) continue;
    knapsack_solver.Init(lifting_profits, lifting_weights,
                         lifting_capacity.value());
    knapsack_solver.set_node_limit(100);
    // NOTE: Since all profits and weights are integer, solution of
    // knapsack is also integer.
    // TODO(user): Use an integer solver or heuristic.
    knapsack_solver.Solve(time_limit, &is_solution_optimal);
    const double knapsack_upper_bound =
        std::round(knapsack_solver.GetUpperBound());
    const IntegerValue cut_coeff = cut->ub - knapsack_upper_bound;
    if (cut_coeff > IntegerValue(0)) {
      is_lifted = true;
      cut->vars.push_back(var);
      cut->coeffs.push_back(cut_coeff);
      lifting_profits.push_back(cut_coeff.value());
      lifting_weights.push_back(var_original_coeff.value());
    }
  }
  return is_lifted;
}

LinearConstraint GetPreprocessedLinearConstraint(
    const LinearConstraint& constraint,
    const gtl::ITIVector<IntegerVariable, double>& lp_values,
    const IntegerTrail& integer_trail) {
  IntegerValue ub = constraint.ub;
  LinearConstraint constraint_with_left_vars;
  for (int i = 0; i < constraint.vars.size(); ++i) {
    const IntegerVariable var = constraint.vars[i];
    const IntegerValue var_ub = integer_trail.LevelZeroUpperBound(var);
    const IntegerValue coeff = constraint.coeffs[i];
    if (var_ub.value() - lp_values[var] <= 1.0 - kMinCutViolation) {
      constraint_with_left_vars.vars.push_back(var);
      constraint_with_left_vars.coeffs.push_back(coeff);
    } else {
      // Variable not in cut
      const IntegerValue var_lb = integer_trail.LevelZeroLowerBound(var);
      ub -= coeff * var_lb;
    }
  }
  constraint_with_left_vars.ub = ub;
  constraint_with_left_vars.lb = constraint.lb;
  return constraint_with_left_vars;
}

bool ConstraintIsTriviallyTrue(const LinearConstraint& constraint,
                               const IntegerTrail& integer_trail) {
  IntegerValue term_sum = IntegerValue(0);
  for (int i = 0; i < constraint.vars.size(); ++i) {
    const IntegerVariable var = constraint.vars[i];
    const IntegerValue var_ub = integer_trail.LevelZeroUpperBound(var);
    const IntegerValue coeff = constraint.coeffs[i];
    term_sum += coeff * var_ub;
  }
  if (term_sum <= constraint.ub) {
    VLOG(2) << "Filtered by cover filter";
    return true;
  }
  return false;
}

bool CanBeFilteredUsingCutLowerBound(
    const LinearConstraint& preprocessed_constraint,
    const gtl::ITIVector<IntegerVariable, double>& lp_values,
    const IntegerTrail& integer_trail) {
  std::vector<double> variable_upper_bound_distances;
  for (const IntegerVariable var : preprocessed_constraint.vars) {
    const IntegerValue var_ub = integer_trail.LevelZeroUpperBound(var);
    variable_upper_bound_distances.push_back(var_ub.value() - lp_values[var]);
  }
  // Compute the min cover size.
  const int smallest_cover_size =
      GetSmallestCoverSize(preprocessed_constraint, integer_trail);

  std::nth_element(
      variable_upper_bound_distances.begin(),
      variable_upper_bound_distances.begin() + smallest_cover_size - 1,
      variable_upper_bound_distances.end());
  double cut_lower_bound = 0.0;
  for (int i = 0; i < smallest_cover_size; ++i) {
    cut_lower_bound += variable_upper_bound_distances[i];
  }
  if (cut_lower_bound >= 1.0 - kMinCutViolation) {
    VLOG(2) << "Filtered by kappa heuristic";
    return true;
  }
  return false;
}

double GetKnapsackUpperBound(std::vector<KnapsackItem> items,
                             const double capacity) {
  // Sort items by value by weight ratio.
  std::sort(items.begin(), items.end(), std::greater<KnapsackItem>());
  double left_capacity = capacity;
  double profit = 0.0;
  for (const KnapsackItem item : items) {
    if (item.weight <= left_capacity) {
      profit += item.profit;
      left_capacity -= item.weight;
    } else {
      profit += (left_capacity / item.weight) * item.profit;
      break;
    }
  }
  return profit;
}

bool CanBeFilteredUsingKnapsackUpperBound(
    const LinearConstraint& constraint,
    const gtl::ITIVector<IntegerVariable, double>& lp_values,
    const IntegerTrail& integer_trail) {
  std::vector<KnapsackItem> items;
  double capacity = -constraint.ub.value() - 1.0;
  double sum_variable_profit = 0;
  for (int i = 0; i < constraint.vars.size(); ++i) {
    const IntegerVariable var = constraint.vars[i];
    const IntegerValue var_ub = integer_trail.LevelZeroUpperBound(var);
    const IntegerValue var_lb = integer_trail.LevelZeroLowerBound(var);
    const IntegerValue coeff = constraint.coeffs[i];
    KnapsackItem item;
    item.profit = var_ub.value() - lp_values[var];
    item.weight = (coeff * (var_ub - var_lb)).value();
    items.push_back(item);
    capacity += (coeff * var_ub).value();
    sum_variable_profit += item.profit;
  }

  // Return early if the required upper bound is negative since all the profits
  // are non negative.
  if (sum_variable_profit - 1.0 + kMinCutViolation < 0.0) return false;

  // Get the knapsack upper bound.
  const double knapsack_upper_bound =
      GetKnapsackUpperBound(std::move(items), capacity);
  if (knapsack_upper_bound < sum_variable_profit - 1.0 + kMinCutViolation) {
    VLOG(2) << "Filtered by knapsack upper bound";
    return true;
  }
  return false;
}

bool CanFormValidKnapsackCover(
    const LinearConstraint& preprocessed_constraint,
    const gtl::ITIVector<IntegerVariable, double>& lp_values,
    const IntegerTrail& integer_trail) {
  if (ConstraintIsTriviallyTrue(preprocessed_constraint, integer_trail)) {
    return false;
  }
  if (CanBeFilteredUsingCutLowerBound(preprocessed_constraint, lp_values,
                                      integer_trail)) {
    return false;
  }
  if (CanBeFilteredUsingKnapsackUpperBound(preprocessed_constraint, lp_values,
                                           integer_trail)) {
    return false;
  }
  return true;
}

void ConvertToKnapsackForm(const LinearConstraint& constraint,
                           std::vector<LinearConstraint>* knapsack_constraints,
                           IntegerTrail* integer_trail) {
  // If all coefficient are the same, the generated knapsack cuts cannot be
  // stronger than the constraint itself. However, when we substitute variables
  // using the implication graph, this is not longer true. So we only skip
  // constraints with same coeff and no substitutions.
  if (SmallRangeAndAllCoefficientsMagnitudeAreTheSame(constraint,
                                                      integer_trail)) {
    return;
  }
  if (constraint.ub < kMaxIntegerValue) {
    LinearConstraint canonical_knapsack_form;

    // Negate the variables with negative coefficients.
    for (int i = 0; i < constraint.vars.size(); ++i) {
      const IntegerVariable var = constraint.vars[i];
      const IntegerValue coeff = constraint.coeffs[i];
      if (coeff > IntegerValue(0)) {
        canonical_knapsack_form.AddTerm(var, coeff);
      } else {
        canonical_knapsack_form.AddTerm(NegationOf(var), -coeff);
      }
    }
    canonical_knapsack_form.ub = constraint.ub;
    canonical_knapsack_form.lb = kMinIntegerValue;
    knapsack_constraints->push_back(canonical_knapsack_form);
  }

  if (constraint.lb > kMinIntegerValue) {
    LinearConstraint canonical_knapsack_form;

    // Negate the variables with positive coefficients.
    for (int i = 0; i < constraint.vars.size(); ++i) {
      const IntegerVariable var = constraint.vars[i];
      const IntegerValue coeff = constraint.coeffs[i];
      if (coeff > IntegerValue(0)) {
        canonical_knapsack_form.AddTerm(NegationOf(var), coeff);
      } else {
        canonical_knapsack_form.AddTerm(var, -coeff);
      }
    }
    canonical_knapsack_form.ub = -constraint.lb;
    canonical_knapsack_form.lb = kMinIntegerValue;
    knapsack_constraints->push_back(canonical_knapsack_form);
  }
}

// TODO(user): Move the cut generator into a class and reuse variables.
CutGenerator CreateKnapsackCoverCutGenerator(
    const std::vector<LinearConstraint>& base_constraints,
    const std::vector<IntegerVariable>& vars, Model* model) {
  CutGenerator result;
  result.vars = vars;

  IntegerTrail* integer_trail = model->GetOrCreate<IntegerTrail>();
  std::vector<LinearConstraint> knapsack_constraints;
  for (const LinearConstraint& constraint : base_constraints) {
    // There is often a lot of small linear base constraints and it doesn't seem
    // super useful to generate cuts for constraints of size 2. Any valid cut
    // of size 1 should be already infered by the propagation.
    //
    // TODO(user): The case of size 2 is a bit less clear. investigate more if
    // it is useful.
    if (constraint.vars.size() <= 2) continue;

    ConvertToKnapsackForm(constraint, &knapsack_constraints, integer_trail);
  }
  VLOG(1) << "#knapsack constraints: " << knapsack_constraints.size();

  // Note(user): for Knapsack cuts, it seems always advantageous to replace a
  // variable X by a TIGHT lower bound of the form "coeff * binary + lb". This
  // will not change "covers" but can only result in more violation by the
  // current LP solution.
  ImpliedBoundsProcessor implied_bounds_processor(
      vars, integer_trail, model->GetOrCreate<ImpliedBounds>());

  // TODO(user): do not add generator if there are no knapsack constraints.
  result.generate_cuts = [implied_bounds_processor, knapsack_constraints, vars,
                          model, integer_trail](
                             const gtl::ITIVector<IntegerVariable, double>&
                                 lp_values,
                             LinearConstraintManager* manager) {
    // TODO(user): When we use implied-bound substitution, we might still infer
    // an interesting cut even if all variables are integer. See if we still
    // want to skip all such constraints.
    if (AllVarsTakeIntegerValue(vars, lp_values)) return;

    KnapsackSolverForCuts knapsack_solver(
        "Knapsack on demand cover cut generator");
    int64 skipped_constraints = 0;
    LinearConstraint mutable_constraint;

    // Iterate through all knapsack constraints.
    for (const LinearConstraint& constraint : knapsack_constraints) {
      if (model->GetOrCreate<TimeLimit>()->LimitReached()) break;
      VLOG(2) << "Processing constraint: " << constraint.DebugString();

      mutable_constraint = constraint;
      implied_bounds_processor.ProcessUpperBoundedConstraint(
          lp_values, &mutable_constraint);
      MakeAllCoefficientsPositive(&mutable_constraint);

      const LinearConstraint preprocessed_constraint =
          GetPreprocessedLinearConstraint(mutable_constraint, lp_values,
                                          *integer_trail);
      if (preprocessed_constraint.vars.empty()) continue;

      if (!CanFormValidKnapsackCover(preprocessed_constraint, lp_values,
                                     *integer_trail)) {
        skipped_constraints++;
        continue;
      }

      // Profits are (upper_bounds[i] - lp_values[i]) for knapsack variables.
      std::vector<double> profits;
      profits.reserve(preprocessed_constraint.vars.size());

      // Weights are (coeffs[i] * (upper_bound[i] - lower_bound[i])).
      std::vector<double> weights;
      weights.reserve(preprocessed_constraint.vars.size());

      double capacity = -preprocessed_constraint.ub.value() - 1.0;

      // Compute and store the sum of variable profits. This is the constant
      // part of the objective of the problem we are trying to solve. Hence
      // this part is not supplied to the knapsack_solver and is subtracted
      // when we receive the knapsack solution.
      double sum_variable_profit = 0;

      // Compute the profits, the weights and the capacity for the knapsack
      // instance.
      for (int i = 0; i < preprocessed_constraint.vars.size(); ++i) {
        const IntegerVariable var = preprocessed_constraint.vars[i];
        const double coefficient = preprocessed_constraint.coeffs[i].value();
        const double var_ub = ToDouble(integer_trail->LevelZeroUpperBound(var));
        const double var_lb = ToDouble(integer_trail->LevelZeroLowerBound(var));
        const double variable_profit = var_ub - lp_values[var];
        profits.push_back(variable_profit);

        sum_variable_profit += variable_profit;

        const double weight = coefficient * (var_ub - var_lb);
        weights.push_back(weight);
        capacity += weight + coefficient * var_lb;
      }
      if (capacity < 0.0) continue;

      std::vector<IntegerVariable> cut_vars;
      std::vector<IntegerValue> cut_vars_original_coefficients;

      VLOG(2) << "Knapsack size: " << profits.size();
      knapsack_solver.Init(profits, weights, capacity);

      // Set the time limit for the knapsack solver.
      const double time_limit_for_knapsack_solver =
          model->GetOrCreate<TimeLimit>()->GetTimeLeft();

      // Solve the instance and subtract the constant part to compute the
      // sum_of_distance_to_ub_for_vars_in_cover.
      // TODO(user): Consider solving the instance approximately.
      bool is_solution_optimal = false;
      knapsack_solver.set_solution_upper_bound_threshold(
          sum_variable_profit - 1.0 + kMinCutViolation);
      // TODO(user): Consider providing lower bound threshold as
      // sum_variable_profit - 1.0 + kMinCutViolation.
      // TODO(user): Set node limit for knapsack solver.
      auto time_limit_for_solver =
          absl::make_unique<TimeLimit>(time_limit_for_knapsack_solver);
      const double sum_of_distance_to_ub_for_vars_in_cover =
          sum_variable_profit -
          knapsack_solver.Solve(time_limit_for_solver.get(),
                                &is_solution_optimal);
      if (is_solution_optimal) {
        VLOG(2) << "Knapsack Optimal solution found yay !";
      }
      if (time_limit_for_solver->LimitReached()) {
        VLOG(1) << "Knapsack Solver run out of time limit.";
      }
      if (sum_of_distance_to_ub_for_vars_in_cover < 1.0 - kMinCutViolation) {
        // Constraint is eligible for the cover.

        IntegerValue constraint_ub_for_cut = preprocessed_constraint.ub;
        std::set<IntegerVariable> vars_in_cut;
        for (int i = 0; i < preprocessed_constraint.vars.size(); ++i) {
          const IntegerVariable var = preprocessed_constraint.vars[i];
          const IntegerValue coefficient = preprocessed_constraint.coeffs[i];
          if (!knapsack_solver.best_solution(i)) {
            cut_vars.push_back(var);
            cut_vars_original_coefficients.push_back(coefficient);
            vars_in_cut.insert(var);
          } else {
            const IntegerValue var_lb = integer_trail->LevelZeroLowerBound(var);
            constraint_ub_for_cut -= coefficient * var_lb;
          }
        }
        LinearConstraint cut = GenerateKnapsackCutForCover(
            cut_vars, cut_vars_original_coefficients, constraint_ub_for_cut,
            *integer_trail);

        // Check if the constraint has only binary variables.
        bool is_lifted = false;
        if (ConstraintIsEligibleForLifting(cut, *integer_trail)) {
          if (LiftKnapsackCut(mutable_constraint, lp_values,
                              cut_vars_original_coefficients, *integer_trail,
                              model->GetOrCreate<TimeLimit>(), &cut)) {
            is_lifted = true;
          }
        }

        CHECK(!SolutionSatisfiesConstraint(cut, lp_values));
        manager->AddCut(cut, is_lifted ? "LiftedKnapsack" : "Knapsack",
                        lp_values);
      }
    }
    if (skipped_constraints > 0) {
      VLOG(2) << "Skipped constraints: " << skipped_constraints;
    }
  };

  return result;
}

std::function<IntegerValue(IntegerValue)> GetSuperAdditiveRoundingFunction(
    IntegerValue rhs_remainder, IntegerValue divisor, IntegerValue max_t,
    IntegerValue max_scaling) {
  CHECK_GE(max_t, 1);
  CHECK_GE(max_scaling, 1);

  // Compute the larger t <= max_t such that
  // t * rhs_remainder >= divisor / 2.
  const IntegerValue t =
      rhs_remainder == 0
          ? max_t
          : std::min(max_t, CeilRatio(divisor / 2, rhs_remainder));

  // Adjust after the multiplication by t.
  //
  // Note(user): the modulo is only needed when t is large which is currently
  // not possible, but I left it here to not forget to do that in experiments.
  rhs_remainder *= t;
  rhs_remainder %= divisor;

  // Make sure we don't have an integer overflow below. Note that we assume that
  // divisor and the maximum coeff magnitude are not too different (maybe a
  // factor 1000 at most) so that the final result will never overflow.
  max_scaling = std::min(max_scaling, kint64max / divisor);

  const IntegerValue size = divisor - rhs_remainder;
  if (max_scaling == 1 || size == 1) {
    // TODO(user): Use everywhere a two step computation to avoid overflow?
    // First divide by divisor, then multiply by t. For now, we limit t so that
    // we never have an overflow instead.
    return [t, divisor](IntegerValue coeff) {
      return FloorRatio(t * coeff, divisor);
    };
  } else if (size <= max_scaling) {
    return [size, rhs_remainder, t, divisor](IntegerValue coeff) {
      const IntegerValue ratio = FloorRatio(t * coeff, divisor);
      const IntegerValue remainder = t * coeff - ratio * divisor;
      const IntegerValue diff = remainder - rhs_remainder;
      return size * ratio + std::max(IntegerValue(0), diff);
    };
  } else if (max_scaling.value() * rhs_remainder.value() < divisor) {
    // Because of our max_t limitation, the rhs_remainder might stay small.
    //
    // If it is "too small" we cannot use the code below because it will not be
    // valid. So we just divide divisor into max_scaling bucket. The
    // rhs_remainder will be in the bucket 0.
    //
    // Note(user): This seems the same as just increasing t, modulo integer
    // overflows. Maybe we should just always do the computation like this so
    // that we can use larger t even if coeff is close to kint64max.
    return [t, divisor, max_scaling](IntegerValue coeff) {
      const IntegerValue ratio = FloorRatio(t * coeff, divisor);
      const IntegerValue remainder = t * coeff - ratio * divisor;
      const IntegerValue bucket = FloorRatio(remainder * max_scaling, divisor);
      return max_scaling * ratio + bucket;
    };
  } else {
    // We divide (size = divisor - rhs_remainder) into (max_scaling - 1) buckets
    // and increase the function by 1 / max_scaling for each of them.
    //
    // Note that for different values of max_scaling, we get a family of
    // functions that do not dominate each others. So potentially, a max scaling
    // as low as 2 could lead to the better cut (this is exactly the Letchford &
    // Lodi function).
    //
    // Another intersting fact, is that if we want to compute the maximum alpha
    // for a constraint with 2 terms like:
    //    divisor * Y + (ratio * divisor + remainder) * X
    //               <= rhs_ratio * divisor + rhs_remainder
    // so that we have the cut:
    //              Y + (ratio + alpha) * X  <= rhs_ratio
    // This is the same as computing the maximum alpha such that for all integer
    // X > 0 we have CeilRatio(alpha * divisor * X, divisor)
    //    <= CeilRatio(remainder * X - rhs_remainder, divisor).
    // We can prove that this alpha is of the form (n - 1) / n, and it will
    // be reached by such function for a max_scaling of n.
    //
    // TODO(user): This function is not always maximal when
    // size % (max_scaling - 1) == 0. Improve?
    return [size, rhs_remainder, t, divisor, max_scaling](IntegerValue coeff) {
      const IntegerValue ratio = FloorRatio(t * coeff, divisor);
      const IntegerValue remainder = t * coeff - ratio * divisor;
      const IntegerValue diff = remainder - rhs_remainder;
      const IntegerValue bucket =
          diff > 0 ? CeilRatio(diff * (max_scaling - 1), size)
                   : IntegerValue(0);
      return max_scaling * ratio + bucket;
    };
  }
}

// TODO(user): This has been optimized a bit, but we can probably do even better
// as it still takes around 25% percent of the run time when all the cuts are on
// for the opm*mps.gz problems and others.
void IntegerRoundingCut(RoundingOptions options,
                        const std::vector<double>& lp_values,
                        const std::vector<IntegerValue>& lower_bounds,
                        const std::vector<IntegerValue>& upper_bounds,
                        LinearConstraint* cut) {
  const int size = lp_values.size();
  if (size == 0) return;
  CHECK_EQ(lower_bounds.size(), size);
  CHECK_EQ(upper_bounds.size(), size);
  CHECK_EQ(cut->vars.size(), size);
  CHECK_EQ(cut->coeffs.size(), size);
  CHECK_EQ(cut->lb, kMinIntegerValue);

  // To optimize the computation of the best divisor below, we only need to
  // look at the indices with a shifted lp value that is not close to zero.
  //
  // TODO(user): use a class to reuse this memory. Note however that currently
  // this do not appear in the cpu profile.
  //
  // TODO(user): sort by decreasing lp_values so that our early abort test in
  // the critical loop below has more chance of returning early? I tried but it
  // didn't seems to change much though.
  std::vector<int> relevant_indices;
  std::vector<double> relevant_lp_values;
  std::vector<IntegerValue> relevant_coeffs;
  std::vector<IntegerValue> relevant_bound_diffs;
  std::vector<IntegerValue> divisors;
  std::vector<std::pair<int, IntegerValue>> adjusted_coeffs;

  // Shift each variable using its lower/upper bound so that no variable can
  // change sign. We eventually do a change of variable to its negation so
  // that all variable are non-negative.
  bool overflow = false;
  std::vector<bool> change_sign_at_postprocessing(size, false);
  IntegerValue max_magnitude(0);
  for (int i = 0; i < size; ++i) {
    if (cut->coeffs[i] == 0) continue;

    // We might change them below.
    IntegerValue lb = lower_bounds[i];
    double lp_value = lp_values[i];

    const IntegerValue ub = upper_bounds[i];
    const IntegerValue bound_diff =
        IntegerValue(CapSub(ub.value(), lb.value()));

    // Note that since we use ToDouble() this code works fine with lb/ub at
    // min/max integer value.
    {
      if (std::abs(lp_value - ToDouble(lb)) >
          std::abs(lp_value - ToDouble(ub))) {
        // Change the variable sign.
        change_sign_at_postprocessing[i] = true;
        cut->coeffs[i] = -cut->coeffs[i];
        lp_value = -lp_value;
        lb = -ub;
      }
    }

    // Always shift to lb.
    // coeff * X = coeff * (X - shift) + coeff * shift.
    lp_value -= ToDouble(lb);
    if (!AddProductTo(-cut->coeffs[i], lb, &cut->ub)) {
      overflow = true;
      break;
    }

    // Deal with fixed variable, no need to shift back in this case, we can
    // just remove the term.
    if (bound_diff == 0) {
      cut->coeffs[i] = IntegerValue(0);
      lp_value = 0.0;
    }

    const IntegerValue magnitude = IntTypeAbs(cut->coeffs[i]);
    if (std::abs(lp_value) > 1e-2) {
      relevant_coeffs.push_back(cut->coeffs[i]);
      relevant_indices.push_back(i);
      relevant_lp_values.push_back(lp_value);
      relevant_bound_diffs.push_back(bound_diff);

      divisors.push_back(magnitude);
    }
    max_magnitude = std::max(max_magnitude, magnitude);
  }

  // TODO(user): Maybe this shouldn't be called on such constraint.
  if (relevant_coeffs.empty()) {
    VLOG(2) << "Issue, nothing to cut.";
    *cut = LinearConstraint(IntegerValue(0), IntegerValue(0));
    return;
  }
  CHECK_NE(max_magnitude, 0);

  // Our heuristic will try to generate a few different cuts, and we will keep
  // the most violated one scaled by the l2 norm of the relevant position.
  //
  // TODO(user): Experiment for the best value of this initial violation
  // threshold. Note also that we use the l2 norm on the restricted position
  // here. Maybe we should change that? On that note, the L2 norm usage seems a
  // bit weird to me since it grows with the number of term in the cut. And
  // often, we already have a good cut, and we make it stronger by adding extra
  // terms that do not change its activity.
  //
  // The discussion above only concern the best_scaled_violation initial value.
  // The remainder_threshold allows to not consider cuts for which the final
  // efficacity is clearly lower than 1e-3 (it is a bound, so we could generate
  // cuts with a lower efficacity than this).
  double best_scaled_violation = 0.01;
  const IntegerValue remainder_threshold(max_magnitude / 1000);

  // The cut->ub might have grown quite a bit with the bound substitution, so
  // we need to include it too since we will apply the rounding function on it.
  max_magnitude = std::max(max_magnitude, IntTypeAbs(cut->ub));

  // Make sure that when we multiply the rhs or the coefficient by a factor t,
  // we do not have an integer overflow. Actually, we need a bit more room
  // because we might round down a value to the next multiple of
  // max_magnitude.
  const IntegerValue threshold = kMaxIntegerValue / 2;
  if (overflow || max_magnitude >= threshold) {
    VLOG(2) << "Issue, overflow.";
    *cut = LinearConstraint(IntegerValue(0), IntegerValue(0));
    return;
  }
  const IntegerValue max_t = threshold / max_magnitude;

  // There is no point trying twice the same divisor or a divisor that is too
  // small. Note that we use a higher threshold than the remainder_threshold
  // because we can boost the remainder thanks to our adjusting heuristic below
  // and also because this allows to have cuts with a small range of
  // coefficients.
  //
  // TODO(user): Note that the std::sort() is visible in some cpu profile.
  {
    int new_size = 0;
    const IntegerValue divisor_threshold = max_magnitude / 10;
    for (int i = 0; i < divisors.size(); ++i) {
      if (divisors[i] <= divisor_threshold) continue;
      divisors[new_size++] = divisors[i];
    }
    divisors.resize(new_size);
  }
  gtl::STLSortAndRemoveDuplicates(&divisors, std::greater<IntegerValue>());

  // TODO(user): Avoid quadratic algorithm? Note that we are quadratic in
  // relevant_indices not the full cut->coeffs.size(), but this is still too
  // much on some problems.
  IntegerValue best_divisor(0);
  for (const IntegerValue divisor : divisors) {
    // Skip if we don't have the potential to generate a good enough cut.
    const IntegerValue initial_rhs_remainder =
        cut->ub - FloorRatio(cut->ub, divisor) * divisor;
    if (initial_rhs_remainder <= remainder_threshold) continue;

    IntegerValue temp_ub = cut->ub;
    adjusted_coeffs.clear();

    // We will adjust coefficient that are just under an exact multiple of
    // divisor to an exact multiple. This is meant to get rid of small errors
    // that appears due to rounding error in our exact computation of the
    // initial constraint given to this class.
    //
    // Each adjustement will cause the initial_rhs_remainder to increase, and we
    // do not want to increase it above divisor. Our threshold below guarantees
    // this. Note that the higher the rhs_remainder becomes, the more the
    // function f() has a chance to reduce the violation, so it is not always a
    // good idea to use all the slack we have between initial_rhs_remainder and
    // divisor.
    //
    // TODO(user): If possible, it might be better to complement these
    // variables. Even if the adjusted lp_values end up larger, if we loose less
    // when taking f(), then we will have a better violation.
    const IntegerValue adjust_threshold =
        (divisor - initial_rhs_remainder - 1) / IntegerValue(size);
    if (adjust_threshold > 0) {
      // Even before we finish the adjust, we can have a lower bound on the
      // activily loss using this divisor, and so we can abort early. This is
      // similar to what is done below in the function.
      bool early_abort = false;
      double loss_lb = 0.0;
      const double threshold = ToDouble(initial_rhs_remainder);

      for (int i = 0; i < relevant_coeffs.size(); ++i) {
        // Compute the difference of coeff with the next multiple of divisor.
        const IntegerValue coeff = relevant_coeffs[i];
        const IntegerValue remainder =
            CeilRatio(coeff, divisor) * divisor - coeff;

        if (divisor - remainder <= initial_rhs_remainder) {
          // We do not know exactly f() yet, but it will always round to the
          // floor of the division by divisor in this case.
          loss_lb += ToDouble(divisor - remainder) * relevant_lp_values[i];
          if (loss_lb >= threshold) {
            early_abort = true;
            break;
          }
        }

        // Adjust coeff of the form k * divisor - epsilon.
        const IntegerValue diff = relevant_bound_diffs[i];
        if (remainder > 0 && remainder <= adjust_threshold &&
            CapProd(diff.value(), remainder.value()) <= adjust_threshold) {
          temp_ub += remainder * diff;
          adjusted_coeffs.push_back({i, coeff + remainder});
        }
      }

      if (early_abort) continue;
    }

    // Create the super-additive function f().
    const IntegerValue rhs_remainder =
        temp_ub - FloorRatio(temp_ub, divisor) * divisor;
    if (rhs_remainder == 0) continue;

    const auto f = GetSuperAdditiveRoundingFunction(rhs_remainder, divisor,
                                                    max_t, options.max_scaling);

    // As we round coefficients, we will compute the loss compared to the
    // current scaled constraint activity. As soon as this loss crosses the
    // slack, then we known that there is no violation and we can abort early.
    //
    // TODO(user): modulo the scaling, we could compute the exact threshold
    // using our current best cut. Note that we also have to account the change
    // in slack due to the adjust code above.
    const double scaling = ToDouble(f(divisor)) / ToDouble(divisor);
    const double threshold = scaling * ToDouble(rhs_remainder);
    double loss = 0.0;

    // Apply f() to the cut and compute the cut violation. Note that it is
    // okay to just look at the relevant indices since the other have a lp
    // value which is almost zero. Doing it like this is faster, and even if
    // the max_magnitude might be off it should still be relevant enough.
    double violation = -ToDouble(f(temp_ub));
    double l2_norm = 0.0;
    bool early_abort = false;
    int adjusted_coeffs_index = 0;
    for (int i = 0; i < relevant_coeffs.size(); ++i) {
      IntegerValue coeff = relevant_coeffs[i];

      // Adjust coeff according to our previous computation if needed.
      if (adjusted_coeffs_index < adjusted_coeffs.size() &&
          adjusted_coeffs[adjusted_coeffs_index].first == i) {
        coeff = adjusted_coeffs[adjusted_coeffs_index].second;
        adjusted_coeffs_index++;
      }

      if (coeff == 0) continue;
      const IntegerValue new_coeff = f(coeff);
      const double new_coeff_double = ToDouble(new_coeff);
      const double lp_value = relevant_lp_values[i];

      l2_norm += new_coeff_double * new_coeff_double;
      violation += new_coeff_double * lp_value;
      loss += (scaling * ToDouble(coeff) - new_coeff_double) * lp_value;
      if (loss >= threshold) {
        early_abort = true;
        break;
      }
    }
    if (early_abort) continue;

    // Here we scale by the L2 norm over the "relevant" positions. This seems
    // to work slighly better in practice.
    violation /= sqrt(l2_norm);
    if (violation > best_scaled_violation) {
      best_scaled_violation = violation;
      best_divisor = divisor;
    }
  }

  if (best_divisor == 0) {
    *cut = LinearConstraint(IntegerValue(0), IntegerValue(0));
    return;
  }

  // Adjust coefficients.
  //
  // TODO(user): It might make sense to also adjust the one with a small LP
  // value, but then the cut will be slighlty different than the one we computed
  // above. Try with and without maybe?
  const IntegerValue initial_rhs_remainder =
      cut->ub - FloorRatio(cut->ub, best_divisor) * best_divisor;
  const IntegerValue adjust_threshold =
      (best_divisor - initial_rhs_remainder - 1) / IntegerValue(size);
  if (adjust_threshold > 0) {
    for (int i = 0; i < relevant_indices.size(); ++i) {
      const int index = relevant_indices[i];
      const IntegerValue diff = relevant_bound_diffs[i];
      if (diff > adjust_threshold) continue;

      // Adjust coeff of the form k * best_divisor - epsilon.
      const IntegerValue coeff = cut->coeffs[index];
      const IntegerValue remainder =
          CeilRatio(coeff, best_divisor) * best_divisor - coeff;
      if (CapProd(diff.value(), remainder.value()) <= adjust_threshold) {
        cut->ub += remainder * diff;
        cut->coeffs[index] += remainder;
      }
    }
  }

  // Create the super-additive function f().
  //
  // TODO(user): Try out different rounding function and keep the best. We can
  // change max_t and max_scaling. It might not be easy to choose which cut is
  // the best, but we can at least know for sure if one dominate the other
  // completely. That is, if for all coeff f(coeff)/f(divisor) is greater than
  // or equal to the same value for another function f.
  const IntegerValue rhs_remainder =
      cut->ub - FloorRatio(cut->ub, best_divisor) * best_divisor;
  auto f = GetSuperAdditiveRoundingFunction(rhs_remainder, best_divisor, max_t,
                                            options.max_scaling);

  // Look amongst all our possible function f() for one that dominate greedily
  // our current best one. Note that we prefer lower scaling factor since that
  // result in a cut with lower coefficients.
  std::vector<IntegerValue> remainders;
  for (int i = 0; i < size; ++i) {
    const IntegerValue coeff = cut->coeffs[i];
    const IntegerValue r =
        coeff - FloorRatio(coeff, best_divisor) * best_divisor;
    if (r > rhs_remainder) remainders.push_back(r);
  }
  gtl::STLSortAndRemoveDuplicates(&remainders);
  if (remainders.size() <= 100) {
    std::vector<IntegerValue> best_rs;
    for (const IntegerValue r : remainders) {
      best_rs.push_back(f(r));
    }
    IntegerValue best_d = f(best_divisor);

    // Note that the complexity seems high 100 * 2 * options.max_scaling, but
    // this only run on cuts that are already efficient and the inner loop tend
    // to abort quickly. I didn't see this code in the cpu profile so far.
    std::vector<IntegerValue> rs;
    for (const IntegerValue t : {IntegerValue(1), max_t}) {
      for (IntegerValue s(2); s <= options.max_scaling; ++s) {
        const auto g =
            GetSuperAdditiveRoundingFunction(rhs_remainder, best_divisor, t, s);
        int num_strictly_better = 0;
        rs.clear();
        const IntegerValue d = g(best_divisor);
        for (int i = 0; i < best_rs.size(); ++i) {
          const IntegerValue temp = g(remainders[i]);
          if (temp * best_d < best_rs[i] * d) break;
          if (temp * best_d > best_rs[i] * d) num_strictly_better++;
          rs.push_back(temp);
        }
        if (rs.size() == best_rs.size() && num_strictly_better > 0) {
          f = g;
          best_rs = rs;
          best_d = d;
        }
      }
    }
  }

  // Apply f() to the cut.
  //
  // Remove the bound shifts so the constraint is expressed in the original
  // variables and do some basic post-processing.
  cut->ub = f(cut->ub);
  for (int i = 0; i < size; ++i) {
    IntegerValue coeff = cut->coeffs[i];
    if (coeff == 0) continue;
    cut->coeffs[i] = coeff = f(coeff);
    if (coeff == 0) continue;
    if (change_sign_at_postprocessing[i]) {
      cut->ub = IntegerValue(
          CapAdd((coeff * -upper_bounds[i]).value(), cut->ub.value()));
      cut->coeffs[i] = -coeff;
    } else {
      cut->ub = IntegerValue(
          CapAdd((coeff * lower_bounds[i]).value(), cut->ub.value()));
    }
  }
  RemoveZeroTerms(cut);
  DivideByGCD(cut);
}

CutGenerator CreatePositiveMultiplicationCutGenerator(IntegerVariable z,
                                                      IntegerVariable x,
                                                      IntegerVariable y,
                                                      Model* model) {
  CutGenerator result;
  result.vars = {z, x, y};

  IntegerTrail* const integer_trail = model->GetOrCreate<IntegerTrail>();
  result.generate_cuts =
      [z, x, y, integer_trail](
          const gtl::ITIVector<IntegerVariable, double>& lp_values,
          LinearConstraintManager* manager) {
        const int64 x_lb = integer_trail->LevelZeroLowerBound(x).value();
        const int64 x_ub = integer_trail->LevelZeroUpperBound(x).value();
        const int64 y_lb = integer_trail->LevelZeroLowerBound(y).value();
        const int64 y_ub = integer_trail->LevelZeroUpperBound(y).value();

        // TODO(user): Compute a better bound (int_max / 4 ?).
        const int64 kMaxSafeInteger = (int64{1} << 53) - 1;

        if (CapProd(x_ub, y_ub) >= kMaxSafeInteger) {
          VLOG(3) << "Potential overflow in PositiveMultiplicationCutGenerator";
          return;
        }

        const double x_lp_value = lp_values[x];
        const double y_lp_value = lp_values[y];
        const double z_lp_value = lp_values[z];

        // TODO(user): As the bounds change monotonically, these cuts
        // dominate any previous one.  try to keep a reference to the cut and
        // replace it. Alternatively, add an API for a level-zero bound change
        // callback.

        // Cut -z + x_coeff * x + y_coeff* y <= rhs
        auto try_add_above_cut = [manager, z_lp_value, x_lp_value, y_lp_value,
                                  x, y, z, lp_values](
                                     int64 x_coeff, int64 y_coeff, int64 rhs) {
          if (-z_lp_value + x_lp_value * x_coeff + y_lp_value * y_coeff >=
              rhs + kMinCutViolation) {
            LinearConstraint cut;
            cut.vars.push_back(z);
            cut.coeffs.push_back(IntegerValue(-1));
            if (x_coeff != 0) {
              cut.vars.push_back(x);
              cut.coeffs.push_back(IntegerValue(x_coeff));
            }
            if (y_coeff != 0) {
              cut.vars.push_back(y);
              cut.coeffs.push_back(IntegerValue(y_coeff));
            }
            cut.lb = kMinIntegerValue;
            cut.ub = IntegerValue(rhs);
            manager->AddCut(cut, "PositiveProduct", lp_values);
          }
        };

        // Cut -z + x_coeff * x + y_coeff* y >= rhs
        auto try_add_below_cut = [manager, z_lp_value, x_lp_value, y_lp_value,
                                  x, y, z, lp_values](
                                     int64 x_coeff, int64 y_coeff, int64 rhs) {
          if (-z_lp_value + x_lp_value * x_coeff + y_lp_value * y_coeff <=
              rhs - kMinCutViolation) {
            LinearConstraint cut;
            cut.vars.push_back(z);
            cut.coeffs.push_back(IntegerValue(-1));
            if (x_coeff != 0) {
              cut.vars.push_back(x);
              cut.coeffs.push_back(IntegerValue(x_coeff));
            }
            if (y_coeff != 0) {
              cut.vars.push_back(y);
              cut.coeffs.push_back(IntegerValue(y_coeff));
            }
            cut.lb = IntegerValue(rhs);
            cut.ub = kMaxIntegerValue;
            manager->AddCut(cut, "PositiveProduct", lp_values);
          }
        };

        // McCormick relaxation of bilinear constraints. These 4 cuts are the
        // exact facets of the x * y polyhedron for a bounded x and y.
        //
        // Each cut correspond to plane that contains two of the line
        // (x=x_lb), (x=x_ub), (y=y_lb), (y=y_ub). The easiest to
        // understand them is to draw the x*y curves and see the 4
        // planes that correspond to the convex hull of the graph.
        try_add_above_cut(y_lb, x_lb, x_lb * y_lb);
        try_add_above_cut(y_ub, x_ub, x_ub * y_ub);
        try_add_below_cut(y_ub, x_lb, x_lb * y_ub);
        try_add_below_cut(y_lb, x_ub, x_ub * y_lb);
      };

  return result;
}

CutGenerator CreateSquareCutGenerator(IntegerVariable y, IntegerVariable x,
                                      Model* model) {
  CutGenerator result;
  result.vars = {y, x};

  IntegerTrail* integer_trail = model->GetOrCreate<IntegerTrail>();
  result.generate_cuts =
      [y, x, integer_trail](
          const gtl::ITIVector<IntegerVariable, double>& lp_values,
          LinearConstraintManager* manager) {
        const int64 x_ub = integer_trail->LevelZeroUpperBound(x).value();
        const int64 x_lb = integer_trail->LevelZeroLowerBound(x).value();

        if (x_lb == x_ub) return;

        // Check for potential overflows.
        if (x_ub > (int64{1} << 31)) return;
        DCHECK_GE(x_lb, 0);

        const double y_lp_value = lp_values[y];
        const double x_lp_value = lp_values[x];

        // First cut: target should be below the line:
        //     (x_lb, x_lb ^ 2) to (x_ub, x_ub ^ 2).
        // The slope of that line is (ub^2 - lb^2) / (ub - lb) = ub + lb.
        const int64 y_lb = x_lb * x_lb;
        const int64 above_slope = x_ub + x_lb;
        const double max_lp_y = y_lb + above_slope * (x_lp_value - x_lb);
        if (y_lp_value >= max_lp_y + kMinCutViolation) {
          // cut: y <= (x_lb + x_ub) * x - x_lb * x_ub
          LinearConstraint above_cut;
          above_cut.vars.push_back(y);
          above_cut.coeffs.push_back(IntegerValue(1));
          above_cut.vars.push_back(x);
          above_cut.coeffs.push_back(IntegerValue(-above_slope));
          above_cut.lb = kMinIntegerValue;
          above_cut.ub = IntegerValue(-x_lb * x_ub);
          manager->AddCut(above_cut, "SquareUpper", lp_values);
        }

        // Second cut: target should be above all the lines
        //     (value, value ^ 2) to (value + 1, (value + 1) ^ 2)
        // The slope of that line is 2 * value + 1
        //
        // Note that we only add one of these cuts. The one for x_lp_value in
        // [value, value + 1].
        const int64 x_floor = static_cast<int64>(std::floor(x_lp_value));
        const int64 below_slope = 2 * x_floor + 1;
        const double min_lp_y =
            below_slope * x_lp_value - x_floor - x_floor * x_floor;
        if (min_lp_y >= y_lp_value + kMinCutViolation) {
          // cut: y >= below_slope * (x - x_floor) + x_floor ^ 2
          //    : y >= below_slope * x - x_floor ^ 2 - x_floor
          LinearConstraint below_cut;
          below_cut.vars.push_back(y);
          below_cut.coeffs.push_back(IntegerValue(1));
          below_cut.vars.push_back(x);
          below_cut.coeffs.push_back(-IntegerValue(below_slope));
          below_cut.lb = IntegerValue(-x_floor - x_floor * x_floor);
          below_cut.ub = kMaxIntegerValue;
          manager->AddCut(below_cut, "SquareLower", lp_values);
        }
      };

  return result;
}

void ImpliedBoundsProcessor::ProcessUpperBoundedConstraint(
    const gtl::ITIVector<IntegerVariable, double>& lp_values,
    LinearConstraint* cut) const {
  tmp_terms_.clear();
  IntegerValue new_ub = cut->ub;
  bool changed = false;

  // TODO(user): we could relax a bit this test.
  int64 overflow_detection = 0;

  const int size = cut->vars.size();
  for (int i = 0; i < size; ++i) {
    // Make sure we have a positive coefficient.
    IntegerVariable var = cut->vars[i];
    IntegerValue coeff = cut->coeffs[i];
    if (coeff < 0) {
      coeff = -coeff;
      var = NegationOf(var);
    }

    // Skip variable at their Lower bound in the relaxation.
    const IntegerValue lb = integer_trail_->LevelZeroLowerBound(var);
    if (lp_values[var] < lb.value() + 1e-6) {
      tmp_terms_.push_back({var, coeff});
      continue;
    }

    bool keep_original_term = true;
    for (const ImpliedBoundEntry& entry :
         implied_bounds_->GetImpliedBounds(var)) {
      // Only process entries with a Boolean variable currently part of the LP
      // we are considering for this cut.
      //
      // TODO(user): the more we use cuts, the less it make sense to have a lot
      // of small independent LPs.
      if (!lp_vars_.contains(PositiveVariable(entry.literal_view))) {
        continue;
      }

      const IntegerValue diff = entry.lower_bound - lb;
      CHECK_GE(diff, 0);
      const double lp_value = entry.is_positive
                                  ? lp_values[entry.literal_view]
                                  : 1.0 - lp_values[entry.literal_view];

      // Only consider "tight" implied bounds. The implied bound could be above
      // if the relaxation of the implied relation wasn't added to the LP.
      //
      // TODO(user): Just generate an implied cut then?
      if (lb.value() + lp_value * diff.value() + 1e-6 < lp_values[var]) {
        continue;
      }

      if (CapProd(std::abs(coeff.value()), diff.value()) >= kMaxIntegerValue) {
        VLOG(2) << "Overflow";
        return;
      }

      if (entry.is_positive) {
        // X >= Indicator * (bound - lb) + lb
        tmp_terms_.push_back({entry.literal_view, coeff * diff});
        if (!AddProductTo(-coeff, lb, &new_ub)) {
          VLOG(2) << "Overflow";
          return;
        }
      } else {
        // X >= (1 - Indicator) * (bound - lb) + lb
        // X >= -Indicator * (bound - lb) + bound
        tmp_terms_.push_back({entry.literal_view, -coeff * diff});
        if (!AddProductTo(-coeff, entry.lower_bound, &new_ub)) {
          VLOG(2) << "Overflow";
          return;
        }
      }

      changed = true;
      keep_original_term = false;
      VLOG(2) << "var = " << var << " (" << lp_values[var] << ") "
              << entry.literal_view << " (" << lp_values[entry.literal_view]
              << " == " << (entry.is_positive ? 1 : 0)
              << ") => var >=" << entry.lower_bound << " "
              << integer_trail_->InitialVariableDomain(var);
      break;
    }

    if (keep_original_term) {
      tmp_terms_.push_back({var, coeff});
    }
    overflow_detection =
        CapAdd(overflow_detection, std::abs(tmp_terms_.back().second.value()));
  }

  if (overflow_detection >= kMaxIntegerValue) {
    VLOG(2) << "Overflow";
    return;
  }
  if (!changed) return;

  // Update the cut.
  //
  // Note that because of our overflow_detection variable, there should be
  // no integer overflow when we merge identical terms.
  cut->lb = kMinIntegerValue;  // Not relevant.
  cut->ub = new_ub;
  CleanTermsAndFillConstraint(&tmp_terms_, cut);
}

namespace {

void TryToGenerateAllDiffCut(
    const std::vector<std::pair<double, IntegerVariable>>& sorted_vars_lp,
    const IntegerTrail& integer_trail,
    const gtl::ITIVector<IntegerVariable, double>& lp_values,
    LinearConstraintManager* manager) {
  Domain current_union;
  std::vector<IntegerVariable> current_set_vars;
  double sum = 0.0;
  for (auto value_var : sorted_vars_lp) {
    sum += value_var.first;
    const IntegerVariable var = value_var.second;
    Domain var_domain = integer_trail.InitialVariableDomain(var);
    // TODO(user): The union of the domain of the variable being considered
    // does not give the tightest bounds, try to get better bounds.
    current_union = current_union.UnionWith(var_domain);
    current_set_vars.push_back(var);
    const int64 required_min_sum =
        SumOfKMinValueInDomain(current_union, current_set_vars.size());
    const int64 required_max_sum =
        SumOfKMaxValueInDomain(current_union, current_set_vars.size());
    if (sum < required_min_sum || sum > required_max_sum) {
      LinearConstraint cut;
      for (IntegerVariable var : current_set_vars) {
        cut.AddTerm(var, IntegerValue(1));
      }
      cut.lb = IntegerValue(required_min_sum);
      cut.ub = IntegerValue(required_max_sum);
      manager->AddCut(cut, "all_diff", lp_values);
      // NOTE: We can extend the current set but it is more helpful to generate
      // the cut on a different set of variables so we reset the counters.
      sum = 0.0;
      current_set_vars.clear();
      current_union = Domain();
    }
  }
}

}  // namespace

CutGenerator CreateAllDifferentCutGenerator(
    const std::vector<IntegerVariable>& vars, Model* model) {
  CutGenerator result;
  result.vars = vars;
  IntegerTrail* integer_trail = model->GetOrCreate<IntegerTrail>();
  Trail* trail = model->GetOrCreate<Trail>();
  result.generate_cuts =
      [vars, integer_trail, trail](
          const gtl::ITIVector<IntegerVariable, double>& lp_values,
          LinearConstraintManager* manager) {
        // These cuts work at all levels but the generator adds too many cuts on
        // some instances and degrade the performance so we only use it at level
        // 0.
        if (trail->CurrentDecisionLevel() > 0) return;
        std::vector<std::pair<double, IntegerVariable>> sorted_vars;
        for (const IntegerVariable var : vars) {
          if (integer_trail->LevelZeroLowerBound(var) ==
              integer_trail->LevelZeroUpperBound(var)) {
            continue;
          }
          sorted_vars.push_back(std::make_pair(lp_values[var], var));
        }
        std::sort(sorted_vars.begin(), sorted_vars.end());
        TryToGenerateAllDiffCut(sorted_vars, *integer_trail, lp_values,
                                manager);
        // Other direction.
        std::reverse(sorted_vars.begin(), sorted_vars.end());
        TryToGenerateAllDiffCut(sorted_vars, *integer_trail, lp_values,
                                manager);
      };
  VLOG(1) << "Created all_diff cut generator of size: " << vars.size();
  return result;
}

}  // namespace sat
}  // namespace operations_research
