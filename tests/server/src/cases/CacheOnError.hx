package cases;

/**
	With `-D server-cache-on-error`, a compilation that has errors still caches the modules
	of the files that have none.
**/
class CacheOnError extends TestCase {
	static final MAIN = "class Main {
	static function main() {
		trace(Good.value() + Broken.value());
	}
}";

	static final GOOD = "class Good {
	public static function value():Int {
		return Leaf.value() + 1;
	}
}";

	static final LEAF = "class Leaf {
	public static function value():Int {
		return 1;
	}
}";

	static final BROKEN = "class Broken {
	public static function value():Int {
		return 2;
	}

	static function wrong():Int {
		var s:String = 12;
		return 0;
	}
}";

	static final FIXED = "class Broken {
	public static function value():Int {
		return 2;
	}

	static function wrong():Int {
		var s:Int = 12;
		return s;
	}
}";

	function putFiles() {
		vfs.putContent("Main.hx", MAIN);
		vfs.putContent("Good.hx", GOOD);
		vfs.putContent("Leaf.hx", LEAF);
		vfs.putContent("Broken.hx", BROKEN);
	}

	function testCachesTheModulesWithoutErrors(_) {
		putFiles();
		var args = ["--main", "Main", "--js", "test.js", "-D", "server-cache-on-error"];
		runHaxe(args);
		Assert.isTrue(lastResult.hasError);
		assertErrorMessage("Int should be String");

		// The file with the error is typed again, and so is what depends on it
		runHaxe(args);
		Assert.isTrue(lastResult.hasError);
		assertReuse("Good");
		assertReuse("Leaf");
		assertSkipping("Main", DependencyDirty("Broken - Tainted has_errors"));
		Assert.isFalse(hasMessage("reusing Broken"));
		Assert.isFalse(hasMessage("reusing Main"));

		// Once the error is fixed, everything compiles and what was cached is still used
		vfs.putContent("Broken.hx", FIXED);
		runHaxeJson([], ServerMethods.Invalidate, {file: new FsPath("Broken.hx")});
		runHaxe(args);
		assertSuccess();
		assertReuse("Good");
		assertReuse("Leaf");

		runHaxe(args);
		assertSuccess();
		assertReuse("Main");
		assertReuse("Broken");
	}

	function testCachesNothingWithoutTheDefine(_) {
		putFiles();
		var args = ["--main", "Main", "--js", "test.js"];
		runHaxe(args);
		Assert.isTrue(lastResult.hasError);
		runHaxe(args);
		Assert.isTrue(lastResult.hasError);
		Assert.isFalse(hasMessage("reusing Good"));
		Assert.isFalse(hasMessage("reusing Leaf"));
	}

	function testDiagnosticsCacheTheModulesWithoutErrors(_) {
		putFiles();
		var args = ["--main", "Main", "--js", "test.js", "-D", "server-cache-on-error"];
		runHaxeJson(args, DisplayMethods.Diagnostics, {file: new FsPath("Broken.hx")});
		runHaxeJson(args, DisplayMethods.Diagnostics, {file: new FsPath("Main.hx")});
		assertReuse("Good");
		assertReuse("Leaf");
		Assert.isFalse(hasMessage("reusing Broken"));
	}
}
