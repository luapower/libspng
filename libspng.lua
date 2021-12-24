
--libspng LuaJIT binding.
--Written by Cosmin Apreutesei. Public Domain.

local bit = require'bit'
local ffi = require'ffi'
require'libspng_h'
local C = ffi.load'spng'

local spng = {}

function spng.load(opt)

	local buf, sz = opt.read_buffer, opt.read_buffer_size
	if not buf then
		sz = sz or 4096
		buf = ffi.new('uint8_t[?]', sz)
	end

	local ctx = C.spng_ctx_new(0)
	C.spng_set_png_buffer(ctx, buf, sz)

	local fmt = C.SPNG_FMT_RGBA8
	local flags = bit.bor(
		C.SPNG_DECODE_TRNS ,
		C.SPNG_DECODE_GAMMA,
		C.SPNG_DECODE_PROGRESSIVE
	)
	C.spng_decode_image(ctx, nil, 0, fmt, flags)

	local out_size = ffi.new'size_t[1]'
	C.spng_decoded_image_size(ctx, C.SPNG_FMT_RGBA8, out_size)

	local image_width = image_size / ihdr.height
	local row_info = ffi.new'struct spng_row_info'
	while true do
		local error = C.spng_get_row_info(ctx, row_info)
		if error ~= 0 break
		local row = image + image_width * row_info.row_num
		error = C.spng_decode_row(ctx, row, len)
	end

	int spng_decode_chunks(spng_ctx *ctx);

	local function free()
		C.spng_ctx_free(ctx)
	end

	return {free = free}
end

typedef int spng_read_fn(spng_ctx *ctx, void *user, void *dest, size_t length);
typedef int spng_write_fn(spng_ctx *ctx, void *user, void *src, size_t length);

typedef int spng_rw_fn(spng_ctx *ctx, void *user, void *dst_src, size_t length);

spng_ctx *spng_ctx_new(int flags);
spng_ctx *spng_ctx_new2(struct spng_alloc *alloc, int flags);
void spng_ctx_free(spng_ctx *ctx);

int spng_set_png_buffer(spng_ctx *ctx, const void *buf, size_t size);
int spng_set_png_stream(spng_ctx *ctx, spng_rw_fn *rw_func, void *user);
int spng_set_png_file(spng_ctx *ctx, FILE *file);

void *spng_get_png_buffer(spng_ctx *ctx, size_t *len, int *error);

int spng_set_image_limits(spng_ctx *ctx, uint32_t width, uint32_t height);
int spng_get_image_limits(spng_ctx *ctx, uint32_t *width, uint32_t *height);

int spng_set_chunk_limits(spng_ctx *ctx, size_t chunk_size, size_t cache_size);
int spng_get_chunk_limits(spng_ctx *ctx, size_t *chunk_size, size_t *cache_size);

int spng_set_crc_action(spng_ctx *ctx, int critical, int ancillary);

int spng_set_option(spng_ctx *ctx, enum spng_option option, int value);
int spng_get_option(spng_ctx *ctx, enum spng_option option, int *value);

int spng_decoded_image_size(spng_ctx *ctx, int fmt, size_t *len);

/* Encode/decode */
int spng_get_row_info(spng_ctx *ctx, struct spng_row_info *row_info);

/* Encode */
int spng_encode_image(spng_ctx *ctx, const void *img, size_t len, int fmt, int flags);

/* Progressive encode */
int spng_encode_scanline(spng_ctx *ctx, const void *scanline, size_t len);
int spng_encode_row(spng_ctx *ctx, const void *row, size_t len);
int spng_encode_chunks(spng_ctx *ctx);

int spng_get_ihdr(spng_ctx *ctx, struct spng_ihdr *ihdr);
int spng_get_plte(spng_ctx *ctx, struct spng_plte *plte);
int spng_get_trns(spng_ctx *ctx, struct spng_trns *trns);
int spng_get_chrm(spng_ctx *ctx, struct spng_chrm *chrm);
int spng_get_chrm_int(spng_ctx *ctx, struct spng_chrm_int *chrm_int);
int spng_get_gama(spng_ctx *ctx, double *gamma);
int spng_get_gama_int(spng_ctx *ctx, uint32_t *gama_int);
int spng_get_iccp(spng_ctx *ctx, struct spng_iccp *iccp);
int spng_get_sbit(spng_ctx *ctx, struct spng_sbit *sbit);
int spng_get_srgb(spng_ctx *ctx, uint8_t *rendering_intent);
int spng_get_text(spng_ctx *ctx, struct spng_text *text, uint32_t *n_text);
int spng_get_bkgd(spng_ctx *ctx, struct spng_bkgd *bkgd);
int spng_get_hist(spng_ctx *ctx, struct spng_hist *hist);
int spng_get_phys(spng_ctx *ctx, struct spng_phys *phys);
int spng_get_splt(spng_ctx *ctx, struct spng_splt *splt, uint32_t *n_splt);
int spng_get_time(spng_ctx *ctx, struct spng_time *time);
int spng_get_unknown_chunks(spng_ctx *ctx, struct spng_unknown_chunk *chunks, uint32_t *n_chunks);

/* Official extensions */
int spng_get_offs(spng_ctx *ctx, struct spng_offs *offs);
int spng_get_exif(spng_ctx *ctx, struct spng_exif *exif);


int spng_set_ihdr(spng_ctx *ctx, struct spng_ihdr *ihdr);
int spng_set_plte(spng_ctx *ctx, struct spng_plte *plte);
int spng_set_trns(spng_ctx *ctx, struct spng_trns *trns);
int spng_set_chrm(spng_ctx *ctx, struct spng_chrm *chrm);
int spng_set_chrm_int(spng_ctx *ctx, struct spng_chrm_int *chrm_int);
int spng_set_gama(spng_ctx *ctx, double gamma);
int spng_set_gama_int(spng_ctx *ctx, uint32_t gamma);
int spng_set_iccp(spng_ctx *ctx, struct spng_iccp *iccp);
int spng_set_sbit(spng_ctx *ctx, struct spng_sbit *sbit);
int spng_set_srgb(spng_ctx *ctx, uint8_t rendering_intent);
int spng_set_text(spng_ctx *ctx, struct spng_text *text, uint32_t n_text);
int spng_set_bkgd(spng_ctx *ctx, struct spng_bkgd *bkgd);
int spng_set_hist(spng_ctx *ctx, struct spng_hist *hist);
int spng_set_phys(spng_ctx *ctx, struct spng_phys *phys);
int spng_set_splt(spng_ctx *ctx, struct spng_splt *splt, uint32_t n_splt);
int spng_set_time(spng_ctx *ctx, struct spng_time *time);
int spng_set_unknown_chunks(spng_ctx *ctx, struct spng_unknown_chunk *chunks, uint32_t n_chunks);

/* Official extensions */
int spng_set_offs(spng_ctx *ctx, struct spng_offs *offs);
int spng_set_exif(spng_ctx *ctx, struct spng_exif *exif);

const char *spng_strerror(int err);
const char *spng_version_string(void);

return spng
