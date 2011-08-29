xquery version "1.0-ml";

module  namespace f   = "http://marklogic.com/rundmc/facets";
declare namespace api = "http://marklogic.com/rundmc/api";
declare namespace ml  = "http://developer.marklogic.com/site/internal";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare function f:category-parse($_, $query-element) as schema-element(cts:query) {
  let $val := lower-case($query-element//cts:text),
      $query := if ($val eq "function") then cts:element-query(xs:QName("api:function-page") ,cts:and-query(()))
           else if ($val eq "guide")    then cts:element-query(xs:QName("guide")             ,cts:and-query(()))
           else if ($val eq "news")     then cts:element-query(xs:QName("ml:Announcement")   ,cts:and-query(()))
           else if ($val eq "event")    then cts:element-query(xs:QName("ml:Event")          ,cts:and-query(()))
           else if ($val eq "tutorial") then cts:element-query(xs:QName("ml:Article")        ,cts:and-query(()))
           else if ($val eq "blog")     then cts:element-query(xs:QName("ml:Post")           ,cts:and-query(()))
           else if ($val eq "code")     then cts:element-query(xs:QName("ml:Project")        ,cts:and-query(()))
           else if ($val eq "xcc")      then cts:directory-query("/pubs/4.2/javadoc/","infinity")
           else if ($val eq "xccn")     then cts:directory-query("/pubs/4.2/dotnet/" ,"infinity")
           else cts:or-query(()) (: always return false for an unknown category :)

  return <_>{$query}</_>/*
};
