KTX for OpenFL Format Matrix
============================

A Starling demo that adapts to the GPU it is actually running on. The same
run-cycle sprite sheet is shipped eight times — once as a PNG atlas and seven
times as KTX — and only the formats this runtime can sample are played as
animated clips in a grid. Unsupported formats are listed as plain text on the
right with a short reason. There are no grey placeholder cells.

It uses stock OpenFL and Starling plus the `ktx-openfl` Starling bridge. No
OpenFL or Starling class is forked or replaced.

What ships
----------

| Container | Label | Loading path |
|---|---|---|
| PNG | PNG · bitmap | stock `Texture.fromBitmapData()` |
| KTXv1 | KTX · ASTC | `KtxTextures.fromKtxData()` after a live GPU probe |
| KTXv1 | KTX · DXT1 | same |
| KTXv1 | KTX · DXT5 | same |
| KTXv1 | KTX · ETC1 | same |
| KTXv1 | KTX · ETC2 RGB | same |
| KTXv1 | KTX · ETC2 RGBA | same |
| KTXv1 | KTX · PVRTC I 4bpp | same |

ASTC is a first-class entry here, not an optional extra. Which cells animate
depends on the hardware, driver and target (for example DXT on many desktop
GL setups, ETC on many mobile GL setups, and a smaller set under WebGL).

How loading works
-----------------

All eight assets are listed in one declarative table (`kMatrix`). There is no
filesystem scan.

* **PNG** — `Assets.getBitmapData()` then stock `Texture.fromBitmapData()`.
* **KTX** — `Assets.getBytes()` → `Ktx.readData(bytes)` →
  `Ktx.supports(Starling.current.context, ktx)` **before** upload.
  Supported files go through
  `KtxTextures.fromKtxData(bytes, 1, true, null, false)` with PMA stated
  explicitly as `false` (KTX does not record premultiplied alpha on v1; these
  assets store straight alpha). Unsupported files are not uploaded; the
  reason uses the header `formatName`, e.g.
  `unsupported on this GPU (ASTC 4x4)`.

Loading is deliberate and direct rather than through Starling's
`AssetManager`, so each texture stays paired with its own atlas XML. The
`KtxAssets.register()` factory path (`.ktx` / `.ktx2`; v2 still rejected at
load) is shown in the sibling `ktx-starling` example.

Atlas XML frame names embed the texture file base name, so each cell asks its
`TextureAtlas` for `getTextures(prefix)` with that prefix. The KTX
`ByteArray` is not disposed: the bridge keeps it for context-loss restore.

How to run
----------

From this folder (`examples/ktx-format-matrix`):

```sh
openfl test html5     # or: lime test html5
openfl test hl        # HashLink desktop
openfl test linux     # C++ desktop (also mac / windows)
```

The demo expects the `ktx-openfl` haxelib to be available; during library
development, point it at this checkout with
`haxelib dev ktx-openfl ../..`.

What to expect
--------------

* A short title: only formats this GPU can sample are animated; the rest are
  listed on the right.
* A grid of labelled, animated clips (6 frames at 12 fps) for every supported
  container — PNG and whichever KTX formats the live GPU accepts.
* A right-hand panel headed **Unsupported on this runtime**, listing the
  others with a short reason. If everything ships successfully on this
  machine, the panel says all shipped formats are supported on this runtime.
* Resizing the window reflows the grid and panel via `layoutGrid()`. Textures
  and juggler clips are not recreated.

On-screen strings use Starling's mini bitmap font charset; list bullets are
plain ASCII hyphens so every glyph stays inside that set.

Learner notes
-------------

* Probe with `Ktx.supports(context, ktxData)` before upload so unsupported
  compressed formats (ASTC included) become a clean list entry instead of a
  failed texture. Prefer this over the advanced `Ktx.isFormatSupported` GL
  probe when you already hold `KtxData`.
* Pass `premultipliedAlpha` explicitly; never infer it from `hasAlpha`.
* Prefer the direct `fromKtxData` path when each atlas must stay tied to a
  known XML pair; use `KtxAssets` when you want `AssetManager` to own loading.
* Keep the source bytes while a texture may restore after context loss — the
  bridge already does this when you leave the `ByteArray` alone.
