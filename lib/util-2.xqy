xquery version "1.0-ml";

module namespace u="http://marklogic.com/rundmc/util";

import module namespace search = "http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

(: 
 : @author Eric Bloch
 : @date 21 April 2010
 :)

declare default function namespace "http://www.w3.org/2005/xpath-functions";

(: 
 : @param $path /-prefixed string that is path to the XML file
 : that represents the document
 :
 : @return document read in from the give path, which is relative
 : to the current ML modules root
 :)
declare function u:get-doc($path as xs:string) as node() {
    let $root := xdmp:modules-root()
    return xdmp:document-get(fn:concat($root, $path))
};

(: 
 : @param $dir-uri 
 :
 : @return true if the uri is a directory in the current DB
 : to the current ML modules root
 :)
declare function u:is-directory($uri as xs:string) as xs:boolean {
    xdmp:exists(xdmp:directory($uri, 'infinity'))
};

declare function u:highlight-doc($doc, $highlight-search as xs:string) {
  cts:highlight($doc, cts:query(search:parse($highlight-search, search:get-default-options())),
                      <span style="background-color:yellow">{$cts:text}</span>)
};

declare function u:strip-version-from-path($path as xs:string) {
  fn:replace($path,'/[0-9]+\.[0-9]+/','/')
};
