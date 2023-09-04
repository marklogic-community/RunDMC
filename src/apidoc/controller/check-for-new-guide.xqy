xquery version "1.0-ml";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";

declare function local:add-version(
  $pathname as xs:string
){
  let $parts := fn:tokenize($pathname, "/")
  let $version := $parts[2]
  return try {
    let $check := xs:decimal($version)
    return $pathname
  } catch ($e) {
    fn:concat("/", $api:DEFAULT-VERSION, $pathname)
  }
};

declare function local:find-version(
  $pathname as xs:string
){
  let $parts := fn:tokenize($pathname, "/")
  let $version := $parts[2]
  return try {
    let $check := xs:decimal($version)
    return $version
  } catch ($e) {
    $api:DEFAULT-VERSION
  }
};

declare function local:find-candidate-by-title(
  $version as xs:string,
  $pathname as xs:string,
  $title as xs:string
){
  let $guide-restriction := 
    if (fn:matches($pathname, "/guide/installation(/|$)")) then "guide/installation-guide"
    else if (fn:matches($pathname, "/guide/relnotes(/|$)")) then "guide/release-notes"
    else if (fn:matches($pathname, "/guide/admin(/|$)")) then "guide/admin-guide"
    else if (fn:matches($pathname, "/guide/security(/|$)")) then "guide/security-guide"
    else "path/that/does/not/exist"
  let $parts := ("", "paligo", $version, $guide-restriction, "")
  let $query := cts:and-query((
      cts:directory-query(fn:string-join($parts, "/"), 'infinity'),
      cts:element-value-query(fn:QName('http://www.w3.org/1999/xhtml','title'), fn:lower-case($title))
    ))
  return cts:uris('', ("limit=1"), $query)
};

declare function local:find-candidate-by-anchor(
  $version as xs:string,
  $pathname as xs:string,
  $anchor as element()
){
  let $title := fn:head((
    $anchor/../*:h1/string(),
    $anchor/../*:h2/string(),
    $anchor/../*:h3/string(),
    $anchor/../*:h4/string(),
    $anchor/../*:h5/string(),
    $anchor/../*:h6/string()
  ))
  let $result := local:find-candidate-by-title($version, $pathname, $title)
  return if ($result) then $result
    else if (fn:root($anchor) = $anchor/..) then ()
    else local:find-candidate-by-anchor($version, $pathname, $anchor/..)
};

(: This allows for overrides where either the titles do not match or match too many with no pattern whatsoever. :)
declare variable $HARDCODED := map:map()
  => map:with("/guide/installation/appendix#id_pgfId-1052911", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/red-hat-enterprise-linux-7/marklogic-server.html")
  => map:with("/guide/installation/appendix#id_pgfId-1038023", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/red-hat-enterprise-linux-7/marklogic-converters.html")
  => map:with("/guide/installation/appendix#id_pgfId-1053295", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/red-hat-enterprise-linux-8/marklogic-server.html")
  => map:with("/guide/installation/appendix#id_pgfId-1053377", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/red-hat-enterprise-linux-8/marklogic-converters.html")
  => map:with("/guide/installation/appendix#id_pgfId-1053499", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/centos-7/marklogic-server.html")
  => map:with("/guide/installation/appendix#id_pgfId-1053581", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/centos-7/marklogic-converters.html")
  => map:with("/guide/installation/appendix#id_pgfId-1053685", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/centos-7/marklogic-server.html")
  => map:with("/guide/installation/appendix#id_pgfId-1053767", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/centos-7/marklogic-converters.html")
  => map:with("/guide/installation/appendix#id_pgfId-1053889", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/amazon-linux-1/marklogic-server.html")
  => map:with("/guide/installation/appendix#id_pgfId-1053971", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/amazon-linux-1/marklogic-converters.html")
  => map:with("/guide/installation/appendix#id_pgfId-1054075", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/amazon-linux-2/marklogic-server.html")
  => map:with("/guide/installation/appendix#id_pgfId-1054157", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/amazon-linux-2/marklogic-converters.html")

  (: need to repeat the above with actual version. we need to keep this list version specific. :)
  => map:with("/11.0/guide/installation/appendix#id_pgfId-1052911", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/red-hat-enterprise-linux-7/marklogic-server.html")
  => map:with("/11.0/guide/installation/appendix#id_pgfId-1038023", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/red-hat-enterprise-linux-7/marklogic-converters.html")
  => map:with("/11.0/guide/installation/appendix#id_pgfId-1053295", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/red-hat-enterprise-linux-8/marklogic-server.html")
  => map:with("/11.0/guide/installation/appendix#id_pgfId-1053377", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/red-hat-enterprise-linux-8/marklogic-converters.html")
  => map:with("/11.0/guide/installation/appendix#id_pgfId-1053499", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/centos-7/marklogic-server.html")
  => map:with("/11.0/guide/installation/appendix#id_pgfId-1053581", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/centos-7/marklogic-converters.html")
  => map:with("/11.0/guide/installation/appendix#id_pgfId-1053685", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/centos-7/marklogic-server.html")
  => map:with("/11.0/guide/installation/appendix#id_pgfId-1053767", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/centos-7/marklogic-converters.html")
  => map:with("/11.0/guide/installation/appendix#id_pgfId-1053889", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/amazon-linux-1/marklogic-server.html")
  => map:with("/11.0/guide/installation/appendix#id_pgfId-1053971", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/amazon-linux-1/marklogic-converters.html")
  => map:with("/11.0/guide/installation/appendix#id_pgfId-1054075", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/amazon-linux-2/marklogic-server.html")
  => map:with("/11.0/guide/installation/appendix#id_pgfId-1054157", "/11.0/guide/installation-guide/en/appendix--packages-by-linux-platform/amazon-linux-2/marklogic-converters.html")
  
  (: at the time of this writing, only admin in 10.0 is migrated, 11.0 is not. :)
  => map:with("/10.0/guide/admin/groups#id_marker-1042797", "/10.0/guide/admin-guide/en/groups/procedures-for-configuring-and-managing-groups/configuring-an-smtp.html")
  => map:with("/10.0/guide/admin/webdav#id_81091", "/10.0/guide/admin-guide/en/webdav-servers/example--setting-up-a-webdav-server-to-add-or-modify-documents-used-by-another-server.html")
  => map:with("/10.0/guide/admin/session-login#id_60460", "/10.0/guide/admin-guide/en/managing-user-requests-and-monitoring-login-attempts/storing-and-monitoring-the-last-user-login-attempt/displaying-the-last-login-information.html")
  => map:with("/10.0/guide/admin/backup_restore#id_96977", "/10.0/guide/admin-guide/en/backing-up-and-restoring-a-database/incremental-backup/including-new-forests-in-incremental-backups.html")
  => map:with("/10.0/guide/admin/backup_restore#id_70233", "/10.0/guide/admin-guide/en/backing-up-and-restoring-a-database/using-journal-archiving-with-incremental-backups.html")
  => map:with("/10.0/guide/admin/rolling-upgrades#id_93421", "/10.0/guide/admin-guide/en/rolling-upgrades/understanding-rolling-upgrades/rolling-upgrade-status-in-the-admin-interface.html")
  => map:with("/10.0/guide/admin/logfiles#id_42187", "/10.0/guide/admin-guide/en/log-files/viewing-access-log-files.html")
  => map:with("/10.0/guide/admin/config_manager#id_62060", "/10.0/guide/admin-guide/en/using-the-configuration-manager/exporting-and-importing-configurations/comparing-the-imported-configuration-with-the-current-configuration.html")
  => map:with("/10.0/guide/admin/merges#id_55008", "/10.0/guide/admin-guide/en/understanding-and-controlling-database-merges/setting-merge-policy/configuring-the-merge-policy.html")
  => map:with("/10.0/guide/admin/admin_inter", "/10.0/guide/admin-guide/en/administrative--admin--interface.html")
  => map:with("/10.0/guide/admin", "/10.0/guide/admin-guide/en/administrating-marklogic-server.html")
  
  (: list is used as key-value so repeat for 11 :)
  => map:with("/11.0/guide/admin/groups#id_marker-1042797", "/11.0/guide/admin-guide/en/groups/procedures-for-configuring-and-managing-groups/configuring-an-smtp-server.html")
  => map:with("/11.0/guide/admin/webdav#id_81091", "/11.0/guide/admin-guide/en/webdav-servers/example--setting-up-a-webdav-server-to-add-or-modify-documents-used-by-another-server.html")
  => map:with("/11.0/guide/admin/session-login#id_60460", "/11.0/guide/admin-guide/en/managing-user-requests-and-monitoring-login-attempts/storing-and-monitoring-the-last-user-login-attempt/displaying-the-last-login-information.html")
  => map:with("/11.0/guide/admin/backup_restore#id_96977", "/11.0/guide/admin-guide/en/backing-up-and-restoring-a-database/incremental-backup/including-new-forests-in-incremental-backups.html")
  => map:with("/11.0/guide/admin/backup_restore#id_70233", "/11.0/guide/admin-guide/en/backing-up-and-restoring-a-database/using-journal-archiving-with-incremental-backups.html")
  => map:with("/11.0/guide/admin/rolling-upgrades#id_93421", "/11.0/guide/admin-guide/en/rolling-upgrades/understanding-rolling-upgrades/rolling-upgrade-status-in-the-admin-interface.html")
  => map:with("/11.0/guide/admin/logfiles#id_42187", "/11.0/guide/admin-guide/en/log-files/viewing-access-log-files.html")
  => map:with("/11.0/guide/admin/merges#id_55008", "/11.0/guide/admin-guide/en/understanding-and-controlling-database-merges/setting-merge-policy/configuring-the-merge-policy.html")
  => map:with("/11.0/guide/admin/admin_inter", "/11.0/guide/admin-guide/en/administrative--admin--interface.html")
  => map:with("/11.0/guide/admin", "/11.0/guide/admin-guide/en/administrating-marklogic-server.html")
  
  (: list is used as key-value so repeat for no version that is currently 11 :)
  => map:with("/guide/admin/groups#id_marker-1042797", "/11.0/guide/admin-guide/en/groups/procedures-for-configuring-and-managing-groups/configuring-an-smtp-server.html")
  => map:with("/guide/admin/webdav#id_81091", "/11.0/guide/admin-guide/en/webdav-servers/example--setting-up-a-webdav-server-to-add-or-modify-documents-used-by-another-server.html")
  => map:with("/guide/admin/session-login#id_60460", "/11.0/guide/admin-guide/en/managing-user-requests-and-monitoring-login-attempts/storing-and-monitoring-the-last-user-login-attempt/displaying-the-last-login-information.html")
  => map:with("/guide/admin/backup_restore#id_96977", "/11.0/guide/admin-guide/en/backing-up-and-restoring-a-database/incremental-backup/including-new-forests-in-incremental-backups.html")
  => map:with("/guide/admin/backup_restore#id_70233", "/11.0/guide/admin-guide/en/backing-up-and-restoring-a-database/using-journal-archiving-with-incremental-backups.html")
  => map:with("/guide/admin/rolling-upgrades#id_93421", "/11.0/guide/admin-guide/en/rolling-upgrades/understanding-rolling-upgrades/rolling-upgrade-status-in-the-admin-interface.html")
  => map:with("/guide/admin/logfiles#id_42187", "/11.0/guide/admin-guide/en/log-files/viewing-access-log-files.html")
  => map:with("/guide/admin/merges#id_55008", "/11.0/guide/admin-guide/en/understanding-and-controlling-database-merges/setting-merge-policy/configuring-the-merge-policy.html")
  => map:with("/guide/admin/admin_inter", "/11.0/guide/admin-guide/en/administrative--admin--interface.html")
  => map:with("/guide/admin", "/11.0/guide/admin-guide/en/administrating-marklogic-server.html")
  
  => map:with("/10.0/guide/security", "/10.0/guide/security-guide/en/securing-marklogic-server.html")
;

declare function local:check-hard-coded(
  $full-path as xs:string,
  $hash as xs:string?
) {
  let $key := $full-path || $hash
  return map:get($HARDCODED, $key)
};

declare function local:check-redirect(
  $pathname as xs:string,
  $hash as xs:string?
) {
  let $full-path := local:add-version($pathname)
  let $filename := fn:concat("/apidoc", $full-path, ".xml")
  let $guide := fn:doc($filename)
  let $anchor := $guide//*:a[@id = fn:substring-after($hash, "#")]
  let $version := local:find-version($pathname)
  let $candidate := fn:head((
      local:check-hard-coded($full-path, $hash),
      local:find-candidate-by-anchor($version, $pathname, $anchor),
      local:find-candidate-by-title($version, $pathname, $guide//*:title),
      local:find-candidate-by-title($version, $pathname, $guide//*:guide-title),
      (: known as non-match for title. :)
      ()
    ))

  (: 
    /paligo/11.0/guide/installation-guide/en/procedures/configuring-the-first-and-subsequent-hosts/configuring-an-additional-host-in-a-cluster.html 

    <title xmlns="http://www.w3.org/1999/xhtml">Configuring an Additional Host in a Cluster</title>
  :)
  let $result := fn:replace($candidate, "^/paligo", "")
  return object-node {
    "redirect" : fn:count($candidate) gt 0,
    "target" : $result
  }
};

let $pathname := xdmp:get-request-field('pathname')
let $hash := xdmp:get-request-field('hash')
return local:check-redirect($pathname, $hash)
