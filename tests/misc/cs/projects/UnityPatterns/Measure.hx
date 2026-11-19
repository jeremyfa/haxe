/**
	An enum with a constructor of its own name: in its own module, so that `Measure`
	is the type for the code that uses it.
**/
enum Measure {
	Measure(size:Float);
	Small;
	Large;
}
