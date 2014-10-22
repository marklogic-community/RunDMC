xquery version "1.0-ml";

module namespace sc="http://marklogic.com/rundmc/server-config";

(: Processes the server configuration in server-config.xml :)

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace u="http://marklogic.com/rundmc/util"
  at "/lib/util-2.xqy";

declare variable $HOSTS := (
  u:get-doc('/config/server-urls-local.xml')/hosts/host,
  u:get-doc('/config/server-urls.xml')/hosts/host
);

declare variable $HOST-NAME := xdmp:host-name(xdmp:host());

(: Default means a development environment. :)
declare variable $DEFAULT-HOST := ($HOSTS[xs:boolean(@default-host)])[1] ;

declare variable $HOST-BY-NAME := $HOSTS[@name eq $HOST-NAME] ;

declare variable $THIS-HOST := (
  if ($HOST-BY-NAME) then $HOST-BY-NAME else $DEFAULT-HOST) ;

(: return entire config :)
declare function sc:server-config($type as xs:string)
as element()
{
  let $name := xs:QName($type||'-server')
  return $THIS-HOST/*[node-name(.) eq $name]
};

(: server-config.xqy :)
