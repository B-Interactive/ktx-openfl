import utest.ITest;
import utest.UTest;

/**
	The unit test entry point for KTX for OpenFL.

	The core suites run on every target. The Starling bridge suites are compiled
	and run only when the Starling library is available, so the core test build
	does not depend on it.
**/
class TestMain
{
	public static function main():Void
	{
		var cases:Array<ITest> = [
			new ktx.Ktx1ReaderTest(),
			new ktx.KtxFormatTest(),
			new ktx.KtxDataTest(),
			new ktx.KtxCompressedFormatsTest(),
			new ktx.KtxUploadTest()
		];

		#if starling
		cases.push(new ktx.starling.KtxTextureFactoryTest());
		#end

		UTest.run(cases);
	}
}
