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

package cs;

import haxe.io.Bytes;

/**
	Where `haxe.Resource` reads the resources from when they are written as files
	(`-D cs.resource-files`).

	With this define, the compiler writes each resource given with `--resource` to
	`Resources/<file name>` in the output folder instead of putting it in the
	generated code, and the generated project embeds these files in the assembly.

	A host that builds the output its own way (Unity for example) stores the files
	where it wants and sets `loader` to read them.
**/
class ResourceFiles {
	/**
		Reads the content of a resource file, given by its name in the `Resources`
		folder of the output (see `fileName`). Returns `null` when there is none.

		`null` (the default): the files embedded in the assembly by the generated
		project.
	**/
	public static var loader:(fileName:String) -> Bytes = null;

	/**
		The name of the file that holds the resource `name`: the characters other
		than ASCII letters, digits, `_` and `.` are escaped, so that any resource
		name gives a valid file name.
	**/
	public static function fileName(name:String):String {
		var bytes = Bytes.ofString(name);
		var buf = new StringBuf();
		for (i in 0...bytes.length) {
			var c = bytes.get(i);
			if ((c >= "a".code && c <= "z".code) || (c >= "A".code && c <= "Z".code) || (c >= "0".code && c <= "9".code) || c == "_".code
				|| c == ".".code)
				buf.addChar(c);
			else {
				buf.add("-x");
				buf.add(c);
			}
		}
		return buf.toString();
	}

	@:allow(haxe.Resource)
	static function load(name:String):Bytes {
		var file = fileName(name);
		if (loader != null)
			return loader(file);
		var assembly:cs.system.reflection.Assembly = cs.Syntax.code("typeof(global::cs.ResourceFiles).Assembly");
		var stream = assembly.GetManifestResourceStream(file);
		if (stream == null)
			return null;
		var memory = new cs.system.io.MemoryStream();
		stream.CopyTo(memory);
		stream.Dispose();
		return Bytes.ofData(memory.ToArray());
	}
}
