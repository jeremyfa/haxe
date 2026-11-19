import haxe.ds.Vector;

/**
	Code patterns that a host like Unity relies on, and patterns that used to need
	a workaround with the previous C# target. Each test writes the pattern the
	natural way and checks the result at run time.

	The output is built as a library (-D cs.library) and called by a host with its
	own entry point (host/Host.cs), which never runs Program.Main.
**/
class Main {
	static var failures = 0;
	static var count = 0;
	static var current = "";

	static function t(cond:Bool, ?pos:haxe.PosInfos) {
		count++;
		if (!cond) {
			failures++;
			Sys.println('FAILED ${current} at ${pos.fileName}:${pos.lineNumber}');
		}
	}

	static function test(name:String, f:() -> Void) {
		current = name;
		try {
			f();
		} catch (e:Dynamic) {
			failures++;
			Sys.println('FAILED ${name}: exception ${e}');
		}
	}

	static function main() {
		run();
	}

	/** Called by the host. Returns the number of failures. **/
	@:keep public static function run():Int {
		test("reflection without Program.Main", testReflectionWithoutMain);
		test("@:classCode", testClassCode);
		test("inline C# with braces", testInlineCodeBraces);
		test("string constants with special characters", testStringConstants);
		test("extern class of the root package", testRootExtern);
		test("final class with statements before super()", testFinalTwoPhase);
		test("methods with many arguments", testManyArguments);
		test("statements before super()", testStatementsBeforeSuper);
		test("optional Int given to an optional Float", testOptionalNumbers);
		test("Dynamic values in typed code", testDynamicInTypedCode);
		test("constructor argument named like a local of an inlined call", testConstructorArgumentNames);
		test("increment of a Null<Int> in a comparison", testNullIncrementInComparison);
		test("enum constructor named like its enum", testEnumConstructorName);
		test("values converted to what receives them", testValueConversions);
		test("null and _ arguments", testNullAndUnderscoreArguments);
		test("constructor calling an overridable method, parent with arguments", testVirtualCallInConstructor);
		test("abstract over a type parameter returned by a method", testAbstractOverTypeParameter);
		test("resize before the first value", testResizeBeforeFirstValue);
		test("null check of a Null value typed by an abstract", testNullCheckOfAbstract);
		test("null given to a local Null of an abstract over a number", testNullLocalOfAbstract);
		test("arrays of an abstract over a number", testArrayOfAbstract);
		test("comparison of a Null number next to another condition", testNullComparisonGrouping);
		test("break of a loop in a switch of an outer loop", testBreakOfInnerLoop);
		test("Dynamic value in the literal of a typed array", testDynamicInArrayLiteral);
		test("Null value given to generic code", testNullValueInGenericCode);
		test("Int given to a Dynamic argument through a function value", testIntThroughFunctionValue);
		test("statements made from values", testStatementsFromValues);
		test("function value returning a Null number, in a ternary", testNullReturnInTernary);
		test("closure called with an array of numbers as arguments", testCallMethodTypedArgs);
		test("override of a generic method with an argument named like a C# keyword", testKeywordArgumentInOverride);
		test("final fields of an interface", testInterfaceFinalFields);
		test("toString with arguments", testToStringWithArguments);
		test("class without a constructor, with initialized fields, parent with arguments", testInheritedConstructorWithFieldInits);
		test("override of a method that returns a type parameter", testOverrideOfTypeParameterReturn);
		test("Dynamic index of an array", testDynamicArrayIndex);
		test("element changed in place in an array stored another way", testInPlaceOnOtherStorage);
		test("Null value written to a field of a Dynamic object", testNullValueToDynamicField);
		test("conditional between a value and a Bool, as a Dynamic", testConditionalWithBool);
		test("comparison of a call that returns a Null number", testNullCallComparedOnce);
		test("increment of an element of an array of objects", testIncrementOfObjectElement);
		test("object literals given to structures", testObjectLiteralsForStructures);
		test("class extending a native class", testNativeBase);
		test("stable sort on typed storage", testSort);
		test("native array of a Haxe array", testArrayData);
		test("resources written as files", testResourceFiles);
		test("zlib compression", testZip);
		test("createInstance with optional arguments", testCreateInstanceOptionalArgs);
		test("field access through a constrained type parameter", testConstrainedTypeParam);
		test("array variance", testArrayVariance);
		test("Vector in a generic class", testVectorInGenericClass);
		test("generic class over a value type abstract", testUnitTask);
		test("type parameter used only in a nested closure", testNestedClosureTypeParam);
		test("duplicate underscore parameters in a generic class", testUnderscoreParams);
		test("override with a more specific return type", testCovariantOverride);
		test("captured Null<T> of a type parameter", testCapturedNullTypeParam);
		test("generic interface variance", testInterfaceVariance);
		test("generic interface method taking Null<T>", testInterfaceNullParam);
		test("constructor with type parameters", testGenericConstructor);
		test("generic array copy", testGenericArrayCopy);
		test("rest arguments", testRest);
		test("Any compared with a Bool", testAnyBool);
		test("numbers do not follow the culture", testCulture);
		test("small integer types", testSmallIntegers);
		test("switch on a class", testSwitchOnClass);
		test("reserved looking names", testNames);
		test("break in a switch in a loop", testBreakInSwitch);
		test("inline with locals in two branches", testInlineLocals);
		test("rethrow in a catch", testRethrow);
		test("zero initialized storage", testZeroInit);
		test("map iteration", testMaps);
		test("reflective call of a generic method", testReflectiveGenericCall);
		test("assignment of a value that needs statements", testAssignPreparedValue);
		Sys.println('Done ${count} tests with ${failures} failures');
		return failures;
	}

	// ---------------------------------------------------------------------
	// Fixes of the target
	// ---------------------------------------------------------------------

	static function testReflectionWithoutMain() {
		// All of these go through the reflection registry, which used to be
		// connected by Program.Main only.
		var red:Color = Type.createEnum(Color, "Red");
		t(red == Red);
		var rgb:Color = Type.createEnum(Color, "Rgb", [1, 2, 3]);
		t(switch rgb {
			case Rgb(1, 2, 3): true;
			default: false;
		});
		t(Type.getEnumConstructs(Color).join(",") == "Red,Green,Rgb");
		t(Reflect.field(WithStatics, "counter") == 12);
		t(Type.getClassFields(WithStatics).indexOf("counter") != -1);
		var c = Type.resolveClass("WithStatics");
		t(c != null);
		var inst:WithStatics = Type.createInstance(c, [5]);
		t(inst != null && inst.value == 5);
		t(Type.getInstanceFields(WithStatics).indexOf("value") != -1);
		var e = Type.resolveEnum("Color");
		t(e != null);
		// private constructor, no arguments
		var p:PrivateCtor = Type.createInstance(PrivateCtor, []);
		t(p != null && p.ok);
		var empty:WithStatics = Type.createEmptyInstance(WithStatics);
		t(empty != null && empty.value == 0);
	}

	static function testClassCode() {
		t(NativeMembers.twice(21) == 42);
		var items:Array<Int> = [];
		NativeMembers.collect(items);
		t(items.join(",") == "1,2,3");
	}

	static function testInlineCodeBraces() {
		// Braces that are not placeholders are plain C#
		untyped __cs__('byte[] pair = {7, 9}');
		var sum:Int = untyped __cs__('pair[0] + pair[1]');
		t(sum == 16);
		var three:Int = cs.Syntax.code("new int[] {1,2,3}.Length");
		t(three == 3);
		var viaLambda:Int = cs.Syntax.code("((global::System.Func<int, int>)(v => {return v + {0};}))(40)", 2);
		t(viaLambda == 42);
	}

	static function testStringConstants() {
		// Characters that end a line for the C# compiler, controls, the byte order mark
		var lines = "a\u2028b\u2029c\u0085d";
		t(lines.length == 7 && lines.charCodeAt(1) == 0x2028 && lines.charCodeAt(3) == 0x2029 && lines.charCodeAt(5) == 0x85);
		var controls = "\x00\x01\x1F\x7F\u009F";
		t(controls.length == 5 && controls.charCodeAt(0) == 0 && controls.charCodeAt(3) == 0x7F && controls.charCodeAt(4) == 0x9F);
		var bom = "\uFEFFx";
		t(bom.length == 2 && bom.charCodeAt(0) == 0xFEFF);
		// kept as they are
		var text = "é ÷ 日本 😀 \"quoted\" back\\slash";
		t(text.length == 29 && text.charCodeAt(0) == 0xE9 && text.indexOf("😀") == 7);
		var followed = "\x05B";
		t(followed.length == 2 && followed.charCodeAt(0) == 5 && followed.charCodeAt(1) == 0x42);
	}

	static function testRootExtern() {
		// HostHelper is written in C#, in the global namespace (host/HostHelper.cs)
		t(HostHelper.twice(4) == 8);
		var helper = new HostHelper();
		helper.next();
		t(helper.next() == 2 && helper.calls == 2);
		var list:Array<HostHelper> = [helper];
		t(list[0].calls == 2);
		var mode = HostMode.On;
		t(mode != HostMode.Off);
		var keeper = new KeepsHelper(helper);
		t(keeper.helper.calls == 2);
	}

	static function testFinalTwoPhase() {
		var s = new SealedNode(21);
		t(s.doubled == 42 && s.name() == "base");
	}

	static function testManyArguments() {
		// More arguments than the typed closures of the runtime take
		var many = new ManyArgs();
		t(many.sum(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11.5, "x") == "66.5x");
		var f = many.sum;
		t(f(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 0.5, "y") == "55.5y");
		var viaReflect:String = Reflect.callMethod(many, Reflect.field(many, "sum"), [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0.5, "z"]);
		t(viaReflect == "10.5z");
		var g = ManyArgs.count;
		g(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, true);
		t(ManyArgs.total == 55);
		Reflect.callMethod(ManyArgs, Reflect.field(ManyArgs, "count"), [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, false]);
		t(ManyArgs.total == 54);
	}

	static function testStatementsBeforeSuper() {
		// The argument of super() is computed by statements before it, among which an
		// inlined call that declares locals named like the arguments of the constructor
		var tex = new RenderTex(10, 20);
		t(tex.item == "20x40 d1" && tex.density == 2 && tex.depth && tex.antialiasing == 0 && tex.flag);
		var other = new RenderTex(10, 20, 1, false, 4);
		t(other.item == "10x20 4" && other.density == 1 && !other.depth && other.antialiasing == 4);
		t(RenderTex.maker.count == 2);
		var sub = new SubRenderTex(3);
		t(sub.item == "6x6 d1" && sub.extra == 3 && sub.flag);
		// A statement before super() that the constructor of the parent depends on
		var guarded = new GuardedChild(5);
		t(guarded.value == 5 && !GuardedBase.internalAlloc);
		var direct = false;
		try {
			new GuardedBase();
		} catch (e:Dynamic) {
			direct = true;
		}
		t(direct);
		// created inside an expression
		t(makeAll([new GuardedChild(1), new GuardedChild(2)]) == 3);
	}

	static function makeAll(list:Array<GuardedChild>):Int {
		var sum = 0;
		for (g in list)
			sum += g.value;
		return sum;
	}

	static function testOptionalNumbers() {
		var p = new Packer(3, 4);
		t(p.inlined.w == 3 && p.inlined.h == 4 && p.plain.w == 3 && p.plain.h == 4);
		var q = new Packer();
		t(q.inlined.w == 0 && q.plain.h == 0);
	}

	static function testDynamicInTypedCode() {
		// a typed field combined with a Dynamic value
		var entry = new Entry();
		entry.alpha *= dynamicMin(1.0, 0.5);
		var three:Dynamic = 3;
		entry.alpha += three;
		t(entry.alpha == 4);
		// a Dynamic index on a Dynamic array
		var arr:Dynamic = [1, 2, 3];
		var index:Dynamic = 1;
		arr[index] = 5;
		var got:Int = arr[index];
		t(got == 5 && arr[2] == 3);
		arr[index] += 2;
		t(arr[1] == 7);
		// a function kept in a Dynamic field
		var item = new Listener();
		var log = [];
		item.willEmit = function() log.push("0");
		item.willEmit();
		item.willEmit = function(a:Int) log.push("1:" + a);
		item.willEmit(7);
		item.willEmit = function(a:Int, b:String) log.push(a + b);
		item.willEmit(8, "x");
		t(log.join(",") == "0,1:7,8x");
	}

	static function dynamicMin(a:Dynamic, b:Dynamic):Dynamic {
		return Math.min(a, b);
	}

	static function testConstructorArgumentNames() {
		var ph = new Phys(1.5);
		t(ph.body.rot == 3 && ph.body.seen == "box");
		var other = new Phys(2, "circle");
		t(other.body.rot == 4 && other.body.seen == "circle");
	}

	static function testNullIncrementInComparison() {
		t(fill([1, 2, 3, 4], 2) == 2);
		t(fill([1, 2, 3]) == 3);
	}

	static function fill(items:Array<Int>, ?count:Int):Int {
		if (count == null)
			count = items.length;
		var done = 0;
		for (j in 0...items.length) {
			done++;
			if (--count <= 0)
				break;
		}
		return done;
	}

	static function testEnumConstructorName() {
		var s:Measure = Measures.of(12.5);
		var px = switch s {
			case Measure(size): size;
			case Small: 1;
			case Large: 3;
		}
		t(px == 12.5);
		t(Type.enumConstructor(s) == "Measure" && Type.enumParameters(s)[0] == 12.5);
		var made:Measure = Type.createEnum(Measure, "Measure", [2.0]);
		t(Type.enumEq(made, Measures.of(2.0)));
		var f = Measures.maker();
		t(Type.enumEq(f(4), Measures.of(4)));
		var small:Measure = Small;
		var large:Measure = Large;
		t(small != large && Type.enumIndex(large) == 2);
	}

	static function testValueConversions() {
		// inline C# (Math.abs) given to an argument of another number type
		var bits = haxe.io.FPHelper.floatToI32(Math.abs(-1.5));
		t(haxe.io.FPHelper.i32ToFloat(bits) == 1.5);
		// a null element in an array of Null<Float>
		var maybe:Array<Null<Float>> = [null];
		t(maybe.length == 1 && maybe[0] == null);
		var mixed:Array<Null<Float>> = [1.5, null];
		t(mixed[0] == 1.5 && mixed[1] == null);
		// Dynamic values in the literal of an Array<Int>, an Int in an Array<Float>
		var d:Dynamic = {order: 7};
		var i = 2;
		var ints:Array<Int> = [d.order, 0, i];
		t(ints.join(",") == "7,0,2");
		var floats:Array<Float> = [i, 0.5];
		t(floats[0] + floats[1] == 2.5);
		// an Int64 made of a negative low part, in a static initializer
		t(Seeds.SEED == haxe.Int64.make(0x243F6A88, 0x85A308D3));
		t(haxe.Int64.toStr(Seeds.SEED) == "2611923443488327891");
	}

	static function testNullAndUnderscoreArguments() {
		// null fits the constructor argument and the EmptyConstructor one
		var b = new StyleBox(null);
		t(b.style == null);
		var c = new StyleBox(new StyleBox(null));
		t(c.style != null);
		// `_` used as a real argument, with another `_` before it
		t(Underscores.second(1, "two") == "two");
		var u = new Underscores(3, "kept");
		t(u.kept == "kept");
		t(Underscores.make("x", 4).kept == "4");
	}

	static function testVirtualCallInConstructor() {
		var leaf = new GradientElement("doc", 5);
		t(leaf.document == "doc" && leaf.id == 5 && leaf.setupCalls == 1 && leaf.kind == "gradient");
	}

	static function testAbstractOverTypeParameter() {
		var slot = new Slot(new Context(3));
		var weak:Weak<Context> = new Weak(slot);
		var strong:Context = weak.upgrade();
		t(strong != null && strong.size == 3);
		t((weak.upgrade() : Context).size == 3);
		t(sizeOf(weak) == 3);
		slot.alive = false;
		t(weak.upgrade() == null);
		// the same abstract as a field of a generic class
		var keyed = new Keyed<Context>(cast new Context(7));
		var entity:Context = keyed.entity;
		t(entity.size == 7);
		keyed.entity = cast new Context(8);
		t(readKeyed(keyed).size == 8);
	}

	static function readKeyed(keyed:Keyed<Context>):Context {
		return keyed.entity;
	}

	static function sizeOf(weak:Weak<Context>):Float {
		var c:Context = weak.upgrade();
		return c == null ? -1 : c.size;
	}

	static function testResizeBeforeFirstValue() {
		// The array gets its length before any value tells how it is stored
		var objects:Array<Context> = [];
		objects.resize(6);
		objects[0] = new Context(1);
		objects[5] = new Context(6);
		t(objects.length == 6 && objects[0].size == 1 && objects[5].size == 6 && objects[3] == null);
		objects.push(new Context(7));
		t(objects.length == 7 && objects[6].size == 7 && objects[5].size == 6);

		var ints:Array<Int> = [];
		ints.resize(10);
		ints[0] = 4;
		t(ints.length == 10 && ints[0] == 4 && ints[9] == 0);
		ints[9] = 5;
		ints.push(6);
		t(ints.length == 11 && ints[9] == 5 && ints[10] == 6);

		var floats:Array<Float> = [];
		floats.resize(3);
		floats[2] = 1.5;
		t(floats[0] == 0 && floats[2] == 1.5 && floats.length == 3);

		var bools:Array<Bool> = [];
		bools.resize(5);
		bools[4] = true;
		t(!bools[0] && bools[4] && bools.length == 5);
	}

	static function testNullCheckOfAbstract() {
		var holder = new ErrorHolder();
		t(holder.check() == "none");
		holder.error = TooBig;
		t(holder.check() == "too big");
		holder.error = null;
		t(holder.check() == "none" && holder.error == null);
		var local:Null<ErrorCode> = holder.error;
		t(local == null && !(local != null));
		local = TooSmall;
		t(local != null && local == TooSmall);
	}

	static function testNullLocalOfAbstract() {
		// The null of these locals is typed by the abstract alone: none of them has a value
		var flag = Sys.args().length > 100;
		var id:Null<NodeId> = null;
		if (flag)
			id = new NodeId(1);
		var ratio:Null<Ratio> = null;
		if (flag)
			ratio = new Ratio(0.5);
		var later:Null<NodeId>;
		later = null;
		var list:Array<Null<NodeId>> = [null, new NodeId(4)];
		var obj:{id:Null<NodeId>} = {id: null};
		t(id == null && ratio == null && later == null && obj.id == null);
		t(list[0] == null && list[1] != null && list[1] == new NodeId(4));
		// in a closure, and given on as the only element of an array
		var count = (() -> {
			var replacement:Null<NodeId> = null;
			if (flag)
				replacement = new NodeId(2);
			var ids:Null<Array<NodeId>> = replacement != null ? [replacement] : null;
			return ids == null ? -1 : ids.length;
		})();
		t(count == -1);
		id = new NodeId(0);
		t(id != null && id == new NodeId(0));
	}

	static function testArrayOfAbstract() {
		// Stored as the numbers they are (the storage is the one of an Array<Int>)
		var ids:Array<NodeId> = [];
		ids.resize(2);
		for (i in 0...2)
			ids[i] = new NodeId(7 + i);
		ids.push(new NodeId(12));
		var ints:Array<Int> = cast ids;
		t(ints.join(",") == "7,8,12" && ids.indexOf(new NodeId(8)) == 1);
		t(cs.Syntax.code("{0}.__intArray != null", ids));
		var total = 0;
		for (id in ids)
			total += id.toInt();
		t(total == 27);
		var last:Null<NodeId> = ids.pop();
		var none:Null<NodeId> = ([] : Array<NodeId>).pop();
		t(last == new NodeId(12) && none == null && ids.length == 2);
		var ratios:Array<Ratio> = [new Ratio(1.5), new Ratio(2.5)];
		ratios.unshift(new Ratio(0.5));
		t(ratios[0].toFloat() + ratios[2].toFloat() == 3.0);
		t(cs.Syntax.code("{0}.__floatArray != null", ratios));
		var codes:Array<ErrorCode> = [TooBig, TooSmall];
		t(codes[1] == TooSmall && codes.contains(TooBig));
		// map keeps numbers as numbers
		var doubled = ids.map(id -> id.toInt() * 2);
		t(doubled.join(",") == "14,16");
		t(cs.Syntax.code("{0}.__intArray != null", doubled));
		var halves = [1, 2].map(i -> i / 2);
		t(halves.join(",") == "0.5,1" && cs.Syntax.code("{0}.__floatArray != null", halves));
		var names = ids.map(id -> "n" + id.toInt());
		t(names.join(",") == "n7,n8");
	}

	static function testNullComparisonGrouping() {
		// The comparison is several C# conditions: they stay one operand of what is around
		var holder = new WithNullIndex();
		var other:Null<String> = Sys.args().length > 100 ? "x" : null;
		var ix = 2;
		t(!(holder.index != ix && other != null));
		t(!(other != null && holder.index != ix));
		t(holder.index != ix || other != null);
		holder.index = 2;
		t(holder.index == ix && other == null);
		t(!(holder.index != ix && other == null));
		var a:Null<Int> = null;
		var b:Null<Int> = 3;
		t(!(a >= b && other == null) && !(a == b && other == null) && (a != b && other == null));
		// arithmetic regrouped by inlining
		t(Grouping.scale(1 + ix, 2) == 6 && Grouping.minus(10, ix - 1) == 9);
	}

	static function testBreakOfInnerLoop() {
		// The outer loop has a break in a switch (a goto in C#); the break of the inner
		// loop, in a case of that switch, leaves the inner loop only
		var ops = [1, 2, 1, 3];
		var stack = [5, 6, 7, 8];
		var log = [];
		var i = 0;
		while (true) {
			var op = ops[i++];
			switch (op) {
				case 1:
					var k = stack.length;
					while (true) {
						k--;
						if (stack[k] < 7)
							break;
					}
					log.push("found" + k);
				case 2:
					var n = 0;
					do {
						n++;
						if (n == 2)
							break;
					} while (true);
					log.push("n" + n);
				case 3:
					break;
				default:
			}
			log.push("op" + op);
		}
		t(log.join(",") == "found1,op1,n2,op2,found1,op1");
		// the same with the inner loop as a value
		var out = [];
		for (op in ops) {
			switch (op) {
				case 1:
					var first = -1;
					for (j in 0...stack.length) {
						if (stack[j] > 5) {
							first = j;
							break;
						}
					}
					out.push(first);
				case 3:
					break;
				default:
					out.push(-op);
			}
		}
		t(out.join(",") == "1,-2,1");
	}

	static function testDynamicInArrayLiteral() {
		var data:Dynamic = {name: "n", count: 2};
		// captured and assigned in a closure: kept in an array of its type
		var name:Null<String> = data.name;
		var set = () -> name = name + "!";
		set();
		t(name == "n!");
		var names:Array<String> = [data.name, "x"];
		t(names.join(",") == "n,x");
	}

	static function testNullValueInGenericCode() {
		// A Null<Int> given where C# takes an object is its value or null, never the
		// Null<int> struct in a box (which is not null)
		var none:Null<Int> = Sys.args().length > 100 ? 1 : null;
		var five:Null<Int> = 5;
		var holder = new Holder<Null<Int>>();
		holder.put(none);
		t(holder.isEmpty() && holder.get() == null);
		holder.put(five);
		t(!holder.isEmpty() && holder.get() == 5 && isInt(holder.get()));
		var list:Array<Null<Int>> = [];
		list.push(none);
		list.push(five);
		list.unshift(none);
		list.insert(1, five);
		t(list.map(describeDynamic).join(",") == "null,5i,null,5i");
		t(list.indexOf(five) == 1 && list.contains(none) && list.remove(five) && list.length == 3);
		// in the literal of an array of Dynamic
		var entry = new Holder<String>();
		var rows = [for (e in [entry]) ([e.index(false), e.index(true), "s"] : Array<Dynamic>)];
		t(rows[0][0] == null && rows[0][1] == 3 && isInt(rows[0][1]));
		var mixed:Array<Dynamic> = [none, five];
		t(mixed[0] == null && isInt(mixed[1]));
	}

	static function isInt(d:Dynamic):Bool
		return Std.isOfType(d, Int);

	static function describeDynamic(d:Dynamic):String
		return d == null ? "null" : Std.string(d) + (Std.isOfType(d, Int) ? "i" : "?");

	static function testIntThroughFunctionValue() {
		// The Int is still an Int for the code that receives it as Dynamic
		var describe:Dynamic->String = describeDynamic;
		t(describe(5) == "5i");
		t([1, 2].map(describeDynamic).join(",") == "1i,2i");
		var same:Int->Dynamic = x -> x;
		t(describeDynamic(same(7)) == "7i" && Type.typeof(same(7)) == TInt);
		var big:haxe.Int64->Dynamic = x -> x;
		t(Std.string(big(haxe.Int64.make(1, 0))) == "4294967296");
		t(haxe.Json.stringify([1, 2].map(x -> (x : Dynamic))) == "[1,2]");
	}

	static function testStatementsFromValues() {
		// a Dynamic condition of a value that needs statements
		var data:Dynamic = {on: true, off: false};
		var a = new Names();
		var picked = data.on ? [a.finalize(), 2] : [3];
		var other = data.off ? [a.finalize(), 2] : [3];
		t(picked.length == 2 && other.length == 1);
		// a variable every case of an exhaustive switch assigns
		var code = Sys.args().length > 100 ? TooBig : TooSmall;
		var label:String;
		switch (code) {
			case TooSmall:
				label = "small";
			case TooBig:
				label = "big";
		}
		t(label == "small");
		// a value made by inline C# code, not used
		var total = 0.0;
		for (i in 0...3) {
			if (i == 1)
				rounded(i + 0.5);
			else
				total += rounded(i + 0.25);
		}
		t(total == 2.5);
		// the break of the loop, in a switch that gives a value
		var seen = [];
		for (i in 0...10) {
			var name = switch (i) {
				case 0: "zero";
				case 3: break;
				default: "n" + i;
			}
			seen.push(name);
		}
		t(seen.join(",") == "zero,n1,n2");
	}

	static inline function rounded(v:Float):Float
		return cs.Syntax.code("((double)(float)({0}))", v);

	static function testNullReturnInTernary() {
		// What the call returns is the Null<T>: no value stays no value, not 0
		var some:Null<KeyResolver> = new KeyResolver();
		var none:Null<KeyResolver> = Sys.args().length > 100 ? some : null;
		var list = [some, none];
		var keys:Array<Null<NodeId>> = [for (r in list) r != null ? r.resolver(0) : null];
		t(keys[0] == null && keys[1] == null);
		keys = [for (r in list) r != null ? r.resolver(4) : null];
		t(keys[0] != null && keys[0] == new NodeId(4) && keys[1] == null);
		var ints:Array<Null<Int>> = [for (r in list) r != null ? r.ints(0) : null];
		t(ints[0] == null && ints[1] == null);
		var methods:Array<Null<NodeId>> = [for (r in list) r != null ? r.key(0) : null];
		t(methods[0] == null);
		var one:Null<NodeId> = some != null ? some.resolver(0) : null;
		t(one == null);
	}

	static function testCallMethodTypedArgs() {
		// The arguments are read from the array whatever it stores (ints here, not objects)
		var k = 10;
		var add = (a:Int, b:Int) -> a + b + k;
		var ints = [1, 2];
		t(Reflect.callMethod(null, add, ints) == 13);
		t(Reflect.callMethod(null, add, [3, 4]) == 17);
		var not = (b:Bool) -> !b;
		t(Reflect.callMethod(null, not, [true]) == false);
		var half = (f:Float) -> f / 2;
		t(Reflect.callMethod(null, half, [3.0]) == 1.5);
		var mixed:Array<Dynamic> = [1.5, "x"];
		t(Reflect.callMethod(null, (a:Float, s:String) -> s + a, mixed) == "x1.5");
	}

	static function testKeywordArgumentInOverride() {
		var emitter = new QueueingEmitter();
		emitter.fire("a");
		emitter.paused = false;
		emitter.fire("b");
		t(emitter.queued.join(",") == "a" && emitter.fired.join(",") == "b");
	}

	static function testInterfaceFinalFields() {
		// read through the interface, one of them with a more specific type in the class
		var model:IPanelModel = new PanelModel();
		t(model.name == "m" && model.layout.size() == 3 && model.count == 2);
		t(new PanelModel().layout.extra() == 4 && Reflect.field(model, "name") == "m");
	}

	static function testToStringWithArguments() {
		// all optional: still the toString of Std.string() and of a concatenation
		var uri = new EncodedUri();
		var any:Dynamic = uri;
		t(uri.toString() == "encoded" && uri.toString(true) == "raw");
		t(Std.string(uri) == "encoded" && "" + uri == "encoded" && Std.string(any) == "encoded");
		// required: another method
		t(new TokenStore().toString(5) == "t5");
	}

	static function testInheritedConstructorWithFieldInits() {
		// The class is made with the arguments of the constructor it inherits
		var command = new MultiCommand({id: "undo"});
		command.add("a");
		t(command.id == "undo" && command.count() == 1 && command.registered);
		var child = new CountedChild(4);
		var other = new CountedChild(4, "abc");
		t(child.total == 5 && child.len() == 1 && other.total == 7);
		var made:CountedBase = Type.createInstance(CountedChild, [1, "ab"]);
		t(made.total == 3);
	}

	static function testOverrideOfTypeParameterReturn() {
		// Called on the class that overrides it: C# returns an object, like the first declaration
		var text = new TextOption();
		var number = new NumberOption();
		var base:ValueOption<String> = text;
		t(textLength(text.validate(true)) == 2 && textLength(text.validate("abc")) == 3 && text.validate(1).length == 1);
		t(number.validate(true) + 1 == 6 && number.pick(3) * 2 == 8 && textLength(base.validate(false)) == 5);
		// through the parent type, with a number of another kind than the override takes
		var ratio:ValueOption<Float> = new RatioOption();
		var anyOption:ValueOption<Any> = cast ratio;
		t(anyOption.pick(3) == 6.0 && anyOption.pick(1.5) == 3.0);
	}

	static function textLength(s:String):Int
		return s.length;

	static function testDynamicArrayIndex() {
		var holder:Dynamic = {id: 2};
		var texts = ["a", "b", "c"];
		var ints = [1, 2, 3];
		var bools = [true, false, true];
		var any:Array<Dynamic> = [1, "x", null];
		texts[holder.id] = "z";
		ints[holder.id] = 9;
		bools[holder.id] = false;
		any[holder.id] = 4;
		ints[holder.id] += 1;
		ints[holder.id]++;
		t(texts[holder.id] == "z" && ints[holder.id] == 11 && bools[holder.id] == false && any[holder.id] == 4);
	}

	static function testInPlaceOnOtherStorage() {
		// a[i] op= v writes to the native array: the array may not have it yet
		var empty:Array<Int> = [];
		var a = empty.slice(0);
		a.push(0);
		a[0] |= 4;
		var b = empty.copy();
		b.push(1);
		b[0] += 2;
		b[0]++;
		var c:Array<Int> = cast([] : Array<Dynamic>);
		c.push(5);
		c[0] -= 1;
		var d = empty.filter(x -> true);
		d.push(2);
		d[0] ^= 3;
		t(a[0] == 4 && b[0] == 4 && c[0] == 4 && d[0] == 1);
		var floats:Array<Float> = ([] : Array<Float>).slice(0);
		floats.push(1.5);
		floats[0] *= 2;
		t(floats[0] == 3.0);
		var mixed:Array<Dynamic> = [1, 2];
		var ints:Array<Int> = cast mixed;
		ints[1] += 5;
		t(ints.join(",") == "1,7");
		var sized:Array<Int> = [];
		sized.resize(2);
		sized[1] += 3;
		t(sized.join(",") == "0,3");
	}

	static function testNullValueToDynamicField() {
		// from a property, a field and a method: the value or null is written
		var props = new NullableProps();
		var result:Dynamic = {};
		result.tabSize = props.tabSize;
		result.readOnly = props.readOnly;
		result.plain = props.plain;
		result.made = props.make();
		t(result.tabSize == null && result.readOnly == null && result.plain == null && result.made == null);
		props.tabSize = 2;
		props.plain = 7;
		result.tabSize = props.tabSize;
		result.readOnly = props.readOnly;
		result.plain = props.plain;
		result.made = props.make();
		t(isInt(result.tabSize) && result.tabSize == 2 && Std.isOfType(result.readOnly, Bool) && result.readOnly == true);
		t(isInt(result.plain) && result.plain == 7 && isInt(result.made) && result.made == 2);
		t(haxe.Json.stringify(result).indexOf('"tabSize":2') != -1);
	}

	static function testConditionalWithBool() {
		// Haxe writes `c ? value : false` as `c && value` when the result is Dynamic
		var seen = [];
		for (list in [false, true]) {
			final option:Any = list ? ["a", "b"] : false;
			final other:Any = list ? true : ["c"];
			final number:Dynamic = list ? 5 : false;
			seen.push(Std.string(option) + "/" + Std.string(other) + "/" + Std.string(number));
		}
		t(seen.join(" ") == "false/[c]/false [a,b]/true/5");
	}

	static function testNullCallComparedOnce() {
		// The call is made once: a pop that is compared pops one value
		var stack:Array<ErrorCode> = [TooBig, TooSmall, TooBig];
		t(!(stack.pop() != TooBig) && stack.length == 2);
		t(stack.pop() == TooSmall && stack.length == 1);
		t(stack.pop() != TooSmall && stack.length == 0 && !(stack.pop() == TooBig) && stack.pop() != TooBig);
		var ints = [3, 4];
		t(ints.pop() > 3 && ints.pop() <= 3 && ints.length == 0);
		// nothing left: no value is neither less nor greater than a number
		var geq = ints.pop() >= 0;
		var lt = ints.pop() < 1;
		t(!geq && !lt);
		var some = new CallCounter(5);
		t(some.value == 5 && !(some.value != 5) && some.value > 4 && !(some.value <= 4) && some.next() >= 5 && 5 == some.next());
		t(some.calls == 6);
		var none = new CallCounter(null);
		var results = [none.value == 5, none.value != 5, none.value > 4, none.next() <= 4, none.next() >= none.next(), some.next() == none.next()];
		t(results.join(",") == "false,true,false,false,true,false");
		t(none.calls == 7);
	}

	static function testIncrementOfObjectElement() {
		var list:Array<Null<Int>> = [1, 5];
		var before = list[0]++;
		var after = ++list[1];
		list[0]--;
		t(before == 1 && after == 6 && list.join(",") == "1,6");
		// a captured Null<Int> is kept in such an array
		var index:Null<Int> = 0;
		var step = () -> {
			index++;
			return index;
		};
		step();
		t(step() == 2 && index == 2);
	}

	static function testObjectLiteralsForStructures() {
		// a plain value for an optional field: boxed as it is
		var size = 12.5;
		var count = 3;
		var options:FontOptions = {family: "f", size: size, count: count};
		var copy:Dynamic = Reflect.copy(options);
		t(options.size == 12.5 && options.count == 3 && copy.size == 12.5);
		t(describeFont({family: "f", size: size}) == "f/12.5/null");
		// cast to the structure with values that are not of its fields: still an object
		t(describeFont(cast {family: 12, size: "big"}) == "12/big/null");
		t(describeFont(cast {count: "two"}) == "null/null/two");
	}

	static function describeFont(o:FontOptions):String
		return Std.string(Reflect.field(o, "family")) + "/" + Std.string(Reflect.field(o, "size")) + "/" + Std.string(Reflect.field(o, "count"));

	static function testNativeBase() {
		// What Unity needs from a MonoBehaviour written in Haxe: it creates the object
		// itself (parameterless constructor) and finds its message methods by name.
		var type:cs.system.Type = cs.Syntax.code("typeof(global::haxe.root.Lifecycle)");
		t(cs.Syntax.code("{0}.GetConstructor(global::System.Type.EmptyTypes) != null", type));
		t(cs.Syntax.code("typeof(global::System.EventArgs).IsAssignableFrom({0})", type));
		var obj:Dynamic = cs.Syntax.code("global::System.Activator.CreateInstance({0})", type);
		t(obj != null);
		var found:Bool = cs.Syntax.code("{0}.GetMethod(\"OnApplicationFocus\", global::System.Reflection.BindingFlags.Instance | global::System.Reflection.BindingFlags.Public | global::System.Reflection.BindingFlags.NonPublic, null, new global::System.Type[] { typeof(bool) }, null) != null", type);
		t(found);
		cs.Syntax.code("{0}.GetMethod(\"OnApplicationFocus\", global::System.Reflection.BindingFlags.Instance | global::System.Reflection.BindingFlags.Public | global::System.Reflection.BindingFlags.NonPublic).Invoke({1}, new object[] { true })", type, obj);
		t(Lifecycle.focusCount == 1);
	}

	static function testSort() {
		var a = [3, 1, 2];
		a.sort((x, y) -> x - y);
		t(a.join(",") == "1,2,3");
		// the array is still an int array: these write to the typed storage
		a[0]++;
		a[1] += 10;
		t(a.join(",") == "2,12,3");

		var f = [2.5, 0.5, 1.5];
		f.sort((x, y) -> x < y ? -1 : x > y ? 1 : 0);
		f[0] += 1;
		t(f.join(",") == "1.5,1.5,2.5");

		var b = [true, false, true, false];
		b.sort((x, y) -> (x ? 1 : 0) - (y ? 1 : 0));
		t(b.join(",") == "false,false,true,true");

		// stable: elements with the same key keep their order (short and long arrays)
		for (n in [12, 500]) {
			var items = [for (i in 0...n) {k: i % 3, i: i}];
			items.sort((p, q) -> p.k - q.k);
			var ok = true;
			for (i in 1...n) {
				var p = items[i - 1], q = items[i];
				if (p.k > q.k || (p.k == q.k && p.i > q.i))
					ok = false;
			}
			t(ok);
		}

		var big = [for (i in 0...1000) (i * 7919) % 1000];
		big.sort((x, y) -> x - y);
		var sorted = true;
		for (i in 1...big.length)
			if (big[i - 1] > big[i])
				sorted = false;
		t(sorted);
		big[999] += 1;
		t(big[999] == 1000);

		var s = ["b", "a", "c"];
		s.sort((x, y) -> x < y ? -1 : x > y ? 1 : 0);
		t(s.join("") == "abc");
	}

	static function testArrayData() {
		var ints = [1, 2, 3];
		var rawInts = cs.ArrayData.ints(ints);
		t(rawInts.length >= 3 && rawInts[1] == 2);
		rawInts[1] = 20;
		t(ints[1] == 20);

		var floats:Array<Float> = [];
		floats.push(1.5);
		floats.push(2.5);
		var rawFloats = cs.ArrayData.floats(floats);
		t(rawFloats[0] + rawFloats[1] == 4);

		// an empty array that was never written to
		var empty:Array<Int> = [];
		t(cs.ArrayData.ints(empty) != null);
		empty.push(7);
		t(cs.ArrayData.ints(empty)[0] == 7);

		// filled through Dynamic: converted to int storage
		var viaDynamic:Array<Int> = [];
		var d:Dynamic = viaDynamic;
		d.push(4);
		d.push(5);
		t(cs.ArrayData.ints(viaDynamic)[1] == 5);
		t(viaDynamic[0] == 4 && viaDynamic.length == 2);

		// an abstract over Int
		var colors:Array<Rgba> = [new Rgba(0xFF00FF)];
		t(cs.ArrayData.ints(cast colors)[0] == 0xFF00FF);

		var strings = ["a", "b"];
		t(cs.ArrayData.objects(strings)[1] == "b");
		var bools = [true, false];
		t(cs.ArrayData.bools(bools)[0] && !cs.ArrayData.bools(bools)[1]);

		// an int array does not become an object array
		var refused = false;
		try {
			cs.ArrayData.objects(ints);
		} catch (e:Dynamic) {
			refused = true;
		}
		t(refused);
		t(ints[1] == 20);
	}

	static function testResourceFiles() {
		var names = haxe.Resource.listNames();
		names.sort(Reflect.compare);
		t(names.join("|") == "hello|some data/with any name");
		// embedded in the assembly by the project
		t(haxe.Resource.getString("hello") == "hello resource");
		var data = haxe.Resource.getBytes("some data/with any name");
		t(data != null && data.length == 8 && data.get(3) == 255 && data.get(7) == 0);
		t(haxe.Resource.getBytes("missing") == null);
		t(haxe.Resource.getString("missing") == null);
		t(cs.ResourceFiles.fileName("some data/with any name") == "some-x32data-x47with-x32any-x32name");

		// a host that stores the files itself
		var asked = [];
		cs.ResourceFiles.loader = fileName -> {
			asked.push(fileName);
			return fileName == "hello" ? haxe.io.Bytes.ofString("from the host") : null;
		};
		t(haxe.Resource.getString("hello") == "from the host");
		t(haxe.Resource.getBytes("some data/with any name") == null);
		t(asked.join("|") == "hello|some-x32data-x47with-x32any-x32name");
		cs.ResourceFiles.loader = null;
		t(haxe.Resource.getString("hello") == "hello resource");
	}

	static function testZip() {
		var text = [for (i in 0...200) "some text to compress " + (i % 7)].join("\n");
		var data = haxe.io.Bytes.ofString(text);
		for (level in [0, 1, 6, 9]) {
			var packed = haxe.zip.Compress.run(data, level);
			// (level 0 is not checked: Mono compresses whatever the level asked)
			t(level == 0 || packed.length < data.length >> 2);
			t(haxe.zip.Uncompress.run(packed).compare(data) == 0);
			// also read by the inflate written in Haxe: the header and the checksum are valid
			t(haxe.zip.InflateImpl.run(new haxe.io.BytesInput(packed)).compare(data) == 0);
		}
		t(haxe.zip.Uncompress.run(haxe.zip.Compress.run(haxe.io.Bytes.alloc(0), 9)).length == 0);
		// data compressed by zlib itself
		var fromZlib = haxe.io.Bytes.ofHex("78dacb48ac4855a8ca2c50c84067000080bd098c");
		t(haxe.zip.Uncompress.run(fromZlib).toString() == "haxe zip haxe zip haxe zip");
		var refused = false;
		try {
			haxe.zip.Uncompress.run(haxe.io.Bytes.ofString("not zlib data"));
		} catch (e:Dynamic) {
			refused = true;
		}
		t(refused);
	}

	static function testCreateInstanceOptionalArgs() {
		// Arguments that are all optional: none given, they take their default values
		var o:OptionalArgs = Type.createInstance(OptionalArgs, []);
		t(o != null && o.a == null && o.b == "x" && o.c == 3);
		var p:OptionalArgs = Type.createInstance(OptionalArgs, [5]);
		t(p.a == 5 && p.b == "x" && p.c == 3);
		var q:OptionalArgs = Type.createInstance(OptionalArgs, [5, "y", 9]);
		t(q.a == 5 && q.b == "y" && q.c == 9);
	}

	// ---------------------------------------------------------------------
	// Generics and variance
	// ---------------------------------------------------------------------

	static function testConstrainedTypeParam() {
		var p = new Particles<FastEmitter>(new FastEmitter());
		t(p.go() == 7);
		t(p.emitter.speed == 2);
		// an inline method of the constraint: its `this` becomes a local typed by the type parameter
		p.range(3);
		t(p.emitter.speed == 3 && p.emitter.maxSpeed == 3);
		p.range(4, 9);
		t(p.emitter.speed == 4 && p.emitter.maxSpeed == 9);
	}

	static function testArrayVariance() {
		var strings:Array<String> = ["a", "b"];
		var anys:Array<Any> = cast strings;
		t(sameArrays(anys, cast ["a", "b"]));
		// same object, not a copy
		anys.push("c");
		t(strings.length == 3 && strings[2] == "c");

		var ints:Array<Int> = [1, 2];
		var dyn:Array<Dynamic> = cast ints;
		t(dyn[1] == 2);
		dyn.push(3);
		t(ints.length == 3);

		var sprites:Array<Sprite<Any>> = [];
		sprites.push(cast new Sprite<Int>(4));
		sprites.push(cast new Sprite<String>("x"));
		var total = 0;
		for (s in sprites)
			total += s.update();
		t(total == 2);
	}

	static function sameArrays(a:Array<Any>, b:Array<Any>):Bool {
		if (a.length != b.length)
			return false;
		for (i in 0...a.length)
			if (a[i] != b[i])
				return false;
		return true;
	}

	static function testVectorInGenericClass() {
		var ints = new Slots<Int>(2);
		ints.set(0, 5);
		ints.resize(8);
		ints.set(7, 9);
		t(ints.get(0) == 5 && ints.get(7) == 9);

		var strings = new Slots<String>(2);
		strings.set(1, "a");
		strings.resize(4);
		t(strings.get(1) == "a" && strings.get(3) == null);

		var floats = new Slots<Float>(1);
		floats.set(0, 1.5);
		floats.resize(2);
		t(floats.get(0) == 1.5);
	}

	static function testUnitTask() {
		var task = new Task<Unit>();
		var any:Task<Dynamic> = cast task;
		t(any == cast task);
		// the same object: completing one completes the other
		any.done = true;
		t(task.done);
		task.result = Unit.unit;
		t(any.result != null);
	}

	static function testNestedClosureTypeParam() {
		var make = nested([1, 2, 3]);
		t(make()().join(",") == "1,2,3");
		var makeS = nested(["a"]);
		t(makeS()().join(",") == "a");
	}

	static function nested<I>(items:Array<I>):() -> (() -> Array<I>) {
		return () -> {
			return () -> {
				var r:Array<I> = [];
				for (i in items)
					r.push(i);
				return r;
			};
		};
	}

	static function testUnderscoreParams() {
		var table = new Table<String>();
		t(table.onClick(1, "row", "x") == "row");
		var handler:(Int, String, String) -> String = table.onClick;
		t(handler(0, "r", "") == "r");
	}

	static function testCovariantOverride() {
		var g = new GenNode<Int>(3);
		var same:GenNode<Int> = g.at(0);
		t(same == g && same.value == 3);
		var base:BaseNode = g;
		t(base.at(0) == g);
		var leaf = new LeafNode();
		t(leaf.at(0).name() == "leaf");
		var deep = new DeepLeafNode();
		t(deep.at(0).name() == "deep");
		// what the override returns is used as its own type: a method of the child, a return
		t(leaf.at(0).leafOnly() == 1);
		t(deep.at(0).at(1).deepOnly() == 2);
		t(sameLeaf(leaf).leafOnly() == 1);
	}

	static function sameLeaf(leaf:LeafNode):LeafNode {
		return leaf.at(0);
	}

	static function testCapturedNullTypeParam() {
		var a = 0, b = 0;
		edges(() -> 4, (top, right) -> {
			a = top;
			b = right == null ? -1 : right;
		});
		t(a == 4 && b == -1);
		var s = "";
		edges(() -> "v", (top, right) -> s = top + (right == null ? "!" : right));
		t(s == "v!");
		var f = 0.0;
		edges(() -> 1.5, (top, right) -> f = top);
		t(f == 1.5);
	}

	static function edges<T>(value:() -> T, done:(Null<T>, Null<T>) -> Void):Void {
		var top:Null<T> = null, right:Null<T> = null;
		var set = () -> {
			top = value();
		};
		set();
		done(top, right);
	}

	static function testInterfaceVariance() {
		var options:Array<IOption<Any>> = [];
		options.push(cast new IntOption(3));
		options.push(cast new StringOption("s"));
		t(options[0].read() == 3);
		t(options[1].read() == "s");
		t(options[0].id + options[1].id == 3);
		var r = options[0].apply(5);
		t(r.changed && r.value == 5);
	}

	static function testInterfaceNullParam() {
		var m:Measurer<Context> = new ContextMeasurer();
		t(m.measure(null) == -1);
		t(m.measure(new Context(2)) == 2);
	}

	static function testGenericConstructor() {
		var c = new Compact([1, 2, 3], (a, b) -> a == b);
		t(c.n == 3);
		var d = new Compact(["a"], (a, b) -> a == b);
		t(d.n == 1);
	}

	static function testGenericArrayCopy() {
		var ints = [1, 2, 3, 4];
		var into = [0, 0, 0, 0];
		arrayCopy(ints, 1, into, 0, 3);
		t(into.join(",") == "2,3,4,0");
		var floats = [1.5, 2.5];
		var intoF = [0.0, 0.0];
		arrayCopy(floats, 0, intoF, 0, 2);
		t(intoF.join(",") == "1.5,2.5");
		var objs:Array<Dynamic> = ["a", 1];
		var intoO:Array<Dynamic> = [null, null];
		arrayCopy(objs, 0, intoO, 0, 2);
		t(intoO[0] == "a" && intoO[1] == 1);
		t(maxOf(1, 2) == 2 && maxOf(1.5, 0.5) == 1.5);
	}

	static function arrayCopy<T>(src:Array<T>, srcPos:Int, dst:Array<T>, dstPos:Int, len:Int):Void {
		for (i in 0...len)
			dst[dstPos + i] = src[srcPos + i];
	}

	static function maxOf<T:Float>(a:T, b:T):T {
		return a > b ? a : b;
	}

	// ---------------------------------------------------------------------
	// Language and std
	// ---------------------------------------------------------------------

	static function testRest() {
		var list = nullInts(1, null, 3);
		t(list.length == 3 && list[0] == 1 && list[1] == null && list[2] == 3);
		var fns = functions(i -> i > 0, i -> i < 0);
		t(fns.length == 2 && fns[0](1) && !fns[1](1));
		var exprs = nodes(new Context(1), null);
		t(exprs.length == 2 && exprs[0].size == 1 && exprs[1] == null);
	}

	static function nullInts(...values:Null<Int>):Array<Null<Int>> {
		return values.toArray();
	}

	static function functions(...values:Int->Bool):Array<Int->Bool> {
		return values.toArray();
	}

	static function nodes(...values:Null<Context>):Array<Null<Context>> {
		return values.toArray();
	}

	static function testAnyBool() {
		var yes:Any = true;
		var no:Any = false;
		var other:Any = 1;
		t(yes == true);
		t(!(no == true));
		t(no == false);
		t(!(other == true));
		var d:Dynamic = true;
		t(d == true);
	}

	static function testCulture() {
		// A culture with a decimal comma
		cs.Syntax.code("var previous = global::System.Globalization.CultureInfo.CurrentCulture");
		cs.Syntax.code("global::System.Globalization.CultureInfo.CurrentCulture = new global::System.Globalization.CultureInfo(\"fr-FR\")");
		var half = 1.5;
		t(Std.string(half) == "1.5");
		t("" + half == "1.5");
		t('${half}' == "1.5");
		t(Std.parseFloat("2.5") == 2.5);
		var d:Dynamic = half;
		t(Std.string(d) == "1.5");
		t([half].join(",") == "1.5");
		t(haxe.Json.stringify({v: half}) == '{"v":1.5}');
		t(haxe.Json.parse('{"v":3.25}').v == 3.25);
		var single:Single = 0.5;
		t(Std.string(single) == "0.5");
		var buf = new StringBuf();
		buf.add(half);
		t(buf.toString() == "1.5");
		cs.Syntax.code("global::System.Globalization.CultureInfo.CurrentCulture = previous");
	}

	static function testSmallIntegers() {
		var n = 300;
		var u16:cs.UInt16 = n;
		var back:Int = u16;
		t(back == 300);
		var native = new cs.NativeArray<cs.UInt16>(2);
		native[0] = n + 1;
		t((native[0] : Int) == 301);
		var c:cs.Char16 = cs.Syntax.code("'A'");
		var code:Int = c;
		t(code == 65);
		var bytes = new cs.NativeArray<cs.UInt8>(1);
		bytes[0] = 200;
		t((bytes[0] : Int) == 200);
		var i16:cs.Int16 = -5;
		t((i16 : Int) == -5);

		var uints:Array<UInt> = [1, 2];
		var ints:Array<Int> = cast uints;
		t(ints[1] == 2);
	}

	static function testSwitchOnClass() {
		t(className(new haxe.ds.StringMap<Int>()) == "string map");
		t(className(new haxe.ds.IntMap<Int>()) == "int map");
		t(className(new Context(1)) == "other");
	}

	static function className(value:Dynamic):String {
		return switch Type.typeof(value) {
			case TClass(c):
				if (c == haxe.ds.StringMap) "string map" else if (c == haxe.ds.IntMap) "int map" else "other";
			default: "none";
		}
	}

	static function testNames() {
		var f = new Names();
		t(f.finalize() == 1);
		t(f.unsafe(true) == 2);
		t(f.lock(3) == 3);
		t(f.params == 4);
		t(Reflect.field(f, "params") == 4);
	}

	static function testBreakInSwitch() {
		var i = 0;
		var seen = [];
		do {
			switch i {
				case 2:
					break;
				default:
					seen.push(i);
			}
			i++;
		} while (i < 5);
		t(seen.join(",") == "0,1");

		var out = [];
		for (j in 0...5) {
			switch j {
				case 1:
					continue;
				case 3:
					break;
				default:
			}
			out.push(j);
		}
		t(out.join(",") == "0,2");
	}

	static function testInlineLocals() {
		t(branchy(true) == 6);
		t(branchy(false) == 12);
	}

	static function branchy(first:Bool):Int {
		var r = if (first) sumTo(3) else sumTo(3) * 2;
		return r;
	}

	static inline function sumTo(n:Int):Int {
		var total = 0;
		var i = 1;
		while (i <= n) {
			total += i;
			i++;
		}
		return total;
	}

	static function testRethrow() {
		var marked = false;
		var caught:Dynamic = null;
		try {
			try {
				throw "first";
			} catch (e:Dynamic) {
				marked = true;
				cs.Syntax.code("throw");
			}
		} catch (e:Dynamic) {
			caught = e;
		}
		t(marked && caught == "first");

		caught = null;
		try {
			try {
				throw new haxe.Exception("second");
			} catch (e:haxe.Exception) {
				throw e;
			}
		} catch (e:haxe.Exception) {
			caught = e.message;
		}
		t(caught == "second");
	}

	static function testZeroInit() {
		var a = new Array<Int>();
		a[15] = 1;
		t(a.length == 16 && a[3] == 0 && a[15] == 1);
		var v = new Vector<Int>(4);
		t(v[2] == 0);
		var fv = new Vector<Float>(2);
		t(fv[1] == 0);
		var f = new Array<Float>();
		f[3] = 2.5;
		t(f[0] == 0 && f[3] == 2.5);
	}

	static function testMaps() {
		var im = new Map<Int, String>();
		im.set(1, "a");
		im.set(2, "b");
		var keys = 0, values = "";
		for (k => v in im) {
			keys += k;
			values += v;
		}
		t(keys == 3 && values.length == 2);
		var sm = new Map<String, Int>();
		sm.set("x", 5);
		for (k in sm.keys())
			t(k == "x");
		for (v in sm)
			t(v == 5);
		var om = new Map<Context, Int>();
		var key = new Context(1);
		om.set(key, 7);
		t(om.get(key) == 7 && om.exists(key));
	}

	static function testReflectiveGenericCall() {
		// A generic interface method called through its erased form and through reflection.
		// (Passing a value of another type than the option's, a String to an Int option, is
		// converted by the typed implementation and fails: code that does it on purpose
		// has to go around the typed method.)
		var option:IOption<Any> = cast new IntOption(1);
		var raw:Dynamic = {value: 7};
		var r = option.apply(Reflect.field(raw, "value"));
		t(r.changed && r.value == 7);
		var viaReflect:Dynamic = Reflect.callMethod(option, Reflect.field(option, "apply"), [8]);
		t(viaReflect.value == 8);
		var text:IOption<Any> = cast new StringOption("a");
		t(text.apply("b").value == "b");
	}

	static function testAssignPreparedValue() {
		// The value needs statements before the assignment (a Null<Int> parameter in a
		// conditional), and the target is not a plain variable or field.
		var a = 0, b = 0;
		pair((top, right) -> {
			a = top;
			b = right == null ? -1 : right;
		});
		t(a == 4 && b == -1);
		var c = 0;
		pair((top, right) -> c = right == null ? -1 : right);
		t(c == -1);
		var list = [0, 0];
		var floats = [0.0];
		var objects:Array<String> = [null];
		var structure = {x: 0};
		var map = new Map<String, Int>();
		var prop = new WithProperty();
		pair((top, right) -> {
			list[1] = right == null ? -2 : right;
			floats[0] = right == null ? 1.5 : right;
			objects[0] = right == null ? "none" : "some";
			structure.x = right == null ? -3 : right;
			map["k"] = right == null ? -4 : right;
			prop.value = right == null ? -5 : right;
		});
		t(list[1] == -2 && floats[0] == 1.5 && objects[0] == "none");
		t(structure.x == -3 && map["k"] == -4 && prop.value == -5);
	}

	static function pair(done:(Null<Int>, Null<Int>) -> Void) {
		done(4, null);
	}
}

enum Color {
	Red;
	Green;
	Rgb(r:Int, g:Int, b:Int);
}

@:keep class WithStatics {
	public static var counter = 12;

	public var value:Int;

	public function new(value:Int) {
		this.value = value;
	}
}

@:keep class PrivateCtor {
	public var ok = true;

	function new() {}
}

@:classCode('
public static int nativeTwice(int value) {
    return value * 2;
}

// An iterator method: Haxe has no yield
public static global::System.Collections.IEnumerator steps() {
    yield return 1;
    yield return 2;
#if NEVER_DEFINED
    yield return 99;
#endif
    yield return 3;
}
')
class NativeMembers {
	public static function twice(value:Int):Int {
		return cs.Syntax.code("global::haxe.root.NativeMembers.nativeTwice({0})", value);
	}

	public static function collect(into:Array<Int>):Void {
		var e:Dynamic = cs.Syntax.code("global::haxe.root.NativeMembers.steps()");
		while (cs.Syntax.code("((global::System.Collections.IEnumerator){0}).MoveNext()", e))
			record(into, cs.Syntax.code("(int)((global::System.Collections.IEnumerator){0}).Current", e));
	}

	@:keep static function record(into:Array<Int>, value:Int):Void {
		into.push(value);
	}
}

/** Like a MonoBehaviour: the host creates it and calls its methods by name. **/
@:keep
class Lifecycle extends cs.system.EventArgs {
	public static var focusCount = 0;

	function OnApplicationFocus(focused:Bool):Void {
		if (focused)
			focusCount++;
	}
}

extern class HostHelper {
	var calls:Int;
	function new();
	static function twice(value:Int):Int;
	function next():Int;
}

extern enum HostMode {
	Off;
	On;
}

class KeepsHelper {
	public var helper:HostHelper;

	public function new(helper:HostHelper) {
		this.helper = helper;
	}
}

final class SealedNode extends BaseNode {
	public var doubled:Int;

	public function new(value:Int) {
		var computed = value * 2;
		super();
		doubled = computed;
	}
}

@:keep class ManyArgs {
	public static var total = 0;

	public function new() {}

	public function sum(a:Int, b:Int, c:Int, d:Int, e:Int, f:Int, g:Int, h:Int, i:Int, j:Int, k:Float, s:String):String {
		return (a + b + c + d + e + f + g + h + i + j + k) + s;
	}

	public static function count(a:Int, b:Int, c:Int, d:Int, e:Int, f:Int, g:Int, h:Int, i:Int, j:Int, add:Bool):Void {
		var n = a + b + c + d + e + f + g + h + i + j;
		total += add ? n : -n;
	}
}

class TexBase {
	public var item:String;
	public var density:Float;

	public function new(item:String, density:Float) {
		this.item = item;
		this.density = density;
	}
}

class TexMaker {
	public var count = 0;

	public function new() {}

	inline public function make(width:Int, height:Int, depth:Bool, antialiasing:Int):String {
		if (antialiasing < 1)
			antialiasing = 1;
		var r:String = null;
		untyped __cs__('var native = new global::System.Text.StringBuilder().Append({0}).Append("x").Append({1})', width, height);
		if (depth)
			r = untyped __cs__('native.ToString()') + " d" + antialiasing;
		else
			r = untyped __cs__('native.ToString()') + " " + antialiasing;
		count++;
		return r;
	}
}

class RenderTex extends TexBase {
	public static var maker = new TexMaker();

	public var depth:Bool;
	public var antialiasing:Int;
	public var flag = false;

	public function new(width:Float, height:Float, density:Float = -1, depth:Bool = true, antialiasing:Int = 0) {
		if (density == -1)
			density = 2;
		this.depth = depth;
		this.antialiasing = antialiasing;
		var backendItem = maker.make(Math.round(width * density), Math.round(height * density), depth, antialiasing);
		super(backendItem, density);
		flag = true;
	}
}

class SubRenderTex extends RenderTex {
	public var extra:Int;

	public function new(size:Int) {
		var doubled = size * 2;
		super(size, size, doubled / size);
		extra = size;
	}
}

class PackRect {
	public var w:Float;
	public var h:Float;
	public var flipped:Bool;

	public inline function new(x:Float = 0, y:Float = 0, width:Float = 0, height:Float = 0, flipped:Bool = false) {
		w = width;
		h = height;
		this.flipped = flipped;
	}
}

class PlainRect {
	public var w:Float;
	public var h:Float;

	public function new(x:Float = 0, y:Float = 0, width:Float = 0, height:Float = 0) {
		w = width;
		h = height;
	}
}

class Packer {
	public var inlined:PackRect;
	public var plain:PlainRect;

	public function new(width:Int = 0, height:Int = 0) {
		inlined = new PackRect(0, 0, width, height);
		plain = new PlainRect(0, 0, width, height);
	}
}

class Entry {
	public var alpha:Float = 2;

	public function new() {}
}

class Listener {
	public var willEmit:Dynamic = null;

	public function new() {}
}

class PhysBody {
	public var rot:Float = 0;
	public var seen = "";

	public function new() {}

	inline public function setRotation(rotation:Float):Void {
		var rotation = rotation * 2;
		rot = rotation;
	}
}

class Phys {
	public var body:PhysBody;

	public function new(rotation:Float, ?shape:String) {
		if (shape == null)
			shape = "box";
		body = new PhysBody();
		body.seen = shape;
		body.setRotation(rotation);
	}
}

class GuardedBase {
	public static var internalAlloc = false;

	public function new() {
		if (!internalAlloc)
			throw "Cannot instantiate a GuardedBase";
	}
}

class GuardedChild extends GuardedBase {
	public var value:Int;

	public function new(value:Int) {
		GuardedBase.internalAlloc = true;
		super();
		GuardedBase.internalAlloc = false;
		this.value = value;
	}
}

class Seeds {
	public static var SEED:haxe.Int64 = haxe.Int64.make(0x243F6A88, 0x85A308D3);
}

class StyleBox {
	public var style:StyleBox;

	public function new(style:StyleBox) {
		this.style = style;
	}
}

class Underscores {
	public var kept:String;

	public function new(_:Int, _:String) {
		kept = _;
	}

	public static function second(_:Int, _:String):String {
		return _;
	}

	public static function make(_:String, n:Int):Underscores {
		return new Underscores(n, Std.string(n));
	}
}

class Element {
	public var document:String;
	public var id:Int;
	public var setupCalls = 0;
	public var kind = "";

	public function new(document:String, id:Int) {
		this.document = document;
		this.id = id;
	}

	public function setup():Void {
		setupCalls++;
	}
}

class GradientElement extends Element {
	public function new(document:String, id:Int) {
		super(document, id);
		// a method that a child class can override
		setup();
	}

	override public function setup():Void {
		super.setup();
		kind = "gradient";
	}
}

class Slot {
	public var model:Dynamic;
	public var alive = true;

	public function new(model:Dynamic) {
		this.model = model;
	}
}

abstract Strong<T>(T) to T {}

abstract Weak<T>(Slot) {
	public inline function new(slot:Slot) {
		this = slot;
	}

	public function upgrade():Null<Strong<T>> {
		return this.alive ? cast this.model : null;
	}
}

class Keyed<T> {
	public var entity:Strong<T>;

	public function new(entity:Strong<T>) {
		this.entity = entity;
	}
}

enum abstract ErrorCode(Int) {
	var TooSmall = 1;
	var TooBig = 2;

	public function message():String {
		return switch (cast this : ErrorCode) {
			case TooSmall: "too small";
			case TooBig: "too big";
		}
	}
}

class ErrorHolder {
	public var error:Null<ErrorCode> = null;

	public function new() {}

	public function check():String {
		if (error != null)
			return error.message();
		return "none";
	}
}

class Emitter {
	public var speed:Float = 1;

	public function new() {}

	public function emit():Int {
		return 3;
	}

	public var maxSpeed:Float = 1;

	inline public function speedRange(min:Float, ?max:Float):Void {
		this.speed = min;
		if (max == null) {
			this.maxSpeed = min;
		} else {
			this.maxSpeed = max;
		}
	}
}

class FastEmitter extends Emitter {
	override public function emit():Int {
		return 5;
	}
}

class Particles<T:Emitter> {
	public var emitter:T;

	public function new(emitter:T) {
		this.emitter = emitter;
	}

	public function go():Float {
		emitter.speed = 2;
		return emitter.emit() + emitter.speed;
	}

	inline public function range(min:Float, ?max:Float):Void {
		emitter.speedRange(min, max);
	}
}

class Sprite<T> {
	public var data:T;

	public function new(data:T) {
		this.data = data;
	}

	public function update():Int {
		return 1;
	}
}

class Slots<V> {
	public var values(default, null):Vector<V>;

	public function new(size:Int) {
		values = new Vector<V>(size);
	}

	public function resize(size:Int) {
		var previous = values;
		values = new Vector<V>(size);
		for (i in 0...previous.length)
			values.set(i, previous.get(i));
	}

	public function get(i:Int):V {
		return values.get(i);
	}

	public function set(i:Int, v:V):Void {
		values.set(i, v);
	}
}

enum abstract Unit(Int) {
	var unit = 0;
}

class Task<T> {
	public var result:T;
	public var done = false;

	public function new() {}
}

class Table<T> {
	public function new(?_:Int, ?_:String) {}

	public function onClick(_:Int, row:T, _:String):T {
		return row;
	}
}

class BaseNode {
	public function new() {}

	public function at(i:Int):BaseNode {
		return this;
	}

	public function name():String {
		return "base";
	}
}

class GenNode<T> extends BaseNode {
	public var value:T;

	public function new(value:T) {
		super();
		this.value = value;
	}

	override public function at(i:Int):GenNode<T> {
		return this;
	}
}

class LeafNode extends BaseNode {
	override public function at(i:Int):LeafNode {
		return this;
	}

	override public function name():String {
		return "leaf";
	}

	public function leafOnly():Int {
		return 1;
	}
}

class DeepLeafNode extends LeafNode {
	override public function at(i:Int):DeepLeafNode {
		return this;
	}

	override public function name():String {
		return "deep";
	}

	public function deepOnly():Int {
		return 2;
	}
}

typedef ApplyResult<V> = {
	var value:V;
	var changed:Bool;
}

interface IOption<V> {
	var id:Int;
	function read():V;
	function apply(update:V):ApplyResult<V>;
}

class IntOption implements IOption<Int> {
	public var id = 1;

	var value:Int;

	public function new(value:Int) {
		this.value = value;
	}

	public function read():Int {
		return value;
	}

	public function apply(update:Int):ApplyResult<Int> {
		return Options.apply(value, update);
	}
}

class StringOption implements IOption<String> {
	public var id = 2;

	var value:String;

	public function new(value:String) {
		this.value = value;
	}

	public function read():String {
		return value;
	}

	public function apply(update:String):ApplyResult<String> {
		return Options.apply(value, update);
	}
}

class Options {
	public static function apply<V>(value:Null<V>, update:V):ApplyResult<V> {
		return {value: update, changed: value != update};
	}
}

class Context {
	public var size:Float;

	public function new(size:Float) {
		this.size = size;
	}
}

interface Measurer<T> {
	function measure(context:Null<T>):Float;
}

class ContextMeasurer implements Measurer<Context> {
	public function new() {}

	public function measure(context:Null<Context>):Float {
		return context == null ? -1 : context.size;
	}
}

class Compact {
	public var n:Int;

	public function new<T>(old:Array<T>, same:(T, T) -> Bool) {
		n = 0;
		for (item in old)
			if (same(item, item))
				n++;
	}
}

abstract Rgba(Int) {
	public inline function new(value:Int) {
		this = value;
	}
}

@:keep class OptionalArgs {
	public var a:Null<Int>;
	public var b:String;
	public var c:Int;

	public function new(?a:Int, b:String = "x", c:Int = 3) {
		this.a = a;
		this.b = b;
		this.c = c;
	}
}

class WithProperty {
	public var value(get, set):Int;

	var stored = 0;

	public function new() {}

	function get_value()
		return stored;

	function set_value(v:Int)
		return stored = v;
}

class Names {
	public var params = 4;

	public function new() {}

	public function finalize():Int {
		return 1;
	}

	public function unsafe(unsafe:Bool):Int {
		return unsafe ? 2 : 0;
	}

	public function lock(event:Int):Int {
		return event;
	}
}

abstract NodeId(Int) {
	public inline function new(v:Int)
		this = v;

	public inline function toInt():Int
		return this;
}

abstract Ratio(Float) {
	public inline function new(v:Float)
		this = v;

	public inline function toFloat():Float
		return this;
}

class WithNullIndex {
	public var index(get, set):Null<Int>;

	var stored:Null<Int> = null;

	public function new() {}

	function get_index():Null<Int>
		return stored;

	function set_index(v:Null<Int>):Null<Int>
		return stored = v;
}

class Grouping {
	public static inline function scale(a:Int, b:Int):Int
		return a * b;

	public static inline function minus(a:Int, b:Int):Int
		return a - b;
}

class Holder<T> {
	var value:T;

	public function new() {}

	public function put(v:T):Void
		value = v;

	public function get():T
		return value;

	public function isEmpty():Bool
		return value == null;

	public function index(some:Bool):Null<Int>
		return some ? 3 : null;
}

class KeyResolver {
	public final resolver:(Int) -> Null<NodeId>;
	public final ints:(Int) -> Null<Int>;

	public function new() {
		resolver = x -> x > 0 ? new NodeId(x) : null;
		ints = x -> x > 0 ? x : null;
	}

	public function key(x:Int):Null<NodeId>
		return x > 0 ? new NodeId(x) : null;
}

class BaseEmitter<T> {
	public var fired:Array<T> = [];

	public function new() {}

	public function fire(event:T):Void {
		fired.push(event);
	}
}

class QueueingEmitter extends BaseEmitter<String> {
	public var paused = true;
	public var queued:Array<String> = [];

	// `event` is a C# keyword, and the argument is an object in the parent
	override public function fire(event:String):Void {
		if (paused)
			queued.push(event);
		else
			super.fire(event);
	}
}

interface IPanelLayout {
	function size():Int;
}

interface IPanelModel {
	final name:String;
	final layout:IPanelLayout;
	var count(default, null):Int;
}

class PanelLayout implements IPanelLayout {
	public function new() {}

	public function size():Int
		return 3;

	public function extra():Int
		return 4;
}

class PanelModel implements IPanelModel {
	public final name:String;
	public final layout:PanelLayout;
	public var count(default, null):Int = 2;

	public function new() {
		name = "m";
		layout = new PanelLayout();
	}
}

class EncodedUri {
	public function new() {}

	public function toString(skipEncoding:Bool = false):String
		return skipEncoding ? "raw" : "encoded";
}

class TokenStore {
	public function new() {}

	public function toString(start:Int):String
		return "t" + start;
}

abstract class BaseCommand {
	public final id:String;
	public var registered = false;

	public function new(opts:{id:String}) {
		this.id = opts.id;
		register();
	}

	function register() {
		registered = true;
	}
}

class MultiCommand extends BaseCommand {
	final implementations:Array<String> = [];

	public function add(s:String)
		implementations.push(s);

	public function count()
		return implementations.length;
}

class CountedBase {
	public var total:Int;

	public function new(a:Int, b:String = "x") {
		total = a + b.length;
	}
}

@:keep class CountedChild extends CountedBase {
	var list:Array<Int> = [1];

	public function len()
		return list.length;
}

typedef FontOptions = {?family:String, ?size:Float, ?count:Int};

class ValueOption<V> {
	public var fallback:V;

	public function new(fallback:V)
		this.fallback = fallback;

	public function validate(input:Any):V
		return fallback;

	public function pick(value:V):V
		return value;
}

class TextOption extends ValueOption<String> {
	public function new()
		super("d");

	override public function validate(input:Any):String
		return input == true ? "on" : Std.string(input);
}

class NumberOption extends ValueOption<Int> {
	public function new()
		super(1);

	override public function validate(input:Any):Int
		return input == true ? 5 : 2;

	override public function pick(value:Int):Int
		return value + 1;
}

class NullableProps {
	public var tabSize(get, set):Null<Int>;
	public var readOnly(get, never):Null<Bool>;
	public var plain:Null<Int> = null;

	var stored:Null<Int> = null;

	public function new() {}

	function get_tabSize():Null<Int>
		return stored;

	function set_tabSize(v:Null<Int>):Null<Int>
		return stored = v;

	function get_readOnly():Null<Bool>
		return stored == null ? null : stored > 1;

	public function make():Null<Int>
		return stored;
}

class RatioOption extends ValueOption<Float> {
	public function new()
		super(0.5);

	override public function pick(value:Float):Float
		return value * 2;
}

class CallCounter {
	public var calls = 0;
	public var value(get, never):Null<Int>;

	var stored:Null<Int>;

	public function new(stored:Null<Int>)
		this.stored = stored;

	function get_value():Null<Int> {
		calls++;
		return stored;
	}

	public function next():Null<Int> {
		calls++;
		return stored;
	}
}
