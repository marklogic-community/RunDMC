(: Processes the server URL configuration in server-urls.xml :)

module namespace s = "http://marklogic.com/rundmc/server-urls";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace u = "http://marklogic.com/rundmc/util"
       at "../lib/util-2.xqy";

import module namespace draft = "http://developer.marklogic.com/site/internal/filter-drafts"
       at "../model/filter-drafts.xqy";

declare variable $s:hosts := u:get-doc('/config/server-urls.xml')/hosts/host;

declare variable $s:host-name := xdmp:host-name(xdmp:host());

declare variable $s:this-host :=  if ($s:hosts[@name eq $s:host-name])
                                 then $s:hosts[@name eq $s:host-name]
                                 else $s:hosts[@default-host]; (: default means we're on a development machine :)

declare variable $s:cookie-domain := string($this-host/@cookie-domain);

(: "staging", "production", or "development" :)
declare variable $s:host-type := string($s:this-host/@type);

declare variable $s:current-request-host := xdmp:get-request-header('Host');

declare variable $s:request-host-without-port := if (contains($s:current-request-host,':'))
                                        then substring-before($s:current-request-host,':')
                                        else                  $s:current-request-host;

declare variable $s:viewing-standalone-api := let $server-name := xdmp:server-name(xdmp:server())
                                              return contains($server-name,'standalone');

declare variable $s:main-server   := s:server-url("main");
declare variable $s:draft-server  := s:server-url("draft");
declare variable $s:webdav-server := s:server-url("webdav");
declare variable $s:admin-server  := s:server-url("admin");
declare variable $s:api-server    := s:server-url("api");
declare variable $s:standalone-api-server    := s:server-url("standalone-api");

declare variable $s:effective-api-server := if ($s:viewing-standalone-api) then $s:standalone-api-server
                                                                           else $s:api-server;

declare variable $s:primary-server := if ($draft:public-docs-only) then $s:main-server
                                                                   else $s:draft-server;

declare variable $s:search-page-url := if ($s:viewing-standalone-api) then concat($s:standalone-api-server, "/do-search")
                                                                      else concat($s:main-server, "/search");

(: Use the @url if provided in the config; otherwise, use the same server but with the specified @port :)
declare function s:server-url($type as xs:string) {
  let $element-name  := concat($type,'-server'),
      $server-config := $s:this-host/*[local-name(.) eq $element-name] return
  if ($server-config/@url)
  then string($server-config/@url)
  else concat('http://',$s:request-host-without-port,':',$server-config/@port)
};
