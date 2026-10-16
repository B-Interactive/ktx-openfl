package ktx;

import openfl.display3D.textures.CubeTexture;
import openfl.errors.IllegalOperationError;
import ktx.openfl._internal.Ktx1Reader;
import ktx.openfl.Ktx;
import utest.Assert;
import utest.ITest;

using ktx.openfl.CubeTextureKtx;

/**
	Tests for the dimensionality guards of the KTX upload API.

	These exercise the checks that run before any GL work, so they pass on
	targets without a rendering context.
**/
class KtxUploadTest implements ITest
{
	public function new() {}

	public function testCubeFixtureParsesAsCubemap()
	{
		var reader = new Ktx1Reader(KtxFixtures.buildCube());

		Assert.isTrue(reader.isCubeMap);
		Assert.equals(6, reader.faceCount);
		Assert.equals(64, reader.width);
		Assert.equals(64, reader.height);
		Assert.equals(4, reader.mipCount);
		Assert.equals(24, reader.images.length); // 4 levels * 6 faces
	}

	public function testCubeFixtureFacesAndSizes()
	{
		var reader = new Ktx1Reader(KtxFixtures.buildCube());

		// Faces cycle 0..5 within each level, and each face shrinks by the
		// block-compressed rule (a 4x4 texel block per unit).
		for (level in 0...4)
		{
			var blocks = 16 >> level;
			var faceSize = blocks * blocks * 16; // DXT5: 16 bytes per block

			for (face in 0...6)
			{
				var image = reader.images[level * 6 + face];

				Assert.equals(level, image.level);
				Assert.equals(face, image.face);
				Assert.equals(faceSize, image.size);
				Assert.equals(Std.int(Math.max(1, 64 >> level)), image.width);
				Assert.equals(Std.int(Math.max(1, 64 >> level)), image.height);
			}
		}
	}

	public function testCubeFixtureDxt1Sizes()
	{
		var reader = new Ktx1Reader(KtxFixtures.buildCube(0x83F0, 32, 2, 8));

		Assert.equals(0x83F0, reader.glInternalFormat);
		Assert.isFalse(reader.hasAlpha);
		Assert.equals(8 * 8 * 8, reader.images[0].size); // 32 / 4 = 8 blocks a side
		Assert.equals(4 * 4 * 8, reader.images[6].size); // 16 / 4 = 4 blocks a side
	}

	public function testTwoDUploadRejectsCubemapData()
	{
		var data = KtxFixtures.buildCube();

		Assert.raises(function() Ktx.uploadCompressedTextureFromByteArray(cast null, data),
			IllegalOperationError);
	}

	public function testTwoDUploadAsyncRejectsCubemapDataImmediately()
	{
		// The guard must run before the deferred upload, so the error is
		// thrown synchronously even when async is requested.
		var data = KtxFixtures.buildCube();

		Assert.raises(function() Ktx.uploadCompressedTextureFromByteArray(cast null, data, 0, true),
			IllegalOperationError);
	}

	public function testTwoDCreateRejectsCubemapData()
	{
		var data = KtxFixtures.buildCube();

		Assert.raises(function() Ktx.createTexture(cast null, data), IllegalOperationError);
	}

	public function testCubeUploadRejectsTwoDData()
	{
		var data = KtxFixtures.build(0x83F3, 64, 64, 4);

		Assert.raises(function() Ktx.uploadCompressedCubeTextureFromByteArray(cast null, data),
			IllegalOperationError);
	}

	public function testCubeCreateRejectsTwoDData()
	{
		var data = KtxFixtures.build(0x83F3, 64, 64, 4);

		Assert.raises(function() Ktx.createCubeTexture(cast null, data), IllegalOperationError);
	}

	public function testTwoDUploadGuidanceNamesCubeApi()
	{
		var data = KtxFixtures.buildCube();
		var message = null;

		try
		{
			Ktx.uploadCompressedTextureFromByteArray(cast null, data);
		}
		catch (e:IllegalOperationError)
		{
			message = e.message;
		}

		Assert.notNull(message);
		Assert.stringContains("createCubeTexture", message);
	}

	public function testCubeUploadGuidanceNamesTwoDApi()
	{
		var data = KtxFixtures.build(0x83F3, 64, 64, 4);
		var message = null;

		try
		{
			Ktx.uploadCompressedCubeTextureFromByteArray(cast null, data);
		}
		catch (e:IllegalOperationError)
		{
			message = e.message;
		}

		Assert.notNull(message);
		Assert.stringContains("not a cubemap", message);
	}

	public function testCubeExtensionRejectsTwoDData()
	{
		var data = KtxFixtures.build(0x83F3, 64, 64, 4);

		Assert.raises(function() (cast null:CubeTexture).uploadKtxFromByteArray(data, 0),
			IllegalOperationError);
	}

	public function testCreateTextureRejectsKtx2()
	{
		// Detection runs before any texture creation is attempted.
		Assert.raises(function() Ktx.createTexture(cast null, KtxFixtures.buildAsKtx2()),
			IllegalOperationError);
	}

	public function testVersionString()
	{
		Assert.equals("0.5.0", Ktx.VERSION);
	}

	public function testSupportsWithoutDataReportsFalse()
	{
		// Without a live context, only the data-side guards can be checked.
		Assert.isFalse(Ktx.supports(cast null, null));
	}
}
