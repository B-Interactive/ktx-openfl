package ktx.openfl.starling;

import openfl.display3D.Context3D;
import openfl.display3D.Context3DTextureFormat;
import openfl.errors.ArgumentError;
import openfl.events.Event;
import ktx.openfl.Ktx;
import ktx.openfl.KtxData;
import openfl.utils.ByteArray;
import starling.core.Starling;
import starling.errors.MissingContextError;
import starling.textures.ConcretePotTexture;
import starling.textures.ConcreteTexture;
import starling.textures.Texture;

/**
	Creates stock Starling textures from KTX data, mirroring
	`starling.textures.Texture.fromAtfData`.

	KTXv2 data is detected but rejected with an `IllegalOperationError` when
	this method parses the bytes; only KTXv1 can be loaded today.

	This class lives in the optional `ktx.openfl.starling` package and does not
	replace or subclass any Starling class; applications that use it add the
	Starling library (`-lib starling`) themselves. Compiling this file without
	Starling fails, which is expected, because the bridge depends on Starling
	types.

	The bridge constructs Starling's private `ConcretePotTexture` directly, in
	the same way that `Texture.fromAtfData` does internally. That requires
	`@:access` into `starling.textures`, which is a deliberate coupling to
	Starling's private texture classes; it mirrors the narrow `@:access` use in
	`Ktx1Upload` for OpenFL's private upload state.

	Only 2D textures are supported: Starling has no cubemap texture support, so
	cubemap data throws an `ArgumentError`. Like ATF data, KTX data must have
	power-of-two dimensions, because the texture is backed by a
	`ConcretePotTexture`; non-power-of-two data throws an `ArgumentError`.

	Premultiplied alpha is an explicit parameter. The presence of an alpha
	channel in a KTX file does not imply premultiplication, so `hasAlpha` is
	never used as a premultiplied-alpha hint.
**/
@:access(starling.textures.ConcretePotTexture)
@:access(starling.textures.ConcreteTexture)
class KtxTextures
{
	/**
		Creates a Starling texture from KTX data, mirroring
		`Texture.fromAtfData`.

		The original `ByteArray` is retained for context-loss restore, so it
		must not be disposed while the texture is in use. The texture's
		`root.onRestore` callback re-uploads the KTX data through `Ktx` after
		a context loss, without any application code.

		@param data              The ByteArray containing KTX data.
		@param scale             The scale factor of the created texture; this
		                          affects the reported width and height.
		@param useMipMaps        If the KTX data contains mip levels, this
		                          parameter controls whether they are used.
		@param async             When set, the texture is uploaded
		                          asynchronously and the callback runs once the
		                          texture is ready. Do not use the texture
		                          before the callback has executed.
		@param premultipliedAlpha Indicates whether the texture data is stored
		                          with premultiplied alpha. This is never
		                          inferred from the file's alpha channel.
		@return                    A Starling texture holding the KTX data.
	**/
	public static function fromKtxData(data:ByteArray, scale:Float = 1, useMipMaps:Bool = true,
			async:Texture->Void = null, premultipliedAlpha:Bool = false):Texture
	{
		var starling = Starling.current;
		var context:Context3D = (starling != null) ? starling.context : null;
		if (context == null) throw new MissingContextError();

		var ktx = new KtxData(data);

		if (ktx.isCubeMap)
		{
			throw new ArgumentError("KTX for OpenFL: Starling does not support cubemap textures");
		}

		var nativeFormat:Context3DTextureFormat = ktx.hasAlpha
			? Context3DTextureFormat.COMPRESSED_ALPHA
			: Context3DTextureFormat.COMPRESSED;

		var native:openfl.display3D.textures.Texture = context.createTexture(ktx.width, ktx.height,
			nativeFormat, false);

		var mipFlag = useMipMaps && ktx.numTextures > 1;

		// ConcretePotTexture expects the Context3D format as a String, matching
		// AtfData.format ("compressed" / "compressedAlpha").
		var concrete = new ConcretePotTexture(native, ktx.format, ktx.width, ktx.height, mipFlag,
			premultipliedAlpha, false, scale);

		if (async != null)
		{
			var onTextureReady:Event->Void = null;

			onTextureReady = function(event:Event):Void
			{
				native.removeEventListener(Event.TEXTURE_READY, onTextureReady);
				async(concrete);
			};

			native.addEventListener(Event.TEXTURE_READY, onTextureReady);
		}

		// The KTX path always uploads through Ktx; the stock ATF upload is
		// never used for KTX data.
		Ktx.uploadCompressedTextureFromByteArray(native, data, 0, async != null);
		concrete.setDataUploaded();

		concrete.onRestore = function(root:ConcreteTexture):Void
		{
			var base:openfl.display3D.textures.Texture = cast root.base;
			Ktx.uploadCompressedTextureFromByteArray(base, data, 0, false);
			root.setDataUploaded();
		};

		return concrete;
	}
}
