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
}

class DeepLeafNode extends LeafNode {
	override public function at(i:Int):DeepLeafNode {
		return this;
	}

	override public function name():String {
		return "deep";
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
