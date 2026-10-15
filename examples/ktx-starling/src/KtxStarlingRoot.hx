package;

import openfl.Assets;
import ktx.openfl.Ktx;
import ktx.openfl.KtxData;
import ktx.openfl.starling.KtxAssets;
import starling.assets.AssetManager;
import starling.core.Starling;
import starling.display.MovieClip;
import starling.display.Sprite;
import starling.events.Event;
import starling.text.BitmapFont;
import starling.text.TextField;
import starling.text.TextFieldAutoSize;
import starling.text.TextFormat;
import starling.textures.TextureOptions;
import starling.textures.TextureAtlas;
import starling.utils.Align;
import starling.utils.Color;

/**
	Shows a running cat as a Starling `MovieClip`, with the spritesheet coming
	from a KTX compressed texture.

	The texture is picked by format preference: the first candidate that this
	GPU can sample wins (DXT5, then ETC2, PVRTC, DXT1, ETC1). The winner is
	loaded through Starling's `AssetManager`, after `KtxAssets.register()`
	teaches the manager about `.ktx` files. The AssetManager pairs the texture
	with its atlas XML and builds a `TextureAtlas` automatically.

	After a context loss the `KtxTextureFactory` reloads the bytes from the
	original URL and re-uploads them, so no demo code is needed.
**/
class KtxStarlingRoot extends Sprite
{
	private static inline var MOVIE_FPS = 12;

	/** Candidate atlases, best format first. */
	private static var CANDIDATES:Array<Candidate> = [
		{ file: "cat_run_ktx-dxt5", formatHint: "DXT5" },
		{ file: "cat_run_ktx-etc2-rgba", formatHint: "ETC2" },
		{ file: "cat_run_ktx-pvrtci-4bpp-rgba", formatHint: "PVRTC" },
		{ file: "cat_run_ktx-dxt1", formatHint: "DXT1" },
		{ file: "cat_run_ktx-etc1", formatHint: "ETC1" }
	];

	private var clip:MovieClip;

	public function new()
	{
		super();

		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}

	private function onAddedToStage(event:Event):Void
	{
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

		probeCandidate(0);
	}

	// Format preference: load each candidate's header in order and keep the
	// first format this GPU supports. Bytes load asynchronously, which is the
	// only way to read them on HTML5.

	private function probeCandidate(index:Int):Void
	{
		if (index >= CANDIDATES.length)
		{
			showMessage("None of the shipped KTX formats is supported by this GPU.");
			return;
		}

		var candidate = CANDIDATES[index];
		var bytesFuture = Assets.loadBytes("assets/" + candidate.file + ".ktx");

		bytesFuture.onComplete(function(bytes):Void
			{
				if (bytes != null && Ktx.isKtx1(bytes))
				{
					var ktx = new KtxData(bytes);

					if (Ktx.isFormatSupported(Starling.current.context, ktx.glInternalFormat))
					{
						loadWinner(candidate);
						return;
					}
				}

				probeCandidate(index + 1);
			});

		bytesFuture.onError(function(error:Dynamic):Void
			{
				// A missing file simply moves on to the next candidate.
				probeCandidate(index + 1);
			});
	}

	// Load the winning ktx + xml pair through the AssetManager.

	private function loadWinner(candidate:Candidate):Void
	{
		trace("Using " + candidate.formatHint + " (" + candidate.file + ").");

		var assets = new AssetManager();

		// One registration teaches the manager to turn KTX bytes into textures.
		KtxAssets.register(assets);

		// Compressed textures ship their own mip levels; KTX does not record
		// whether alpha is premultiplied, and these assets use straight alpha.
		assets.textureOptions = new TextureOptions(1.0, true, "bgra", false);

		// Paths become URLs the factory reloads after a context loss.
		assets.enqueue([
			Assets.getPath("assets/" + candidate.file + ".ktx"),
			Assets.getPath("assets/" + candidate.file + ".xml")
		]);

		assets.addEventListener(Event.TEXTURES_RESTORED, function(_):Void
			{
				trace("Textures restored after context loss.");
			});

		assets.loadQueue(function():Void
			{
				// Starling names the texture after its file and pairs the
				// atlas XML with it automatically.
				var atlas = assets.getTextureAtlas(candidate.file);

				if (atlas == null)
				{
					showMessage("The atlas could not be created.");
					return;
				}

				showMovieClip(atlas, candidate);
			},
			function(error:String):Void
			{
				showMessage("Loading failed: " + error);
			});
	}

	private function showMovieClip(atlas:TextureAtlas, candidate:Candidate):Void
	{
		// Subtexture names start with the file name, so the prefix collects
		// the run-cycle frames in alphabetical order.
		var clip = new MovieClip(atlas.getTextures(candidate.file), MOVIE_FPS);
		clip.alignPivot(Align.CENTER, Align.CENTER);

		addChild(clip);
		Starling.current.juggler.add(clip);

		this.clip = clip;
		centreClip();

		var label = new TextField(256, 32, candidate.formatHint,
			new TextFormat(BitmapFont.MINI, BitmapFont.NATIVE_SIZE * 2, Color.WHITE));
		label.autoSize = TextFieldAutoSize.HORIZONTAL;
		label.x = Std.int((stage.stageWidth - label.width) / 2);
		label.y = 8;
		addChild(label);
	}

	/** Centres the clip; called on load and from `Main` on every resize. */
	public function centreClip():Void
	{
		if (clip != null)
		{
			clip.x = stage.stageWidth / 2;
			clip.y = stage.stageHeight / 2;
		}
	}

	private function showMessage(text:String):Void
	{
		var label = new TextField(256, 64, text,
			new TextFormat(BitmapFont.MINI, BitmapFont.NATIVE_SIZE * 2, Color.WHITE));
		label.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
		label.x = (stage.stageWidth - Std.int(label.width)) / 2;
		label.y = stage.stageHeight / 2;
		addChild(label);
	}
}

/** One atlas the demo can pick, best format first. */
private typedef Candidate =
{
	var file:String;
	var formatHint:String;
}
