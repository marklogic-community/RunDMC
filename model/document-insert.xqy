xquery version "1.0-ml";

(: A wrapper to transactionally separate auxiliary document insertions :)

declare variable $uri external;
declare variable $document external;

() (: xdmp:document-insert($uri, $document) :)
