package ktx.openfl;

import openfl.display3D.textures.Texture;
import openfl.utils.ByteArray;

/**
	A static extension that adds KTX upload methods to stock
	`openfl.display3D.textures.Texture` instances.

	Enable it with `using ktx.openfl.TextureKtx;`:

	```haxe
	using ktx.openfl.TextureKtx;

	var texture = context.createTexture(width, height, COMPRESSED_ALPHA, false);
	texture.uploadKtxFromByteArray(ktxBytes, 0);
	```

	This class only adds new methods; it does not, and cannot, replace the
	stock `uploadCompressedTextureFromByteArray` method, which remains
	reserved for Adobe Texture Format (ATF) data on unmodified OpenFL.
**/
class TextureKtx
{
	/**
		Uploads KTX data into an existing texture.

		@param texture   The stock texture to receive the image data.
		@param data      The ByteArray containing KTX data.
		@param offset    The position in the ByteArray at which KTX data begins.
		@param async     When true, the upload is deferred and signals completion
		                  with `Event.TEXTURE_READY`.
	**/
	public static function uploadKtxFromByteArray(texture:Texture, data:ByteArray,
			offset:UInt = 0, async:Bool = false):Void
	{
		Ktx.uploadCompressedTextureFromByteArray(texture, data, offset, async);
	}
}
