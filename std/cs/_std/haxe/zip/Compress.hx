/*
 * Copyright (C)2005-2019 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package haxe.zip;

import cs.system.io.MemoryStream;
import cs.system.io.compression.CompressionLevel;
import cs.system.io.compression.DeflateStream;

class Compress {
	public function new(level:Int) {
		throw new haxe.exceptions.NotImplementedException("Not implemented for this platform");
	}

	public function execute(src:haxe.io.Bytes, srcPos:Int, dst:haxe.io.Bytes, dstPos:Int):{done:Bool, read:Int, write:Int} {
		return null;
	}

	public function setFlushMode(f:FlushMode) {}

	public function close() {}

	public static function run(s:haxe.io.Bytes, level:Int):haxe.io.Bytes {
		// A zlib stream (RFC 1950) around the raw deflate data of .NET: .NET Standard 2.1
		// has DeflateStream but no ZLibStream.
		var memory = new MemoryStream();
		// Header: deflate with a 32K window, then the compression level hint and
		// the bits that make the two bytes a multiple of 31
		memory.WriteByte(0x78);
		memory.WriteByte(level <= 1 ? 0x01 : level < 6 ? 0x5E : level == 6 ? 0x9C : 0xDA);
		var compression = level == 0 ? CompressionLevel.NoCompression : level < 6 ? CompressionLevel.Fastest : CompressionLevel.Optimal;
		var deflate = new DeflateStream(memory, compression, true);
		deflate.Write(s.getData(), 0, s.length);
		// writes the end of the deflate data
		deflate.Dispose();
		// Checksum of the uncompressed data, big endian
		var adler = haxe.crypto.Adler32.make(s);
		memory.WriteByte((adler >>> 24) & 0xFF);
		memory.WriteByte((adler >>> 16) & 0xFF);
		memory.WriteByte((adler >>> 8) & 0xFF);
		memory.WriteByte(adler & 0xFF);
		return haxe.io.Bytes.ofData(memory.ToArray());
	}
}
