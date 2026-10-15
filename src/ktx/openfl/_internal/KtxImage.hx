package ktx.openfl._internal;

import haxe.io.Bytes;

/**
	A single image for one mipmap level and face within a KTXv1 file.
**/
class KtxImage
{
	/**
		The mipmap level index (0 is the base level).
	**/
	public var level:Int;

	/**
		The cubemap face index (0 for 2D textures, 0 to 5 for cubemaps).
	**/
	public var face:Int;

	/**
		The width of this level, in texels.
	**/
	public var width:Int;

	/**
		The height of this level, in texels.
	**/
	public var height:Int;

	/**
		The size of the pixel data, in bytes.
	**/
	public var size:Int;

	/**
		The pixel data for this level and face.
	**/
	public var bytes:Bytes;

	/**
		Creates an image record.

		@param level  The mipmap level index.
		@param face   The face index.
		@param width  The level width, in texels.
		@param height The level height, in texels.
		@param size   The size of the pixel data, in bytes.
		@param bytes  The pixel data.
	**/
	public function new(level:Int, face:Int, width:Int, height:Int, size:Int, bytes:Bytes)
	{
		this.level = level;
		this.face = face;
		this.width = width;
		this.height = height;
		this.size = size;
		this.bytes = bytes;
	}
}
