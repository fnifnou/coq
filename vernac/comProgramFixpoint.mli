(************************************************************************)
(*         *   The Coq Proof Assistant / The Coq Development Team       *)
(*  v      *         Copyright INRIA, CNRS and contributors             *)
(* <O___,, * (see version control and CREDITS file for authors & dates) *)
(*   \VV/  **************************************************************)
(*    //   *    This file is distributed under the terms of the         *)
(*         *     GNU Lesser General Public License Version 2.1          *)
(*         *     (see LICENSE file for the text of the license)         *)
(************************************************************************)

open Vernacexpr

(** Special Fixpoint handling when command is activated. *)
val do_fixpoint :
     pm:Declare.OblState.t
  -> scope:Locality.definition_scope
  -> ?clearbody:bool
  -> poly:bool
  -> ?typing_flags:Declarations.typing_flags
  -> ?user_warns:UserWarn.t
  -> ?using:Vernacexpr.section_subset_expr
  -> fixpoints_expr
  -> Declare.OblState.t

val do_cofixpoint :
     pm:Declare.OblState.t
  -> scope:Locality.definition_scope
  -> ?clearbody:bool
  -> poly:bool
  -> ?typing_flags:Declarations.typing_flags
  -> ?user_warns:UserWarn.t
  -> ?using:Vernacexpr.section_subset_expr
  -> cofixpoints_expr
  -> Declare.OblState.t

val do_mutually_recursive :
     pm:Declare.OblState.t
  -> scope:Locality.definition_scope
  -> ?clearbody:bool
  -> poly:bool
  -> ?typing_flags:Declarations.typing_flags
  -> ?user_warns:UserWarn.t
  -> ?using:Vernacexpr.section_subset_expr
  -> recursives_expr
  -> Declare.OblState.t
