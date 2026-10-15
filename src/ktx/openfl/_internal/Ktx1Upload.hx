package ktx.openfl._internal;

#if !(flash || air)

import haxe.Timer;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.textures.CubeTexture;
import openfl.display3D.textures.Texture;
import openfl.errors.ArgumentError;
import openfl.errors.IllegalOperationError;
import openfl.events.Event;
import ktx.openfl.Ktx1Reader;
import ktx.openfl.KtxCompressedFormats;
import openfl.utils._internal.UInt8Array;

/**
	Uploads parsed KTXv1 image data into stock OpenFL textures.

	This is an implementation detail of the `ktx.openfl` public API; it uses
	`@:access` to drive the same OpenGL calls that OpenFL's own ATF upload path
	uses, without modifying any OpenFL class.
**/
@:access(openfl.display3D.textures.Texture)
@:access(openfl.display3D.textures.CubeTexture)
@:access(openfl.display3D.textures.TextureBase)
@:access(openfl.display3D.Context3D)
class Ktx1Upload
{
	/**
		Creates a stock texture sized and formatted from the KTXv1 header, then
		uploads its image data.

		Cubemap data must go through `createCubeTexture` instead.

		@param context                     The rendering context to create the texture on.
		@param reader                       A parsed KTXv1 reader.
		@param optimizeForRenderToTexture   Whether the texture may be used as a render target.
		@param streamingLevels              The number of streaming mipmap levels.
		@return                             A stock texture populated with the KTXv1 data.
	**/
	public static function createTexture(context:Context3D, reader:Ktx1Reader,
			optimizeForRenderToTexture:Bool = false, streamingLevels:Int = 0, async:Bool = false):Texture
	{
		if (reader.isCubeMap)
		{
			throw new IllegalOperationError(CUBEMAP_UPLOAD_MESSAGE);
		}

		var format = reader.hasAlpha ? Context3DTextureFormat.COMPRESSED_ALPHA : Context3DTextureFormat.COMPRESSED;

		var texture = context.createTexture(reader.width, reader.height, format, optimizeForRenderToTexture,
			streamingLevels);

		uploadAsync(texture, reader, async);
		return texture;
	}

	/**
		Uploads KTXv1 image data into an existing stock texture, in the same way
		that OpenFL uploads compressed ATF data.

		The texture dimensions must match the KTXv1 base level. The texture's
		internal GL format state is updated to the compressed format actually
		uploaded, mirroring OpenFL's ATF behaviour.

		@param texture  The stock texture to receive the image data.
		@param reader   A parsed KTXv1 reader.
	**/
	public static function upload(texture:Texture, reader:Ktx1Reader):Void
	{
		if (reader.isCubeMap)
		{
			throw new IllegalOperationError(CUBEMAP_UPLOAD_MESSAGE);
		}

		if (reader.width != texture.__width || reader.height != texture.__height)
		{
			throw new ArgumentError('Texture Size Does Not Match: KTXv1 base level is '
				+ reader.width + 'x' + reader.height + ' but the texture is '
				+ texture.__width + 'x' + texture.__height);
		}

		var context = texture.__context;
		var gl = context.gl;

		var format = KtxCompressedFormats.resolve(context, reader.glInternalFormat);

		context.__bindGLTexture2D(texture.__textureID);

		texture.__format = format;
		texture.__internalFormat = format;

		reader.readTextures(function(face, level, gpuFormat, width, height, dataLength, bytes)
			{
				gl.compressedTexImage2D(texture.__textureTarget, level, format, width, height, 0,
					UInt8Array.fromBytes(bytes));
			});

		context.__bindGLTexture2D(null);
	}

	/**
		Uploads KTXv1 image data into an existing stock texture, optionally
		asynchronously, dispatching `Event.TEXTURE_READY` on completion.

		Cubemap data is rejected immediately, even when `async` is true.

		@param texture         The stock texture to receive the image data.
		@param reader          A parsed KTXv1 reader.
		@param async           When true, the upload is deferred to the next tick.
	**/
	public static function uploadAsync(texture:Texture, reader:Ktx1Reader, async:Bool):Void
	{
		if (reader.isCubeMap)
		{
			throw new IllegalOperationError(CUBEMAP_UPLOAD_MESSAGE);
		}

		if (!async)
		{
			upload(texture, reader);
			return;
		}

		Timer.delay(function()
			{
				upload(texture, reader);

				var event = new Event(Event.TEXTURE_READY);
				texture.dispatchEvent(event);
			}, 1);
	}

	/**
		Creates a stock cube texture sized and formatted from the KTXv1 header,
		then uploads its image data.

		Two-dimensional data must go through `createTexture` instead.

		@param context                     The rendering context to create the texture on.
		@param reader                       A parsed KTXv1 reader holding a cubemap.
		@param optimizeForRenderToTexture   Whether the texture may be used as a render target.
		@param streamingLevels              The number of streaming mipmap levels.
		@return                              A stock cube texture populated with the KTXv1 data.
	**/
	public static function createCubeTexture(context:Context3D, reader:Ktx1Reader,
			optimizeForRenderToTexture:Bool = false, streamingLevels:Int = 0, async:Bool = false):CubeTexture
	{
		if (!reader.isCubeMap)
		{
			throw new IllegalOperationError(NOT_CUBEMAP_MESSAGE);
		}

		var format = reader.hasAlpha ? Context3DTextureFormat.COMPRESSED_ALPHA : Context3DTextureFormat.COMPRESSED;

		var texture = context.createCubeTexture(reader.width, format, optimizeForRenderToTexture,
			streamingLevels);

		uploadCubeAsync(texture, reader, async);
		return texture;
	}

	/**
		Uploads KTXv1 cubemap data into an existing stock cube texture, in the
		same way that OpenFL uploads compressed ATF cube data.

		The cube edge length must match the KTXv1 base level. The texture's
		internal GL format state is updated to the compressed format actually
		uploaded. Face indices 0 to 5 map to positive X, negative X, positive Y,
		negative Y, positive Z and negative Z, matching both the KTXv1 store
		order and OpenFL's own side-to-target mapping.

		@param texture  The stock cube texture to receive the image data.
		@param reader   A parsed KTXv1 reader holding a cubemap.
	**/
	public static function uploadCube(texture:CubeTexture, reader:Ktx1Reader):Void
	{
		if (!reader.isCubeMap)
		{
			throw new IllegalOperationError(NOT_CUBEMAP_MESSAGE);
		}

		if (reader.width != texture.__size || reader.height != texture.__size)
		{
			throw new ArgumentError('Texture Size Does Not Match: KTXv1 base level is '
				+ reader.width + 'x' + reader.height + ' but the cube texture edge is '
				+ texture.__size);
		}

		var context = texture.__context;
		var gl = context.gl;

		var format = KtxCompressedFormats.resolve(context, reader.glInternalFormat);

		context.__bindGLTextureCubeMap(texture.__textureID);

		texture.__format = format;
		texture.__internalFormat = format;

		reader.readTextures(function(face, level, gpuFormat, width, height, dataLength, bytes)
			{
				var target = texture.__sideToTarget(face);

				gl.compressedTexImage2D(target, level, format, width, height, 0,
					UInt8Array.fromBytes(bytes));
			});

		context.__bindGLTextureCubeMap(null);
	}

	/**
		Uploads KTXv1 cubemap data into an existing stock cube texture, optionally
		asynchronously, dispatching `Event.TEXTURE_READY` on completion.

		Two-dimensional data is rejected immediately, even when `async` is true.

		@param texture  The stock cube texture to receive the image data.
		@param reader   A parsed KTXv1 reader holding a cubemap.
		@param async    When true, the upload is deferred to the next tick.
	**/
	public static function uploadCubeAsync(texture:CubeTexture, reader:Ktx1Reader, async:Bool):Void
	{
		if (!reader.isCubeMap)
		{
			throw new IllegalOperationError(NOT_CUBEMAP_MESSAGE);
		}

		if (!async)
		{
			uploadCube(texture, reader);
			return;
		}

		Timer.delay(function()
			{
				uploadCube(texture, reader);

				var event = new Event(Event.TEXTURE_READY);
				texture.dispatchEvent(event);
			}, 1);
	}

	private static inline var CUBEMAP_UPLOAD_MESSAGE = "KTX for OpenFL: cubemap data requires CubeTexture upload; "
		+ "use Ktx.createCubeTexture or Ktx.uploadCompressedCubeTextureFromByteArray";

	private static inline var NOT_CUBEMAP_MESSAGE = "KTX for OpenFL: KTX data is a 2D texture, not a cubemap; "
		+ "use Ktx.createTexture or Ktx.uploadCompressedTextureFromByteArray";
}

#else

import openfl.display3D.Context3D;
import openfl.display3D.textures.CubeTexture;
import openfl.display3D.textures.Texture;
import openfl.errors.IllegalOperationError;
import ktx.openfl.Ktx1Reader;

/**
	Flash and AIR targets cannot upload Khronos Texture (KTX) data, because the
	native runtime accepts only Adobe Texture Format (ATF) through the
	Stage3D compressed-texture API. Parsing KTX metadata remains possible;
	uploading does not.
**/
class Ktx1Upload
{
	public static function createTexture(context:Context3D, reader:Ktx1Reader,
			optimizeForRenderToTexture:Bool = false, streamingLevels:Int = 0, async:Bool = false):Texture
	{
		throw new IllegalOperationError(UNSUPPORTED_MESSAGE);
	}

	public static function upload(texture:Texture, reader:Ktx1Reader):Void
	{
		throw new IllegalOperationError(UNSUPPORTED_MESSAGE);
	}

	public static function uploadAsync(texture:Texture, reader:Ktx1Reader, async:Bool):Void
	{
		throw new IllegalOperationError(UNSUPPORTED_MESSAGE);
	}

	public static function createCubeTexture(context:Context3D, reader:Ktx1Reader,
			optimizeForRenderToTexture:Bool = false, streamingLevels:Int = 0, async:Bool = false):CubeTexture
	{
		throw new IllegalOperationError(UNSUPPORTED_MESSAGE);
	}

	public static function uploadCube(texture:CubeTexture, reader:Ktx1Reader):Void
	{
		throw new IllegalOperationError(UNSUPPORTED_MESSAGE);
	}

	public static function uploadCubeAsync(texture:CubeTexture, reader:Ktx1Reader, async:Bool):Void
	{
		throw new IllegalOperationError(UNSUPPORTED_MESSAGE);
	}

	private static inline var UNSUPPORTED_MESSAGE = "KTX for OpenFL: KTX texture upload is not supported on Flash or AIR targets; use Adobe Texture Format (ATF) instead";
}

#end
