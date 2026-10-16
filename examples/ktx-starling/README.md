KTX for OpenFL Starling Sample
==============================

A small Starling demo that shows a running cat as a `MovieClip`, using a
KTX compressed spritesheet loaded through Starling's `AssetManager`.

What it does
------------

* Registers the KTX factory once with `KtxAssets.register()`, so the
  `AssetManager` turns `.ktx` (and `.ktx2`) files into textures. KTXv2 is
  still rejected at load with a clear error; only KTXv1 uploads today.
* Picks the first atlas format this GPU can sample, in this order:
  **DXT5 → ETC2 → PVRTC → DXT1 → ETC1**. Each candidate's header is read
  with `Ktx.readData` / `KtxData` and checked with `Ktx.supports()` before
  it is loaded; only the winner is enqueued. (`ktx-openfl` also supports
  ASTC 2D LDR and EAC R/RG when the GPU allows; this sample does not ship
  those assets.)
* Enqueues the winning `.ktx` and its atlas `.xml`. The `AssetManager` pairs
  them into a `TextureAtlas` (the XML's `imagePath` names the texture), and
  the frames become a 12 fps `MovieClip` centred on stage, labelled with the
  chosen format.
* Texture options set premultiplied alpha to `false` (typical for compressed
  KTX; the container does not record PMA on v1).
* If no candidate is supported, a short message is shown instead.

Context loss
------------

The KTX texture was created with a URL by the `AssetManager`, so after a
context loss `KtxTextureFactory` reloads the bytes from that URL and
re-uploads them; the demo code does nothing. It traces a line when the
manager fires `Event.TEXTURES_RESTORED`. This is why the assets are not
embedded: the factory needs a reloadable file path or URL.

How to run
----------

From this folder (`examples/ktx-starling`):

```sh
lime build html5      # then serve bin/html5/bin
lime test hl          # HashLink desktop
lime test linux       # C++ desktop (also mac / windows)
```

During library development, point the haxelib at this checkout with
`haxelib dev ktx-openfl ../..`.
