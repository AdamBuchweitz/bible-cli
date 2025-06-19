(** Configuration constants for the Bible CLI application *)

module ApiStrings : sig
  val base_url : string
  val translations_endpoint : string
  val books_endpoint_suffix : string
end

module Defaults : sig
  val translation : string
  val language : string
  val file_permissions : int
end

module Messages : sig
  val done_message : string
end

module Sorting : sig
  val traditional : string
  val alphabetical : string
  val chronological : string
end

module ListTypes : sig
  val translations : string
  val books : string
end

module ErrorMessages : sig
  val missing_text_and_poem : string
  val invalid_content_item : string
  val unknown_content_type_format : string
end