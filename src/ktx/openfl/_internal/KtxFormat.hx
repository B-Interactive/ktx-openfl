package ktx.openfl._internal;

import ktx.openfl.KtxGPUFormat;

/**
	Describes a single KTX texture format.

	The information is derived from the OpenGL `glInternalFormat` value stored
	in the file header, using the same GPU format buckets as Adobe Texture
	Format (ATF), so KTX textures can be routed through compressed-texture
	upload paths that mirror OpenFL's ATF handling.
**/
@:structInit @:dox(hide)
class KtxFormatInfo
{
	/**
		The GPU format bucket for this texture.
	**/
	public var gpuFormat:KtxGPUFormat;

	/**
		Whether the format stores an alpha channel.
	**/
	public var hasAlpha:Bool;

	/**
		A friendly name for the format (for example, `DXT5`).
	**/
	public var name:String;
}

/**
	Format mapping for KTX internal formats.

	Used by the internal reader and upload pipeline; applications consume
	format details through `KtxData` and `Ktx`.
**/
@:dox(hide)
class KtxFormat
{
	/**
		Returns the format description for an OpenGL internal format value,
		or `null` when the format is not supported by this library.

		@param	glInternalFormat	An OpenGL internal format constant from a KTXv1 header.
		@return	A description of the format, or `null`.
	**/
	public static function describe(glInternalFormat:Int):Null<KtxFormatInfo>
	{
		return switch (glInternalFormat)
			{
				case KtxGL.COMPRESSED_RGB_S3TC_DXT1_EXT:
					{gpuFormat: KtxGPUFormat.DXT, hasAlpha: false, name: "DXT1"};
				case KtxGL.COMPRESSED_RGBA_S3TC_DXT1_EXT:
					{gpuFormat: KtxGPUFormat.DXT, hasAlpha: false, name: "DXT1 (alpha)"};
				case KtxGL.COMPRESSED_RGBA_S3TC_DXT3_EXT:
					{gpuFormat: KtxGPUFormat.DXT, hasAlpha: true, name: "DXT3"};
				case KtxGL.COMPRESSED_RGBA_S3TC_DXT5_EXT:
					{gpuFormat: KtxGPUFormat.DXT, hasAlpha: true, name: "DXT5"};
				case KtxGL.COMPRESSED_RGB_PVRTC_4BPPV1_IMG, KtxGL.COMPRESSED_RGB_PVRTC_2BPPV1_IMG:
					{gpuFormat: KtxGPUFormat.PVRTC, hasAlpha: false, name: "PVRTC RGB"};
				case KtxGL.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG, KtxGL.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG:
					{gpuFormat: KtxGPUFormat.PVRTC, hasAlpha: true, name: "PVRTC RGBA"};
				case KtxGL.ETC1_RGB8_OES:
					{gpuFormat: KtxGPUFormat.ETC1, hasAlpha: false, name: "ETC1"};
				case KtxGL.COMPRESSED_R11_EAC:
					{gpuFormat: KtxGPUFormat.ETC2, hasAlpha: false, name: "EAC R11"};
				case KtxGL.COMPRESSED_SIGNED_R11_EAC:
					{gpuFormat: KtxGPUFormat.ETC2, hasAlpha: false, name: "EAC SIGNED R11"};
				case KtxGL.COMPRESSED_RG11_EAC:
					{gpuFormat: KtxGPUFormat.ETC2, hasAlpha: false, name: "EAC RG11"};
				case KtxGL.COMPRESSED_SIGNED_RG11_EAC:
					{gpuFormat: KtxGPUFormat.ETC2, hasAlpha: false, name: "EAC SIGNED RG11"};
				case KtxGL.COMPRESSED_RGB8_ETC2, KtxGL.COMPRESSED_SRGB8_ETC2:
					{gpuFormat: KtxGPUFormat.ETC2, hasAlpha: false, name: "ETC2 RGB"};
				case KtxGL.COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2, KtxGL.COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2:
					{gpuFormat: KtxGPUFormat.ETC2, hasAlpha: true, name: "ETC2 punchthrough"};
				case KtxGL.COMPRESSED_RGBA8_ETC2_EAC, KtxGL.COMPRESSED_SRGB8_ALPHA8_ETC2_EAC:
					{gpuFormat: KtxGPUFormat.ETC2, hasAlpha: true, name: "ETC2 RGBA"};
				case KtxGL.COMPRESSED_RGBA_ASTC_4x4, KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_4x4:
					{gpuFormat: KtxGPUFormat.ASTC, hasAlpha: true, name: "ASTC 4x4"};
				case KtxGL.COMPRESSED_RGBA_ASTC_5x4, KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_5x4:
					{gpuFormat: KtxGPUFormat.ASTC, hasAlpha: true, name: "ASTC 5x4"};
				case KtxGL.COMPRESSED_RGBA_ASTC_5x5, KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_5x5:
					{gpuFormat: KtxGPUFormat.ASTC, hasAlpha: true, name: "ASTC 5x5"};
				case KtxGL.COMPRESSED_RGBA_ASTC_6x5, KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_6x5:
					{gpuFormat: KtxGPUFormat.ASTC, hasAlpha: true, name: "ASTC 6x5"};
				case KtxGL.COMPRESSED_RGBA_ASTC_6x6, KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_6x6:
					{gpuFormat: KtxGPUFormat.ASTC, hasAlpha: true, name: "ASTC 6x6"};
				case KtxGL.COMPRESSED_RGBA_ASTC_8x5, KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_8x5:
					{gpuFormat: KtxGPUFormat.ASTC, hasAlpha: true, name: "ASTC 8x5"};
				case KtxGL.COMPRESSED_RGBA_ASTC_8x6, KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_8x6:
					{gpuFormat: KtxGPUFormat.ASTC, hasAlpha: true, name: "ASTC 8x6"};
				case KtxGL.COMPRESSED_RGBA_ASTC_8x8, KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_8x8:
					{gpuFormat: KtxGPUFormat.ASTC, hasAlpha: true, name: "ASTC 8x8"};
				case KtxGL.COMPRESSED_RGBA_ASTC_10x5, KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_10x5:
					{gpuFormat: KtxGPUFormat.ASTC, hasAlpha: true, name: "ASTC 10x5"};
				case KtxGL.COMPRESSED_RGBA_ASTC_10x6, KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_10x6:
					{gpuFormat: KtxGPUFormat.ASTC, hasAlpha: true, name: "ASTC 10x6"};
				case KtxGL.COMPRESSED_RGBA_ASTC_10x8, KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_10x8:
					{gpuFormat: KtxGPUFormat.ASTC, hasAlpha: true, name: "ASTC 10x8"};
				case KtxGL.COMPRESSED_RGBA_ASTC_10x10, KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_10x10:
					{gpuFormat: KtxGPUFormat.ASTC, hasAlpha: true, name: "ASTC 10x10"};
				case KtxGL.COMPRESSED_RGBA_ASTC_12x10, KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_12x10:
					{gpuFormat: KtxGPUFormat.ASTC, hasAlpha: true, name: "ASTC 12x10"};
				case KtxGL.COMPRESSED_RGBA_ASTC_12x12, KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_12x12:
					{gpuFormat: KtxGPUFormat.ASTC, hasAlpha: true, name: "ASTC 12x12"};
				default:
					null;
			}
	}

	/**
		Returns the Context3D texture format string ("compressed" or
		"compressedAlpha") appropriate for a KTX internal format.

		Uncompressed or unknown formats return `null`.

		@param	glInternalFormat	An OpenGL internal format constant from a KTXv1 header.
	**/
	public static function toContext3DFormatString(glInternalFormat:Int):Null<String>
	{
		var info = describe(glInternalFormat);
		if (info == null) return null;
		return info.hasAlpha ? "compressedAlpha" : "compressed";
	}
}
