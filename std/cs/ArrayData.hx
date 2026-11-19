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

/**
	The native array that holds the values of a Haxe `Array`.

	A Haxe array stores its values in an `int[]`, a `double[]`, a `bool[]` or an
	`object[]`, depending on what it holds. These functions give that array to
	code that works on native arrays (a native library, a Burst job in Unity...).

	The returned array is the storage itself, not a copy: writing to it writes to
	the Haxe array. It can be longer than the Haxe array: only the first
	`array.length` values are meaningful. It is replaced when the Haxe array
	grows, so it must not be kept across a `push` or any other change of length.

	Each function fixes the storage of the array: an array whose values are
	stored another way (it was filled through `Dynamic` for example) is converted
	first, and an array that another type already fixed is refused with an
	exception.
**/
@:access(Array)
class ArrayData {
	/** The `int[]` of an array of `Int` (or of an abstract over `Int`). **/
	public static function ints(array:Array<Int>):NativeArray<Int> {
		array.__cast(1);
		if (array.__intArray == null)
			array.__initIntArray(0);
		return array.__intArray;
	}

	/** The `double[]` of an array of `Float`. **/
	public static function floats(array:Array<Float>):NativeArray<Float> {
		array.__cast(2);
		if (array.__floatArray == null)
			array.__initFloatArray(0);
		return array.__floatArray;
	}

	/** The `bool[]` of an array of `Bool`. **/
	public static function bools(array:Array<Bool>):NativeArray<Bool> {
		array.__cast(3);
		if (array.__boolArray == null)
			array.__initBoolArray(0);
		return array.__boolArray;
	}

	/** The `object[]` of an array of anything else. **/
	public static function objects(array:Array<Dynamic>):NativeArray<Dynamic> {
		array.__cast(4);
		// An array fixed to int, float or bool storage keeps it
		if ((cast array.__arrayType : Int) != 4)
			throw "The values of this array are not stored as objects";
		if (array.__objectArray == null)
			array.__initObjectArray(0);
		return array.__objectArray;
	}
}
