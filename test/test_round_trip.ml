open! Core
open! Import

let round_trip contents =
  Lexing.from_string contents
  |> Ppxlib.Parse.use_file
  |> Mlt_parser.parse ~contents
  |> List.map ~f:(function
       | Org body -> sprintf "[%%%%org{|%s|}]" body
       | Expect body -> sprintf "[%%%%expect {|%s|}]" body
       | Code body -> sprintf "%s" body)
  |> String.concat
  |> print_patdiff contents
;;

let%expect_test "round-trip a file through mlt parser" =
  round_trip
    {contents|
    [%%org {|
* Title
** Subtitle|}];;

    #verbose true;;
    (* Comment before *)
    (** Documentation comment. *)
    [@@@part "foo"]
    type t =
      { foo : int  (* (* Nested *) comment *)
      ; bar : string (* Multi-line
 comment *)
      ; baz : float (** Documentation comment *)
      ; qux : int [@doc "(* Comment *) in extension payload."]
      }

    (** Documentation comment. *)

    (* Toplevel multi-line
 comment *)
    (* Toplevel (* nested *) comment *)
    [%%expect {|
some output.
 Not the real thing.
 |}]

    (** Toplevel documentation comment *)
|contents};
  [%expect
    {xxx|
    -1,25 +1,24
      [%%org{|
      * Title
      ** Subtitle|}];;

          #verbose true;;
          (* Comment before *)
          (** Documentation comment. *)
    -|    [@@@part "foo"]
          type t =
            { foo : int  (* (* Nested *) comment *)
            ; bar : string (* Multi-line
       comment *)
            ; baz : float (** Documentation comment *)
            ; qux : int [@doc "(* Comment *) in extension payload."]
            }

          (** Documentation comment. *)

          (* Toplevel multi-line
       comment *)
          (* Toplevel (* nested *) comment *)
          [%%expect {|
          some output.
           Not the real thing. |xxx}]
;;
