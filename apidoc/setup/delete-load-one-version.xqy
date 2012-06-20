xquery version "1.0-ml";

(: run this to delete one version and then do all the steps to load it :)

declare variable $srcdir  := xdmp:get-request-field("srcdir", "");
declare variable $staticdir  := xdmp:get-request-field("staticdir", "");
declare variable $version := xdmp:get-request-field("version", ""); 
declare variable $user := xdmp:get-request-field("user", ""); 
declare variable $pw := xdmp:get-request-field("pw", "");
(: host and port are currently hardcoded :) 
declare variable $connection := "http://localhost:9898/apidoc/setup/";
declare variable $options := 
    <options xmlns="xdmp:http">
       <authentication method="digest">
         <username>{$user}</username>
         <password>{$pw}</password>
       </authentication>
       <timeout>600</timeout>
     </options> ;
 
xdmp:set-request-time-limit(1200),

if ( $srcdir eq "" ) 
then fn:error(xs:QName("ERROR"), "You must specify a srcdir.")
else (),

if ( $staticdir eq "" ) 
then fn:error(xs:QName("ERROR"), "You must specify a staticdir.")
else (),

if ( $version eq "" ) 
then fn:error(xs:QName("ERROR"), "You must specify a version.")
else (),

(: Delete this version :)
xdmp:http-get(fn:concat($connection, "delete-raw-docs.xqy?version=", $version),
   $options),
xdmp:http-get(fn:concat($connection, "delete-docs.xqy?version=", $version),
   $options),
xdmp:http-get(fn:concat($connection, "delete-static-docs.xqy?version=", 
   $version),
   $options),
fn:concat("Deleted ", $version, " docs."),

(: README_FOR_NIGHTLY_BUILD.txt step 1 :)
xdmp:http-get(fn:concat($connection, "load-raw-docs.xqy?version=", $version, 
   "&amp;srcdir=", $srcdir),
   $options),
"Loaded raw docs.",

(: README_FOR_NIGHTLY_BUILD.txt step 2a :)
xdmp:http-get(fn:concat($connection, "consolidate-guides.xqy?version=", 
   $version),
   $options),
"Consolidated docs.",

(: README_FOR_NIGHTLY_BUILD.txt step 2b :)
xdmp:http-get(fn:concat($connection, "convert-guides.xqy?version=", $version),
   $options),
"Converted docs.",

(: README_FOR_NIGHTLY_BUILD.txt step 2c :)
xdmp:http-get(fn:concat($connection, "copy-guide-images.xqy?version=", 
   $version),
   $options),
"Copied images.",

(: README_FOR_NIGHTLY_BUILD.txt step 3a :)
xdmp:http-get(fn:concat($connection, "pull-function-docs.xqy?version=", 
   $version),
   $options),
"Pull function docs.",

(: README_FOR_NIGHTLY_BUILD.txt step 3b :)
xdmp:http-get(fn:concat($connection, "create-toc.xqy?version=", $version),
   $options),
"Created XML TOC.",

(: README_FOR_NIGHTLY_BUILD.txt step 3c :)
xdmp:http-get(fn:concat($connection, "render-toc.xqy?version=", $version),
   $options),
"Rendered HTML docs.",

(: README_FOR_NIGHTLY_BUILD.txt step 3d :)
xdmp:http-get(fn:concat($connection, "delete-old-toc.xqy?version=", $version),
   $options),
"Deleted old toc.",

(: README_FOR_NIGHTLY_BUILD.txt step 3e :)
xdmp:http-get(fn:concat($connection, "make-list-pages.xqy?version=", $version),
   $options),
"Made list pages.",

(: Building static docs :)
xdmp:http-get(fn:concat($connection, "load-static-docs.xqy?version=", $version, 
                        "&amp;staticdir=", $staticdir),
   $options),
"Loaded static docs.",

(: Run category tagger :)
xdmp:invoke("/setup/collection-tagger.xqy"),
"Ran collection tagger",

fn:concat("
Done loading ", $version, " docs.")


