// An exception subclass without a constructor, compiled with -dce no
// (it made the exception filter fail on the Haxe 5 C# target)
class NoConstructorException extends haxe.Exception {}

class Main {
	static function main() {
		try {
			throw new NoConstructorException("no constructor");
		} catch (e:NoConstructorException) {
			if (e.message != "no constructor")
				throw "unexpected message: " + e.message;
		}
	}
}
