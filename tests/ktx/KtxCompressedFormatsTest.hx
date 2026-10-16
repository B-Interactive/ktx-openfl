package ktx;

import ktx.openfl._internal.KtxCompressedFormats;
import ktx.openfl._internal.KtxGL;
import utest.Assert;

/**
	Tests for the ASTC HDR profile probe.

	The probe is exercised through duck-typed GL and extension objects, so
	these run on every target without a rendering context. The profile
	helper's two implementations (WebGL profiles list, native extension
	object) report consistently for the cases below, so the assertions are
	shared; the wiring tests document the branch-specific behaviour where
	the two paths legitimately differ.
**/
@:access(ktx.openfl._internal.KtxCompressedFormats)
class KtxCompressedFormatsTest implements utest.ITest
{
	public function new() {}

	/**
		A GL object whose getExtension answers only the ASTC names.
	**/
	private static function makeGl(ldr:Dynamic, hdr:Dynamic, version:Dynamic):Dynamic
	{
		return {
			getExtension: function(name:String):Dynamic
			{
				return switch (name)
				{
					case "WEBGL_compressed_texture_astc", "KHR_texture_compression_astc_ldr",
						"GL_KHR_texture_compression_astc_ldr": ldr;
					case "KHR_texture_compression_astc_hdr", "GL_KHR_texture_compression_astc_hdr": hdr;
					default: null;
				}
			},
			getParameter: function(pname:Int):Dynamic return version
		};
	}

	/**
		An LDR extension object exposing the given getSupportedProfiles value.
	**/
	private static function makeLdrExtension(getSupportedProfiles:Dynamic):Dynamic
	{
		return {getSupportedProfiles: getSupportedProfiles};
	}

	public function testHdrProbeNullExtension()
	{
		Assert.isFalse(KtxCompressedFormats.detectAstcHdrProfile(makeGl(null, null, null), null));
	}

	public function testHdrProbeMissingProfilesApi()
	{
		var ldr = makeLdrExtension(null);
		Assert.isFalse(KtxCompressedFormats.detectAstcHdrProfile(makeGl(ldr, null, null), ldr));
	}

	public function testHdrProbeLdrProfilesOnly()
	{
		var ldr = makeLdrExtension(function():Dynamic return ["ldr"]);
		Assert.isFalse(KtxCompressedFormats.detectAstcHdrProfile(makeGl(ldr, null, null), ldr));
	}

	public function testHdrProbeHdrProfiles()
	{
		var ldr = makeLdrExtension(function():Dynamic return ["ldr", "hdr"]);
		Assert.isTrue(KtxCompressedFormats.detectAstcHdrProfile(makeGl(ldr, {}, null), ldr));
	}

	public function testHdrProbeThrows()
	{
		var ldr = makeLdrExtension(function():Dynamic throw "boom");
		Assert.isFalse(KtxCompressedFormats.detectAstcHdrProfile(makeGl(ldr, null, null), ldr));
	}

	public function testCoreFallbackDoesNotSetHdr()
	{
		// The OpenGL ES 3.2 core path marks the LDR formats when no extension
		// object is present, but never sets the HDR profile flag.
		KtxCompressedFormats.reset();
		KtxCompressedFormats.supported = new Map();
		KtxCompressedFormats.detectAstc(makeGl(null, null, "OpenGL ES 3.2 (Mock)"));

		#if !((js && html5))
		Assert.isTrue(KtxCompressedFormats.isSupportedFormat(KtxGL.COMPRESSED_RGBA_ASTC_4x4));
		#end
		Assert.isFalse(KtxCompressedFormats.astcHdrSupported);

		KtxCompressedFormats.reset();
	}

	public function testHdrExtensionAloneDoesNotMarkFormats()
	{
		// A bare HDR profile must not enable the block formats for upload.
		KtxCompressedFormats.reset();
		KtxCompressedFormats.supported = new Map();
		KtxCompressedFormats.detectAstc(makeGl(null, {}, "4.5.0 (Mock)"));

		Assert.isFalse(KtxCompressedFormats.isSupportedFormat(KtxGL.COMPRESSED_RGBA_ASTC_4x4));

		#if (js && html5)
		// WebGL reports HDR through the LDR extension object, which is absent.
		Assert.isFalse(KtxCompressedFormats.astcHdrSupported);
		#else
		Assert.isTrue(KtxCompressedFormats.astcHdrSupported);
		#end

		KtxCompressedFormats.reset();
	}
}
