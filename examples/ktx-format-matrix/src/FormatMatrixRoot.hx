package;

import openfl.Assets;
import ktx.openfl.Ktx;
import ktx.openfl.KtxData;
import ktx.openfl.starling.KtxTextures;
import starling.core.Starling;
import starling.display.MovieClip;
import starling.display.Sprite;
import starling.events.Event;
import starling.text.BitmapFont;
import starling.text.TextField;
import starling.text.TextFieldAutoSize;
import starling.text.TextFormat;
import starling.textures.Texture;
import starling.textures.TextureAtlas;
import starling.utils.Align;
import starling.utils.Color;

/**
	The Starling display root for the format matrix.

	One animated sprite sheet is loaded eight times: once as a PNG atlas,
	and seven times as KTX (ASTC, DXT1, DXT5, ETC1, ETC2 RGB, ETC2 RGBA and
	PVRTC I 4bpp). Each container holds the same run cycle in a different
	GPU-compressed (or bitmap) format.

	The demo adapts to the GPU it is actually running on. Assets the runtime
	can sample are played as animated clips in a grid; the rest are listed as
	plain text on the right-hand side with a short reason. There are no
	placeholder cells.

	All loading is declarative: `kMatrix` lists every asset pair, and the
	same code path runs on every target. There is no filesystem scan.

	* PNG uses the stock `Texture.fromBitmapData()`.
	* KTX uses the `ktx-openfl` Starling bridge (`KtxTextures.fromKtxData()`)
	  behind a `Ktx.isFormatSupported()` probe, so every compressed format,
	  ASTC included, is checked against the live GPU before it is uploaded.

	`layoutGrid()` runs on load and again from `Main` on every window
	resize; it only moves things around and never recreates textures.

	No OpenFL or Starling class is forked or replaced.
**/
class FormatMatrixRoot extends Sprite
{
	/** Container kinds handled by this demo. */
	static inline var KIND_PNG = "png";
	static inline var KIND_KTX = "ktx";

	/** Frames per second of each animated clip. */
	static inline var MOVIE_FPS = 12;

	/** Width of the right-hand panel that lists unsupported formats. */
	static inline var PANEL_WIDTH = 320;

	/** Space around the edges of the stage. */
	static inline var PADDING = 16;

	/** Space between grid cells, and between text blocks. */
	static inline var GUTTER = 12;

	private static var kMatrix:Array<MatrixEntry> = [
		{ id: "cat_run_png", kind: KIND_PNG, tex: "assets/img/cat_run_png.png",
			xml: "assets/img/cat_run_png.xml", prefix: "cat_run_png", label: "PNG · bitmap" },

		{ id: "cat_run_ktx-astc", kind: KIND_KTX, tex: "assets/ktx/cat_run_ktx-astc.ktx",
			xml: "assets/ktx/cat_run_ktx-astc.xml", prefix: "cat_run_ktx-astc", label: "KTX · ASTC" },
		{ id: "cat_run_ktx-dxt1", kind: KIND_KTX, tex: "assets/ktx/cat_run_ktx-dxt1.ktx",
			xml: "assets/ktx/cat_run_ktx-dxt1.xml", prefix: "cat_run_ktx-dxt1", label: "KTX · DXT1" },
		{ id: "cat_run_ktx-dxt5", kind: KIND_KTX, tex: "assets/ktx/cat_run_ktx-dxt5.ktx",
			xml: "assets/ktx/cat_run_ktx-dxt5.xml", prefix: "cat_run_ktx-dxt5", label: "KTX · DXT5" },
		{ id: "cat_run_ktx-etc1", kind: KIND_KTX, tex: "assets/ktx/cat_run_ktx-etc1.ktx",
			xml: "assets/ktx/cat_run_ktx-etc1.xml", prefix: "cat_run_ktx-etc1", label: "KTX · ETC1" },
		{ id: "cat_run_ktx-etc2-rgb-noalpha", kind: KIND_KTX, tex: "assets/ktx/cat_run_ktx-etc2-rgb-noalpha.ktx",
			xml: "assets/ktx/cat_run_ktx-etc2-rgb-noalpha.xml", prefix: "cat_run_ktx-etc2-rgb-noalpha",
			label: "KTX · ETC2 RGB" },
		{ id: "cat_run_ktx-etc2-rgba", kind: KIND_KTX, tex: "assets/ktx/cat_run_ktx-etc2-rgba.ktx",
			xml: "assets/ktx/cat_run_ktx-etc2-rgba.xml", prefix: "cat_run_ktx-etc2-rgba", label: "KTX · ETC2 RGBA" },
		{ id: "cat_run_ktx-pvrtci-4bpp-rgba", kind: KIND_KTX, tex: "assets/ktx/cat_run_ktx-pvrtci-4bpp-rgba.ktx",
			xml: "assets/ktx/cat_run_ktx-pvrtci-4bpp-rgba.xml", prefix: "cat_run_ktx-pvrtci-4bpp-rgba",
			label: "KTX · PVRTC I 4bpp" }
	];

	private var title:TextField;
	private var panel:Sprite;
	private var cells:Array<Sprite>;

	public function new()
	{
		super();

		cells = new Array<Sprite>();

		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}

	private function onAddedToStage(event:Event):Void
	{
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

		title = createTitle();
		addChild(title);

		var unsupported = new Array<String>();

		for (entry in kMatrix)
		{
			var outcome = loadTexture(entry);

			if (outcome.texture == null)
			{
				unsupported.push(describeFailure(entry, outcome.reason));
				continue;
			}

			var cell = createCell(entry, outcome.texture);

			if (cell == null)
			{
				unsupported.push(describeFailure(entry, "no frames matched the atlas"));
				continue;
			}

			addChild(cell);
			cells.push(cell);
		}

		panel = createUnsupportedPanel(unsupported);
		addChild(panel);

		layoutGrid();
	}

	/**
		Places the supported cells in a grid within the space left of the
		right-hand panel, and pins the panel to the right edge. Called on
		load and again from `Main` on every window resize; layout only, no
		textures are recreated and no clips are re-added to the juggler.
	**/
	public function layoutGrid():Void
	{
		if (title == null || panel == null)
		{
			return;
		}

		var panelX = Std.int(stage.stageWidth - PANEL_WIDTH - PADDING);

		title.width = panelX - PADDING * 2;
		panel.x = panelX;

		var contentTop = PADDING + Std.int(title.height) + GUTTER;
		panel.y = contentTop;

		if (cells.length == 0)
		{
			return;
		}

		var cellWidth = 0;
		var cellHeight = 0;

		for (cell in cells)
		{
			cellWidth = Std.int(Math.max(cellWidth, cell.width));
			cellHeight = Std.int(Math.max(cellHeight, cell.height));
		}

		if (cellWidth == 0 || cellHeight == 0)
		{
			return;
		}

		var usableWidth = panelX - PADDING * 2;
		if (usableWidth < cellWidth)
		{
			usableWidth = cellWidth;
		}

		var columns = Std.int(usableWidth / (cellWidth + GUTTER));
		if (columns < 1)
		{
			columns = 1;
		}

		for (i in 0...cells.length)
		{
			var col = i % columns;
			var row = Std.int(i / columns);
			cells[i].x = PADDING + col * (cellWidth + GUTTER);
			cells[i].y = contentTop + row * (cellHeight + GUTTER);
		}
	}

	// Display construction

	private function createTitle():TextField
	{
		var text = new TextField(stage.stageWidth - PADDING * 2, 16,
			"Only the formats this GPU can sample are animated; the rest are listed on the right.",
			new TextFormat(BitmapFont.MINI, BitmapFont.NATIVE_SIZE * 2, Color.WHITE));
		text.autoSize = TextFieldAutoSize.VERTICAL;
		text.x = PADDING;
		text.y = PADDING;
		return text;
	}

	/** Builds one animated clip cell with its label, or null when the atlas has no frames. */
	private function createCell(entry:MatrixEntry, texture:Texture):Null<Sprite>
	{
		// The atlas XML names embed the texture file name, so every frame of
		// this entry starts with the declared prefix.
		var atlas = new TextureAtlas(texture, Assets.getText(entry.xml));
		var frames = atlas.getTextures(entry.prefix);

		if (frames.length == 0)
		{
			return null;
		}

		var cell = new Sprite();

		var clip = new MovieClip(frames, MOVIE_FPS);
		clip.alignPivot(Align.CENTER, Align.CENTER);
		clip.x = Std.int(clip.width * 0.5);
		clip.y = Std.int(clip.height * 0.5);
		cell.addChild(clip);
		Starling.current.juggler.add(clip);

		var text = new TextField(Std.int(clip.width), 16, entry.label,
			new TextFormat(BitmapFont.MINI, BitmapFont.NATIVE_SIZE * 2, Color.WHITE));
		text.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
		text.x = Std.int((clip.width - text.width) / 2);
		text.y = Std.int(clip.height) + 4;
		cell.addChild(text);

		return cell;
	}

	/** Builds the right-hand text panel listing the formats this runtime cannot play. */
	private function createUnsupportedPanel(unsupported:Array<String>):Sprite
	{
		var panel = new Sprite();
		var format = new TextFormat(BitmapFont.MINI, BitmapFont.NATIVE_SIZE * 2, Color.WHITE);

		var heading = new TextField(PANEL_WIDTH, 16, "Unsupported on this runtime", format);
		heading.autoSize = TextFieldAutoSize.VERTICAL;
		panel.addChild(heading);

		var body = unsupported.length == 0
			? "All shipped formats are supported on this runtime."
			: unsupported.join("\n");

		var list = new TextField(PANEL_WIDTH, 16, body, format);
		list.autoSize = TextFieldAutoSize.VERTICAL;
		list.y = Std.int(heading.height) + GUTTER;
		panel.addChild(list);

		return panel;
	}

	private static function describeFailure(entry:MatrixEntry, reason:String):String
	{
		// One line of the unsupported list; plain hyphens keep every glyph
		// inside the mini bitmap font's charset.
		return "- " + entry.label + " - " + reason;
	}

	// Texture loading, one path per container kind

	private function loadTexture(entry:MatrixEntry):LoadOutcome
	{
		switch (entry.kind)
		{
			case KIND_PNG:
				var bitmapData = Assets.getBitmapData(entry.tex);

				if (bitmapData == null)
				{
					return { texture: null, reason: "missing PNG asset" };
				}

				// Stock bitmap path; mipmaps are not needed by this demo.
				return { texture: Texture.fromBitmapData(bitmapData, false), reason: null };

			case KIND_KTX:
				try
				{
					var bytes = Assets.getBytes(entry.tex);
					var ktx = new KtxData(bytes);

					// Probe the live GPU before uploading, so a compressed
					// format such as ASTC is listed when this hardware cannot
					// sample it.
					if (!Ktx.isFormatSupported(Starling.current.context, ktx.glInternalFormat))
					{
						return { texture: null, reason: "unsupported on this GPU (" + ktx.formatName + ")" };
					}

					// KTX files do not record premultiplied alpha, so PMA is
					// stated explicitly as false for these straight-alpha
					// assets. The bridge keeps the ByteArray for context-loss
					// restore, so it is not disposed here.
					return { texture: KtxTextures.fromKtxData(bytes, 1, true, null, false), reason: null };
				}
				catch (e:Dynamic)
				{
					// Parse, upload or missing-context problems are listed too,
					// keeping the demo running on any target.
					return { texture: null, reason: "KTX could not load: " + e };
				}
		}

		return { texture: null, reason: "unknown container" };
	}
}

/** One row of the format matrix. */
private typedef MatrixEntry =
{
	var id:String;
	var kind:String;
	var tex:String;
	var xml:String;
	var prefix:String;
	var label:String;
}

/** The outcome of loading one texture: a texture, or a reason it is unsupported. */
private typedef LoadOutcome =
{
	var texture:Null<Texture>;
	var reason:Null<String>;
}
