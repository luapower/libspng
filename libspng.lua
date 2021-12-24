
--libspng LuaJIT binding.
--Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
require'libspng_h'
local C = ffi.load'spng'

