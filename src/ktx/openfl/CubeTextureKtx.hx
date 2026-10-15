package ktx.openfl;

import openfl.display3D.textures.CubeTexture;
import openfl.utils.ByteArray;

/**
	A static extension that adds KTX upload methods to stock
	`openfl.display3D.textures.CubeTexture` instances.

	Enable it with `using ktx.openfl.CubeTextureKtx;`:

	```haxe
	using ktx.openfl.CubeTextureKtx;

	var cube = context.createCubeTexture(256, COMPRESSED_ALPHA, false);
	cube.uploadKtxFromByteArray(ktxBytes, 0);
	```

	This class only adds new methods; it does not, and cannot, replace the
	stock `uploadCompressedTextureFromByteArray` method, which remains
	reserved for Adobe Texture Format (ATF) data on unmodified OpenFL.
**/
class CubeTextureKtx
{
	/**
		Uploads KTX cubemap data into an existing cube texture.

		@param texture   The stock cube texture to receive the image data.
		@param data      The ByteArray containing KTX cubemap data.
		@param offset    The position in the ByteArray at which KTX data begins.
		@param async     When true, the upload is deferred and signals completion
		                  with `Event.TEXTURE_READY`.
	**/
	public static function uploadKtxFromByteArray(texture:CubeTexture, data:ByteArray,
			offset:UInt = 0, async:Bool = false):Void
	{
		Ktx.uploadCompressedCubeTextureFromByteArray(texture, data, offset, async);
	}
}
