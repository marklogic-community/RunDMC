(: Processes the server configuration in server-config.xml :)

module namespace sc = "http://marklogic.com/rundmc/server-config";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace u = "http://marklogic.com/rundmc/util" at "../lib/util-2.xqy";

declare variable $sc:hosts := u:get-doc('/config/server-urls.xml')/hosts/host;

declare variable $sc:host-name := xdmp:host-name(xdmp:host());

declare variable $sc:this-host :=  if ($s:hosts[@name eq $s:host-name])
                                 then $s:hosts[@name eq $s:host-name]
                                 else $s:hosts[@default-host]; (: default means we're on a development machine :)

(: "staging", "production", or "development" :)
declare variable $sc:host-type := string($s:this-host/@type);

declare variable $sc:facebook-config := sc:server-config("facebook");


(: return entire config :)
declare function sc:server-config($type as xs:string) {
  let $element-name  := concat($type,'-config'),
      $server-config := $sc:this-host/*[local-name(.) eq $element-name] return
  $server-config
};
