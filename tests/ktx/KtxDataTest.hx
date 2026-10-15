package ktx;

import openfl.errors.ArgumentError;
import openfl.errors.IllegalOperationError;
import ktx.openfl.Ktx;
import ktx.openfl.KtxData;
import ktx.openfl.KtxGPUFormat;
import openfl.utils.ByteArray;
import utest.Assert;

/**
	Tests for the KtxData metadata wrapper and the Ktx façade parsing
	entry points. (These do not require a rendering context.)
**/
class KtxDataTest implements utest.ITest
{
	public function new() {}

	public function testMetadataForDxt5()
	{
		var data = KtxFixtures.build(0x83F3, 64, 64, 4);
		var ktx = new KtxData(data);

		Assert.equals(64, ktx.width);
		Assert.equals(64, ktx.height);
		Assert.equals(4, ktx.numTextures);
		Assert.equals(1, ktx.faceCount);
		Assert.isFalse(ktx.isCubeMap);
		Assert.isTrue(ktx.hasAlpha);
		Assert.equals("compressedAlpha", ktx.format);
		Assert.isTrue(ktx.gpuFormat == KtxGPUFormat.DXT);
		Assert.equals(0x83F3, ktx.glInternalFormat);
		Assert.equals("DXT5", ktx.formatName);
	}

	public function testMetadataForEtc2RgbIsOpaque()
	{
		var data = KtxFixtures.build(0x9274, 64, 64, 1);
		var ktx = new KtxData(data);

		// Regression guard: ETC2 RGB is not an alpha format.
		Assert.isFalse(ktx.hasAlpha);
		Assert.equals("compressed", ktx.format);
	}

	public function testMetadataForEacR11IsOpaque()
	{
		var data = KtxFixtures.build(0x9270, 64, 64, 1);
		var ktx = new KtxData(data);

		Assert.isFalse(ktx.hasAlpha);
		Assert.equals("compressed", ktx.format);
		Assert.isTrue(ktx.gpuFormat == KtxGPUFormat.ETC2);
		Assert.equals("EAC R11", ktx.formatName);
	}

	public function testMetadataForAstc4x4()
	{
		var data = KtxFixtures.build(0x93B0, 64, 64, 4);
		var ktx = new KtxData(data);

		Assert.isTrue(ktx.hasAlpha);
		Assert.equals("compressedAlpha", ktx.format);
		Assert.isTrue(ktx.gpuFormat == KtxGPUFormat.ASTC);
		Assert.equals(0x93B0, ktx.glInternalFormat);
		Assert.equals("ASTC 4x4", ktx.formatName);
	}

	public function testMetadataForCubemap()
	{
		var data = KtxFixtures.build(0x8D64, 64, 64, 3, 6);
		var ktx = new KtxData(data);

		Assert.isTrue(ktx.isCubeMap);
		Assert.equals(6, ktx.faceCount);
	}

	public function testDataIsRetained()
	{
		var data = KtxFixtures.build(0x83F0, 64, 64, 1);
		var ktx = new KtxData(data);

		// The original ByteArray reference is kept for re-upload after a context loss.
		Assert.isTrue(data == ktx.data);
		Assert.equals(0, ktx.byteArrayOffset);
	}

	public function testOffsetAwareParsing()
	{
		// KTX data can live inside a larger buffer (for example, an asset bundle).
		var ktx = KtxFixtures.build(0x83F0, 64, 64, 1);
		var bytes = haxe.io.Bytes.alloc(10 + ktx.length);

		for (i in 0...ktx.length)
		{
			bytes.set(10 + i, ktx[i]);
		}

		var wrapped = ByteArray.fromBytes(bytes);
		Assert.isTrue(KtxData.isKtxData(wrapped, 10));
		Assert.isFalse(KtxData.isKtxData(wrapped));

		var info = new KtxData(wrapped, 10);
		Assert.equals(64, info.width);
		Assert.equals(10, info.byteArrayOffset);
	}

	public function testIsKtxDataDetection()
	{
		// isKtxData accepts any KTX magic, v1 or v2.
		Assert.isTrue(KtxData.isKtxData(KtxFixtures.build(0x83F0, 64, 64, 1)));
		Assert.isTrue(KtxData.isKtxData(KtxFixtures.buildAsKtx2()));
		Assert.isFalse(KtxData.isKtxData(ByteArray.fromBytes(haxe.io.Bytes.ofString("ATF!......"))));
		Assert.isFalse(KtxData.isKtxData(null));
	}

	public function testConstructRejectsKtx2()
	{
		// Detection is broader than loading: v2 is recognised but never parsed.
		var data = KtxFixtures.buildAsKtx2();
		Assert.isTrue(KtxData.isKtxData(data));

		var message = null;

		try
		{
			new KtxData(data);
		}
		catch (e:IllegalOperationError)
		{
			message = e.message;
		}

		Assert.equals("KTX for OpenFL: KTXv2 is not supported yet", message);
	}

	public function testConstructRejectsNonKtx()
	{
		var data = ByteArray.fromBytes(haxe.io.Bytes.ofString("NOTAKTXFILE....."));
		Assert.raises(function() new KtxData(data), ArgumentError);
	}

	public function testFacadeProbeMatrix()
	{
		var v1 = KtxFixtures.build(0x83F0, 64, 64, 1);
		var v2 = KtxFixtures.buildAsKtx2();
		var atf = ByteArray.fromBytes(haxe.io.Bytes.ofString("ATFDATA....."));

		Assert.isTrue(Ktx.isKtx(v1));
		Assert.isTrue(Ktx.isKtx1(v1));
		Assert.isFalse(Ktx.isKtx2(v1));

		Assert.isTrue(Ktx.isKtx(v2));
		Assert.isFalse(Ktx.isKtx1(v2));
		Assert.isTrue(Ktx.isKtx2(v2));

		Assert.isFalse(Ktx.isKtx(atf));
		Assert.isFalse(Ktx.isKtx1(atf));
		Assert.isFalse(Ktx.isKtx2(atf));

		Assert.isFalse(Ktx.isKtx(null));
		Assert.isFalse(Ktx.isKtx1(null));
		Assert.isFalse(Ktx.isKtx2(null));
	}

	public function testFacadeReadData()
	{
		var data = KtxFixtures.build(0x8C02, 64, 64, 2);
		Assert.isTrue(Ktx.isKtx1(data));

		var reader = Ktx.readData(data);
		Assert.isTrue(reader.gpuFormat == KtxGPUFormat.PVRTC);
		Assert.isTrue(reader.hasAlpha);
	}

	public function testFacadeReadDataRejectsKtx2()
	{
		Assert.raises(function() Ktx.readData(KtxFixtures.buildAsKtx2()), IllegalOperationError);
	}

	public function testFacadeReadDataRejectsNonKtx()
	{
		var data = ByteArray.fromBytes(haxe.io.Bytes.ofString("NOTAKTXFILE....."));
		Assert.raises(function() Ktx.readData(data), ArgumentError);
	}
}
