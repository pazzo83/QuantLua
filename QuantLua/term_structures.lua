-- Term Structures
local current_folder = (...):gsub('%.[^%.]+$', '')

require(current_folder .. '.class')
local lazy = require(current_folder .. '.lazy')
local alg = require 'sci.alg'

local term_structures = {}
-- bootstrapping
term_structures.BootStrap = class()
term_structures.IterativeBootstrap = class(term_structures.BootStrap, function(boot, solver, first_solver)
	boot.solver = solver
	boot.first_solver = first_solver
	boot.errors = {}
end)

term_structures.TermStructure = class(lazy.LazyObject, function(ts, settlement_days, reference_date, calendar, day_counter, jump_times, jump_dates)
	ts.settlement_days = settlement_days
	ts.reference_date = reference_date
	ts.calendar = calendar
	ts.day_counter = day_counter
	ts.jump_times = jump_times
	ts.jump_dates = jump_dates
end)

term_structures.YieldTermStructure = class(term_structures.TermStructure)
term_structures.Curve = class(term_structures.YieldTermStructure)
term_structures.InterpolatedCurve = class(term_structures.Curve, function(ic, settlement_days, reference_date, calendar, day_counter, times, data, interpolator, n)
	term_structures,TermStructure.init(ic, settlement_days, reference_date, calendar, day_counter)
	n = n or 1
	ic.times = times or alg.vec(n)
	ic.data = data or alg.vec(n)
	ic.interpolator = interpolator
end)

return term_structures