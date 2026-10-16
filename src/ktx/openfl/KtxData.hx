package ktx.openfl;

import ktx.openfl._internal.Ktx1Reader;
import openfl.utils.ByteArray;

/**
	Metadata for a KTX texture, mirroring the shape of Starling's `AtfData`.

	Parsing a KTX ByteArray into a `KtxData` instance gives quick access to
	the header information needed to create and upload a matching texture,
	without exposing the raw parser. The original bytes and their offset are
	retained so a texture can be re-uploaded, for example after a context
	loss.

	The fields describe the container in a version-agnostic way. Only KTXv1
	is parsed today, so the version-dependent fields report their KTXv1
	values: version `1`, no recorded premultiplied alpha, no
	supercompression, and GPU-ready data that needs no transcoding.

	Only KTXv1 data is parsed today. KTXv2 files are detected but rejected
	with an `IllegalOperationError`; data without a KTX file identifier
	throws an `ArgumentError`.
**/
class KtxData
{
	/**
		The original ByteArray containing the KTX data.
	**/
	public var data(default, null):ByteArray;

	/**
		The offset within `data` at which the KTX data begins.
	**/
	public var byteArrayOffset(default, null):UInt;

	/**
		The container version, read from the file identifier. KTXv1 files
		report `1`.
	**/
	public var version(default, null):Int;

	/**
		True when the container records premultiplied alpha, false when it
		records straight alpha, and `null` when it does not say. KTXv1 files
		never record the answer, so this is always `null`; premultiplication
		must be stated by the application or the asset pipeline.
	**/
	public var premultipliedAlpha(default, null):Null<Bool>;

	/**
		The supercompression scheme applied to the texture data. KTXv1 files
		are never supercompressed, so this reports `KtxSupercompression.NONE`.
	**/
	public var supercompression(default, null):KtxSupercompression;

	/**
		True when the data must be transcoded to a GPU format before it can
		be uploaded. Block-compressed KTXv1 data is already GPU-ready, so
		this reports false.
	**/
	public var needsTranscode(default, null):Bool;

	/**
		True when the data can be uploaded to the GPU as it is. KTXv1 data
		that parses successfully is always upload-ready.
	**/
	public var isUploadReady(default, null):Bool;

	/**
		The internal parser behind the metadata getters; not part of the
		public contract.
	**/
	@:noCompletion private var reader(default, null):Ktx1Reader;

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

		this.version = 1;
		this.premultipliedAlpha = null;
		this.supercompression = KtxSupercompression.NONE;
		this.needsTranscode = false;
		this.isUploadReady = true;
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
		True when the file's header asks for mipmap generation because only
		the base level is embedded. Uploading never generates mipmaps; only
		the levels embedded in the file are uploaded.
	**/
	public var generateMipmaps(get, never):Bool;

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
		The OpenGL internal format recorded by the container. For KTXv1 this
		is also the format used for upload, so it doubles as the resolved GL
		format.
	**/
	public var glInternalFormat(get, never):Int;

	/**
		A friendly name for the texture format (for example, `DXT5`).
	**/
	public var formatName(get, never):String;

	@:noCompletion private function get_format():String
	{
		return reader.hasAlpha ? "compressedAlpha" : "compressed";
	}

	@:noCompletion private function get_width():Int return reader.width;
	@:noCompletion private function get_height():Int return reader.height;
	@:noCompletion private function get_numTextures():Int return reader.mipCount;
	@:noCompletion private function get_generateMipmaps():Bool return reader.generateMipmaps;
	@:noCompletion private function get_faceCount():Int return reader.faceCount;
	@:noCompletion private function get_isCubeMap():Bool return reader.isCubeMap;
	@:noCompletion private function get_hasAlpha():Bool return reader.hasAlpha;
	@:noCompletion private function get_gpuFormat():KtxGPUFormat return reader.gpuFormat;
	@:noCompletion private function get_glInternalFormat():Int return reader.glInternalFormat;
	@:noCompletion private function get_formatName():String return reader.formatName;
}
