xquery version "1.0-ml";

"[" ||
  fn:string-join(
    cts:uri-match("/media/" || xdmp:get-request-field("uri") || "*") ! ('"' || . || '"'),
    ", "
  ) ||
"]"
