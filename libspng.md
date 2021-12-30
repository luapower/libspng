
## `local spng = require'libspng'`

A ffi binding of [libspng](https://libspng.org/).

## API

<warn>Work in progress</warn>

------------------------------------ -----------------------------------------
`spng.open(opt | read) -> img`       open a PNG image for decoding
`img:load([opt]) -> bmp`             load the image into a bitmap
`img:free()`                         free the image
`spng.save(opt)`                     compress a bitmap into a PNG image
------------------------------------ -----------------------------------------

### `spng.open(opt) -> img`

Open a PNG image and read its header. `opt` is a table containing at least
the read function and possibly other options.

The read function has the form `read(buf, size) -> readsize`, **it cannot yield**
and it must signal I/O errors by returning `nil`. It will only be asked
to read a positive number of bytes and it can return less bytes than asked,
including zero which signals EOF.

The `opt` table has the fields:

  * `read`: the read function (required).

The returned image object has the fields:

* `format`, `w`, `h`, `compressed`, `interlaced`: image native format,
dimensions and flags.

### `img:load(opt) -> bmp`

The `opt` table has the fields:

* `accept`: a table with the fields:
  * `[format] = true` specify one or more accepted formats:
  `'bgra8', 'rgba8', 'rgba16', 'rgb8', 'g8', 'ga8', 'ga16'`.
  * `bottom_up`: bottom-up bitmap (false).
  * `stride_aligned`: align stride to 4 bytes (false).

* `accept`: if present, it is a table specifying conversion options.
If no `accept` option is given, the image is returned in an 8 bit-per-channel,
top down, palette expanded, 'g', 'rgb', 'rgba' or 'ga' format.
* if no pixel format is specified, resulted bit depth will not necessarily
be 8 since no conversion will take place.
* `bottom_up`: true for a bottom-up image.
* `stride_aligned`: true for row stride to be a multiple of 4.

The returned bitmap has the standard [bitmap] fields `format`, `bottom_up`,
`stride`, `data`, `size`, `w`, `h`.

### `spng.save(opt)`

Encode a [bitmap] in PNG format.

The `opt` table has the fields:
