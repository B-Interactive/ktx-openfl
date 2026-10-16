package ktx.openfl.starling;

import haxe.Constraints.Function;
import ktx.openfl.Ktx;
import openfl.utils.ByteArray;
import starling.assets.AssetFactory;
import starling.assets.AssetFactoryHelper;
import starling.assets.AssetReference;
import starling.textures.Texture;
import starling.utils.Execute;

/**
	This `AssetFactory` creates texture assets from KTX files, mirroring the
	behaviour of Starling's own `AtfTextureFactory`.

	Register it once at startup with `KtxAssets.register()`; afterwards the
	`AssetManager` recognises KTX data by its file signature, whether it is
	loaded from a URL, an asset path, or raw bytes, and turns it into a
	`starling.textures.Texture`.

	KTXv2 files are recognised by `canHandle` but fail during `create` with a
	clear "not supported yet" error, because only KTXv1 can be loaded today.

	Context-loss restoration reloads the bytes from the original URL and
	uploads them through the KTX path; the stock ATF upload is never used, and
	the parsed bytes are not kept in memory afterwards.

	Only 2D KTX files are supported; a cubemap reference throws an
	`ArgumentError`, which the manager reports as a creation error.
**/
@:access(starling.textures.ConcreteTexture)
class KtxTextureFactory extends AssetFactory
{
	/**
		Creates a new instance.
	**/
	public function new()
	{
		super();
		addExtensions(["ktx", "ktx2"]);
	}

	/**
		Reports whether this factory can create a texture from the given
		reference: the reference must hold ByteArray data that begins with a
		KTX file signature. Both KTXv1 and KTXv2 are recognised; KTXv2 data
		fails later, during `create`, with a clear unsupported-format error.
	**/
	override public function canHandle(reference:AssetReference):Bool
	{
		return (#if (haxe_ver < 4.2) Std.is #else Std.isOfType #end(reference.data, #if commonjs ByteArray #else ByteArrayData #end))
			&& Ktx.isKtx(cast reference.data);
	}

	/**
		Creates the texture from the reference's KTX data, following the same
		control flow as `AtfTextureFactory`.
	**/
	override public function create(reference:AssetReference, helper:AssetFactoryHelper,
			onComplete:String->Dynamic->Void, onError:String->Void):Void
	{
		var onReloadError:String->Void = null;
		var createTexture:Void->Void = null;

		onReloadError = function(error:String):Void
		{
			helper.log("Texture restoration failed for " + reference.url + ". " + error);
			helper.onEndRestore();
		};

		createTexture = function():Void
		{
			var texture:Texture = null;

			var onReady:Function = reference.textureOptions.onReady;

			reference.textureOptions.onReady = function(_):Void
			{
				Execute.execute(onReady, [texture]);
				onComplete(reference.name, texture);
			};

			var url:String = reference.url;
			var options = reference.textureOptions;

			try
			{
				texture = KtxTextures.fromKtxData(cast reference.data, options.scale, options.mipMapping,
					options.onReady, options.premultipliedAlpha);
			}
			catch (e:Dynamic)
			{
				onError(Std.string(e));
			}

			if (url != null && texture != null)
			{
				texture.root.onRestore = function(_):Void
				{
					helper.onBeginRestore();
					helper.loadDataFromUrl(url, function(?data:ByteArray, ?mimeType:String,
							?name:String, ?extension:String):Void
						{
							helper.executeWhenContextReady(function():Void
								{
									try
									{
										var native:openfl.display3D.textures.Texture = cast texture.root.base;
										Ktx.uploadCompressedTextureFromByteArray(native, data, 0, false);
										texture.root.setDataUploaded();
									}
									catch (e:Dynamic)
									{
										helper.log("Texture restoration failed: " + e);
									}

									helper.onEndRestore();
								});
						}, onReloadError);
				};
			}

			reference.data = null; // prevent closures from keeping the raw data in memory
		};

		helper.executeWhenContextReady(createTexture);
	}
}
