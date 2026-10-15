package ktx.openfl._internal;

/**
	OpenGL and KTXv1 constants used by the reader and the upload pipeline.

	KTXv1 stores raw OpenGL `GLenum` values inside the file, so the numeric
	formats in this table double as the values passed to
	`glCompressedTexImage2D`. Centralising them keeps the parser free of
	magic numbers and lets tests run without a GL context.
**/
class KtxGL
{
	/**
		The 12-byte KTXv1 file identifier (`«KTX 11»\r\n\x1A\n`).
	**/
	public static final KTX1_SIGNATURE = [0xAB, 0x4B, 0x54, 0x58, 0x20, 0x31, 0x31, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A];

	/**
		The 12-byte KTXv2 file identifier (`«KTX 20»\r\n\x1A\n`).

		KTXv2 shares the KTXv1 identifier except for bytes 5–6; the library
		detects this magic and reports the format as not yet supported.
	**/
	public static final KTX2_SIGNATURE = [0xAB, 0x4B, 0x54, 0x58, 0x20, 0x32, 0x30, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A];

	/**
		`KTX_ENDIAN_REF` — the header was written on a little-endian machine.
	**/
	public static inline var KTX_ENDIAN_REF = 0x04030201;

	/**
		`KTX_ENDIAN_REF_REV` — the header was written on a big-endian machine;
		all 32-bit header fields must be byte-swapped.
	**/
	public static inline var KTX_ENDIAN_REF_REV = 0x01020304;

	/**
		Total header size in bytes (12-byte identifier + thirteen 32-bit fields).
	**/
	public static inline var KTX_HEADER_SIZE = 64;

	// --- S3TC / DXT -----------------------------------------------------------

	public static inline var COMPRESSED_RGB_S3TC_DXT1_EXT = 0x83F0;
	public static inline var COMPRESSED_RGBA_S3TC_DXT1_EXT = 0x83F1;
	public static inline var COMPRESSED_RGBA_S3TC_DXT3_EXT = 0x83F2;
	public static inline var COMPRESSED_RGBA_S3TC_DXT5_EXT = 0x83F3;

	// --- PVRTC ----------------------------------------------------------------

	public static inline var COMPRESSED_RGB_PVRTC_4BPPV1_IMG = 0x8C00;
	public static inline var COMPRESSED_RGB_PVRTC_2BPPV1_IMG = 0x8C01;
	public static inline var COMPRESSED_RGBA_PVRTC_4BPPV1_IMG = 0x8C02;
	public static inline var COMPRESSED_RGBA_PVRTC_2BPPV1_IMG = 0x8C03;

	// --- ETC1 -----------------------------------------------------------------

	public static inline var ETC1_RGB8_OES = 0x8D64;

	// --- EAC / ETC2 -----------------------------------------------------------

	// The EAC single- and two-channel formats precede the colour ETC2 values.
	public static inline var COMPRESSED_R11_EAC = 0x9270;
	public static inline var COMPRESSED_SIGNED_R11_EAC = 0x9271;
	public static inline var COMPRESSED_RG11_EAC = 0x9272;
	public static inline var COMPRESSED_SIGNED_RG11_EAC = 0x9273;

	public static inline var COMPRESSED_RGB8_ETC2 = 0x9274;
	public static inline var COMPRESSED_SRGB8_ETC2 = 0x9275;
	public static inline var COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2 = 0x9276;
	public static inline var COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2 = 0x9277;
	public static inline var COMPRESSED_RGBA8_ETC2_EAC = 0x9278;
	public static inline var COMPRESSED_SRGB8_ALPHA8_ETC2_EAC = 0x9279;

	// --- ASTC 2D LDR ----------------------------------------------------------

	public static inline var COMPRESSED_RGBA_ASTC_4x4 = 0x93B0;
	public static inline var COMPRESSED_RGBA_ASTC_5x4 = 0x93B1;
	public static inline var COMPRESSED_RGBA_ASTC_5x5 = 0x93B2;
	public static inline var COMPRESSED_RGBA_ASTC_6x5 = 0x93B3;
	public static inline var COMPRESSED_RGBA_ASTC_6x6 = 0x93B4;
	public static inline var COMPRESSED_RGBA_ASTC_8x5 = 0x93B5;
	public static inline var COMPRESSED_RGBA_ASTC_8x6 = 0x93B6;
	public static inline var COMPRESSED_RGBA_ASTC_8x8 = 0x93B7;
	public static inline var COMPRESSED_RGBA_ASTC_10x5 = 0x93B8;
	public static inline var COMPRESSED_RGBA_ASTC_10x6 = 0x93B9;
	public static inline var COMPRESSED_RGBA_ASTC_10x8 = 0x93BA;
	public static inline var COMPRESSED_RGBA_ASTC_10x10 = 0x93BB;
	public static inline var COMPRESSED_RGBA_ASTC_12x10 = 0x93BC;
	public static inline var COMPRESSED_RGBA_ASTC_12x12 = 0x93BD;

	public static inline var COMPRESSED_SRGB8_ALPHA8_ASTC_4x4 = 0x93D0;
	public static inline var COMPRESSED_SRGB8_ALPHA8_ASTC_5x4 = 0x93D1;
	public static inline var COMPRESSED_SRGB8_ALPHA8_ASTC_5x5 = 0x93D2;
	public static inline var COMPRESSED_SRGB8_ALPHA8_ASTC_6x5 = 0x93D3;
	public static inline var COMPRESSED_SRGB8_ALPHA8_ASTC_6x6 = 0x93D4;
	public static inline var COMPRESSED_SRGB8_ALPHA8_ASTC_8x5 = 0x93D5;
	public static inline var COMPRESSED_SRGB8_ALPHA8_ASTC_8x6 = 0x93D6;
	public static inline var COMPRESSED_SRGB8_ALPHA8_ASTC_8x8 = 0x93D7;
	public static inline var COMPRESSED_SRGB8_ALPHA8_ASTC_10x5 = 0x93D8;
	public static inline var COMPRESSED_SRGB8_ALPHA8_ASTC_10x6 = 0x93D9;
	public static inline var COMPRESSED_SRGB8_ALPHA8_ASTC_10x8 = 0x93DA;
	public static inline var COMPRESSED_SRGB8_ALPHA8_ASTC_10x10 = 0x93DB;
	public static inline var COMPRESSED_SRGB8_ALPHA8_ASTC_12x10 = 0x93DC;
	public static inline var COMPRESSED_SRGB8_ALPHA8_ASTC_12x12 = 0x93DD;
}
