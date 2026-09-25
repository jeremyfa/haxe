package cases;

class StringInterpolationUnicode extends DisplayTestCase {
	/**
		class Main {
			static var theme = { accent: 1 };
			static function main() {
				var a = [];
				var s1 = 'é • ⌥ 😀 ${a.{-1-}} y';
				var s2 = 'é • ⌥ 😀 ${true ? '${a.{-2-}}' : "h"} y';
				var s3 = 'é • ⌥ 😀 ${th{-3-}eme.accent}';
			}
		}
	**/
	function test() {
		eq(true, hasField(fields(pos(1)), "length", "Int"));
		eq(true, hasField(fields(pos(2)), "length", "Int"));
		eq("{ accent : Int }", type(pos(3)));
	}
}
