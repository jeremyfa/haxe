(*
	The Haxe Compiler
	Copyright (C) 2005-2019  Haxe Foundation

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *)

(* Typed classes for anonymous structures.

   A value typed by a structure is an `object` in C#: at runtime it can be an object
   literal, an instance of a class that has the fields, or a fully dynamic object. For
   every structure the program names, this module generates a class in haxe.generated
   that extends haxe.lang.HaxeDynamicObject and stores the fields in typed C# fields.
   Object literals are created as instances of these classes, and field accesses go
   through static accessors that test the class first:

       public static int _hx_get_x(object o)
           => o is Anon_x_y c ? c.x : Runtime.toInt(Runtime.getField(o, "x"));

   so that the common case reads a field, without a dictionary lookup or boxing, and
   every other kind of object still works.

   Two structures with the same field names, in the same order, and the same C# field
   types share a class, whatever typedef names them. A typedef with type parameters is identified by its
   declaration, where a type parameter is an object, so that Pair<Int> and Pair<String>
   are the same class.

   The classes are not registered in HaxeReflectionInit and have no _hx_bind: the names
   of their fields only exist in their own file. *)

open Globals
open Type
open CsAst
open CsGlobals
open CsTypeMapping
open CsContext

(* The absent fields of an object are a bit mask in a ulong *)
let max_fields = 64

let generated_pack = ["haxe"; "generated"]

(* Members of HaxeDynamicObject and System.Object a field cannot be named after *)
let reserved_names = ["toString"; "ToString"; "Equals"; "GetHashCode"; "GetType"; "MemberwiseClone"; "Finalize"; "ReferenceEquals"]

let is_valid_field_name s =
	let n = String.length s in
	let is_start c = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c = '_' in
	let is_part c = is_start c || (c >= '0' && c <= '9') in
	let rec all i = i >= n || (is_part s.[i] && all (i + 1)) in
	let has_prefix p = n >= String.length p && String.sub s 0 (String.length p) = p in
	n > 0 && is_start s.[0] && all 1
	&& not (has_prefix "_hx_") && not (has_prefix "__hx_")
	&& not (List.mem s reserved_names)

let is_normal_anon an = match !(an.a_status) with
	| Closed | Const | Extend _ -> true
	| Statics _ | EnumStatics _ | AbstractStatics _ -> false

(* C# type of the field that stores a value of the given Haxe type *)
let field_type gctx t =
	let ct = cs_type_of_type gctx t in
	if collect_type_params [] ct <> [] then CsTypeObject
	else match ct with
	| CsTypeVoid | CsTypeDynamic | CsTypeVar -> CsTypeObject
	| _ -> ct

let class_type ac = CsTypeClass (ac.ac_path, [])

let find_field ac name =
	try Some (List.find (fun af -> af.af_name = name) ac.ac_fields) with Not_found -> None

let getter_name af = "_hx_get_" ^ af.af_name
let setter_name af = "_hx_set_" ^ af.af_name

let register gctx an =
	let fields = PMap.fold (fun cf acc -> cf :: acc) an.a_fields [] in
	let count = List.length fields in
	if count = 0 || count > max_fields || List.exists (fun cf -> not (is_valid_field_name cf.cf_name)) fields then
		None
	else begin
		(* declaration order: it is the order Reflect.fields, Std.string and Json give *)
		let fields = List.sort (fun cf1 cf2 ->
			compare (cf1.cf_pos.pfile, cf1.cf_pos.pmin, cf1.cf_name) (cf2.cf_pos.pfile, cf2.cf_pos.pmin, cf2.cf_name)
		) fields in
		let fields = List.mapi (fun i cf -> {
			af_name = cf.cf_name;
			af_type = field_type gctx cf.cf_type;
			af_index = i;
		}) fields in
		let key = String.concat ";" (List.map (fun af -> af.af_name ^ ":" ^ CsPrinter.s_cs_type af.af_type) fields) in
		try
			Some (Hashtbl.find gctx.anon_by_key key)
		with Not_found ->
			let names = String.concat "_" (List.map (fun af -> af.af_name) fields) in
			let names = if String.length names > 40 then String.sub names 0 40 else names in
			let digest = Digest.to_hex (Digest.string key) in
			let rec pick len =
				let name = Printf.sprintf "Anon_%s_%s" names (String.sub digest 0 len) in
				if Hashtbl.mem gctx.anon_names name && len < 32 then pick (len + 8) else name
			in
			let name = pick 8 in
			Hashtbl.replace gctx.anon_names name ();
			let ac = {
				ac_path = (generated_pack, name);
				ac_fields = fields;
			} in
			Hashtbl.replace gctx.anon_by_key key ac;
			Some ac
	end

(* The class of the structure a type is, if it is one we generate a class for *)
let identify gctx t =
	let rec direct t = match t with
		| TAnon an -> Some an
		| TMono {tm_type = Some t} -> direct t
		| TLazy f -> direct (lazy_type f)
		| _ -> None
	in
	let rec loop depth t =
		if depth > 32 then None else match t with
		| TType (td, tl) ->
			begin try
				Hashtbl.find gctx.anon_by_typedef td.t_path
			with Not_found -> match direct td.t_type with
				| Some an ->
					(* the declaration, not its application to tl: see the note on type parameters above *)
					let r = if is_normal_anon an then register gctx an else None in
					Hashtbl.replace gctx.anon_by_typedef td.t_path r;
					r
				| None ->
					loop (depth + 1) (apply_typedef td tl)
			end
		| TMono {tm_type = Some t} ->
			loop (depth + 1) t
		| TLazy f ->
			loop (depth + 1) (lazy_type f)
		| TAbstract ({a_path = ([], "Null")}, [t]) ->
			loop (depth + 1) t
		| TAbstract (a, tl) when not (Meta.has Meta.CoreType a.a_meta) ->
			loop (depth + 1) (Abstract.get_underlying_type a tl)
		| TAnon an when is_normal_anon an ->
			register gctx an
		| _ ->
			None
	in
	loop 0 t

(* ---- Expected types of object literals

   The typer gives an object literal the type of the fields it has: {x: 1} passed where
   {x:Int, ?y:Int} is expected has the type {x:Int}, which is another class. This pass
   gives every literal the structure type its context expects, when the literal fits it,
   so that it is created as the class its readers test for. haxe.PosInfos, whose
   customParams field is almost never given, depends on it. *)

let fits gctx fields t =
	match identify gctx t with
	| Some ac -> List.for_all (fun ((name, _, _), _) -> find_field ac name <> None) fields
	| None -> false

let anon_field_type t name =
	let rec loop depth t =
		if depth > 32 then None else match t with
		| TType (td, tl) -> loop (depth + 1) (apply_typedef td tl)
		| TMono {tm_type = Some t} -> loop (depth + 1) t
		| TLazy f -> loop (depth + 1) (lazy_type f)
		| TAbstract ({a_path = ([], "Null")}, [t]) -> loop (depth + 1) t
		| TAbstract (a, tl) when not (Meta.has Meta.CoreType a.a_meta) -> loop (depth + 1) (Abstract.get_underlying_type a tl)
		| TAnon an -> (try Some (PMap.find name an.a_fields).cf_type with Not_found -> None)
		| _ -> None
	in
	loop 0 t

let retype_object_decls gctx ret e =
	let rec loop ret expected e =
		let none = loop ret None in
		match e.eexpr with
		| TObjectDecl fields ->
			let t = match expected with
				| Some t when fits gctx fields t -> t
				| _ -> e.etype
			in
			let fields = List.map (fun ((name, _, _) as key, e1) ->
				(key, loop ret (anon_field_type t name) e1)
			) fields in
			{ e with eexpr = TObjectDecl fields; etype = t }
		| TVar (v, Some e1) ->
			{ e with eexpr = TVar (v, Some (loop ret (Some v.v_type) e1)) }
		| TBinop (OpAssign, e1, e2) ->
			let e1 = none e1 in
			{ e with eexpr = TBinop (OpAssign, e1, loop ret (Some e1.etype) e2) }
		| TCall (ef, args) ->
			let ef = none ef in
			let rec map_args args params = match args, params with
				| e1 :: args, (_, _, t) :: params -> loop ret (Some t) e1 :: map_args args params
				| args, [] -> List.map none args
				| [], _ -> []
			in
			let params = match follow ef.etype with
				| TFun (params, _) -> params
				| _ -> []
			in
			{ e with eexpr = TCall (ef, map_args args params) }
		| TNew (c, tl, args) ->
			let params = match c.cl_constructor with
				| Some cf ->
					begin match follow (apply_params c.cl_params tl cf.cf_type) with
					| TFun (params, _) when List.length params >= List.length args -> params
					| _ -> []
					end
				| None -> []
			in
			let rec map_args args params = match args, params with
				| e1 :: args, (_, _, t) :: params -> loop ret (Some t) e1 :: map_args args params
				| args, [] -> List.map none args
				| [], _ -> []
			in
			{ e with eexpr = TNew (c, tl, map_args args params) }
		| TReturn (Some e1) ->
			{ e with eexpr = TReturn (Some (loop ret ret e1)) }
		| TFunction tf ->
			{ e with eexpr = TFunction { tf with tf_expr = loop (Some tf.tf_type) None tf.tf_expr } }
		| TCast (e1, None) ->
			{ e with eexpr = TCast (loop ret (Some e.etype) e1, None) }
		| TParenthesis e1 ->
			{ e with eexpr = TParenthesis (loop ret expected e1) }
		| TMeta (m, e1) ->
			{ e with eexpr = TMeta (m, loop ret expected e1) }
		| TBlock el ->
			let rec map_block el = match el with
				| [] -> []
				| [e1] -> [loop ret expected e1]
				| e1 :: el -> let e1 = none e1 in e1 :: map_block el
			in
			{ e with eexpr = TBlock (map_block el) }
		| TIf (e1, e2, Some e3) ->
			let e1 = none e1 in
			let e2 = loop ret expected e2 in
			{ e with eexpr = TIf (e1, e2, Some (loop ret expected e3)) }
		| TSwitch (e1, cases, def) ->
			let e1 = none e1 in
			let cases = List.map (fun (el, e2) ->
				let el = List.map none el in
				(el, loop ret expected e2)
			) cases in
			{ e with eexpr = TSwitch (e1, cases, Option.map (loop ret expected) def) }
		| TTry (e1, catches) ->
			let e1 = loop ret expected e1 in
			{ e with eexpr = TTry (e1, List.map (fun (v, e2) -> (v, loop ret expected e2)) catches) }
		| TArrayDecl el ->
			let elem = match follow e.etype with
				| TInst ({cl_path = ([], "Array")}, [t]) -> Some t
				| _ -> None
			in
			{ e with eexpr = TArrayDecl (List.map (loop ret elem) el) }
		| _ ->
			Type.map_expr none e
	in
	loop ret None e

let retype_field gctx cf =
	match cf.cf_expr with
	| Some e ->
		let e = match e.eexpr with
			| TFunction _ -> retype_object_decls gctx None e
			| _ ->
				(* a variable initializer *)
				let e = retype_object_decls gctx None { e with eexpr = TCast (e, None); etype = cf.cf_type } in
				(match e.eexpr with TCast (e1, None) -> e1 | _ -> e)
		in
		cf.cf_expr <- Some e
	| None -> ()

(* ---- Class generation *)

let runtime_field name o =
	CsStaticCall (runtime_type, name, o)

(* Tests if a dynamic value can be stored in a field of the given type. A value that
   cannot goes to the dictionary of the object. *)
let rec accepts t value =
	let is t = CsIs (value, t) in
	let is_null = CsBinop (CsOpEq, value, CsNull) in
	let either a b = CsBinop (CsOpBoolOr, a, b) in
	match t with
	| CsTypeObject -> None
	| CsTypeInt -> Some (CsStaticCall (runtime_type, "isInt", [value]))
	| CsTypeDouble -> Some (either (is CsTypeDouble) (is CsTypeInt))
	| CsTypeClass ((["haxe"; "lang"], "Null"), [inner]) ->
		begin match accepts inner value with
		| Some test -> Some (either is_null test)
		| None -> None
		end
	| _ when is_inherently_nullable t -> Some (either is_null (is t))
	| _ -> Some (is t)

let generate_class gctx ac =
	let cls = class_type ac in
	let field_name af = escape_identifier af.af_name in
	let str s = CsConst (CsConstString s) in
	let int i = CsConst (CsConstInt (Int32.of_int i)) in
	let to_object af e =
		CsTypeCoercion.coerce_cs_types ~fresh_temp:(fun () -> "_hx_tmp") gctx e af.af_type CsTypeObject
	in
	let of_object af e =
		CsTypeCoercion.cast_object_to_type af.af_type e
	in
	let meth ?(access = AccessModifier.Protected) ?(modifiers = [MemberModifier.Override]) ?(attributes = []) name ret params body =
		CsMemberMethod {
			m_name = name;
			m_return_type = ret;
			m_access = access;
			m_modifiers = modifiers;
			m_type_params = [];
			m_params = params;
			m_body = Some body;
			m_constraints = [];
			m_explicit_interface = None;
			m_attributes = attributes;
		}
	in
	let param ?default name t = { p_name = name; p_type = Some t; p_default = default; p_modifier = None } in
	let fields = List.map (fun af -> CsMemberField {
		f_name = field_name af;
		f_type = af.af_type;
		f_access = AccessModifier.Public;
		f_modifiers = [];
		f_value = None;
	}) ac.ac_fields in
	let names = CsMemberField {
		f_name = "_hx_names";
		f_type = CsTypeArray (CsTypeString, None);
		f_access = AccessModifier.Private;
		f_modifiers = [MemberModifier.Static; MemberModifier.Readonly];
		f_value = Some (CsNewArray (CsTypeString, List.map (fun af -> str af.af_name) ac.ac_fields));
	} in
	let ctor = CsMemberConstructor {
		ctor_access = AccessModifier.Public;
		ctor_modifiers = [];
		ctor_params = List.map (fun af -> param ~default:(CsDefault af.af_type) (field_name af) af.af_type) ac.ac_fields
			@ [param ~default:(CsRaw "0UL") "_hx_absent" CsTypeULong];
		ctor_base_call = None;
		ctor_this_call = None;
		ctor_body = List.map (fun af ->
			CsExprStmt (CsBinop (CsOpAssign, CsField (CsThis, field_name af), CsLocal (field_name af)))
		) ac.ac_fields @ [CsExprStmt (CsBinop (CsOpAssign, CsField (CsThis, "_hx_absent"), CsLocal "_hx_absent"))];
	} in
	let typed_names = meth "_hx_typedNames" (CsTypeArray (CsTypeString, None)) [] [CsReturn (Some (CsLocal "_hx_names"))] in
	let default_section body = { sw_labels = [CsCaseDefault]; sw_body = body } in
	let typed_index = meth "_hx_typedIndex" CsTypeInt [param "name" CsTypeString] [
		CsSwitch (CsLocal "name", List.map (fun af -> {
			sw_labels = [CsCaseConst (str af.af_name)];
			sw_body = [CsReturn (Some (int af.af_index))];
		}) ac.ac_fields @ [default_section [CsReturn (Some (int (-1)))]])
	] in
	let typed_get = meth "_hx_typedGet" CsTypeObject [param "index" CsTypeInt] [
		CsSwitch (CsLocal "index", List.map (fun af -> {
			sw_labels = [CsCaseConst (int af.af_index)];
			sw_body = [CsReturn (Some (to_object af (CsField (CsThis, field_name af))))];
		}) ac.ac_fields @ [default_section [CsReturn (Some CsNull)]])
	] in
	let typed_set = meth "_hx_typedSet" CsTypeBool [param "index" CsTypeInt; param "value" CsTypeObject] [
		CsSwitch (CsLocal "index", List.map (fun af ->
			let target = CsField (CsThis, field_name af) in
			let store = CsExprStmt (CsBinop (CsOpAssign, target, of_object af (CsLocal "value"))) in
			let body = match accepts af.af_type (CsLocal "value") with
				| None -> [store; CsReturn (Some (CsConst (CsConstBool true)))]
				| Some test -> [
					CsIf (test, CsBlock [store; CsReturn (Some (CsConst (CsConstBool true)))], None);
					CsExprStmt (CsBinop (CsOpAssign, target, CsDefault af.af_type));
					CsReturn (Some (CsConst (CsConstBool false)));
				]
			in
			{ sw_labels = [CsCaseConst (int af.af_index)]; sw_body = body }
		) ac.ac_fields @ [default_section [CsReturn (Some (CsConst (CsConstBool false)))]])
	] in
	let inline = [{
		attr_name = "global::System.Runtime.CompilerServices.MethodImpl";
		attr_args = ["global::System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining"];
	}] in
	let static_meth = meth ~access:AccessModifier.Public ~modifiers:[MemberModifier.Static] ~attributes:inline in
	let accessors = List.concat (List.map (fun af ->
		let o = CsLocal "o" in
		let c = CsLocal "c" in
		let is_class = CsIsPattern (o, cls, Some "c") in
		let getter = static_meth (getter_name af) af.af_type [param "o" CsTypeObject] [
			CsReturn (Some (CsTernary (is_class,
				CsField (c, field_name af),
				of_object af (runtime_field "getField" [o; str af.af_name]))))
		] in
		let setter = static_meth (setter_name af) af.af_type [param "o" CsTypeObject; param "v" af.af_type] [
			CsIf (is_class, CsBlock [
				CsExprStmt (CsBinop (CsOpAssign, CsField (c, field_name af), CsLocal "v"));
				CsExprStmt (CsRaw (Printf.sprintf "c._hx_absent &= ~%LuUL" (Int64.shift_left 1L af.af_index)));
			], Some (CsBlock [
				CsExprStmt (runtime_field "setField" [o; str af.af_name; CsCast (CsTypeObject, to_object af (CsLocal "v"))]);
			]));
			CsReturn (Some (CsLocal "v"));
		] in
		[getter; setter]
	) ac.ac_fields) in
	CsClassDef {
		c_path = ac.ac_path;
		c_access = AccessModifier.Public;
		c_modifiers = [TypeModifier.Sealed];
		c_type_params = [];
		c_base = Some (CsTypeClass (NativeTypes.haxe_dynamic_object_path, []));
		c_interfaces = [];
		c_constraints = [];
		c_members = fields @ [names; ctor; typed_names; typed_index; typed_get; typed_set] @ accessors;
	}

let generate_classes gctx =
	let classes = Hashtbl.fold (fun _ ac acc -> ac :: acc) gctx.anon_by_key [] in
	let classes = List.sort (fun ac1 ac2 -> compare ac1.ac_path ac2.ac_path) classes in
	List.map (generate_class gctx) classes
