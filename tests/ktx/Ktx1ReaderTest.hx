package ktx;

import haxe.io.Bytes;
import openfl.errors.ArgumentError;
import openfl.errors.IllegalOperationError;
import ktx.openfl._internal.Ktx1Reader;
import ktx.openfl.KtxGPUFormat;
import openfl.utils.ByteArray;
import utest.Assert;

/**
	Tests for the internal KTXv1 parser.

	The parser is a library implementation detail; unit tests reach its
	private signature probes through `@:access`.
**/
@:access(ktx.openfl._internal.Ktx1Reader)
class Ktx1ReaderTest implements utest.ITest
{
	public function new() {}

	public function testParseDxt5()
	{
		var reader = new Ktx1Reader(KtxFixtures.build(0x83F3, 64, 64, 4));

		Assert.equals(64, reader.width);
		Assert.equals(64, reader.height);
		Assert.equals(4, reader.mipCount);
		Assert.equals(1, reader.faceCount);
		Assert.isFalse(reader.isCubeMap);
		Assert.isTrue(reader.hasAlpha);
		Assert.isTrue(reader.gpuFormat == KtxGPUFormat.DXT);
		Assert.equals("DXT5", reader.formatName);
		Assert.equals(4, reader.images.length); // one face per level
	}

	public function testLevelDimensionsHalve()
	{
		var reader = new Ktx1Reader(KtxFixtures.build(0x83F0, 64, 64, 4));

		Assert.equals(64, reader.images[0].width);
		Assert.equals(64, reader.images[0].height);
		Assert.equals(32, reader.images[1].width);
		Assert.equals(32, reader.images[1].height);
		Assert.equals(16, reader.images[2].width);
		Assert.equals(8, reader.images[3].width);
	}

	public function testNonSquareDimensions()
	{
		var reader = new Ktx1Reader(KtxFixtures.build(0x83F0, 64, 32, 3));

		Assert.equals(64, reader.width);
		Assert.equals(32, reader.height);
		Assert.equals(32, reader.images[1].width);
		Assert.equals(16, reader.images[1].height);
	}

	public function testCubemapParsesFaces()
	{
		var reader = new Ktx1Reader(KtxFixtures.build(0x83F3, 64, 64, 2, 6));

		Assert.isTrue(reader.isCubeMap);
		Assert.equals(6, reader.faceCount);
		Assert.equals(12, reader.images.length); // 2 levels * 6 faces

		// Faces are ordered 0..5 within each level.
		for (i in 0...6)
		{
			Assert.equals(i, reader.images[i].face);
			Assert.equals(0, reader.images[i].level);
		}
	}

	public function testNonSquareCubemapRejected()
	{
		var reader = KtxFixtures.build(0x83F3, 64, 32, 2, 6);
		Assert.raises(function() new Ktx1Reader(reader), ArgumentError);
	}

	public function testMipLevelZeroMeansGenerateMips()
	{
		// Regression guard: a level count of zero must parse exactly one
		// (base) level and flag mipmap generation, rather than parsing nothing.
		var reader = new Ktx1Reader(KtxFixtures.build(0x83F0, 64, 64, 0));

		Assert.isTrue(reader.generateMipmaps);
		Assert.equals(1, reader.mipCount);
		Assert.equals(1, reader.images.length);
	}

	public function testBigEndianHeaderIsAccepted()
	{
		// Regression guard: big-endian files must be parsed, not rejected.
		var reader = new Ktx1Reader(KtxFixtures.build(0x83F3, 64, 64, 4, 1, true));

		Assert.isFalse(reader.littleEndian);
		Assert.equals(64, reader.width);
		Assert.equals(64, reader.height);
		Assert.equals(4, reader.mipCount);
		Assert.isTrue(reader.hasAlpha);
		Assert.isTrue(reader.gpuFormat == KtxGPUFormat.DXT);
		Assert.equals(4, reader.images.length);
	}

	public function testBigEndianImageSizesAreSwapped()
	{
		var reader = new Ktx1Reader(KtxFixtures.build(0x8D64, 64, 64, 3, 1, true));

		// If imageSize had been misread, level and face counts would break down.
		Assert.equals(3, reader.images.length);
		for (image in reader.images)
		{
			Assert.equals(64, image.size);
		}
	}

	public function testKeyValueDataIsSkipped()
	{
		// 12 bytes of key/value data is 4 bytes of pair plus 8 bytes of padding.
		var reader = new Ktx1Reader(KtxFixtures.build(0x83F0, 64, 64, 4, 1, false, 0, 0, 0, 12));

		Assert.equals(4, reader.images.length);
	}

	public function testImageBytesAreCorrectlySized()
	{
		var reader = new Ktx1Reader(KtxFixtures.build(0x83F0, 64, 64, 2, 1, false, 0, 0, 0, 0, 0x1908, 96));

		for (image in reader.images)
		{
			Assert.equals(96, image.size);
			Assert.equals(96, image.bytes.length);
		}
	}

	public function testReadTexturesCallbackShape()
	{
		var reader = new Ktx1Reader(KtxFixtures.build(0x83F0, 64, 64, 3));

		var count = 0;
		reader.readTextures(function(face, level, gpuFormat, width, height, length, bytes)
			{
				Assert.equals(0, face);
				Assert.equals(count, level);
				Assert.isTrue(gpuFormat == KtxGPUFormat.DXT);
				Assert.equals(Std.int(Math.max(1, 64 >> count)), width);
				Assert.equals(64, length);
				Assert.notNull(bytes);
				count++;
			});

		Assert.equals(3, count);
	}

	public function testUncompressedTexturesRejected()
	{
		// glType of 1 marks uncompressed data, which this library does not load.
		var data = KtxFixtures.build(0x83F0, 64, 64, 1, 1, false, 1);
		Assert.raises(function() new Ktx1Reader(data), IllegalOperationError);
	}

	public function testThreeDRejected()
	{
		var data = KtxFixtures.build(0x83F0, 64, 64, 1, 1, false, 0, 64);
		Assert.raises(function() new Ktx1Reader(data), IllegalOperationError);
	}

	public function testArrayTexturesRejected()
	{
		var data = KtxFixtures.build(0x83F0, 64, 64, 1, 1, false, 0, 0, 4);
		Assert.raises(function() new Ktx1Reader(data), IllegalOperationError);
	}

	public function testBadFaceCountRejected()
	{
		var data = KtxFixtures.build(0x83F0, 64, 64, 1, 3);
		Assert.raises(function() new Ktx1Reader(data), ArgumentError);
	}

	public function testZeroWidthRejected()
	{
		var data = KtxFixtures.build(0x83F0, 0, 64, 1);
		Assert.raises(function() new Ktx1Reader(data), ArgumentError);
	}

	public function testUnsupportedInternalFormatRejected()
	{
		// BPTC is recognised by OpenGL but not supported by this library.
		var data = KtxFixtures.build(0x8E8C, 64, 64, 1);
		Assert.raises(function() new Ktx1Reader(data), IllegalOperationError);
	}

	public function testParseEacR11()
	{
		var reader = new Ktx1Reader(KtxFixtures.build(0x9270, 64, 64, 1));

		Assert.isTrue(reader.gpuFormat == KtxGPUFormat.ETC2);
		Assert.isFalse(reader.hasAlpha);
		Assert.equals("EAC R11", reader.formatName);
	}

	public function testParseEacRg11()
	{
		var reader = new Ktx1Reader(KtxFixtures.build(0x9272, 64, 64, 1));

		Assert.isTrue(reader.gpuFormat == KtxGPUFormat.ETC2);
		Assert.isFalse(reader.hasAlpha);
		Assert.equals("EAC RG11", reader.formatName);
	}

	public function testAstcThreeDRejected()
	{
		// Only the 2D LDR block sizes are recognised; 3D variants are not.
		var data = KtxFixtures.build(0x93C0, 64, 64, 1);
		Assert.raises(function() new Ktx1Reader(data), IllegalOperationError);
	}

	public function testParseAstc4x4()
	{
		var reader = new Ktx1Reader(KtxFixtures.build(0x93B0, 64, 64, 4));

		Assert.equals(64, reader.width);
		Assert.equals(64, reader.height);
		Assert.equals(4, reader.mipCount);
		Assert.isTrue(reader.hasAlpha);
		Assert.isTrue(reader.gpuFormat == KtxGPUFormat.ASTC);
		Assert.equals("ASTC 4x4", reader.formatName);
		Assert.equals(4, reader.images.length);
	}

	public function testParseAstc4x4Srgb()
	{
		var reader = new Ktx1Reader(KtxFixtures.build(0x93D0, 64, 64, 2));

		Assert.isTrue(reader.hasAlpha);
		Assert.isTrue(reader.gpuFormat == KtxGPUFormat.ASTC);
		// The sRGB variant shares the linear format's friendly name.
		Assert.equals("ASTC 4x4", reader.formatName);
	}

	public function testBadEndiannessRejected()
	{
		var bytes = KtxFixtures.buildBytes(0x83F0, 64, 64, 1);
		bytes.set(12, 0x99); // corrupt the endianness field
		var data = ByteArray.fromBytes(bytes);
		Assert.raises(function() new Ktx1Reader(data), ArgumentError);
	}

	public function testTruncatedHeaderRejected()
	{
		// A file shorter than the full header must fail cleanly.
		var bytes = KtxFixtures.buildBytes(0x83F0, 64, 64, 1);
		var data = ByteArray.fromBytes(bytes.sub(0, 40));
		Assert.raises(function() new Ktx1Reader(data), ArgumentError);
	}

	public function testTruncatedImageDataRejected()
	{
		// The header is valid but claims more levels than the file contains.
		var bytes = KtxFixtures.buildBytes(0x83F0, 64, 64, 4);
		var data = ByteArray.fromBytes(bytes.sub(0, bytes.length - 128));

		Assert.raises(function() new Ktx1Reader(data), ArgumentError);
	}

	public function testOversizedImageRejected()
	{
		// A level that claims more bytes than remain in the file must be rejected.
		var bytes = KtxFixtures.buildBytes(0x83F0, 64, 64, 1);
		KtxFixtures.putU32(bytes, 64, 0x7FFFFFFF, false); // imageSize at header end

		var data = ByteArray.fromBytes(bytes);
		Assert.raises(function() new Ktx1Reader(data), ArgumentError);
	}

	public function testNonKtxDataRejected()
	{
		var data = ByteArray.fromBytes(haxe.io.Bytes.ofString("NOTAKTXFILE....."));

		var message = null;

		try
		{
			new Ktx1Reader(data);
		}
		catch (e:ArgumentError)
		{
			message = e.message;
		}

		Assert.equals("Data is not a KTX file", message);
	}

	public function testKtx2RejectedBeforeParsing()
	{
		// The v2 identifier must stop the reader before any v1 header parse.
		var data = KtxFixtures.buildAsKtx2();
		var message = null;

		try
		{
			new Ktx1Reader(data);
		}
		catch (e:IllegalOperationError)
		{
			message = e.message;
		}

		Assert.equals("KTX for OpenFL: KTXv2 is not supported yet", message);
	}

	public function testShortBufferAtParseRejected()
	{
		// A buffer too short to hold the signature is not KTX; the reader
		// reports the version-agnostic message, never a v1 parse error.
		var tiny = ByteArray.fromBytes(haxe.io.Bytes.alloc(6));
		Assert.raises(function() new Ktx1Reader(tiny), ArgumentError);

		var message = null;

		try
		{
			new Ktx1Reader(tiny);
		}
		catch (e:ArgumentError)
		{
			message = e.message;
		}

		Assert.equals("Data is not a KTX file", message);
	}

	public function testNullRejected()
	{
		var message = null;

		try
		{
			new Ktx1Reader(null);
		}
		catch (e:ArgumentError)
		{
			message = e.message;
		}

		Assert.equals("KTX data must not be null", message);
	}

	public function testIsKtx1Signature()
	{
		var data = KtxFixtures.build(0x83F0, 64, 64, 1);
		Assert.isTrue(Ktx1Reader.isKtx1(data));
		Assert.isFalse(Ktx1Reader.isKtx1(ByteArray.fromBytes(haxe.io.Bytes.ofString("ATFDATA....."))));
		Assert.isFalse(Ktx1Reader.isKtx1(data, 1)); // shifted signature fails
		Assert.isFalse(Ktx1Reader.isKtx1(null));
	}

	public function testIsKtx2Signature()
	{
		// Identifier bytes distinguish KTXv2 ("20") from KTXv1 ("11").
		var bytes = KtxFixtures.buildBytes(0x83F0, 64, 64, 1);
		KtxFixtures.asKtx2Bytes(bytes);
		var data = ByteArray.fromBytes(bytes);

		Assert.isTrue(Ktx1Reader.isKtx2(data));
		Assert.isFalse(Ktx1Reader.isKtx2(KtxFixtures.build(0x83F0, 64, 64, 1)));
		Assert.isFalse(Ktx1Reader.isKtx2(null));
	}

	public function testIsKtxAcceptsBothVersions()
	{
		Assert.isTrue(Ktx1Reader.isKtx(KtxFixtures.build(0x83F0, 64, 64, 1)));
		Assert.isTrue(Ktx1Reader.isKtx(KtxFixtures.buildAsKtx2()));
		Assert.isFalse(Ktx1Reader.isKtx(ByteArray.fromBytes(haxe.io.Bytes.ofString("ATFDATA....."))));
		Assert.isFalse(Ktx1Reader.isKtx(null));
	}

	public function testDetectionAtOffset()
	{
		// Both probes classify relative to the given offset.
		var ktx = KtxFixtures.build(0x83F0, 64, 64, 1);
		var v2 = KtxFixtures.buildAsKtx2();

		Assert.isFalse(Ktx1Reader.isKtx(ktx, 1));
		Assert.isFalse(Ktx1Reader.isKtx2(v2, 1));
		Assert.isFalse(Ktx1Reader.isKtx2(ktx));
	}

	public function testIsKtx1BoundsSafe()
	{
		// Regression guard: offset + signature length must be checked against
		// the array length, never simply the raw length.
		var data = KtxFixtures.build(0x83F0, 64, 64, 1);
		var bytes = KtxFixtures.buildBytes(0x83F0, 64, 64, 1);

		Assert.isFalse(Ktx1Reader.isKtx1(data, bytes.length));
		Assert.isFalse(Ktx1Reader.isKtx1(data, 5000000));

		var tiny = ByteArray.fromBytes(haxe.io.Bytes.alloc(6));
		Assert.isFalse(Ktx1Reader.isKtx1(tiny));
		Assert.isFalse(Ktx1Reader.isKtx2(tiny));
		Assert.isFalse(Ktx1Reader.isKtx(tiny));
	}

	public function testGpuFormatFromGL()
	{
		Assert.isTrue(Ktx1Reader.gpuFormatFromGL(0x83F0) == KtxGPUFormat.DXT);
		Assert.isTrue(Ktx1Reader.gpuFormatFromGL(0x8C02) == KtxGPUFormat.PVRTC);
		Assert.isTrue(Ktx1Reader.gpuFormatFromGL(0x8D64) == KtxGPUFormat.ETC1);
		Assert.isTrue(Ktx1Reader.gpuFormatFromGL(0x9278) == KtxGPUFormat.ETC2);
		Assert.isTrue(Ktx1Reader.gpuFormatFromGL(0x9270) == KtxGPUFormat.ETC2);
		Assert.isTrue(Ktx1Reader.gpuFormatFromGL(0x9273) == KtxGPUFormat.ETC2);
		Assert.isTrue(Ktx1Reader.gpuFormatFromGL(0x93B0) == KtxGPUFormat.ASTC);
		Assert.isTrue(Ktx1Reader.gpuFormatFromGL(0x93D0) == KtxGPUFormat.ASTC);
		Assert.isNull(Ktx1Reader.gpuFormatFromGL(0x1908));
	}
}
