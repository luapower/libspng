
--libspng LuaJIT binding.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'libspng_demo'; return end

local bit = require'bit'
local ffi = require'ffi'
require'libspng_h'
local C = ffi.load'spng'

--given a row stride, return the next larger stride that is a multiple of 4.
local function pad_stride(stride)
	return bit.band(stride + 3, bit.bnot(3))
end

local spng = {version = ffi.string(C.spng_version_string())}

local formats = {                                --bpc:
	[C.SPNG_COLOR_TYPE_GRAYSCALE      ] = 'g'   , --1,2,4,8,16
	[C.SPNG_COLOR_TYPE_TRUECOLOR      ] = 'rgb' , --8,16
	[C.SPNG_COLOR_TYPE_INDEXED        ] = 'i'   , --8 (with 1,2,4,8 indexes)
	[C.SPNG_COLOR_TYPE_GRAYSCALE_ALPHA] = 'ga'  , --8,16
	[C.SPNG_COLOR_TYPE_TRUECOLOR_ALPHA] = 'rgba', --8,16
}

--all conversions that libspng implements, in order of preference,
--with or without gamma conversion: {source = {dest1, ...}}.
local rgb8   = {'rgba8', 'bgra8', 'rgb8', 'rgba16'}
local rgba8  = {'rgba8', 'bgra8', 'rgba16', 'rgb8'}
local rgb16  = {'rgba16', 'rgba8', 'bgra8', 'rgb8'}
local rgba16 = {'rgba16', 'rgba8', 'bgra8', 'rgb8'}
local g8     = {'ga8', 'rgba8', 'bgra8', 'rgba16', 'g8', 'rgb8'}
local ga8    = {'ga8', 'rgba8', 'bgra8', 'rgba16', 'g8', 'rgb8'}
local g16    = {'ga16', 'rgba16', 'rgba8', 'bgra8', 'rgb8'}
local ga16   = {'ga16', 'rgba16', 'rgba8', 'bgra8', 'rgb8'}
local conversions = {
	g1     = g8,
	g2     = g8,
	g4     = g8,
	g8     = g8,
	ga8    = ga8,
	g16    = g16,
	ga16   = ga16,
	rgb8   = rgb8,
	rgba8  = rgba8,
	rgb16  = rgb16,
	rgba16 = rgba16,
	i1     = rgb8,
	i2     = rgb8,
	i4     = rgb8,
	i8     = rgb8,
}

local dest_formats_no_gamma = {
	rgba8  = C.SPNG_FMT_RGBA8,
	bgra8  = C.SPNG_FMT_RGBA8,
	rgba16 = C.SPNG_FMT_RGBA16,
	rgb8   = C.SPNG_FMT_RGB8,
	g8     = C.SPNG_FMT_G8,
	ga16   = C.SPNG_FMT_GA16,
	ga8    = C.SPNG_FMT_GA8,
}

local dest_formats_gamma = {
	rgba8  = C.SPNG_FMT_RGBA8,
	bgra8  = C.SPNG_FMT_RGBA8,
	rgba16 = C.SPNG_FMT_RGBA16,
	rgb8   = C.SPNG_FMT_RGB8,
}

local function best_fmt(raw_fmt, accept, gamma, indexed)
	local dest_formats = gamma and dest_formats_gamma or dest_formats_no_gamma
	if accept and conversions[raw_fmt] then --source format convertible
		for _,bmp_fmt in ipairs(conversions[raw_fmt]) do
			if accept[bmp_fmt] then --found a dest format
				local spng_fmt = dest_formats[bmp_fmt]
				if spng_fmt then --dest format is available
					return bmp_fmt, spng_fmt
				end
			end
		end
	end
	if indexed then
		return 'bgra8', C.SPNG_FMT_RGBA8
	end
	return raw_fmt, C.SPNG_FMT_PNG
end

local function struct_getter(ct, get) --getter for a struct type
	local ct = ffi.typeof(ct)
	return function(ctx)
		local s = ct()
		return get(ctx, s) == 0 and s or nil
	end
end
local function prim_getter(ct, get) --getter for a primitive type
	local ct = ffi.typeof(ct)
	return function(ctx)
		local s = ct()
		return get(ctx, s) == 0 and s[0] or nil
	end
end
local function list_getter(ct, get) --getter for a list of structs
	local ct = ffi.typeof(ct)
	return function(ctx)
		local n = ffi.new'uint32_t[1]'
		if get(ctx, nil, n) ~= 0 then return nil end
		n = n[0]
		local s = ct(n)
		if get(ctx, s, n) ~= 0 then return nil end
		return s, n
	end
end
local chunk_decoders = {
	ihdr     = struct_getter('struct spng_ihdr'    , C.spng_get_ihdr),
	plte     = struct_getter('struct spng_plte'    , C.spng_get_plte),
	trns     = struct_getter('struct spng_trns'    , C.spng_get_trns),
	chrm     = struct_getter('struct spng_chrm'    , C.spng_get_chrm),
	chrm_int = struct_getter('struct spng_chrm_int', C.spng_get_chrm_int),
	gama     =   prim_getter('double[1]'           , C.spng_get_gama),
	gama_int =   prim_getter('uint32_t[1]'         , C.spng_get_gama_int),
	iccp     = struct_getter('struct spng_iccp'    , C.spng_get_iccp),
	sbit     = struct_getter('struct spng_sbit'    , C.spng_get_sbit),
	srgb     =   prim_getter('uint8_t[1]'          , C.spng_get_srgb),
	bkgd     = struct_getter('struct spng_bkgd'    , C.spng_get_bkgd),
	hist     = struct_getter('struct spng_hist'    , C.spng_get_hist),
	phys     = struct_getter('struct spng_phys'    , C.spng_get_phys),
	time     = struct_getter('struct spng_time'    , C.spng_get_time),
	text     =   list_getter('struct spng_text[?]' , C.spng_get_text),
	splt     =   list_getter('struct spng_splt[?]' , C.spng_get_splt),
	offs     = struct_getter('struct spng_offs'    , C.spng_get_offs),
	exif     = struct_getter('struct spng_exif'    , C.spng_get_exif),
	unknown  =   list_getter('struct spng_unknown_chunk', C.spng_get_unknown_chunks),
}

local u8a = ffi.typeof'uint8_t[?]'
local u8p = ffi.typeof'uint8_t*'
local rw_fn_ct = ffi.typeof'spng_rw_fn*'
--^^ very important to typeof this to avoid "table overflow" !

local premultiply_funcs = {
	rgba8  = C.spng_premultiply_alpha_rgba8,
	bgra8  = C.spng_premultiply_alpha_rgba8,
	rgba16 = C.spng_premultiply_alpha_rgba16,
	ga8    = C.spng_premultiply_alpha_ga8,
	ga16   = C.spng_premultiply_alpha_ga16,
}

function spng.open(opt)

	if type(opt) == 'function' then
		opt = {read = opt}
	end
	local read = assert(opt.read, 'read expected')

	local ctx = C.spng_ctx_new(0)
	assert(ctx ~= nil)

	local read_cb
	local function free()
		if read_cb then read_cb:free(); read_cb = nil end
		if ctx then C.spng_ctx_free(ctx); ctx = nil end
	end

	local function check(ret)
		if ret == 0 then return true end
		free()
		return nil, ffi.string(C.spng_strerror(ret))
	end

	local function spng_read(ctx, _, buf, len)
		len = tonumber(len)
		::again::
		local sz = read(buf, len)
		if not sz then return -2 end --SPNG_IO_ERROR
		if sz == 0 then return -1 end -- SPNG_IO_EOF
		if sz < len then --partial read
			len = len - sz
			buf = ffi.cast(u8p, buf) + sz
			goto again
		end
		return 0
	end

	--[[local]] read_cb = ffi.cast(rw_fn_ct, spng_read)
	local ok, err = check(C.spng_set_png_stream(ctx, read_cb, nil))
	if not ok then
		return nil, err
	end
	local ok, err = check(C.spng_decode_chunks(ctx))
	if not ok then
		return nil, err
	end

	local img = {free = free}

	function img:chunk(name)
		return assert(chunk_decoders[name], 'unknown chunk name')(ctx)
	end

	local ihdr = img:chunk'ihdr'
	if not ihdr then
		free()
		return nil, 'header decoding failed'
	end
	img.w = ihdr.width
	img.h = ihdr.height
	local bpc = ihdr.bit_depth
	img.format = formats[ihdr.color_type]..bpc
	img.compressed = ihdr.compression_method ~= 0
	img.interlaced = ihdr.interlace_method ~= C.SPNG_INTERLACE_NONE or nil
	local indexed = ihdr.color_type == C.SPNG_COLOR_TYPE_INDEXED
	ihdr = nil

	function img:load(opt)

		local gamma = opt and opt.gamma
		local accept = opt and opt.accept
		local bmp_fmt, spng_fmt = best_fmt(img.format, accept, gamma, indexed)

		local nb = ffi.new'size_t[1]'
		local ok, err = check(C.spng_decoded_image_size(ctx, spng_fmt, nb))
		if not ok then
			return nil, err
		end
		local row_size = tonumber(nb[0]) / img.h

		local bmp = {w = img.w, h = img.h, format = bmp_fmt}

		bmp.stride = row_size
		if opt and opt.accept and opt.accept.stride_aligned then
			bmp.stride = pad_stride(bmp.stride)
		end
		bmp.size = bmp.stride * bmp.h
		bmp.data = ffi.new(u8a, bmp.size)

		local flags = bit.bor(
			C.SPNG_DECODE_TRNS,
			gamma and C.SPNG_DECODE_GAMMA or 0,
			C.SPNG_DECODE_PROGRESSIVE
		)
		C.spng_decode_image(ctx, nil, 0, spng_fmt, flags)

		local row_info = ffi.new'struct spng_row_info'
		local bottom_up = opt and opt.accept and opt.accept.bottom_up
		bmp.bottom_up = bottom_up
		local row_sz = bmp.size / bmp.h
		while true do
			local ret = C.spng_get_row_info(ctx, row_info)
			if ret ~= 0 then bmp.partial = true; break end
			local i = row_info.row_num
			if bottom_up then i = img.h - i - 1 end
			local row = bmp.data + bmp.stride * i
			local ret = C.spng_decode_row(ctx, row, row_size)
			if ret == 75 then break end --SPNG_EOI
			if ret ~= 0 then bmp.partial = true; break end
		end

		local premultiply_alpha = (not opt or opt.premultiply ~= false)
			and premultiply_funcs[bmp.format]
		if premultiply_alpha then
			premultiply_alpha(bmp.data, bmp.size)
		end

		if bmp.format == 'bgra8' then --cairo's native format.
			C.spng_rgba8_to_bgra8(bmp.data, bmp.size)
		end

		return bmp
	end
	jit.off(img.load) --calls back into Lua through a ffi call.

	return img
end
jit.off(spng.open) --calls back into Lua through a ffi call.

function spng:save(opt)

	--

end

return spng
