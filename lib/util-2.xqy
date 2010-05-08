xquery version "1.0-ml";

module namespace u="http://marklogic.com/rundmc/util";

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
