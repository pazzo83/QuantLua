-- ql_time.lua
local current_folder = (...):gsub('%.[^%.]+$', '')

require(current_folder .. '.class')
require(current_folder .. '.helpers')

local time = require 'time'

local ql_time = {}

-- constants for days in week of month calculation - based off Julia impl
local TWENTYNINE = {1,8,15,22,29}
local THIRTY = {1,2,8,9,15,16,22,23,29,30}
local THIRTYONE = {1,2,3,8,9,10,15,16,17,22,23,24,29,30,31}
local DAYSINMONTH = {31,28,31,30,31,30,31,31,30,31,30,31}

ql_time.Calendar = class(function(cal, added_holidays, removed_holidays)
	cal.added_holidays = added_holidays
	cal.removed_holidays = removed_holidays
end)

function ql_time.Calendar:is_business_day(dt)
	if dt:weekday() == 6 or dt:weekday() == 7 or self:is_holiday(dt) then
		return false
	else
		return true
	end
end

ql_time.USSettlementCalendar = class(ql_time.Calendar, function(cal, added_holidays, removed_holidays)
	ql_time.Calendar.init(cal, added_holidays, removed_holidays)
end)

ql_time.Following = class()

function ql_time.Following:adjust_date(cal, dt)
	local dd = dt
	while not cal:is_business_day(dd) do
		dd = dd + time.days(1)
	end

	return dd
end

local function day_of_week_of_month(d)
	local dd = d:day()

	if dd < 8 then
		return 1
	elseif dd < 15 then
		return 2
	elseif dd < 22 then
		return 3
	elseif dd < 29 then
		return 4
	else
		return 5
	end
end

local function days_in_month(y, m)
	local num_days = DAYSINMONTH[m]
	if time.isleapyear(y) and m == 2 then
		num_days = num_days + 1
	end

	return num_days
end

local function adjust_holidays_us(d)
	if d:weekday() == 6 then
		return d - time.days(1)
	end
	if d:weekday() == 7 then
		return d + time.days(1)
	end

	return d
end

local function easter_calc(y)
	-- golden number g
	local g = y % 19 + 1

	-- solar correction s
	local s = math.floor((y - 1600) / 100) - math.floor((y - 1600) / 400)

	-- lunar correction l
	local l = math.floor((math.floor((y - 1400) / 100) * 8) / 25)

	-- uncorrected date for Pascal full moon p1
	local p1 = (3 - 11 * g + s - l) % 30

	-- correction
	local p = 0
	if p1 == 29 or (p1 == 28 and g > 11) then
		p = p1 - 1
	else
		p = p1
	end

	-- dominical number d (following Sunday after the pascal moon)
	local d = (y + math.floor(y / 4) - math.floor(y / 100) + math.floor(y / 400)) % 7

	local d1 = (8 - d) % 7

	local p2 = (3 + p) % 7

	local x1 = d1 - p2

	local x = (x1 - 1) % 7 + 1

	local e = p + x

	if e < 11 then
		return time.date(y, 3, e + 21)
	else
		return time.date(y, 4, e - 10)
	end
end

local function days_of_week_in_month(dt)
	local y, m, d = dt:ymd()
	local ld = days_in_month(y, m)
	if ld == 28 then
		return 4
	elseif ld == 29 then
		if has_value(TWENTYNINE, d) then
			return 5
		else
			return 4
		end
	elseif ld == 30 then
		if has_value(THIRTY, d) then
			return 5
		else
			return 4
		end
	else
		if has_value(THIRTYONE, d) then
			return 5
		else
			return 4
		end
	end
end

function ql_time.USSettlementCalendar:is_holiday(dt)
	local yy, mm, dd = dt:ymd()
	if (
			 -- New Year's Day
			adjust_holidays_us(time.date(yy, 1, 1)) == dt
			or
			-- New Year's Day on the previous year when 1st Jan is Saturday
			(mm == 12 and  dd == 31 and dt:weekday() == 5)
			or
			-- Birthday of Martin Luther King, Jr.
			(dt:weekday() == 1 and day_of_week_of_month(dt) ==3 and mm == 1)
			or
			-- Washington's Birthday
			(dt:weekday() == 1 and day_of_week_of_month(dt) ==3 and mm == 2)
			or
		    -- Good Friday
		    easter_calc(yy) - time.days(2) == dt
		    or
			-- Memorial Day is the last Monday in May
			(dt:weekday() == 1 and day_of_week_of_month(dt) == days_of_week_in_month(dt) and mm == 5)
			or
			-- Independence Day
			adjust_holidays_us(time.date(yy, 7, 4)) == dt
			or
			-- Labor Day is the first Monday in September
			(dt:weekday() == 1 and day_of_week_of_month(dt) == 1 and mm == 9)
			or
			-- Columbus Day is the second Monday in October
			(dt:weekday() == 1 and day_of_week_of_month(dt) == 2 and mm == 10)
			or
			-- Veterans Day
			adjust_holidays_us(time.date(yy, 11, 11)) == dt
			or
			-- Thanksgiving Day is the fourth Thursday in November
			(dt:weekday() == 4 and day_of_week_of_month(dt) == 4 and mm == 11)
			or
			-- Christmas
			adjust_holidays_us(time.date(yy, 12, 25)) == dt
		) then
		return true
	end

	return false
end

ql_time.Schedule = class(function(sched, effective_date, termination_date, tenor, convention, term_convention, end_of_month, calendar, dates)
	-- main init
	-- adjust end date if necessary
	dates[#dates] = term_convention:adjust_date(calendar, dates[#dates])

	sched.effective_date = effective_date
	sched.termination_date = termination_date
	sched.tenor = tenor
	sched.convention = convention
	sched.end_of_month = end_of_month
	sched.calendar = calendar
	sched.dates = dates
end)

function ql_time.Schedule:__tostring()
	local return_str = ""
	for i, v in ipairs(self.dates) do
		return_str = return_str .. tostring(v)
	end

	return return_str
end

ql_time.ForwardSchedule = class(ql_time.Schedule, function(sched, effective_date, termination_date, tenor, convention, term_convention, end_of_month, calendar)
	-- setup dates
	local dates = {}
	local date_iter = effective_date
	local iter = 1
	dates[1] = date_iter

	date_iter = date_iter + tenor

	while date_iter < termination_date do
		iter = iter + 1
		dates[iter] = convention:adjust_date(calendar, date_iter)

		date_iter = date_iter + tenor
	end

	dates[iter + 1] = termination_date

	-- super init
	ql_time.Schedule.init(sched, effective_date, termination_date, tenor, convention, term_convention, end_of_month, calendar, dates)
end)

return ql_time