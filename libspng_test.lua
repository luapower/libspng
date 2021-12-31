local pp = require'pp'
local fs = require'fs'
local spng = require'libspng'

local f = assert(fs.open'media/png/good/z09n2c08.png')
local img = assert(spng.open{read = f:buffered_read()})
local bmp = assert(img:load{accept = {bgra8 = true}})
assert(f:close())

pp(bmp)

local f = assert(fs.open('media/png/good/z09n2c08_1.png', 'w'))
assert(spng.save{
	bitmap = bmp,
	write = function(buf, sz)
		return f:write(buf, sz)
	end,
})
