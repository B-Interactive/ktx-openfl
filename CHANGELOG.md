Changelog
=========

0.5.0 (14/10/2026)
----------

Library rename and extra compression formats.

- ASTC 2D LDR: all 14 block sizes, RGBA and sRGB, mapped to `KtxGPUFormat.ASTC` and Context3D `compressedAlpha`
- EAC R11, SIGNED R11, RG11 and SIGNED RG11, mapped to `KtxGPUFormat.ETC2` and Context3D `compressed`
- `Ktx.isAstcHdrSupported()` (also on `KtxCompressedFormats`) for asset selection. Upload and `isFormatSupported` stay LDR-only; the HDR query does not enable block formats on its own
- Upload is GPU-only via `compressedTexImage2D`. There is no CPU decode path

Not supported yet:

- BPTC / RGTC, PVRTC2, S3TC sRGB variants, ATC, FXT1, LATC and other legacy codecs
- ASTC 3D, array and 1D textures
- Uncompressed KTX
- KTXv2, Basis, UASTC and CPU transcoder
- Flash / AIR native KTX upload

0.4.0 (09/10/2026)
------------------

Version-agnostic public API. KTXv1 and KTXv2 are detected from the file identifier. KTXv2 is recognised and rejected cleanly. KTXv1 loading is unchanged.

**API renames** (no deprecated aliases):

- `ktx.openfl.Ktx1` → `ktx.openfl.Ktx`
- `ktx.openfl.Ktx1Data` → `ktx.openfl.KtxData` (`isKtx1Data()` → `isKtxData()`)
- `ktx.openfl.Ktx1Format` / `Ktx1FormatInfo` → `ktx.openfl.KtxFormat` / `KtxFormatInfo`
- `ktx.openfl.Ktx1GPUFormat` → `ktx.openfl.KtxGPUFormat`
- `TextureKtx.uploadKtx1FromByteArray()` / `CubeTextureKtx.uploadKtx1FromByteArray()` → `uploadKtxFromByteArray()`
- `KtxTextures.fromKtx1Data()` → `fromKtxData()`

**Detection and errors:**

- `Ktx.isKtx()`, `Ktx.isKtx1()` and `Ktx.isKtx2()` classify the 12-byte file identifier without parsing
- `KtxData.isKtxData()` is true for any KTX magic (v1 or v2)
- KTXv2 files are rejected with `IllegalOperationError`: "OpenFL KTX: KTXv2 is not supported yet"
- Non-KTX data throws `ArgumentError`: "Data is not a KTX file"
- Starling `KtxTextureFactory.canHandle()` accepts both versions; `create()` reports unsupported KTXv2 through the manager error callback

`Ktx1Reader` remains the public KTXv1 parser. Internal upload stays `Ktx1Upload`.

Not supported in this release:

- KTXv2 parse and upload (identifier detection only)
- `.ktx2` extension registration with the Starling factory
- 1D, 3D, array and uncompressed KTX

0.3.0 (08/10/2026)
------------------

Optional Starling bridge for loading KTXv1 textures without replacing Starling classes.

- `KtxTextures.fromKtx1Data()` — KTX equivalent of `Texture.fromAtfData()`, with scale, mip-map, async callback and explicit premultiplied-alpha
- `KtxTextureFactory` — `AssetFactory` that turns `.ktx` assets into textures; context-loss restore reloads and re-uploads through KTX, not ATF
- `KtxAssets.register()` — one-line registration at startup
- Context-loss restore uses `texture.root.onRestore`
- `KtxCompressedFormats` re-probes when the live context or GL object changes; `reset()` remains for manual cases
- Cubemap data is rejected with `ArgumentError` (Starling has no cubemap support, same as ATF); non-power-of-two data throws from `ConcretePotTexture`
- No haxelib dependency on Starling; opt in with `-lib starling`
- Starling-gated tests and `examples/ktx-starling` sample

0.2.0 (08/10/2026)
------------------

KTXv1 cubemap upload for OpenFL `CubeTexture`, matching compressed ATF cube behaviour.

- `Ktx1.createCubeTexture()` — creates a `CubeTexture` and uploads all faces and mip levels
- `Ktx1.uploadCompressedCubeTextureFromByteArray()` — uploads into an existing `CubeTexture`, with `async` / `Event.TEXTURE_READY` parity
- `CubeTextureKtx` static extension (`uploadKtx1FromByteArray`)
- Mixing cubemap and 2D APIs throws `IllegalOperationError` before any GL work
- Flash and AIR stubs cover the new cube methods with the unsupported-target message
- OpenFL dependency declared in `haxelib.json`

0.1.0 (10/08/2026)
------------------

Initial preview release as a standalone Haxelib.

- `Ktx1` façade: `isKtx1()`, `readData()`, `isFormatSupported()`, `createTexture()`, `uploadCompressedTextureFromByteArray()`
- Pure-Haxe KTXv1 parser (`Ktx1Reader`) for block-compressed 2D and cubemap textures (little-endian and big-endian)
- DXT1/DXT3/DXT5, PVRTC (2bpp/4bpp), ETC1 and ETC2 (RGB, RGBA, punchthrough) format mapping
- GPU format detection via `KtxCompressedFormats` (including ETC2 on WebGL2 and OpenGL ES 3.0 core)
- `Ktx1Data` metadata wrapper shaped like Starling's `AtfData`
- `TextureKtx` static extension (`uploadKtx1FromByteArray`)
- Synchronous and asynchronous upload with `Event.TEXTURE_READY` parity with OpenFL ATF
- Parsing-only on Flash and AIR (upload not available on those runtimes)
- `examples/ktx-basic` sample
