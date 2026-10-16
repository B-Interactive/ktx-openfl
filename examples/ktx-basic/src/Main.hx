package;

import openfl.Assets;
import openfl.display.Sprite;
import openfl.display.Stage3D;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DRenderMode;
import openfl.display3D.textures.Texture;
import openfl.events.Event;
import ktx.openfl.Ktx;
import ktx.openfl.KtxGPUFormat;
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
		var ktx = Ktx.readData(bytes);
		trace('KTX v${ktx.version}: ${ktx.formatName} ${ktx.width}x${ktx.height}, ${ktx.numTextures} levels, '
			+ 'format ' + ktx.format + (ktx.hasAlpha ? " (alpha)" : ""));

		// Ask the library whether this GPU can upload this data before
		// creating anything, so an unsupported format is skipped rather than
		// thrown on upload.
		if (!Ktx.supports(context, ktx))
		{
			trace("This GPU cannot upload " + ktx.formatName);
			return;
		}

		// Cubemap files use the matching cube API instead.
		if (ktx.isCubeMap)
		{
			var cube = Ktx.createCubeTextureFromData(context, ktx);
			trace("Uploaded via Ktx.createCubeTextureFromData: " + cube);
			return;
		}

		// Façade API: create and upload in one call from raw bytes.
		var texture = Ktx.createTexture(context, bytes);
		trace("Uploaded via Ktx.createTexture: " + texture);

		// The KtxData overload reuses the parsed metadata, avoiding a second
		// header parse.
		var fromData = Ktx.createTextureFromData(context, ktx);
		trace("Uploaded via Ktx.createTextureFromData: " + fromData);

		// Static extension equivalent, into an existing texture.
		var manual = context.createTexture(ktx.width, ktx.height, ktx.format, false);
		manual.uploadKtxFromByteArray(bytes);
		trace("Uploaded via uploadKtxFromByteArray extension");

		trace("GL internal format: 0x" + StringTools.hex(ktx.glInternalFormat, 8)
			+ ", GPU bucket: " + gpuFormatName(ktx.gpuFormat));
	}

	private static function gpuFormatName(gpuFormat:KtxGPUFormat):String
	{
		return switch (gpuFormat)
			{
				case KtxGPUFormat.DXT: "DXT";
				case KtxGPUFormat.PVRTC: "PVRTC";
				case KtxGPUFormat.ETC1: "ETC1";
				case KtxGPUFormat.ETC2: "ETC2";
				case KtxGPUFormat.ASTC: "ASTC";
				default: "Unknown";
			};
	}
}
