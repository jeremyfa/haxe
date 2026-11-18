package unit;
import haxe.io.Bytes;
import haxe.test.Base;
import haxe.test.Base.Base_InnerClass;
import haxe.test.TEnum;
import haxe.test.TEnumWithValue;
import haxe.test.TEnumWithBigValue;
import haxe.test.TEnumWithFlag;
import haxe.test.TEnumWithBigFlag;
import haxe.test.IEditableTextBuffer;
import haxe.test.LowerCaseClass;

import cs.system.componentmodel.DescriptionAttribute;

import NoPackage;

//C#-specific tests: .NET libraries loaded with -net-lib, ref and out arguments
class TestCSharp extends Test
{
#if cs

	function testIssue4325()
	{
		var b = new Base();
		eq(b.Issue4325, 0);
		b.setIssue4325(10);
		eq(b.Issue4325, 10);
	}

	// -net-lib tests
	function testHaxeKeywords()
	{
		eq(Base._inline, 42);
		eq(Base.callback, 43);
		eq(Base._cast, 44);
		eq(Base._untyped, 45);
		Base._untyped = 40;
		eq(Base._untyped, 40);
	}

	function testIssue3474()
	{
		var a:IEditableTextBuffer = cast null;
		eq(a,null);
		var didRun = false;
		try
		{
			eq(a.Property, "should not succeed");
		}
		catch(e:Dynamic)
		{
			didRun = true;
		}

		t(didRun);
	}

	function testLowerCase()
	{
		var l = new LowerCaseClass();
		t(l.works);
	}

	function testGetItem()
	{
		var b = new Base();
		eq(b[1], 20);
		eq(b.get_Item(2,3), 6);
		var dyn:Dynamic = b;
		eq(dyn[1], 20);
		eq(dyn.get_Item(2,3), 6);

		var b:Base = new Base_InnerClass();
		eq(b[1], 20);
		eq(b.get_Item(2,3), 6);
		var dyn:Dynamic = b;
		eq(dyn[1], 20);
		eq(dyn.get_Item(2,3), 6);
	}

	// function testOptional()
	// {
	// 	eq(new Base().optional(), 420);
	// 	eq(new Base().optional(10), 100);
	// }

	function testProp()
	{
		var b = new Base();
		eq(b.prop, "SomeValue");
		var dyn:Dynamic = b;
		eq(dyn.prop, "SomeValue");
	}

	function testTypes()
	{
		eq(Base.charTest(cast 10), cast 10);
		eq(Base.byteTest(cast 10), cast 10);
	}

	function testInnerClass()
	{
		//-java-lib should be able to detect inner classes on import
		var i = new Base_InnerClass();
		eq(10,i.nameClash());

		var i2 = new Base_InnerClass_InnerInnerClass();
		t(true);

		var noPack:NoPackage = new NoPackage();
		t(noPack.isWorking);
		t(noPack.b != null);
		t(noPack.b.isReallyWorking);

		var noPack2 = new NoPackage.NoPackage_NoPackInner();
		t(noPack2.isReallyWorking);
	}

	function testGenerics()
	{
		// t(haxe.test.GenericHelper.staticTypedGeneric(new Base_InnerClass_InnerInnerClass()) != null);

		var helper = new haxe.test.GenericHelper();

		var val = new Base_InnerClass();
		var g1 = new haxe.test.Generic1(val);
		g1.complexTypeParameterOfTypeParameter(new Base_InnerClass_InnerInnerClass());
		//if no compile-time error, we're fine!
		t(true);
	}

	function testDelegates()
	{
		var run = false;
		var v:haxe.test.VoidVoid = function () run = true;
		f(run);
		v.Invoke();
		t(run);
		f(didRun);
		v = doRun;
		v.Invoke();
		t(didRun);

		run = false;
		var someFunc = function() run = true;
		f(run);
		v = someFunc;
		f(run);
		v.Invoke();
		t(run);

		var someFunc2 = someFunc;
		var getFun = function() return someFunc2;
		run = false;
		f(run);
		v = { var x = "complex body"; getFun(); };
		f(run);
		v.Invoke();
		t(run);

		//var dyn:Dynamic = v;
		//t((dyn is haxe.test.VoidVoid));
	}

	var didRun = false;
	function doRun()
	{
		didRun = true;
	}

	function testEnum()
	{
		var e = TEnum.TA;
		switch(e)
		{
			case TA:
				t(true);
			case _:
				t(false);
		}
		eq("TA",Type.enumConstructor(e));

		eq(Type.enumIndex(getTA()), Type.enumIndex(TEnum.TA));
		eq(Type.enumIndex(getTVA()), Type.enumIndex(TEnumWithValue.TVA));
		eq(Type.enumIndex(getTBA()), Type.enumIndex(TEnumWithBigValue.TBA));

		eq(Type.enumIndex(getTVB()), Type.enumIndex(TEnumWithValue.TVB));
		eq(Type.enumIndex(getTBB()), Type.enumIndex(TEnumWithBigValue.TBB));
		eq(Type.enumIndex(getTB()), Type.enumIndex(TEnum.TB));

		eq(Type.enumIndex(getTC()), Type.enumIndex(TEnum.TC));
		eq(Type.enumIndex(getTVC()), Type.enumIndex(TEnumWithValue.TVC));
		eq(Type.enumIndex(getTBC()), Type.enumIndex(TEnumWithBigValue.TBC));

		eq(Type.enumIndex(getTVD()), Type.enumIndex(TEnumWithValue.TVD));
		eq(Type.enumIndex(getTBD()), Type.enumIndex(TEnumWithBigValue.TBD));

		checkEnum(TEnum,TEnum.TA);
		checkEnum(TEnum,TEnum.TB);
		checkEnum(TEnum,TEnum.TC);

		checkEnum(TEnumWithValue,TEnumWithValue.TVA);
		checkEnum(TEnumWithValue,TEnumWithValue.TVB);
		checkEnum(TEnumWithValue,TEnumWithValue.TVC);
		checkEnum(TEnumWithValue,TEnumWithValue.TVD);

		checkEnum(TEnumWithBigValue,TEnumWithBigValue.TBA);
		checkEnum(TEnumWithBigValue,TEnumWithBigValue.TBB);
		checkEnum(TEnumWithBigValue,TEnumWithBigValue.TBC);
		checkEnum(TEnumWithBigValue,TEnumWithBigValue.TBD);

		//issue #2308
		var fn = getEnumValue;
		eq(0x100, Reflect.callMethod(null, fn, [TEnumWithValue.TVA]));

		var e = getTVA();
		switch(e) {
			case TVA if (getEnumValue(e) == getEnumValue(getTVA())):
				t(true);
			case _:
				t(false);
		}

		var e = getTVB();
		switch(e) {
			case TVA:
				t(false);
			case TVB if (getEnumValue(e) != getEnumValue(getTVA())):
				t(true);
			case _:
				t(false);
		}
	}

	static function getEnumValue(e:TEnumWithValue):Int
	{
		return cast e;
	}

	private static function getArray(arr:cs.system.Array)
	{
		return [ for (i in 0...arr.Length) arr.GetValue(i) ];
	}

	function checkEnum<T : EnumValue>(e:Enum<T>,v:T,?pos:haxe.PosInfos)
	{
		var idx = Type.enumIndex(v);
		eq(v,Type.createEnumIndex(e,idx),pos);
	}

	function getTA() return TEnum.TA;
	function getTVA() return TEnumWithValue.TVA;
	function getTBA() return TEnumWithBigValue.TBA;
	function getTB() return TEnum.TB;
	function getTVB() return TEnumWithValue.TVB;
	function getTBB() return TEnumWithBigValue.TBB;
	function getTC() return TEnum.TC;
	function getTVC() return TEnumWithValue.TVC;
	function getTBC() return TEnumWithBigValue.TBC;
	function getTVD() return TEnumWithValue.TVD;
	function getTBD() return TEnumWithBigValue.TBD;

	@:skipReflection private function refTest(i:cs.Ref<Int>):Void
	{
		i *= 2;
	}

	@:skipReflection private function refTestAssign(i:cs.Ref<Int>):Void
	{
		i = 2;
	}

	@:skipReflection private function outTest(out:cs.Out<Int>, x:Int):Void
	{
		out = x * 2;
	}

	// test for https://github.com/HaxeFoundation/haxe/issues/2528
	public function testDynObjectSetField()
	{
		var a:Dynamic = {};
		a.status = 10;
		var b:{status:Int} = a;
		b.status = 15;

		eq(a, b);
		eq(Reflect.fields(a).length, 1);
		eq(Reflect.fields(b).length, 1);
		eq(a.status, 15);
		eq(b.status, 15);
	}

	public function testRef()
	{
		var i = 10;
		refTestAssign(i);
		eq(i, 2);

		var i = 10;
		refTest(i);
		eq(i, 20);

		i = 10;
		var cl = new haxe.test.MyClass();
		cl.refTest(i);
		eq(i,420);
	}

	public function testOut()
	{
		var i = 0;
		outTest(i, 10);
		eq(i, 20);

		var cl = new haxe.test.MyClass();
		cl.outTest(i);
		eq(i,42);
	}

	// test these because C# generator got a special filter for these expressions
	public function testNullConstEq()
	{
		var a:Null<Int> = 10;
		f(a == null);
		f(null == a);
		t(a != null);
		t(null != a);
	}

#end
}
