package ktx.openfl;

/**
	The GPU texture format bucket associated with a KTX internal format.

	These buckets match the Adobe Texture Format (ATF) GPU format classes used
	by OpenFL and the AIR SDK, so that KTX textures can be uploaded through
	the same compressed-texture machinery. The ASTC bucket has no ATF
	equivalent, and is unique to this library.
**/
enum abstract KtxGPUFormat(Int) from Int to Int
{
	/**
		S3TC / DXT family (DXT1, DXT3, DXT5).
	**/
	public var DXT = 0;

	/**
		PVRTC family (2bpp and 4bpp, RGB and RGBA).
	**/
	public var PVRTC = 1;

	/**
		Ericsson Texture Compression 1 (opaque only).
	**/
	public var ETC1 = 2;

	/**
		Ericsson Texture Compression 2 (RGB, RGBA and punchthrough), including
		the EAC R11 and RG11 single- and two-channel formats.
	**/
	public var ETC2 = 3;

	/**
		Adaptive Scalable Texture Compression (2D LDR block formats).
	**/
	public var ASTC = 4;
}
