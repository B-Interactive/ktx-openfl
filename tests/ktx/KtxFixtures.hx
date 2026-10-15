package ktx;

import haxe.io.Bytes;
import ktx.openfl._internal.KtxGL;
import openfl.utils.ByteArray;

/**
	Builds small, synthetic KTXv1 files in memory for unit testing.

	The image payload content is arbitrary filler; only the header and the
	level sizes are meaningful to the parser.
**/
class KtxFixtures
{
	/**
		Builds a ByteArray containing a valid KTXv1 compressed texture.

		@param glInternalFormat The OpenGL internal format value to store.
		@param width            The base level width.
		@param height           The base level height.
		@param mipLevels        The number of mipmap levels to write (0 writes a
		                         header that means "generate mips").
		@param faces            The number of faces (1 for 2D, 6 for cubemap).
		@param bigEndian        When true, the header fields and image sizes are
		                         written in big-endian order.
		@param glType           The glType field (non-zero marks uncompressed data).
		@param depth            The pixelDepth field.
		@param arrayElements    The numberOfArrayElements field.
		@param keyValueBytes    Extra key/value bytes to write between the header
		                         and the image data.
		@param baseFormat       The glBaseInternalFormat value.
		@param faceSize         The pixel data size, in bytes, for one face of one level.
	**/
	public static function build(glInternalFormat:Int, width:Int = 64, height:Int = 64, mipLevels:Int = 4,
			faces:Int = 1, bigEndian:Bool = false, glType:Int = 0, depth:Int = 0, arrayElements:Int = 0,
			keyValueBytes:Int = 0, baseFormat:Int = 0x1908, faceSize:Int = 64):ByteArray
	{
		return ByteArray.fromBytes(buildBytes(glInternalFormat, width, height, mipLevels, faces, bigEndian,
			glType, depth, arrayElements, keyValueBytes, baseFormat, faceSize));
	}

	/**
		Builds the same data as `build()`, but returns raw Bytes.

		Tests that need to corrupt a file should mutate these bytes before
		converting them with `ByteArray.fromBytes()`, because the conversion may
		copy on some targets.
	**/
	public static function buildBytes(glInternalFormat:Int, width:Int = 64, height:Int = 64, mipLevels:Int = 4,
			faces:Int = 1, bigEndian:Bool = false, glType:Int = 0, depth:Int = 0, arrayElements:Int = 0,
			keyValueBytes:Int = 0, baseFormat:Int = 0x1908, faceSize:Int = 64):Bytes
	{
		var imageSize = faceSize * faces;

		// Header (12-byte signature + 13 u32 fields), key/value data, then levels.
		var dataStart = KtxGL.KTX_HEADER_SIZE + keyValueBytes;
		var levelBytes = 4 + imageSize + ((4 - (imageSize % 4)) % 4);
		var totalSize = dataStart + levelBytes * Std.int(Math.max(1, mipLevels));

		var bytes = Bytes.alloc(totalSize);

		// Signature.
		var signature = KtxGL.KTX1_SIGNATURE;
		for (i in 0...12)
		{
			bytes.set(i, signature[i]);
		}

		putU32(bytes, 12, KtxGL.KTX_ENDIAN_REF, bigEndian);
		putU32(bytes, 16, glType, bigEndian);
		putU32(bytes, 20, 1, bigEndian); // glTypeSize
		putU32(bytes, 24, glType == 0 ? 0 : 1, bigEndian); // glFormat
		putU32(bytes, 28, glInternalFormat, bigEndian);
		putU32(bytes, 32, baseFormat, bigEndian);
		putU32(bytes, 36, width, bigEndian);
		putU32(bytes, 40, height, bigEndian);
		putU32(bytes, 44, depth, bigEndian);
		putU32(bytes, 48, arrayElements, bigEndian);
		putU32(bytes, 52, faces, bigEndian);
		putU32(bytes, 56, mipLevels, bigEndian);
		putU32(bytes, 60, keyValueBytes, bigEndian);

		var position = dataStart;
		var levelCount = Std.int(Math.max(1, mipLevels));

		for (level in 0...levelCount)
		{
			putU32(bytes, position, imageSize, bigEndian);
			position += 4;

			for (i in 0...imageSize)
			{
				bytes.set(position + i, (level * 7 + i) & 0xFF);
			}

			position += imageSize + ((4 - (imageSize % 4)) % 4);
		}

		return bytes;
	}

	/**
		Converts a KTXv1 byte buffer into a KTXv2 file identifier by rewriting
		the two version bytes (5 and 6) of the signature.

		Only the identifier changes; the remainder is left as-is, which is
		enough to exercise detection and rejection paths.
	**/
	public static function asKtx2Bytes(bytes:Bytes):Bytes
	{
		bytes.set(5, 0x32); // '2'
		bytes.set(6, 0x30); // '0'
		return bytes;
	}

	/**
		Builds a ByteArray carrying the KTXv2 file identifier.
	**/
	public static function buildAsKtx2(glInternalFormat:Int = 0x83F0, width:Int = 64, height:Int = 64,
			mipLevels:Int = 1):ByteArray
	{
		return ByteArray.fromBytes(asKtx2Bytes(buildBytes(glInternalFormat, width, height, mipLevels)));
	}

	/**
		Builds a ByteArray containing a valid KTXv1 cubemap with realistic
		block-compressed face sizes.

		Face payloads shrink correctly with each mip level, following the
		`ceil(dimension / 4)` block-count rule of DXT/ETC-style formats.
	**/
	public static function buildCube(glInternalFormat:Int = 0x83F3, size:Int = 64, mipLevels:Int = 4,
			blockBytes:Int = 16, bigEndian:Bool = false):ByteArray
	{
		return ByteArray.fromBytes(buildCubeBytes(glInternalFormat, size, mipLevels, blockBytes, bigEndian));
	}

	/**
		Builds the same cubemap data as `buildCube()`, but returns raw Bytes.
	**/
	public static function buildCubeBytes(glInternalFormat:Int = 0x83F3, size:Int = 64, mipLevels:Int = 4,
			blockBytes:Int = 16, bigEndian:Bool = false):Bytes
	{
		var levelCount = Std.int(Math.max(1, mipLevels));
		var imageSizes = [];
		var totalSize = KtxGL.KTX_HEADER_SIZE;

		for (level in 0...levelCount)
		{
			var levelSize = Std.int(Math.max(1, size >> level));

			// One block covers 4x4 texels; the smallest level is still one block.
			var blocks = Std.int(Math.max(1, (levelSize + 3) >> 2));
			var faceSize = blocks * blocks * blockBytes;
			var imageSize = faceSize * 6;

			imageSizes.push(imageSize);
			totalSize += 4 + imageSize + ((4 - (imageSize % 4)) % 4);
		}

		var bytes = Bytes.alloc(totalSize);

		// Signature.
		var signature = KtxGL.KTX1_SIGNATURE;
		for (i in 0...12)
		{
			bytes.set(i, signature[i]);
		}

		putU32(bytes, 12, KtxGL.KTX_ENDIAN_REF, bigEndian);
		putU32(bytes, 16, 0, bigEndian); // glType
		putU32(bytes, 20, 1, bigEndian); // glTypeSize
		putU32(bytes, 24, 0, bigEndian); // glFormat
		putU32(bytes, 28, glInternalFormat, bigEndian);
		putU32(bytes, 32, 0x1908, bigEndian); // glBaseInternalFormat
		putU32(bytes, 36, size, bigEndian);
		putU32(bytes, 40, size, bigEndian);
		putU32(bytes, 44, 0, bigEndian); // depth
		putU32(bytes, 48, 0, bigEndian); // arrayElements
		putU32(bytes, 52, 6, bigEndian); // numberOfFaces
		putU32(bytes, 56, mipLevels, bigEndian);
		putU32(bytes, 60, 0, bigEndian); // keyValueBytes

		var position = KtxGL.KTX_HEADER_SIZE;

		for (level in 0...levelCount)
		{
			var imageSize = imageSizes[level];

			putU32(bytes, position, imageSize, bigEndian);
			position += 4;

			for (i in 0...imageSize)
			{
				bytes.set(position + i, (level * 7 + i) & 0xFF);
			}

			position += imageSize + ((4 - (imageSize % 4)) % 4);
		}

		return bytes;
	}

	/**
		Writes a 32-bit value into the byte buffer, honouring the requested
		byte order.
	**/
	public static function putU32(bytes:Bytes, pos:Int, value:Int, bigEndian:Bool):Void
	{
		var b0 = value & 0xFF;
		var b1 = (value >> 8) & 0xFF;
		var b2 = (value >> 16) & 0xFF;
		var b3 = (value >>> 24) & 0xFF;

		if (bigEndian)
		{
			bytes.set(pos, b3);
			bytes.set(pos + 1, b2);
			bytes.set(pos + 2, b1);
			bytes.set(pos + 3, b0);
		}
		else
		{
			bytes.set(pos, b0);
			bytes.set(pos + 1, b1);
			bytes.set(pos + 2, b2);
			bytes.set(pos + 3, b3);
		}
	}
}
