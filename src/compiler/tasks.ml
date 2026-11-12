
open Type
open CompilationCache

(*
	Collecting a large cache in one go takes more than a second, during which the server can't answer
	any request. The collection is done in slices instead, one task per slice: the server looks for a
	new request between two tasks, so a request waits for one slice at most.
*)

(* How many words a slice handles. A slice should not take more than a few milliseconds. *)
let gc_slice_words = 500000

(* Gives up on a collection that needs more slices than this, to never loop forever. *)
let gc_max_slices = 100000

(* If a collection is in progress, to not start another one on top of it. *)
let gc_running = ref false

(* The size of the heap after the last compaction, 0 if there was none yet. *)
let gc_compacted_heap_words = ref 0

class gc_slice_task (cs : CompilationCache.t) (stats_before : Gc.stat) (last_collection : int) (time : float) (slices : int) = object(self)
	inherit server_task ["gc"] 100

	method private execute =
		let t0 = Timer.get_time() in
		ignore(Gc.major_slice gc_slice_words);
		let time = time +. (Timer.get_time() -. t0) in
		let stats = Gc.quick_stat() in
		if stats.major_collections >= last_collection || slices >= gc_max_slices then begin
			gc_running := false;
			ServerMessage.gc_stats time stats_before false (Gc.get()).space_overhead
		end else
			cs#add_task (new gc_slice_task cs stats_before last_collection time (slices + 1))
end

class gc_task (cs : CompilationCache.t) = object(self)
	inherit server_task ["gc"] 100

	method private execute =
		if not !gc_running then begin
			let stats = Gc.quick_stat() in
			if !gc_compacted_heap_words = 0 then gc_compacted_heap_words := stats.heap_words;
			(* Compacting can't be done in slices: only do it when the heap has grown a lot, which a
			   compilation does but display requests don't. *)
			if float_of_int stats.heap_words > 1.5 *. float_of_int !gc_compacted_heap_words then begin
				let t0 = Timer.get_time() in
				Gc.compact();
				gc_compacted_heap_words := (Gc.quick_stat()).heap_words;
				ServerMessage.gc_stats (Timer.get_time() -. t0) stats true (Gc.get()).space_overhead
			end else begin
				gc_running := true;
				(* Like Gc.full_major: finish the current cycle, then do a complete one. *)
				cs#add_task (new gc_slice_task cs stats (stats.major_collections + 2) 0. 1)
			end
		end
end

class class_maintenance_task (cs : CompilationCache.t) (c : tclass) = object(self)
	inherit server_task ["module maintenance"] 70

	method private execute =
		let rec field cf =
			(* Unset cf_expr. This holds the optimized version for generators, which we don't need to persist. If
				we compile again, the semi-optimized expression will be restored by calling cl_restore(). *)
			cf.cf_expr <- None;
			List.iter field cf.cf_overloads
		in
		(* What we're doing here at the moment is free, so we can just do it in one task. If this ever gets more expensive,
			we should spawn a task per-field. *)
		List.iter field c.cl_ordered_fields;
		List.iter field c.cl_ordered_statics;
		Option.may field c.cl_constructor;
end

class module_maintenance_task (cs : CompilationCache.t) (m : module_def) = object(self)
	inherit server_task ["module maintenance"] 80

	method private execute =
		List.iter (fun mt -> match mt with
			| TClassDecl c ->
				cs#add_task (new class_maintenance_task cs c)
			| _ ->
				()
		) m.m_types
end

class server_exploration_task (cs : CompilationCache.t) = object(self)
	inherit server_task ["server explore"] 90

	method private execute =
		cs#iter_modules (fun m -> cs#add_task (new module_maintenance_task cs m))
end