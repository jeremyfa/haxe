(*
	Haxe 4.3 versions of the few Haxe 5 compiler APIs that the C# generator
	uses. The generator was written for Haxe 5, keeping these here lets the
	rest of the code stay close to the original.
*)

open Type

(* Haxe 5 represents a switch as a record, 4.3 as a tuple *)
type switch_case = {
	case_patterns : texpr list;
	case_expr : texpr;
}

type tswitch = {
	switch_subject : texpr;
	switch_cases : switch_case list;
	switch_default : texpr option;
	switch_exhaustive : bool;
}

let tswitch subject cases default = {
	switch_subject = subject;
	switch_cases = List.map (fun (patterns,e) -> { case_patterns = patterns; case_expr = e }) cases;
	switch_default = default;
	(* the matcher marks exhaustive switches with @:exhaustive on the subject *)
	switch_exhaustive = Texpr.is_exhaustive subject default;
}

(* Constraints of a type parameter. In 4.3 they are stored in the
   KTypeParameter kind of the class that represents the parameter. *)
let get_constraints (ttp : typed_type_param) =
	match follow ttp.ttp_type with
	| TInst({ cl_kind = KTypeParameter tl },_) -> tl
	| _ -> []

(* Haxe 5 wraps type paths with their position, 4.3 does not *)
let make_ptp (tp : Ast.type_path) (_ : Globals.pos) = tp
