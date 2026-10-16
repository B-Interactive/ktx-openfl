package ktx;

import ktx.openfl._internal.KtxFormat;
import ktx.openfl.KtxGPUFormat;
import utest.Assert;

/**
	Tests for the KTX internal-format mapping table.
**/
class KtxFormatTest implements utest.ITest
{
	public function new() {}

	public function testDxt1Rgb()
	{
		var info = KtxFormat.describe(0x83F0);
		Assert.notNull(info);
		Assert.isTrue(info.gpuFormat == KtxGPUFormat.DXT);
		Assert.isFalse(info.hasAlpha);
	}

	public function testDxt1WithAlpha()
	{
		// DXT1 alpha is a 1-bit key colour, not a real alpha channel; the
		// format table treats it as opaque, matching OpenFL's DXT1 handling.
		var info = KtxFormat.describe(0x83F1);
		Assert.notNull(info);
		Assert.isFalse(info.hasAlpha);
	}

	public function testDxt3AndDxt5HaveAlpha()
	{
		Assert.isTrue(KtxFormat.describe(0x83F2).hasAlpha);
		Assert.isTrue(KtxFormat.describe(0x83F3).hasAlpha);
	}

	public function testPvrtcVariants()
	{
		Assert.isFalse(KtxFormat.describe(0x8C00).hasAlpha);
		Assert.isFalse(KtxFormat.describe(0x8C01).hasAlpha);
		Assert.isTrue(KtxFormat.describe(0x8C02).hasAlpha);
		Assert.isTrue(KtxFormat.describe(0x8C03).hasAlpha);
	}

	public function testEtc1()
	{
		var info = KtxFormat.describe(0x8D64);
		Assert.isTrue(info.gpuFormat == KtxGPUFormat.ETC1);
		Assert.isFalse(info.hasAlpha);
	}

	public function testEacFormats()
	{
		var expected = [
			0x9270 => "EAC R11",
			0x9271 => "EAC SIGNED R11",
			0x9272 => "EAC RG11",
			0x9273 => "EAC SIGNED RG11"
		];

		for (glFormat => name in expected)
		{
			var info = KtxFormat.describe(glFormat);
			Assert.notNull(info);
			Assert.isTrue(info.gpuFormat == KtxGPUFormat.ETC2);
			Assert.isFalse(info.hasAlpha);
			Assert.equals(name, info.name);
		}
	}

	public function testEacContext3DFormatStrings()
	{
		Assert.equals("compressed", KtxFormat.toContext3DFormatString(0x9270));
		Assert.equals("compressed", KtxFormat.toContext3DFormatString(0x9271));
		Assert.equals("compressed", KtxFormat.toContext3DFormatString(0x9272));
		Assert.equals("compressed", KtxFormat.toContext3DFormatString(0x9273));
	}

	public function testEtc2RgbDoesNotHaveAlpha()
	{
		// Regression guard: ETC2 RGB must not be flagged as an alpha format.
		var rgb = KtxFormat.describe(0x9274);
		Assert.notNull(rgb);
		Assert.isTrue(rgb.gpuFormat == KtxGPUFormat.ETC2);
		Assert.isFalse(rgb.hasAlpha);

		var srgb = KtxFormat.describe(0x9275);
		Assert.isFalse(srgb.hasAlpha);
	}

	public function testEtc2RgbaHasAlpha()
	{
		Assert.isTrue(KtxFormat.describe(0x9278).hasAlpha);
		Assert.isTrue(KtxFormat.describe(0x9279).hasAlpha);
	}

	public function testEtc2PunchThroughHasAlpha()
	{
		Assert.isTrue(KtxFormat.describe(0x9276).hasAlpha);
		Assert.isTrue(KtxFormat.describe(0x9277).hasAlpha);
	}

	public function testAstcLinearBlockSizes()
	{
		var expected = [
			0x93B0 => "ASTC 4x4",
			0x93B1 => "ASTC 5x4",
			0x93B2 => "ASTC 5x5",
			0x93B3 => "ASTC 6x5",
			0x93B4 => "ASTC 6x6",
			0x93B5 => "ASTC 8x5",
			0x93B6 => "ASTC 8x6",
			0x93B7 => "ASTC 8x8",
			0x93B8 => "ASTC 10x5",
			0x93B9 => "ASTC 10x6",
			0x93BA => "ASTC 10x8",
			0x93BB => "ASTC 10x10",
			0x93BC => "ASTC 12x10",
			0x93BD => "ASTC 12x12"
		];

		for (glFormat => name in expected)
		{
			var info = KtxFormat.describe(glFormat);
			Assert.notNull(info);
			Assert.isTrue(info.gpuFormat == KtxGPUFormat.ASTC);
			Assert.isTrue(info.hasAlpha);
			Assert.equals(name, info.name);
		}
	}

	public function testAstcSrgbMatchesLinearNames()
	{
		// The sRGB block sizes run parallel to the linear ones, from 0x93D0 up.
		for (i in 0...14)
		{
			var linear = KtxFormat.describe(0x93B0 + i);
			var srgb = KtxFormat.describe(0x93D0 + i);

			Assert.notNull(srgb);
			Assert.isTrue(srgb.gpuFormat == KtxGPUFormat.ASTC);
			Assert.isTrue(srgb.hasAlpha);
			Assert.equals(linear.name, srgb.name);
		}
	}

	public function testAstcContext3DFormatStrings()
	{
		Assert.equals("compressedAlpha", KtxFormat.toContext3DFormatString(0x93B0));
		Assert.equals("compressedAlpha", KtxFormat.toContext3DFormatString(0x93D0));
	}

	public function testUnsupportedFormatsReturnNull()
	{
		Assert.isNull(KtxFormat.describe(0x8E8C)); // BPTC RGBA
		Assert.isNull(KtxFormat.describe(0x93C0)); // ASTC 3D 3x3x3
		Assert.isNull(KtxFormat.describe(0x93E0)); // ASTC 3D 3x3x3 sRGB
		Assert.isNull(KtxFormat.describe(0));
		Assert.isNull(KtxFormat.describe(0x1908)); // GL_RGBA, uncompressed
	}

	public function testContext3DFormatStrings()
	{
		Assert.equals("compressed", KtxFormat.toContext3DFormatString(0x83F0));
		Assert.equals("compressedAlpha", KtxFormat.toContext3DFormatString(0x83F3));
		Assert.equals("compressed", KtxFormat.toContext3DFormatString(0x9274));
		Assert.equals("compressedAlpha", KtxFormat.toContext3DFormatString(0x9278));
		Assert.isNull(KtxFormat.toContext3DFormatString(0x1908));
	}
}
