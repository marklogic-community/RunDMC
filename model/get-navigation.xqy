(: This query implements a basic caching mechanism for our $navigation info.
   It checks to see if the files and documents on which $navigation depends
   have been updated since the last time we pre-generated the $navigation,
   whether the draft version or the public-only version. If navigation.xml
   or any of the docs on which it depends have been updated since the last
   time we generated the fully populated navigation, then we must re-generate
   it afresh. Otherwise, we serve up the pre-generated navigation, thereby
   avoiding this costly operation on most server requests.
:) 
   
import module namespace draft = "http://developer.marklogic.com/site/internal/filter-drafts"
       at "filter-drafts.xqy";

declare namespace prop="http://marklogic.com/xdmp/property";
declare namespace dir ="http://marklogic.com/xdmp/directory";
declare namespace xdmp="http://marklogic.com/xdmp";

let $code-dir := xdmp:modules-root(),

    $config-dir := concat($code-dir,'config/'),

    $config-file := "navigation.xml",

    $pre-generated-location := if ($draft:public-docs-only) then "/private/public-navigation.xml"
                                                            else "/private/draft-navigation.xml",

    $pre-generated-navigation := doc($pre-generated-location),

    $last-generated := xdmp:document-properties($pre-generated-location)/*/prop:last-modified,

    $last-update :=

      let $config-last-updated := xdmp:filesystem-directory($config-dir)
                                  /dir:entry [dir:filename eq $config-file]
                                  /dir:last-modified,

          (: A happy side effect of using git is that any time we push
             code, the .git directory should show a new last-modified date;
             this should ensure that any and all code updates will invalidate
             the navigation cache :)
          $code-last-updated := xdmp:filesystem-directory($code-dir)
                                /dir:entry
                                /dir:last-modified,

          $doc-uris := $pre-generated-navigation//page/@href/concat(.,'.xml'),

          $docs-last-updated := max(xdmp:document-properties($doc-uris)/*/prop:last-modified)

      return
         max(($config-last-updated,
              $code-last-updated,
              $docs-last-updated))

return
   if (exists($pre-generated-navigation) and $last-generated gt $last-update)

   then $pre-generated-navigation

   else
     (: Here's where we pre-process navigation.xml with the blog post listings, etc. :)
     let $new-navigation := xdmp:xslt-invoke("/view/pre-process-navigation.xsl",
                                             xdmp:document-get(concat($config-dir,$config-file)))
     return
     (
        xdmp:document-insert($pre-generated-location, $new-navigation),
        $new-navigation
     )
