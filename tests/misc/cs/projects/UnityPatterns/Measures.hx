/** Makes values of `Measure`, whose first constructor has the name of the enum. **/
class Measures {
	public static function of(size:Float):Measure {
		// with the enum expected, `Measure` is the constructor
		return Measure(size);
	}

	public static function maker():Float->Measure {
		var make:Float->Measure = size -> Measure(size);
		return make;
	}
}
