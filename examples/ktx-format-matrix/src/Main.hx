package;

import openfl.display.Sprite;
import openfl.events.Event as OpenFLEvent;
import openfl.geom.Rectangle;
import starling.core.Starling;

/**
	Bootstraps Starling for the format-matrix demo and forwards OpenFL resize
	events to the Starling viewport and stage, so the grid can re-layout.
**/
class Main extends Sprite
{
	public var starling(default, null):Starling;

	public function new()
	{
		super();

		addEventListener(OpenFLEvent.ADDED_TO_STAGE, onAddedToStage);
	}

	private function onAddedToStage(event:OpenFLEvent):Void
	{
		removeEventListener(OpenFLEvent.ADDED_TO_STAGE, onAddedToStage);

		starling = new Starling(FormatMatrixRoot, stage);
		starling.start();

		stage.addEventListener(OpenFLEvent.RESIZE, onResize);
	}

	private function onResize(event:OpenFLEvent):Void
	{
		if (starling == null)
		{
			return;
		}

		starling.viewPort = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
		starling.stage.stageWidth = stage.stageWidth;
		starling.stage.stageHeight = stage.stageHeight;

		var root = Std.downcast(starling.root, FormatMatrixRoot);
		if (root != null)
		{
			root.layoutGrid();
		}

		starling.nextFrame();
	}
}
