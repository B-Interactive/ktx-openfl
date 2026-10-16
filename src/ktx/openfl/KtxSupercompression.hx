package ktx.openfl;

/**
	The supercompression scheme applied to the texture data inside a KTX
	container.

	KTXv1 files are never supercompressed and always report `NONE`. The
	remaining values match the schemes registered for KTXv2, so the type is
	stable when v2 support lands.
**/
enum abstract KtxSupercompression(Int) from Int to Int
{
	/**
		No supercompression; the data is stored ready for upload.
	**/
	public var NONE = 0;

	/**
		Basis Universal (ETC1S) supercompression; reserved for KTXv2.
	**/
	public var BASISLZ = 1;

	/**
		Zstandard supercompression; reserved for KTXv2.
	**/
	public var ZSTD = 2;
}
