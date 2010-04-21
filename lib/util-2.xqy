xquery version "1.0-ml";

module namespace u="http://marklogic.com/rundmc/util";

import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";

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
 : to the current ML appserver root
 :)
declare function u:get-doc($path as xs:string) as node() {
    let $config := admin:get-configuration()
    let $server := xdmp:server()
    let $root := admin:appserver-get-root($config, $server)
    return xdmp:document-get(fn:concat($root, $path))
};
