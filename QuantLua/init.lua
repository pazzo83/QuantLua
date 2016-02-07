-- init.lua
local current_folder = (...):gsub('%.init$', '')

local lazy = require(current_folder .. '.lazy')
local bonds = require(current_folder .. '.bonds')
local ql_time = require(current_folder .. '.ql_time')

local QuantLua = {}

QuantLua.lazy = lazy
QuantLua.bonds = bonds
QuantLua.ql_time = ql_time

return QuantLua