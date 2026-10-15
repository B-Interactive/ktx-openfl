package;

import openfl.Assets;
import openfl.display.Sprite;
import openfl.display.Stage3D;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DRenderMode;
import openfl.display3D.textures.Texture;
import openfl.events.Event;
import ktx.openfl.Ktx;
import ktx.openfl.KtxData;
import ktx.openfl.KtxGPUFormat;
import ktx.openfl.Ktx1Reader;
import ktx.openfl.KtxCompressedFormats;
import ktx.openfl.TextureKtx;

using ktx.openfl.TextureKtx;

/**
	A minimal sample that loads a KTX compressed texture through the
	`ktx-openfl` public API and uploads it to a Stage3D texture.

	It exercises every public entry point, including the static extension, so
	that the upload pipeline is type-checked on each target. Rendering a
	textured quad is intentionally left out; the upload itself validates the
	GL path, and a full rendering showcase will accompany a later release.
**/
class Main extends Sprite
{
	public function new()
	{
		super();

		var stage3D:Stage3D = stage.stage3Ds[0];
		stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreated);
		stage3D.requestContext3D(Context3DRenderMode.AUTO);
	}

	private function onContext3DCreated(event:Event):Void
	{
		var stage3D:Stage3D = cast event.target;
		var context:Context3D = stage3D.context3D;

		if (context == null)
		{
			trace("Stage3D is not available on this target");
			return;
		}

		loadTexture("assets/cat_run_ktx-dxt5.ktx", context);
	}

	private function loadTexture(assetID:String, context:Context3D):Void
	{
		var bytes = Assets.getBytes(assetID);

		// Detect the container before parsing.
		if (!Ktx.isKtx(bytes))
		{
			trace(assetID + " is not a KTX file");
			return;
		}

		// Inspect metadata through the AtfData-style wrapper.
		var ktx = new KtxData(bytes);
		trace('KTX: ${ktx.formatName} ${ktx.width}x${ktx.height}, ${ktx.numTextures} levels, format '
			+ ktx.format + (ktx.hasAlpha ? " (alpha)" : ""));

		// Skip unsupported formats rather than throwing on upload.
		if (!Ktx.isFormatSupported(context, ktx.glInternalFormat))
		{
			trace("This GPU cannot upload " + ktx.formatName);
			return;
		}

		// Cubemap files use the matching cube API instead.
		if (ktx.isCubeMap)
		{
			var cube = Ktx.createCubeTexture(context, bytes);
			trace("Uploaded via Ktx.createCubeTexture: " + cube);
			return;
		}

		// Façade API: create and upload in one call.
		var texture = Ktx.createTexture(context, bytes);
		trace("Uploaded via Ktx.createTexture: " + texture);

		// Static extension equivalent, into an existing texture.
		var manual = context.createTexture(ktx.width, ktx.height, ktx.format, false);
		manual.uploadKtxFromByteArray(bytes);
		trace("Uploaded via uploadKtxFromByteArray extension");

		// Raw reader iteration, mirroring the ATF upload callback shape.
		var reader = new Ktx1Reader(bytes);
		reader.readTextures(function(face, level, gpuFormat, width, height, length, data)
			{
				if (gpuFormat == KtxGPUFormat.DXT && level == 0 && face == 0)
				{
					trace("Base level DXT block: " + length + " bytes");
				}
			});

		// Resolve the GL upload constant that the library would use.
		trace("GL format: 0x" + StringTools.hex(KtxCompressedFormats.resolve(context, ktx.glInternalFormat), 8));
	}
}
