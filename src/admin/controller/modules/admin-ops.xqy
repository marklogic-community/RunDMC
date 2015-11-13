xquery version "1.0-ml";

module namespace admin-ops = "http://marklogic.com/rundmc/admin-ops";


declare function admin-ops:document-insert(
  $uri as xs:string,
  $doc as node()
)
as empty-sequence()
{
  if (fn:doc-available($uri)) then
    xdmp:document-insert(
      $uri,
      $doc,
      xdmp:document-get-permissions($uri),
      xdmp:document-get-collections($uri)
    )
  else
    xdmp:document-insert(
      $uri,
      $doc,
      xdmp:default-permissions()
    )
};

declare function admin-ops:document-insert(
  $uri as xs:string,
  $doc as node(),
  $collections as xs:string*
)
as empty-sequence()
{
  xdmp:document-insert(
    $uri,
    $doc,
    xdmp:default-permissions(),
    $collections
  )
};
