import cs.system.collections.generic.List;

typedef T = {id:String};

class Main {
	public static function main() {
		var list:List<T> = new List();
		list.ConvertAll((t:T) -> t.id);
	}
}