package unit.issues;

#if cs
import cs.system.Attribute;
import haxe.test.AttrWithNullType;
import haxe.test.AttrWithNonNullType;
import haxe.test.MyAttrAttribute;
#end

class Issue9946 extends unit.Test {
	#if cs
	function test() {
		// a Class value is the System.Type of the class
		eq(hasNullArg(cast AttrWithNullType), true);
		eq(hasNullArg(cast AttrWithNonNullType), false);
	}

	static function hasNullArg(cls:cs.system.Type):Null<Bool> {
		var attributes = Attribute.GetCustomAttributes(cls);

		for (i in 0...attributes.length) {
			var attr = attributes[i];
			if (Std.isOfType(attr, MyAttrAttribute)) {
				var a:MyAttrAttribute = cast attr;
				return a.check;
			}
		}

		return null;
	}
	#end
}
