local pp = require'pp'
local fs = require'fs'
local spng = require'libspng'

local function load(file)
	local f = assert(fs.open(file))
	local img = assert(spng.open{read = f:buffered_read()})
	local bmp = assert(img:load{accept = {bgra8 = true}})
	assert(f:close())
	return bmp, img
end

local function save(bmp, file)
	local f = assert(fs.open('media/png/good/z09n2c08_1.png', 'w'))
	assert(spng.save{
		bitmap = bmp,
		write = function(buf, sz)
			return f:write(buf, sz)
		end,
	})
	assert(f:close())
end

local bmp, img = load'media/png/good/z09n2c08.png'
pp(bmp, img)
save(bmp, 'media/png/good/z09n2c08_1.png')
local bmp, img = load'media/png/good/z09n2c08_1.png'
pp(bmp, img)
