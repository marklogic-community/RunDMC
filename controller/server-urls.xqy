(: Processes the server URL configuration in server-urls.xml :)

module namespace srv = "http://marklogic.com/rundmc/server-urls";

import module namespace u = "http://marklogic.com/rundmc/util"
       at "../lib/util-2.xqy";

declare variable $hosts := u:get-doc('/config/server-urls.xml')/hosts/host;

declare variable $host-name := xdmp:host-name(xdmp:host());

declare variable $this-host := if ($hosts[@name eq $host-name])
                              then $hosts[@name eq $host-name]
                              else $hosts[@default-host]; (: default means we're on a development machine :)

(: "staging", "production", or "development" :)
declare variable $host-type := fn:string($this-host/@type);

declare variable $current-request-host := xdmp:get-request-header('Host');

declare variable $request-host-without-port := if (fn:contains($current-request-host,':'))
                                      then fn:substring-before($current-request-host,':')
                                      else                     $current-request-host;


(: Use the @url if provided in the config; otherwise, use the same server but with the specified @port :)
declare variable $draft-server := if ($this-host/draft-server/@url)
                           then fn:string($this-host/draft-server/@url)
                           else fn:concat('http://',$request-host-without-port,':',$this-host/draft-server/@port);

declare variable $webdav-server := if ($this-host/webdav-server/@url)
                        then fn:string($this-host/webdav-server/@url)
                        else fn:concat('http://',$request-host-without-port,':',$this-host/webdav-server/@port);
