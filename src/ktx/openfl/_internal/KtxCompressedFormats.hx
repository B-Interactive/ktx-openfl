package ktx.openfl._internal;

import openfl.display3D.Context3D;
import openfl.errors.IllegalOperationError;

#if !(flash || air)

/**
	Library-owned registry of compressed texture formats supported by the
	current GPU, used to validate KTXv1 uploads.

	This registry exists so that KTX uploads (including ETC2 and ASTC) do not
	depend on OpenFL's private ATF format tables. It never modifies those
	tables; fixing Ericsson Texture Compression 2 support for Adobe Texture
	Format (ATF) is an OpenFL concern, not one for this library.

	The detection logic mirrors OpenFL's own compressed-format probing and
	extends it with ETC2, including the WebGL2 core fallback and the OpenGL ES
	3.0 core path on native targets that the unmerged OpenFL ETC2 patch left
	as a gap. The EAC R11 and RG11 single- and two-channel formats are probed
	alongside the colour ETC2 formats and share the same support table.
	Adaptive Scalable Texture Compression is enabled by its LDR extensions or
	the OpenGL ES 3.2 core path on native targets. The ASTC HDR profile is
	probed separately and never enables block formats on its own; it is
	reported through `isAstcHdrSupported`.

	The capability table is keyed to the live rendering context and its GL
	object, so a lost or replaced context triggers a fresh probe automatically;
	stale results never outlive the GPU state that produced them. A failed
	probe is not cached either, and `reset()` can force a re-probe at any time.
**/
@:access(openfl.display3D.Context3D)
class KtxCompressedFormats
{
	private static var context:Context3D;
	private static var contextGl:Dynamic;
	private static var supported:Map<Int, Bool>;
	private static var astcHdrSupported:Bool;

	private static inline var GL_VERSION = 0x1F02;

	private static final ETC2_FORMATS = [
		KtxGL.COMPRESSED_R11_EAC,
		KtxGL.COMPRESSED_SIGNED_R11_EAC,
		KtxGL.COMPRESSED_RG11_EAC,
		KtxGL.COMPRESSED_SIGNED_RG11_EAC,
		KtxGL.COMPRESSED_RGB8_ETC2,
		KtxGL.COMPRESSED_SRGB8_ETC2,
		KtxGL.COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2,
		KtxGL.COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2,
		KtxGL.COMPRESSED_RGBA8_ETC2_EAC,
		KtxGL.COMPRESSED_SRGB8_ALPHA8_ETC2_EAC
	];

	private static final ASTC_FORMATS = [
		KtxGL.COMPRESSED_RGBA_ASTC_4x4,
		KtxGL.COMPRESSED_RGBA_ASTC_5x4,
		KtxGL.COMPRESSED_RGBA_ASTC_5x5,
		KtxGL.COMPRESSED_RGBA_ASTC_6x5,
		KtxGL.COMPRESSED_RGBA_ASTC_6x6,
		KtxGL.COMPRESSED_RGBA_ASTC_8x5,
		KtxGL.COMPRESSED_RGBA_ASTC_8x6,
		KtxGL.COMPRESSED_RGBA_ASTC_8x8,
		KtxGL.COMPRESSED_RGBA_ASTC_10x5,
		KtxGL.COMPRESSED_RGBA_ASTC_10x6,
		KtxGL.COMPRESSED_RGBA_ASTC_10x8,
		KtxGL.COMPRESSED_RGBA_ASTC_10x10,
		KtxGL.COMPRESSED_RGBA_ASTC_12x10,
		KtxGL.COMPRESSED_RGBA_ASTC_12x12,
		KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_4x4,
		KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_5x4,
		KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_5x5,
		KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_6x5,
		KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_6x6,
		KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_8x5,
		KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_8x6,
		KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_8x8,
		KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_10x5,
		KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_10x6,
		KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_10x8,
		KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_10x10,
		KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_12x10,
		KtxGL.COMPRESSED_SRGB8_ALPHA8_ASTC_12x12
	];

	/**
		Releases the cached capability probe so the next query re-detects against
		the current context. Only needed for a manual context loss that neither
		replaces the `Context3D` object nor its GL context, because the cache
		already re-probes whenever either of those changes.
	**/
	public static function reset():Void
	{
		context = null;
		contextGl = null;
		supported = null;
		astcHdrSupported = false;
	}

	/**
		Returns the OpenGL compressed format constant to upload for a given KTXv1
		internal format, throwing when the current GPU does not support it.

		KTXv1 stores raw OpenGL internal format values, and block-compressed
		formats use the same enumeration value when uploading, so the file's own
		value is returned once support is confirmed.

		@param context           The rendering context to validate against.
		@param glInternalFormat  The OpenGL internal format from the KTXv1 header.
		@return                  The OpenGL constant to pass to `compressedTexImage2D`.
	**/
	public static function resolve(context:Context3D, glInternalFormat:Int):Int
	{
		ensureContext(context);

		if (isSupportedFormat(glInternalFormat))
		{
			return glInternalFormat;
		}

		// Formats that share a GPU bucket but are stored under a different,
		// non-standard constant (for example, sRGB variants) fall back to the
		// bucket's canonical supported constant when one exists.
		var canonical = canonicalFor(glInternalFormat);

		if (canonical != glInternalFormat && isSupportedFormat(canonical))
		{
			return canonical;
		}

		throw new IllegalOperationError("KTX for OpenFL: GPU does not support GL internal format 0x"
			+ StringTools.hex(glInternalFormat, 8));
	}

	/**
		Reports whether the current GPU supports a KTXv1 internal format.

		@param context           The rendering context to validate against.
		@param glInternalFormat  The OpenGL internal format from a KTXv1 header.
	**/
	public static function isSupported(context:Context3D, glInternalFormat:Int):Bool
	{
		ensureContext(context);
		return isSupportedFormat(glInternalFormat) || isSupportedFormat(canonicalFor(glInternalFormat));
	}

	/**
		Reports whether the current GPU advertises the ASTC HDR profile.

		This result is independent of LDR support: it is true only when the
		ASTC HDR extension (native targets) or the `"hdr"` profile (WebGL) is
		present. The HDR profile alone never marks ASTC block formats as
		supported, so upload still requires `isSupported`.

		@param context  The rendering context to validate against.
	**/
	public static function isAstcHdrSupported(context:Context3D):Bool
	{
		ensureContext(context);
		return astcHdrSupported;
	}

	private static inline function isSupportedFormat(format:Int):Bool
	{
		return supported.exists(format) && supported.get(format);
	}

	private static function ensureContext(value:Context3D):Void
	{
		// The probe result is only valid for the exact context and GL object
		// that produced it; either one changing discards the cached table.
		if (supported != null && context == value && contextGl == value.gl) return;

		reset();

		var gl:Dynamic = value.gl;

		// A null GL object (a disposed or lost context) cannot be probed, so
		// nothing is cached and the next call retries with the live context.
		if (gl == null)
		{
			throw new IllegalOperationError("KTX for OpenFL: the rendering context has no usable GL object");
		}

		context = value;
		contextGl = gl;
		supported = new Map();

		// If probing fails partway through, discard the incomplete table rather
		// than caching a permanently empty capability set.
		try
		{
			probeFormats(gl);
		}
		catch (e:Dynamic)
		{
			reset();
			throw e;
		}
	}

	private static function probeFormats(gl:Dynamic):Void
	{
		// S3TC / DXT.
		#if (js && html5)
		var dxtExtension = gl.getExtension("WEBGL_compressed_texture_s3tc");
		#else
		var dxtExtension = gl.getExtension("EXT_texture_compression_s3tc");
		if (dxtExtension == null) dxtExtension = gl.getExtension("GL_EXT_texture_compression_s3tc");
		#end
		registerExtension(dxtExtension, [
			KtxGL.COMPRESSED_RGB_S3TC_DXT1_EXT,
			KtxGL.COMPRESSED_RGBA_S3TC_DXT1_EXT,
			KtxGL.COMPRESSED_RGBA_S3TC_DXT3_EXT,
			KtxGL.COMPRESSED_RGBA_S3TC_DXT5_EXT
		]);

		// ETC1.
		#if (js && html5)
		var etc1Extension = gl.getExtension("WEBGL_compressed_texture_etc1");
		#else
		var etc1Extension = gl.getExtension("OES_compressed_ETC1_RGB8_texture");
		if (etc1Extension == null) etc1Extension = gl.getExtension("GL_OES_compressed_ETC1_RGB8_texture");
		#end
		registerExtension(etc1Extension, [KtxGL.ETC1_RGB8_OES]);

		// PVRTC.
		#if (js && html5)
		var pvrtcExtension = gl.getExtension("WEBKIT_WEBGL_compressed_texture_pvrtc");
		if (pvrtcExtension == null) pvrtcExtension = gl.getExtension("EXT_texture_compression_pvrtc");
		#else
		var pvrtcExtension = gl.getExtension("IMG_texture_compression_pvrtc");
		if (pvrtcExtension == null) pvrtcExtension = gl.getExtension("GL_IMG_texture_compression_pvrtc");
		#end
		registerExtension(pvrtcExtension, [
			KtxGL.COMPRESSED_RGB_PVRTC_4BPPV1_IMG,
			KtxGL.COMPRESSED_RGB_PVRTC_2BPPV1_IMG,
			KtxGL.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG,
			KtxGL.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG
		]);

		detectEtc2(gl);

		detectAstc(gl);
	}

	private static function detectEtc2(gl:Dynamic):Void
	{
		// 1) A dedicated ETC extension object, when the driver provides one.
		#if (js && html5)
		var etc2Extension = gl.getExtension("WEBGL_compressed_texture_etc");
		if (etc2Extension == null) etc2Extension = gl.getExtension("WEBGL_compressed_texture_es3");
		#else
		var etc2Extension = gl.getExtension("EXT_texture_compression_etc2");
		if (etc2Extension == null) etc2Extension = gl.getExtension("GL_EXT_texture_compression_etc2");
		// Desktop GL gains ETC2 through the ES3 compatibility extension.
		if (etc2Extension == null) etc2Extension = gl.getExtension("GL_ARB_ES3_compatibility");
		#end

		registerExtension(etc2Extension, ETC2_FORMATS);

		if (isSupportedFormat(KtxGL.COMPRESSED_RGB8_ETC2)) return;

		#if (js && html5)
		// 2) WebGL2 exposes ETC2 as core, with the enum values available
		//    directly on the context rather than on an extension object.
		if (gl.COMPRESSED_RGB8_ETC2 == KtxGL.COMPRESSED_RGB8_ETC2)
		{
			markSupported(ETC2_FORMATS);
		}
		#else
		// 2) OpenGL ES 3.0 and newer expose ETC2 as core. ETC2 is not part of
		//    desktop OpenGL core, so the version string is the reliable probe.
		var version:String = null;

		try
		{
			version = gl.getParameter(GL_VERSION);
		}
		catch (e:Dynamic)
		{
			version = null;
		}

		if (version != null && version.indexOf("ES 3") != -1)
		{
			markSupported(ETC2_FORMATS);
		}
		#end
	}

	private static function detectAstc(gl:Dynamic):Void
	{
		// 1) A dedicated ASTC LDR extension object, when the driver provides
		//    one. LDR availability gates the block formats; the HDR profile
		//    is recorded separately by the probe below.
		#if (js && html5)
		var astcExtension = gl.getExtension("WEBGL_compressed_texture_astc");
		#else
		var astcExtension = gl.getExtension("KHR_texture_compression_astc_ldr");
		if (astcExtension == null) astcExtension = gl.getExtension("GL_KHR_texture_compression_astc_ldr");
		#end

		registerExtension(astcExtension, ASTC_FORMATS);

		// The HDR profile is probed even when the LDR extension is missing,
		// because some drivers advertise HDR without exposing it as loadable
		// through this library's LDR-only policy.
		astcHdrSupported = detectAstcHdrProfile(gl, astcExtension);

		if (isSupportedFormat(KtxGL.COMPRESSED_RGBA_ASTC_4x4)) return;

		#if !((js && html5))
		// 2) OpenGL ES 3.2 and newer expose the ASTC 2D LDR formats as core.
		//    Desktop GL and WebGL1 do not, so only native targets parse the
		//    version string as a fallback. The core path marks LDR formats
		//    only; it does not set the HDR profile flag.
		var version:String = null;

		try
		{
			version = gl.getParameter(GL_VERSION);
		}
		catch (e:Dynamic)
		{
			version = null;
		}

		if (isOpenGLESAtLeast(version, 3, 2))
		{
			markSupported(ASTC_FORMATS);
		}
		#end
	}

	/**
		Probes the ASTC HDR profile, independent of the LDR block formats.

		On WebGL the already-fetched LDR extension object is reused and its
		`getSupportedProfiles` list is checked for `"hdr"`; an absent object,
		missing API or thrown call all report false. On native targets the
		HDR extension itself is queried through `getExtension`, trying both
		the plain and `GL_`-prefixed names.
	**/
	private static function detectAstcHdrProfile(gl:Dynamic, ldrExtension:Dynamic):Bool
	{
		#if (js && html5)
		if (ldrExtension == null) return false;

		if (ldrExtension.getSupportedProfiles == null) return false;

		var profiles:Dynamic = null;

		try
		{
			profiles = ldrExtension.getSupportedProfiles();
		}
		catch (e:Dynamic)
		{
			return false;
		}

		if (profiles == null) return false;

		var length = profiles.length;

		if (length == null) return false;

		for (i in 0...length)
		{
			if (profiles[i] == "hdr") return true;
		}

		return false;
		#else
		var hdrExtension = gl.getExtension("KHR_texture_compression_astc_hdr");
		if (hdrExtension == null) hdrExtension = gl.getExtension("GL_KHR_texture_compression_astc_hdr");
		return hdrExtension != null;
		#end
	}

	/**
		Parses an OpenGL version string such as `OpenGL ES 3.2 Mesa` and reports
		whether it names an OpenGL ES version at or above the given level.
		Desktop GL strings (no `ES ` marker) report false.
	**/
	private static function isOpenGLESAtLeast(version:String, major:Int, minor:Int):Bool
	{
		if (version == null) return false;

		var esIndex = version.indexOf("ES ");
		if (esIndex == -1) return false;

		var rest = version.substr(esIndex + 3);
		var dot = rest.indexOf(".");

		if (dot == -1) return false;

		var parsedMajor = Std.parseInt(rest.substr(0, dot));
		var parsedMinor = Std.parseInt(rest.substr(dot + 1));

		if (parsedMajor == null || parsedMinor == null) return false;

		return parsedMajor > major || (parsedMajor == major && parsedMinor >= minor);
	}

	private static function registerExtension(extension:Dynamic, formats:Array<Int>):Void
	{
		// Lime creates an extension object only when the driver reports the
		// extension as supported, so a non-null object is sufficient evidence.
		if (extension == null) return;
		markSupported(formats);
	}

	private static function markSupported(formats:Array<Int>):Void
	{
		for (format in formats)
		{
			supported.set(format, true);
		}
	}

	/**
		Maps a stored internal format to the canonical constant of its GPU bucket.
		Identical values are returned unchanged.
	**/
	private static function canonicalFor(glInternalFormat:Int):Int
	{
		return switch (glInternalFormat)
			{
				case KtxGL.COMPRESSED_RGBA_S3TC_DXT1_EXT: KtxGL.COMPRESSED_RGB_S3TC_DXT1_EXT;
				case KtxGL.COMPRESSED_SRGB8_ETC2: KtxGL.COMPRESSED_RGB8_ETC2;
				case KtxGL.COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2: KtxGL.COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2;
				case KtxGL.COMPRESSED_SRGB8_ALPHA8_ETC2_EAC: KtxGL.COMPRESSED_RGBA8_ETC2_EAC;
				default: glInternalFormat;
			}
	}
}

#else

/**
	Flash and AIR targets expose no OpenGL API to Haxe, so compressed format
	capabilities cannot be probed there. KTX uploads are unsupported on these
	targets; every format reports as unavailable.
**/
class KtxCompressedFormats
{
	public static function reset():Void {}

	public static function resolve(context:Context3D, glInternalFormat:Int):Int
	{
		throw new IllegalOperationError("KTX for OpenFL: KTX texture upload is not supported on Flash or AIR targets");
	}

	public static function isSupported(context:Context3D, glInternalFormat:Int):Bool
	{
		return false;
	}

	public static function isAstcHdrSupported(context:Context3D):Bool
	{
		return false;
	}
}

#end
