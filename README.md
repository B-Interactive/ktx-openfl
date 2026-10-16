# KTX for OpenFL

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE.md) [![Haxelib Version](https://img.shields.io/github/tag/B-Interactive/openfl-ktx.svg?style=flat&label=haxelib&color=df7900)](https://lib.haxe.org/p/ktx-openfl)

**ktx-openfl** adds [KTX](https://registry.khronos.org/KTX/specs/1.0/ktxspec.v1.html) (Khronos Texture) GPU texture container support to [OpenFL](https://openfl.org), with an optional [Starling](https://github.com/openfl/starling) bridge. Load KTXv1 compressed textures and upload them straight to the GPU — smaller downloads and lower memory than PNG, without a CPU decode path.

KTXv1 is currently supported. KTXv2 when detected is rejected with an error, until supported.


## Contents

- [Features](#features)
- [Public API](#public-api)
- [Compressed format support](#compressed-format-support)
- [Install](#install)
- [Quick start (OpenFL)](#quick-start-openfl)
- [Starling](#starling)
- [Premultiplied alpha](#premultiplied-alpha)
- [Async upload](#async-upload)
- [Mipmaps](#mipmaps)
- [Examples](#examples)
- [Migrating from ATF](#migrating-from-atf)
- [Targets](#targets)
- [Notes](#notes)
- [Testing](#testing)
- [License](#license)

## Features

- Parse KTXv1 block-compressed textures; detect KTXv1 and KTXv2 identifiers
- Create and upload OpenFL `Texture` and `CubeTexture` from bytes or parsed `KtxData`
- Canonical capability check via `Ktx.supports`; advanced GL probe via `Ktx.isFormatSupported`
- Optional Starling bridge: `KtxTextures.fromKtxData`, `KtxAssets.register` (`.ktx` and `.ktx2`)
- DCE-friendly; written with Haxe 5 compatibility in mind
- Native and HTML5 upload (Flash / AIR: see [Targets](#targets))

## Public API

```haxe
import ktx.openfl.Ktx;
import ktx.openfl.KtxData;
import ktx.openfl.KtxGPUFormat;
import ktx.openfl.KtxSupercompression; // version-stable field on KtxData (NONE on v1)

// optional static extensions
import ktx.openfl.TextureKtx;
import ktx.openfl.CubeTextureKtx;

// optional Starling bridge (-lib starling)
import ktx.openfl.starling.KtxAssets;
import ktx.openfl.starling.KtxTextures;
```

| Type | Role |
| --- | --- |
| `Ktx` | Façade: detect, parse, probe, create, upload |
| `KtxData` | Version-agnostic metadata (AtfData-shaped); retains source bytes |
| `KtxGPUFormat` | GPU format bucket (DXT, PVRTC, ETC1, ETC2, ASTC) |
| `KtxSupercompression` | Supercompression scheme (`NONE` on KTXv1; reserved values for v2) |
| `TextureKtx` / `CubeTextureKtx` | Optional `using` extensions for existing textures |
| `KtxAssets` / `KtxTextures` | Optional Starling bridge |

**Not public:** `Ktx1Reader`, `KtxCompressedFormats`, `KtxFormat`, and other `ktx.openfl._internal` types. Do not import them from application code.

## Compressed format support

### Supported (KTXv1 upload)

| Family | Details | Context3D notes |
| --- | --- | --- |
| DXT / S3TC | DXT1, DXT3, DXT5 | |
| PVRTC1 | 2bpp / 4bpp, RGB and RGBA | |
| ETC1 | RGB | |
| ETC2 | RGB, RGBA, punchthrough (sRGB handled as implemented) | |
| EAC | R11, SIGNED R11, RG11, SIGNED RG11 | opaque `compressed` |
| ASTC 2D LDR | all 14 block sizes × RGBA and sRGB | `compressedAlpha`; LDR gate |

Upload is GPU-only (`compressedTexImage2D`). There is no CPU transcoder.

### Not supported / out of scope

| Item | Status |
| --- | --- |
| KTXv2 load | Detected, rejected cleanly |
| Basis Universal / UASTC | Planned with KTXv2 |
| BPTC / BC7, RGTC | Out of scope |
| PVRTC2, S3TC sRGB variants | Out of scope |
| ATC, FXT1, LATC and other legacy codecs | Out of scope |
| ASTC 3D / array / 1D | Out of scope |
| Uncompressed KTX | Out of scope |
| Flash / AIR upload | Parse only (runtime accepts ATF only) |
| Away3D bridge | Planned as optional (like Starling); not available yet |

## Install

```sh
haxelib install ktx-openfl
```

```xml
<haxelib name="ktx-openfl" />
```

Depends on OpenFL. Starling is optional (`-lib starling` when you use the bridge).

## Quick start (OpenFL)

### Happy path

```haxe
import ktx.openfl.Ktx;
import ktx.openfl.KtxData;

var data = Ktx.readData(bytes); // or: new KtxData(bytes)
// KTXv1 only; KTXv2 throws IllegalOperationError

if (!Ktx.supports(context, data))
{
	// Fall back to PNG / JPEG / ATF as you prefer
	return;
}

var texture = Ktx.createTextureFromData(context, data);
// or one-shot from bytes:
// var texture = Ktx.createTexture(context, bytes);
```

### Detect and inspect

```haxe
if (Ktx.isKtx(bytes)) // true for KTXv1 and KTXv2 identifiers
{
	var ktx = Ktx.readData(bytes);
	trace(ktx.version, ktx.formatName, ktx.width, ktx.height, ktx.numTextures, ktx.format);
	// format is "compressed" or "compressedAlpha", like Starling's AtfData
	// ktx.premultipliedAlpha is null on v1 (container does not record PMA)
	// ktx.supercompression is NONE; ktx.needsTranscode is false; ktx.isUploadReady is true
}

Ktx.isKtx1(bytes);
Ktx.isKtx2(bytes);
```

### Create and upload

```haxe
// From bytes
var texture = Ktx.createTexture(context, bytes);
Ktx.uploadCompressedTextureFromByteArray(texture, bytes, 0);

// From parsed metadata (no second header parse)
var texture = Ktx.createTextureFromData(context, data);
Ktx.uploadTextureFromData(texture, data);

// Optional static extension
using ktx.openfl.TextureKtx;
texture.uploadKtxFromByteArray(bytes, 0);
```

Cubemaps use the matching cube API (`Ktx.createCubeTexture`, `Ktx.createCubeTextureFromData`, `Ktx.uploadCompressedCubeTextureFromByteArray`, `Ktx.uploadCubeTextureFromData`, or `using ktx.openfl.CubeTextureKtx`). Face order is +X, −X, +Y, −Y, +Z, −Z. A 2D file through the cube API (or the reverse) throws before any GPU work.

### Probe the GPU

```haxe
// Canonical check for application code (parsed metadata + upload-ready)
if (!Ktx.supports(context, data))
{
	// Fall back …
}

// Advanced: raw KTXv1 GL internal-format probe (prefer supports when you hold KtxData)
if (!Ktx.isFormatSupported(context, data.glInternalFormat))
{
	// Fall back …
}

// ASTC packs that also ship HDR variants (selection only — LDR still gates upload):
if (Ktx.isAstcHdrSupported(context))
{
	// Prefer an HDR asset for selection if you maintain one
}
```

## Starling

The `ktx.openfl.starling` package is optional. Core `ktx.openfl` does not reference it. Add `-lib starling` when you use the bridge.

### From bytes

```haxe
import ktx.openfl.starling.KtxTextures;

// scale, mipmaps, async callback, premultipliedAlpha (default false)
// PMA false is typical for compressed KTX
var tex = KtxTextures.fromKtxData(bytes, 1, true, null, false);

KtxTextures.fromKtxData(ktxBytes, 1, true, function(texture) {
	addChild(new Image(texture));
}, false);
```

### AssetManager

```haxe
import ktx.openfl.starling.KtxAssets;
import starling.assets.AssetManager;

var assets = new AssetManager();
KtxAssets.register(assets); // registers .ktx and .ktx2
assets.enqueue(["hero.ktx"]);
assets.loadQueue(function() {
	addChild(new Image(assets.getTexture("hero")));
});
```

The factory accepts both `.ktx` and `.ktx2` by extension and file signature. **KTXv2 is still rejected at load** with a clear error; only KTXv1 uploads today.

Context-loss restore re-uploads through the KTX path (never stock ATF). Cubemap KTX is rejected in Starling (same limit as ATF); use the OpenFL cube API instead. Power-of-two sizes are required.

## Premultiplied alpha

KTX does **not** record whether alpha is premultiplied on v1 (`KtxData.premultipliedAlpha` is always `null`). The library never guesses from `hasAlpha`.

| Path | Default | How to enable PMA |
| --- | --- | --- |
| `KtxTextures.fromKtxData` | `premultipliedAlpha = false` | Pass `true` as the last argument |
| `AssetManager` | via `TextureOptions` | Set the 4th constructor arg (or `premultipliedAlpha`) to `true` |

```haxe
// Straight alpha (explicit — matches the shipped examples)
KtxTextures.fromKtxData(bytes, 1, true, null, false);

// Premultiplied alpha
KtxTextures.fromKtxData(bytes, 1, true, null, true);

// AssetManager: scale, mipMapping, format, premultipliedAlpha
assets.textureOptions = new TextureOptions(1.0, true, "bgra", false); // straight
// assets.textureOptions = new TextureOptions(1.0, true, "bgra", true); // PMA
```

## Async upload

When `async` is `true` on OpenFL create/upload methods, work is deferred to the next tick. **The texture is not usable until `Event.TEXTURE_READY`.**

```haxe
texture.addEventListener(Event.TEXTURE_READY, function(_) {
	// safe to sample
});
Ktx.uploadCompressedTextureFromByteArray(texture, bytes, 0, true);
// or: Ktx.createTexture(context, bytes, false, 0, true);
```

On Starling, pass a callback as the fourth argument to `KtxTextures.fromKtxData`. Do not use the texture before that callback runs. `AssetManager` uses `TextureOptions.onReady` the same way.

## Mipmaps

- `KtxData.numTextures` is the number of **embedded** mip levels in the file.
- `KtxData.generateMipmaps` is the **file header flag only** (true when the header says levels were omitted and the consumer should generate the chain).
- **Upload never generates mipmaps.** Only levels embedded in the file are uploaded to the GPU. If the file has a single base level, that is all you get — even when `generateMipmaps` is true.

Ship complete mip chains in the KTX when you need them. Starling's `useMipMaps` / `TextureOptions.mipMapping` only controls whether embedded levels are used, not generation.

## Examples

| Example | What it shows |
| --- | --- |
| [`examples/ktx-basic`](examples/ktx-basic) | OpenFL façade: detect, `Ktx.readData`, `Ktx.supports`, `createTexture` / `createTextureFromData`, extension upload |
| [`examples/ktx-starling`](examples/ktx-starling) | `KtxAssets.register`, format preference via `Ktx.supports`, atlas + `MovieClip`; `textureOptions` PMA = `false` |
| [`examples/ktx-format-matrix`](examples/ktx-format-matrix) | PNG + 7 KTX formats (including ASTC); supported formats animate in a grid, unsupported listed with reasons; live `Ktx.supports` probe, `fromKtxData(..., false)` |

```sh
cd examples/ktx-format-matrix && openfl test html5
```

## Migrating from ATF

| ATF | KTX |
| --- | --- |
| `texture.uploadCompressedTextureFromByteArray(atf, 0)` | `Ktx.createTexture(context, ktx)` or `Ktx.uploadCompressedTextureFromByteArray(texture, ktx, 0)` |
| `CubeTexture` + ATF upload | `Ktx.createCubeTexture(context, ktx)` |
| `Texture.fromAtfData(bytes)` | `KtxTextures.fromKtxData(bytes)` |
| AssetManager `.atf` | `KtxAssets.register(assets)` + enqueue `.ktx` |
| `COMPRESSED` / `COMPRESSED_ALPHA` at creation | Taken from the KTX header (`KtxData.format`) |
| Embedded mipmaps / `async` + `TEXTURE_READY` | Same readiness model; only embedded KTX levels are uploaded |
| ETC1 + separate alpha | Use ETC2 RGBA or DXT5 in a single KTX file |

## Targets

| Target | Parsing | Upload |
| --- | --- | --- |
| Windows / macOS / Linux / Android / iOS / tvOS (C++, HashLink) | Yes | Yes |
| HTML5 / WebAssembly (WebGL) | Yes | Yes |
| Flash / AIR | Yes | No — throws `IllegalOperationError` |

Flash and AIR can still read KTX metadata for build-time tools.

## Notes

- Upload needs the Lime / OpenFL OpenGL backend.
- Keep the source `ByteArray` while a texture may restore after context loss; `KtxData` retains it for you.
- Prefer `Ktx.supports(context, data)` in application code. Use `Ktx.isFormatSupported(context, glInternalFormat)` only when you need a raw GL constant probe.

## Testing

[utest](https://lib.haxe.org/p/utest). From the repository root:

```sh
haxe tests/build-neko.hxml && neko bin/test.n
haxe tests/build-cpp.hxml && bin/cpp/TestMain
haxe tests/build-hl.hxml && (cd bin && hl test.hl)
haxe tests/build-js.hxml && node bin/test.js
```

Core suites do not need Starling. With Starling installed:

```sh
haxe tests/build-starling-neko.hxml && neko bin/test-starling.n
haxe tests/build-starling-hl.hxml && (cd bin && hl test-starling.hl)
```

## License

KTX for OpenFL is released under the [MIT license](LICENSE.md).

KTX is a trademark of The Khronos Group Inc. This library implements the publicly published format specification; it is not endorsed by or affiliated with Khronos.
