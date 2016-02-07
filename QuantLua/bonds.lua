local current_folder = (...):gsub('%.[^%.]+$', '')

require(current_folder .. '.class')
local lazy = require(current_folder .. '.lazy')

local bonds = {}

bonds.Bond = class(lazy.LazyObject, function(bond, faceValue, schedule)
	lazy.LazyObject.init(bond)
	bond.faceValue = faceValue
	bond.schedule = schedule
end)

function bonds.Bond:__tostring()
	local return_str = "Bond: value= "..self.faceValue
	if self.schedule then
		return_str = return_str .. " schedule: "..tostring(self.schedule)
	end
	return return_str
end

return bonds