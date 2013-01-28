(***********************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team    *)
(* <O___,, *        INRIA-Rocquencourt  &  LRI-CNRS-Orsay              *)
(*   \VV/  *************************************************************)
(*    //   *      This file is distributed under the terms of the      *)
(*         *       GNU Lesser General Public License Version 2.1       *)
(***********************************************************************)

open Pp

(** Aliases *)

let push = Backtrace.push_exn

let reraise = Backtrace.reraise

(* Errors *)

exception Anomaly of string option * std_ppcmds * Backtrace.t (* System errors *)

let make_anomaly ?label pp =
  let bt =
    if !Flags.debug then Backtrace.empty
    else Backtrace.none
  in
  Anomaly (label, pp, bt)

let anomaly_gen label pp =
  let bt =
    if !Flags.debug then Backtrace.empty
    else Backtrace.none
  in
  raise (Anomaly (label, pp, bt))

let anomaly ?loc ?label pp =
  let bt =
    if !Flags.debug then Backtrace.empty
    else Backtrace.none
  in
  match loc with
  | None -> raise (Anomaly (label, pp, bt))
  | Some loc ->
    Loc.raise loc (Anomaly (label, pp, bt))

let anomalylabstrm string pps =
  anomaly_gen (Some string) pps

let is_anomaly = function
| Anomaly _ -> true
| _ -> false

exception UserError of string * std_ppcmds (* User errors *)
let error string = raise (UserError("_", str string))
let errorlabstrm l pps = raise (UserError(l,pps))

exception AlreadyDeclared of std_ppcmds (* for already declared Schemes *)
let alreadydeclared pps = raise (AlreadyDeclared(pps))

let todo s = prerr_string ("TODO: "^s^"\n")

let user_err_loc (loc,s,strm) = Loc.raise loc (UserError (s,strm))
let invalid_arg_loc (loc,s) = Loc.raise loc (Invalid_argument s)

(* Like Exc_located, but specifies the outermost file read, the filename
   associated to the location of the error, and the error itself. *)

exception Error_in_file of string * (bool * string * Loc.t) * exn

exception Timeout
exception Drop
exception Quit

let handle_stack = ref []

exception Unhandled

let register_handler h = handle_stack := h::!handle_stack

(** [print_gen] is a general exception printer which tries successively
    all the handlers of a list, and finally a [bottom] handler if all
    others have failed *)

let rec print_gen bottom stk e =
  match stk with
  | [] -> bottom e
  | h::stk' ->
    try h e
    with
    | Unhandled -> print_gen bottom stk' e
    | e' -> print_gen bottom stk' e'

(** Only anomalies should reach the bottom of the handler stack.
    In usual situation, the [handle_stack] is treated as it if was always
    non-empty with [print_anomaly] as its bottom handler. *)

let where = function
| None -> mt ()
| Some s ->
  if !Flags.debug then str ("in "^s^":") ++ spc () else mt ()

let raw_anomaly e = match e with
  | Anomaly (s, pps, bt) -> where s ++ pps ++ str "."
  | Assert_failure _ | Match_failure _ -> str (Printexc.to_string e ^ ".")
  | _ -> str ("Uncaught exception " ^ Printexc.to_string e ^ ".")

let print_anomaly askreport e =
  let bt_info = match e with
  | Anomaly (_, _, Some bt) ->
    let pr_frame f = str (Backtrace.print_frame f) in
    let bt = prlist_with_sep fnl pr_frame bt in
    fnl () ++ hov 0 bt
  | _ -> mt ()
  in
  let info =
    if askreport then
      hov 0 (str "Anomaly: " ++ raw_anomaly e ++ spc () ++ str "Please report.")
    else
      hov 0 (raw_anomaly e)
  in
  info ++ bt_info

(** The standard exception printer *)
let print e = print_gen (print_anomaly true) !handle_stack e

(** Same as [print], except that the "Please report" part of an anomaly
    isn't printed (used in Ltac debugging). *)
let print_no_report e = print_gen (print_anomaly false) !handle_stack e

let print_anomaly e = print_anomaly true e

(** Same as [print], except that anomalies are not printed but re-raised
    (used for the Fail command) *)
let print_no_anomaly e = print_gen (fun e -> raise e) !handle_stack e

(** Predefined handlers **)

let _ = register_handler begin function
  | UserError(s,pps) -> hov 0 (str "Error: " ++ where (Some s) ++ pps)
  | _ -> raise Unhandled
end

let rec anomaly_handler = function
| Anomaly (lbl, pp, bt) ->
  let bt = Backtrace.push bt in
  Some (Anomaly (lbl, pp, bt))
| Loc.Exc_located (loc, e) ->
  begin match anomaly_handler e with
  | None -> None
  | Some e -> Some (Loc.Exc_located (loc, e))
  end
| Error_in_file (s, data, e) ->
  begin match anomaly_handler e with
  | None -> None
  | Some e -> Some (Error_in_file (s, data, e))
  end
| e -> None

let record_backtrace () =
  Backtrace.register_backtrace_handler anomaly_handler
