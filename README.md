# KTX for OpenFL

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE.md) [![Haxelib Version](https://img.shields.io/github/tag/B-Interactive/openfl-ktx.svg?style=flat&label=haxelib&color=df7900)](https://lib.haxe.org/p/ktx-openfl)

**ktx-openfl** adds [KTX](https://registry.khronos.org/KTX/specs/1.0/ktxspec.v1.html) (Khronos Texture) GPU texture container support to [OpenFL](https://openfl.org), with an optional [Starling](https://github.com/openfl/starling) bridge. Load KTXv1 compressed textures and upload them straight to the GPU — smaller downloads and lower memory than PNG, without a CPU decode path.

KTXv1 loads today. KTXv2 is detected from the file identifier and rejected with a clear error until support lands.

## Contents

- [Features](#features)
- [Compressed format support](#compressed-format-support)
- [Install](#install)
- [Quick start (OpenFL)](#quick-start-openfl)
- [Starling](#starling)
- [Premultiplied alpha](#premultiplied-alpha)
- [Examples](#examples)
- [Migrating from ATF](#migrating-from-atf)
- [Targets](#targets)
- [Notes](#notes)
- [Testing](#testing)
- [Roadmap](#roadmap)
- [License](#license)

## Features

- Parse KTXv1 block-compressed textures; detect KTXv1 and KTXv2 identifiers
- Create and upload OpenFL `Texture` and `CubeTexture` (mipmaps included; generate-mipmaps flag honoured)
- Format probe via `Ktx.isFormatSupported`; ASTC HDR profile query via `Ktx.isAstcHdrSupported` (selection only — LDR still gates upload)
- Optional Starling bridge: `KtxTextures.fromKtxData`, `KtxAssets.register`
- DCE-friendly; written with Haxe 5 compatibility in mind
- Native and HTML5 upload (Flash / AIR: see [Targets](#targets))

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
| Basis Universal / UASTC | Out of scope |
| BPTC / BC7, RGTC | Out of scope |
| PVRTC2, S3TC sRGB variants | Out of scope |
| ATC, FXT1, LATC and other legacy codecs | Out of scope |
| ASTC 3D / array / 1D | Out of scope |
| Uncompressed KTX | Out of scope |
| Flash / AIR upload | Parse only (runtime accepts ATF only) |
| Away3D bridge | Not available |

## Install

```sh
haxelib install ktx-openfl
```

```xml
<haxelib name="ktx-openfl" />
```

Depends on OpenFL. Starling is optional (`-lib starling` when you use the bridge).

## Quick start (OpenFL)

### Detect and inspect

```haxe
import ktx.openfl.Ktx;
import ktx.openfl.KtxData;

if (Ktx.isKtx(bytes)) // true for KTXv1 and KTXv2
{
	var ktx = new KtxData(bytes); // KTXv1 only; KTXv2 throws IllegalOperationError
	trace(ktx.formatName, ktx.width, ktx.height, ktx.numTextures, ktx.format);
	// format is "compressed" or "compressedAlpha", like Starling's AtfData
}

Ktx.isKtx1(bytes);
Ktx.isKtx2(bytes);
```

### Create and upload

```haxe
import ktx.openfl.Ktx;

// One-shot: size and format come from the header
var texture = Ktx.createTexture(context, bytes);

// Or upload into an existing texture
Ktx.uploadCompressedTextureFromByteArray(texture, bytes, 0);

// Optional static extension
using ktx.openfl.TextureKtx;
texture.uploadKtxFromByteArray(bytes, 0);
```

Cubemaps use the matching cube API (`Ktx.createCubeTexture`, `Ktx.uploadCompressedCubeTextureFromByteArray`, or `using ktx.openfl.CubeTextureKtx`). Face order is +X, −X, +Y, −Y, +Z, −Z. A 2D file through the cube API (or the reverse) throws before any GPU work.

Optional `async` on create/upload defers work and dispatches `Event.TEXTURE_READY`.

### Probe the GPU

```haxe
if (!Ktx.isFormatSupported(context, ktx.glInternalFormat))
{
	// Fall back to PNG / JPEG / ATF as you prefer
}

// ASTC packs that also ship HDR variants:
if (Ktx.isAstcHdrSupported(context))
{
	// Prefer an HDR asset for selection — upload still requires LDR support
}
```

## Starling

The `ktx.openfl.starling` package is optional. Core `ktx.openfl` does not reference it.

### From bytes

```haxe
import ktx.openfl.starling.KtxTextures;

var texture = KtxTextures.fromKtxData(ktxBytes);

// scale, mipmaps, async callback, premultipliedAlpha (default false)
KtxTextures.fromKtxData(ktxBytes, 1, true, function(texture) {
	addChild(new Image(texture));
}, false);
```

### AssetManager

```haxe
import ktx.openfl.starling.KtxAssets;
import starling.assets.AssetManager;

var assets = new AssetManager();
KtxAssets.register(assets);
assets.enqueue(["hero.ktx"]);
assets.loadQueue(function() {
	addChild(new Image(assets.getTexture("hero")));
});
```

Context-loss restore re-uploads through the KTX path (never stock ATF). Cubemap KTX is rejected in Starling (same limit as ATF); use the OpenFL cube API instead. Power-of-two sizes are required.

## Premultiplied alpha

KTX does **not** record whether alpha is premultiplied. The library never guesses from `hasAlpha`.

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

## Examples

| Example | What it shows |
| --- | --- |
| [`examples/ktx-basic`](examples/ktx-basic) | OpenFL façade: detect, `KtxData`, format probe, `createTexture`, extension upload |
| [`examples/ktx-starling`](examples/ktx-starling) | `KtxAssets.register`, format preference, atlas + `MovieClip`; `textureOptions` PMA = `false` |
| [`examples/ktx-format-matrix`](examples/ktx-format-matrix) | PNG + 7 KTX formats (including ASTC); supported formats animate in a grid, unsupported listed with reasons; live `isFormatSupported` probe, `fromKtxData(..., false)` |

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
| Embedded mipmaps / `async` + `TEXTURE_READY` | Same behaviour |
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

## Roadmap

- **v1.0** — API-stable KTXv1 release with samples
- **Future** — KTXv2 loading

## License

KTX for OpenFL is released under the [MIT license](LICENSE.md).

KTX is a trademark of The Khronos Group Inc. This library implements the publicly published format specification; it is not endorsed by or affiliated with Khronos.
