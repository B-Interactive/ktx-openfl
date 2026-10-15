package ktx.starling;

import ktx.KtxFixtures;
import ktx.openfl.starling.KtxAssets;
import ktx.openfl.starling.KtxTextureFactory;
import ktx.openfl.starling.KtxTextures;
import openfl.utils.ByteArray;
import starling.assets.AssetManager;
import starling.assets.AssetReference;
import starling.core.Starling;
import utest.Assert;
import utest.ITest;

/**
	Tests for the Starling asset bridge.

	These compile only when the Starling library is present, and exercise the
	paths that need no live rendering context: reference detection, extension
	registration, and manager wiring. The full upload path is verified in the
	Starling sample, where a Stage3D context exists.
**/
class KtxTextureFactoryTest implements ITest
{
	public function new() {}

	public function testCanHandleAcceptsKtxData()
	{
		var factory = new KtxTextureFactory();
		var reference = new AssetReference(KtxFixtures.build(0x83F3, 64, 64, 1, 1, false));

		Assert.isTrue(factory.canHandle(reference));
	}

	public function testCanHandleAcceptsKtx2Data()
	{
		// KTXv2 is recognised so the factory reports it, then create() fails
		// with a clear unsupported-format error rather than silently ignoring it.
		var factory = new KtxTextureFactory();
		var reference = new AssetReference(KtxFixtures.buildAsKtx2());

		Assert.isTrue(factory.canHandle(reference));
	}

	public function testCanHandleRejectsNonKtxData()
	{
		var factory = new KtxTextureFactory();

		var atfHeader = new ByteArray();
		atfHeader.writeByte(0x41); // 'A'
		atfHeader.writeByte(0x54); // 'T'
		atfHeader.writeByte(0x46); // 'F'
		for (i in 0...60)
		{
			atfHeader.writeByte(i & 0xFF);
		}

		Assert.isFalse(factory.canHandle(new AssetReference(atfHeader)));
	}

	public function testCanHandleRejectsNullAndStrings()
	{
		var factory = new KtxTextureFactory();

		Assert.isFalse(factory.canHandle(new AssetReference(null)));
		Assert.isFalse(factory.canHandle(new AssetReference("hero.ktx")));
	}

	public function testHandlesKtxExtension()
	{
		var factory = new KtxTextureFactory();
		var extensions = factory.getExtensions();

		Assert.isTrue(extensions.indexOf("ktx") != -1);
	}

	public function testRegisterWithAssetManager()
	{
		var manager = new AssetManager();

		// Registration must not throw and must accept an explicit priority.
		KtxAssets.register(manager);
		KtxAssets.register(manager, 1);
		Assert.isTrue(true);
	}

	public function testMissingContextThrows()
	{
		// Without a running Starling instance there is no context, so texture
		// creation reports the missing context before doing anything else.
		if (Starling.current != null) return;

		var data = KtxFixtures.build(0x83F3, 64, 64, 1, 1, false);

		Assert.raises(function() KtxTextures.fromKtxData(data));
	}
}
