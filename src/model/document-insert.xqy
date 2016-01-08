xquery version "1.0-ml";

(: A wrapper to transactionally separate auxiliary document insertions :)

declare variable $uri external;
declare variable $document external;

if (fn:doc-available($uri)) then
  xdmp:document-insert(
    $uri,
    $document,
    xdmp:document-get-permissions($uri),
    xdmp:document-get-collections($uri))
else
  xdmp:document-insert($uri, $document)
