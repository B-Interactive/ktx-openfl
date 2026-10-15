package ktx.openfl.starling;

import starling.assets.AssetManager;

/**
	Registers the KTX texture factory with a Starling `AssetManager`.

	Applications using this helper add the Starling library (`-lib starling`)
	themselves; the core `ktx.openfl` package never references this class, so
	dead-code elimination drops the bridge when it is unused.
**/
class KtxAssets
{
	/**
		Register a `KtxTextureFactory` so that the manager turns KTX data into
		`starling.textures.Texture` assets.

		Call this once at startup, before loading the asset queue:

		```haxe
		var assets = new AssetManager();
		KtxAssets.register(assets);
		assets.enqueue(["cat_run.ktx"]);
		assets.loadQueue(function():Void
		{
			addChild(new Image(assets.getTexture("cat_run")));
		});
		```

		Each call registers a new factory instance. Duplicate registrations are
		wasteful but harmless, because factories are probed in priority order
		until one can handle a reference.

		@param manager  The asset manager to register the factory with.
		@param priority The factory priority. The default of `0` matches
		                  Starling's own texture factories.
	**/
	public static function register(manager:AssetManager, priority:Int = 0):Void
	{
		manager.registerFactory(new KtxTextureFactory(), priority);
	}
}
