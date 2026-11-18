/**
	Allocation checks for the C# target: each case runs a loop and measures the bytes
	allocated on the managed heap. A case that must not allocate fails when it does.
**/
typedef Point = {x:Int, y:Int};
typedef Options = {name:String, ?size:Int, ?ratio:Float};

class Counter {
	public var total:Int = 0;

	public function new() {}

	public function add(x:Int):Void
		total += x;

	public function opt(x:Int, ?y:Int):Int
		return y == null ? x : x + y;
}

@:generic class Box<T> {
	public var value:T;

	public function new(v:T)
		value = v;

	public function get():T
		return value;
}

class IntRange {
	var i:Int;
	var max:Int;

	public function new(max:Int) {
		i = 0;
		this.max = max;
	}

	public function hasNext():Bool
		return i < max;

	public function next():Int
		return i++;
}

class Main {
	static inline var N = 10000;
	static var failures = 0;
	static var sink:Float = 0;

	static inline function allocated():Float
		return cs.Syntax.code("(double) global::System.GC.GetAllocatedBytesForCurrentThread()");

	/** Bytes allocated per iteration by `f`, which runs a loop of N iterations. **/
	static function perIteration(f:Void->Void):Float {
		f(); // warm up
		var before = allocated();
		f();
		return (allocated() - before) / N;
	}

	/** `maxBytes` is the allowance per iteration. **/
	static function check(name:String, maxBytes:Float, f:Void->Void) {
		var bytes = perIteration(f);
		var ok = bytes <= maxBytes;
		if (!ok)
			failures++;
		Sys.println((ok ? "ok   " : "FAIL ") + name + ": " + Math.round(bytes * 10) / 10 + " bytes per iteration (max " + maxBytes + ")");
	}

	static function callInt(f:Int->Int):Int {
		var sum = 0;
		for (i in 0...N)
			sum += f(i);
		return sum;
	}

	static function callFloat(f:Float->Float):Float {
		var sum = 0.0;
		for (i in 0...N)
			sum += f(i);
		return sum;
	}

	static function callBool(f:Bool->Bool):Int {
		var sum = 0;
		for (i in 0...N)
			if (f(i & 1 == 0))
				sum++;
		return sum;
	}

	static function callVoid(f:Int->Void):Void {
		for (i in 0...N)
			f(i);
	}

	static function twice(x:Int):Int
		return x * 2;

	static function readPoint(p:Point):Int {
		var sum = 0;
		for (i in 0...N)
			sum += p.x + p.y;
		return sum;
	}

	static function writePoint(p:Point):Void {
		for (i in 0...N)
			p.x = i;
	}

	static function readOptions(o:Options):Float {
		var sum = 0.0;
		for (i in 0...N) {
			if (o.size != null)
				sum += o.size;
			if (o.ratio != null)
				sum += o.ratio;
		}
		return sum;
	}

	static function line(?pos:haxe.PosInfos):Int
		return pos.lineNumber;

	static function sumIterator(it:Iterator<Int>):Int {
		var sum = 0;
		for (v in it)
			sum += v;
		return sum;
	}

	static function main() {
		// ---- must not allocate
		check("typed call, static method (Int)", NONE, () -> sink = callInt(twice));
		var k = 3;
		check("typed call, local closure (Int)", NONE, () -> sink = callInt(x -> x + k));
		check("typed call, local closure (Float)", NONE, () -> sink = callFloat(x -> x * 0.5));
		check("typed call, local closure (Bool)", NONE, () -> sink = callBool(b -> !b));
		var counter = new Counter();
		var add = counter.add;
		check("typed call, method closure read once", NONE, () -> callVoid(add));
		var func = new cs.system.Func_2<Int, Int>(twice);
		check(".NET delegate call", NONE, () -> {
			var sum = 0;
			for (i in 0...N)
				sum += func.Invoke(i);
			sink = sum;
		});
		var ints = [for (i in 0...16) i];
		check("Array<Int> read and write", NONE, () -> {
			var sum = 0;
			for (i in 0...N) {
				ints[i & 15] = i;
				sum += ints[(i + 1) & 15];
			}
			sink = sum;
		});
		var floats = [for (i in 0...16) i * 1.5];
		check("Array<Float> read and write", NONE, () -> {
			var sum = 0.0;
			for (i in 0...N) {
				floats[i & 15] = i;
				sum += floats[(i + 1) & 15];
			}
			sink = sum;
		});
		check("Null<Int> operations", NONE, () -> {
			var sum = 0;
			for (i in 0...N) {
				var n:Null<Int> = (i & 1 == 0) ? i : null;
				if (n != null)
					sum += n;
			}
			sink = sum;
		});
		check("method with an optional argument", NONE, () -> {
			var sum = 0;
			for (i in 0...N)
				sum += counter.opt(i) + counter.opt(i, 2);
			sink = sum;
		});
		var box = new Box<Int>(4);
		check("@:generic class with a value type", NONE, () -> {
			var sum = 0;
			for (i in 0...N) {
				box.value = i;
				sum += box.get();
			}
			sink = sum;
		});

		// ---- structures
		var p:Point = {x: 1, y: 2};
		check("structure field read", NONE, () -> sink = readPoint(p));
		check("structure field write", NONE, () -> writePoint(p));
		check("structure field compound assignment and increment", NONE, () -> {
			for (i in 0...N) {
				p.x += i;
				p.y++;
				--p.x;
			}
			sink = p.x;
		});
		var points:Array<Point> = [p, p];
		check("structure field compound assignment, object in an array", NONE, () -> {
			for (i in 0...N) {
				points[i & 1].x += i;
				points[i & 1].y++;
			}
			sink = p.x;
		});
		var o:Options = {name: "o", size: 3};
		check("structure optional field read", NONE, () -> sink = readOptions(o));
		check("call with haxe.PosInfos", POS_MAX, () -> {
			var sum = 0;
			for (i in 0...N)
				sum += line();
			sink = sum;
		});
		check("structure literal", LITERAL_MAX, () -> {
			var sum = 0;
			for (i in 0...N) {
				kept = {x: i, y: i};
				sum += kept.x;
			}
			sink = sum;
		});
		check("for loop on an Iterator<Int> (class instance)", ITERATOR_MAX, () -> {
			// one iterator object per measure, N iterations
			sink = sumIterator(new IntRange(N));
		});

		if (failures > 0) {
			Sys.println(failures + " allocation check(s) failed");
			Sys.exit(1);
		}
		Sys.println("all allocation checks passed");
	}

	// "Does not allocate": less than one byte per iteration. The measure allocates a few
	// objects once (the closures it is given), an allocation in the loop costs 24 bytes or more.
	static inline var NONE = 1.0;

	static var kept:Point;

	// One object and nothing else: no dictionary, no array of values, no boxing
	static inline var POS_MAX = 96.0;
	static inline var LITERAL_MAX = 64.0;

	// Allowance for what still allocates, in bytes per iteration
	static inline var ITERATOR_MAX = 100000.0;
}
