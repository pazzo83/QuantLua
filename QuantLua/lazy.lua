local current_folder = (...):gsub('%.[^%.]+$', '')
require(current_folder .. '.class')

local lazy = {}

lazy.LazyObject = class(function(lz, calculated, frozen)
	calculated = calculated or false
	frozen = frozen or false
	lz.calculated = calculated
	lz.frozen = frozen
end)

return lazy