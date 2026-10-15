package ktx.openfl;

import openfl.utils.ByteArray;

/**
	Metadata for a KTX texture, mirroring the shape of Starling's `AtfData`.

	Parsing a KTX ByteArray into a `KtxData` instance gives quick access to
	the header information needed to create and upload a matching texture,
	without exposing the raw parser. The original bytes are retained so a
	texture can be re-uploaded, for example after a context loss.

	Only KTXv1 data is parsed today. KTXv2 files are detected but rejected
	with an `IllegalOperationError`; data without a KTX file identifier
	throws an `ArgumentError`.
**/
class KtxData
{
	/**
		The parser holding the decoded header and image data.
	**/
	public var reader(default, null):Ktx1Reader;

	/**
		The original ByteArray containing the KTX data.
	**/
	public var data(default, null):ByteArray;

	/**
		The offset within `data` at which the KTX data begins.
	**/
	public var byteArrayOffset(default, null):UInt;

	/**
		Creates a `KtxData` instance by parsing a KTX ByteArray.

		@param data   The ByteArray containing KTX texture data.
		@param offset The position in the ByteArray at which KTX data begins.
	**/
	public function new(data:ByteArray, offset:UInt = 0)
	{
		this.data = data;
		this.byteArrayOffset = offset;
		this.reader = new Ktx1Reader(data, offset);
	}

	/**
		The Context3D texture format string for this texture: either
		`"compressed"` or `"compressedAlpha"`.
	**/
	public var format(get, never):String;

	/**
		The width of the base level, in texels.
	**/
	public var width(get, never):Int;

	/**
		The height of the base level, in texels.
	**/
	public var height(get, never):Int;

	/**
		The number of mipmap levels contained in the file.
	**/
	public var numTextures(get, never):Int;

	/**
		The number of faces (1 for a 2D texture, 6 for a cubemap).
	**/
	public var faceCount(get, never):Int;

	/**
		True when the file stores a cubemap.
	**/
	public var isCubeMap(get, never):Bool;

	/**
		True when the texture format includes an alpha channel. This does not
		imply premultiplied alpha.
	**/
	public var hasAlpha(get, never):Bool;

	/**
		The GPU format bucket for this texture.
	**/
	public var gpuFormat(get, never):KtxGPUFormat;

	/**
		The OpenGL internal format stored in the file header.
	**/
	public var glInternalFormat(get, never):Int;

	/**
		A friendly name for the texture format (for example, `DXT5`).
	**/
	public var formatName(get, never):String;

	/**
		Checks whether the provided ByteArray begins with any supported KTX
		file signature (KTXv1 or KTXv2).

		Construction parses KTXv1 only and rejects KTXv2, so detection is
		broader than what can be loaded today.

		@param data   The ByteArray to inspect.
		@param offset The position in the ByteArray to test.
		@return       True if the data appears to be a KTX file.
	**/
	public static function isKtxData(data:ByteArray, offset:UInt = 0):Bool
	{
		return Ktx.isKtx(data, offset);
	}

	@:noCompletion private function get_format():String
	{
		return reader.hasAlpha ? "compressedAlpha" : "compressed";
	}

	@:noCompletion private function get_width():Int return reader.width;
	@:noCompletion private function get_height():Int return reader.height;
	@:noCompletion private function get_numTextures():Int return reader.mipCount;
	@:noCompletion private function get_faceCount():Int return reader.faceCount;
	@:noCompletion private function get_isCubeMap():Bool return reader.isCubeMap;
	@:noCompletion private function get_hasAlpha():Bool return reader.hasAlpha;
	@:noCompletion private function get_gpuFormat():KtxGPUFormat return reader.gpuFormat;
	@:noCompletion private function get_glInternalFormat():Int return reader.glInternalFormat;
	@:noCompletion private function get_formatName():String return reader.formatName;
}
