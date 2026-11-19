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
import cs.system.io.compression.CompressionMode;
import cs.system.io.compression.DeflateStream;

class Uncompress {
	public function new(?windowBits:Int) {
		throw new haxe.exceptions.NotImplementedException("Not implemented for this platform");
	}

	public function execute(src:haxe.io.Bytes, srcPos:Int, dst:haxe.io.Bytes, dstPos:Int):{done:Bool, read:Int, write:Int} {
		return null;
	}

	public function setFlushMode(f:FlushMode) {}

	public function close() {}

	public static function run(src:haxe.io.Bytes, ?bufsize:Int):haxe.io.Bytes {
		// A zlib stream (RFC 1950): two header bytes, the raw deflate data that .NET
		// reads, then a checksum
		if (src.length < 2)
			throw "Invalid zlib data";
		var cmf = src.get(0);
		var flg = src.get(1);
		if ((cmf & 0x0F) != 8 || ((cmf << 8) | flg) % 31 != 0)
			throw "Invalid zlib header";
		if ((flg & 0x20) != 0)
			throw "Unsupported zlib data: preset dictionary";
		var input = new MemoryStream(src.getData(), 2, src.length - 2);
		var inflate = new DeflateStream(input, CompressionMode.Decompress);
		var output = new MemoryStream();
		inflate.CopyTo(output);
		inflate.Dispose();
		return haxe.io.Bytes.ofData(output.ToArray());
	}
}
