package ktx.openfl;

import openfl.display3D.Context3D;
import openfl.display3D.textures.CubeTexture;
import openfl.display3D.textures.Texture;
import ktx.openfl._internal.Ktx1Reader;
import ktx.openfl._internal.Ktx1Upload;
import ktx.openfl._internal.KtxCompressedFormats;
import openfl.utils.ByteArray;

/**
	Public entry point for loading KTX (Khronos Texture) files into OpenFL.

	The KTX container has two versions. This library detects both from the
	file's 12-byte identifier, but only KTXv1 data is parsed and uploaded
	today; KTXv2 files are recognised and rejected with a clear
	`IllegalOperationError` until support lands in a future release.

	`ktx-openfl` never replaces or overrides any OpenFL class, so textures are
	loaded through this façade (or its `TextureKtx` and `CubeTextureKtx` static
	extensions) rather than through `uploadCompressedTextureFromByteArray`,
	which remains an Adobe Texture Format (ATF) method on stock OpenFL.

	Migrating from ATF to KTX is typically a one-line call-site change:

	```haxe
	// ATF (stock OpenFL)
	var texture = context.createTexture(w, h, Context3DTextureFormat.COMPRESSED, false);
	texture.uploadCompressedTextureFromByteArray(atfBytes, 0);

	// KTX (ktx-openfl)
	var texture = Ktx.createTexture(context, ktxBytes);
	```

	Cubemaps use the matching cube API:

	```haxe
	// ATF (stock OpenFL)
	var cube = context.createCubeTexture(size, Context3DTextureFormat.COMPRESSED, false);
	cube.uploadCompressedTextureFromByteArray(atfBytes, 0);

	// KTX (ktx-openfl)
	var cube = Ktx.createCubeTexture(context, ktxBytes);
	```

	Where metadata is already parsed, the `KtxData` overloads reuse the
	retained bytes and offset without re-parsing:

	```haxe
	var ktx = Ktx.readData(ktxBytes);

	if (Ktx.supports(context, ktx))
	{
		var texture = Ktx.createTextureFromData(context, ktx);
	}
	```

	**Target support:** uploading KTX textures requires a Lime / OpenFL
	OpenGL backend. Flash and AIR targets cannot upload KTX data, because the
	native runtime accepts only ATF; on those targets, the upload and create
	methods throw `IllegalOperationError`, while parsing APIs such as
	`isKtx`, `readData` and `KtxData` continue to work.
**/
@:access(ktx.openfl._internal.Ktx1Reader)
@:access(ktx.openfl.KtxData)
class Ktx
{
	/**
		The library version, formatted as a semantic version string.
	**/
	public static inline var VERSION = "0.5.0";

	/**
		Checks whether the provided ByteArray, at the specified offset, contains
		any supported KTX data (a KTXv1 or KTXv2 file identifier).

		@param data   The ByteArray to inspect.
		@param offset The position in the ByteArray to test.
		@return       True if the data appears to be a KTX file.
	**/
	public static function isKtx(data:ByteArray, offset:UInt = 0):Bool
	{
		return Ktx1Reader.isKtx(data, offset);
	}

	/**
		Checks whether the provided ByteArray, at the specified offset, contains
		KTXv1 data.

		@param data   The ByteArray to inspect.
		@param offset The position in the ByteArray to test.
		@return       True if the data appears to be a KTXv1 file.
	**/
	public static function isKtx1(data:ByteArray, offset:UInt = 0):Bool
	{
		return Ktx1Reader.isKtx1(data, offset);
	}

	/**
		Checks whether the provided ByteArray, at the specified offset, contains
		KTXv2 data. KTXv2 files are detected but not yet supported for loading.

		@param data   The ByteArray to inspect.
		@param offset The position in the ByteArray to test.
		@return       True if the data appears to be a KTXv2 file.
	**/
	public static function isKtx2(data:ByteArray, offset:UInt = 0):Bool
	{
		return Ktx1Reader.isKtx2(data, offset);
	}

	/**
		Parses a KTX ByteArray into version-agnostic metadata.

		`KtxData` exposes the header information needed to create and upload a
		matching texture, and retains the original bytes and offset so the
		textures can be created or re-uploaded through the `KtxData` overloads
		below.

		KTXv2 data throws an `IllegalOperationError`; data without a KTX file
		identifier throws an `ArgumentError`.

		@param data   The ByteArray containing KTX data.
		@param offset The position in the ByteArray at which KTX data begins.
		@return       The parsed texture metadata.
	**/
	public static function readData(data:ByteArray, offset:UInt = 0):KtxData
	{
		return new KtxData(data, offset);
	}

	/**
		Reports whether this library can upload the given parsed texture on the
		current GPU, so an application can choose an appropriate fallback.

		For KTXv1 this confirms the GPU supports the file's internal format;
		other rules, such as rejecting 3D or array data, were already applied
		when the data parsed. The rendering context must already exist.

		@param context  The rendering context to test against.
		@param data     Parsed KTX metadata from `readData` or `new KtxData`.
		@return         True if uploading this data would succeed on this GPU.
	**/
	public static function supports(context:Context3D, data:KtxData):Bool
	{
		if (data == null || !data.isUploadReady)
		{
			return false;
		}

		return isFormatSupported(context, data.glInternalFormat);
	}

	/**
		Reports whether the current GPU can upload a specific KTXv1 internal
		format. This is an advanced probe over raw GL format constants;
		applications holding parsed metadata should prefer `supports`.

		The rendering context must already exist.

		@param context           The rendering context to test against.
		@param glInternalFormat  The OpenGL internal format value from a KTXv1 header.
		@return                  True if upload would succeed on this GPU.
	**/
	public static function isFormatSupported(context:Context3D, glInternalFormat:Int):Bool
	{
		return KtxCompressedFormats.isSupported(context, glInternalFormat);
	}

	/**
		Reports whether the current GPU advertises the ASTC HDR profile.

		HDR availability is independent of LDR support and does not, on its
		own, enable KTX uploads; use `supports` or `isFormatSupported` to test
		whether a specific format can be uploaded. The rendering context must
		already exist.

		@param context  The rendering context to test against.
		@return         True if the GPU exposes the ASTC HDR profile.
	**/
	public static function isAstcHdrSupported(context:Context3D):Bool
	{
		return KtxCompressedFormats.isAstcHdrSupported(context);
	}

	/**
		Creates a stock `openfl.display3D.textures.Texture` sized and formatted from
		the KTX header, and uploads the texture data to it.

		When `async` is true, the upload is deferred to the next tick and the
		texture is not usable until it dispatches `Event.TEXTURE_READY`.

		@param context                     The rendering context to create the texture on.
		@param data                        The ByteArray containing KTX data.
		@param offset                      The position in the ByteArray at which KTX data begins.
		@param optimizeForRenderToTexture  Whether the texture may be used as a render target.
		@param streamingLevels             The number of streaming mipmap levels.
		@param async                       When true, the upload is deferred to the next tick
		                                     and `Event.TEXTURE_READY` is dispatched on completion.
		@return                             A stock texture populated with the KTX data.
	**/
	public static function createTexture(context:Context3D, data:ByteArray, offset:UInt = 0,
			optimizeForRenderToTexture:Bool = false, streamingLevels:Int = 0, async:Bool = false):Texture
	{
		return Ktx1Upload.createTexture(context, new Ktx1Reader(data, offset), optimizeForRenderToTexture,
			streamingLevels, async);
	}

	/**
		Creates a stock texture from parsed KTX metadata, reusing the retained
		bytes and offset without re-parsing the header.

		The metadata must describe a 2D texture; cubemap data throws an
		`IllegalOperationError`. When `async` is true, the upload is deferred
		to the next tick and the texture is not usable until it dispatches
		`Event.TEXTURE_READY`.

		@param context                     The rendering context to create the texture on.
		@param data                        Parsed KTX metadata from `readData` or `new KtxData`.
		@param optimizeForRenderToTexture  Whether the texture may be used as a render target.
		@param streamingLevels             The number of streaming mipmap levels.
		@param async                       When true, the upload is deferred to the next tick
		                                     and `Event.TEXTURE_READY` is dispatched on completion.
		@return                             A stock texture populated with the KTX data.
	**/
	public static function createTextureFromData(context:Context3D, data:KtxData,
			optimizeForRenderToTexture:Bool = false, streamingLevels:Int = 0, async:Bool = false):Texture
	{
		return Ktx1Upload.createTexture(context, readerOf(data), optimizeForRenderToTexture, streamingLevels,
			async);
	}

	/**
		Uploads KTX data into an existing stock texture, mirroring OpenFL's
		compressed ATF upload behaviour.

		The texture's dimensions must match the KTX base level. When `async` is
		true, the upload is deferred to the next tick and `Event.TEXTURE_READY` is
		dispatched on completion; the texture is not usable until then.

		Cubemap data must be uploaded through `uploadCompressedCubeTextureFromByteArray`.

		@param texture          The stock texture to receive the image data.
		@param data             The ByteArray containing KTX data.
		@param offset           The position in the ByteArray at which KTX data begins.
		@param async            When true, the upload is deferred and signals completion
		                          with `Event.TEXTURE_READY`.
	**/
	public static function uploadCompressedTextureFromByteArray(texture:Texture, data:ByteArray,
			offset:UInt = 0, async:Bool = false):Void
	{
		Ktx1Upload.uploadAsync(texture, new Ktx1Reader(data, offset), async);
	}

	/**
		Uploads parsed KTX metadata into an existing stock texture, reusing the
		retained bytes and offset without re-parsing the header.

		The texture's dimensions must match the KTX base level. When `async` is
		true, the upload is deferred to the next tick and `Event.TEXTURE_READY`
		is dispatched on completion; the texture is not usable until then.

		@param texture  The stock texture to receive the image data.
		@param data     Parsed KTX metadata from `readData` or `new KtxData`.
		@param async    When true, the upload is deferred and signals completion
		                  with `Event.TEXTURE_READY`.
	**/
	public static function uploadTextureFromData(texture:Texture, data:KtxData, async:Bool = false):Void
	{
		Ktx1Upload.uploadAsync(texture, readerOf(data), async);
	}

	/**
		Creates a stock `openfl.display3D.textures.CubeTexture` sized and formatted
		from the KTX header, and uploads the cubemap data to it.

		The KTX data must contain a cubemap with square faces. When `async` is
		true, the upload is deferred to the next tick and the texture is not
		usable until it dispatches `Event.TEXTURE_READY`.

		@param context                     The rendering context to create the texture on.
		@param data                        The ByteArray containing KTX cubemap data.
		@param offset                      The position in the ByteArray at which KTX data begins.
		@param optimizeForRenderToTexture  Whether the texture may be used as a render target.
		@param streamingLevels             The number of streaming mipmap levels.
		@param async                       When true, the upload is deferred to the next tick
		                                     and `Event.TEXTURE_READY` is dispatched on completion.
		@return                              A stock cube texture populated with the KTX data.
	**/
	public static function createCubeTexture(context:Context3D, data:ByteArray, offset:UInt = 0,
			optimizeForRenderToTexture:Bool = false, streamingLevels:Int = 0, async:Bool = false):CubeTexture
	{
		return Ktx1Upload.createCubeTexture(context, new Ktx1Reader(data, offset), optimizeForRenderToTexture,
			streamingLevels, async);
	}

	/**
		Creates a stock cube texture from parsed KTX metadata, reusing the
		retained bytes and offset without re-parsing the header.

		The metadata must describe a cubemap; 2D data throws an
		`IllegalOperationError`. When `async` is true, the upload is deferred
		to the next tick and the texture is not usable until it dispatches
		`Event.TEXTURE_READY`.

		@param context                     The rendering context to create the texture on.
		@param data                        Parsed KTX metadata from `readData` or `new KtxData`.
		@param optimizeForRenderToTexture  Whether the texture may be used as a render target.
		@param streamingLevels             The number of streaming mipmap levels.
		@param async                       When true, the upload is deferred to the next tick
		                                     and `Event.TEXTURE_READY` is dispatched on completion.
		@return                              A stock cube texture populated with the KTX data.
	**/
	public static function createCubeTextureFromData(context:Context3D, data:KtxData,
			optimizeForRenderToTexture:Bool = false, streamingLevels:Int = 0, async:Bool = false):CubeTexture
	{
		return Ktx1Upload.createCubeTexture(context, readerOf(data), optimizeForRenderToTexture, streamingLevels,
			async);
	}

	/**
		Uploads KTX cubemap data into an existing stock cube texture, mirroring
		OpenFL's compressed ATF cube upload behaviour.

		The cube texture's edge length must match the KTX base level. When
		`async` is true, the upload is deferred to the next tick and
		`Event.TEXTURE_READY` is dispatched on completion; the texture is not
		usable until then.

		@param texture          The stock cube texture to receive the image data.
		@param data             The ByteArray containing KTX cubemap data.
		@param offset           The position in the ByteArray at which KTX data begins.
		@param async            When true, the upload is deferred and signals completion
		                          with `Event.TEXTURE_READY`.
	**/
	public static function uploadCompressedCubeTextureFromByteArray(texture:CubeTexture, data:ByteArray,
			offset:UInt = 0, async:Bool = false):Void
	{
		Ktx1Upload.uploadCubeAsync(texture, new Ktx1Reader(data, offset), async);
	}

	/**
		Uploads parsed KTX cubemap metadata into an existing stock cube texture,
		reusing the retained bytes and offset without re-parsing the header.

		The cube texture's edge length must match the KTX base level. When
		`async` is true, the upload is deferred to the next tick and
		`Event.TEXTURE_READY` is dispatched on completion; the texture is not
		usable until then.

		@param texture  The stock cube texture to receive the image data.
		@param data     Parsed KTX metadata from `readData` or `new KtxData`.
		@param async    When true, the upload is deferred and signals completion
		                  with `Event.TEXTURE_READY`.
	**/
	public static function uploadCubeTextureFromData(texture:CubeTexture, data:KtxData, async:Bool = false):Void
	{
		Ktx1Upload.uploadCubeAsync(texture, readerOf(data), async);
	}

	/**
		Reuses the parser retained by the metadata, parsing from the retained
		bytes and offset only when none is present.
	**/
	private static function readerOf(data:KtxData):Ktx1Reader
	{
		return (data.reader != null) ? data.reader : new Ktx1Reader(data.data, data.byteArrayOffset);
	}
}
