-- ql math
local current_folder = (...):gsub('%.[^%.]+$', '')

require(current_folder .. '.class')

local ql_math = {}
-- solvers
ql_math.Solver = class(function(solver, max_evals, lower_bound_enforced, upper_bound_enforced, lower_bound, upper_bound)
	solver.max_evals = max_evals or 100
	solver.lower_bound_enforced = lower_bound_enforced or false
	solver.upper_bound_enforced = upper_bound_enforced or false
	solver.lower_bound = lower_bound or 0.0
	solver.upper_bound = upper_bound or 0.0
end)

ql_math.BrentSolver = class(ql_math.Solver, function(solver, max_evals, lower_bound_enforced, upper_bound_enforced, lower_bound, upper_bound)
	ql_math.Solver.init(solver, max_evals, lower_bound_enforced, upper_bound_enforced, lower_bound, upper_bound)
end)

