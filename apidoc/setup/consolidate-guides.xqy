xquery version "1.0-ml";

import module namespace api="http://marklogic.com/rundmc/api"
       at "../model/data-access.xqy";

import module namespace u="http://marklogic.com/rundmc/util"
       at "../../lib/util-2.xqy";

(: Directory in which to find all the guide XML for the requested server version :)
declare variable $guides-dir := concat("/",$api:version,"/xml/");

(: One sub-dir for each guide :)
declare variable $sub-dirs := xdmp:directory-properties($guides-dir)/prop:properties/prop:directory/base-uri(.);

(: Just the name of each dir, not including the full path to it :)
declare function local:dir-name($dir) {
  substring-before(substring-after($dir, $guides-dir),"/")
};

(: The list of guide configs :)
declare variable $guide-list := u:get-doc("/apidoc/config/document-list.xml")/docs/guide;

for $dir in $sub-dirs return
(
  let $title-doc    := doc(concat($dir,'title.xml'))
  let $title        := $title-doc/XML/Title/normalize-space(.)
  let $guide-config := $guide-list[local:dir-name($dir) = tokenize(@source-names,' ')]
  let $url-name     := if ($guide-config) then $guide-config/@url-name else local:dir-name($dir)
  let $target-url   := concat("/",$api:version,"/guides/",$url-name,".xml")
  return
  (
    if ($guide-config/@exclude) then () else
    (
      xdmp:log(concat("Combining fragments into ",$target-url)),
      xdmp:document-insert($target-url,
        <guide original-dir="{$dir}">{
          <title>{$title}</title>,
          (: Get each XML doc in order, except for the title doc :)
          for $doc in xdmp:directory($dir)[XML] except $title-doc
          order by number(normalize-space($doc/pagenum))
          return $doc
        }</guide>
      ),
      xdmp:log("Done.")
    )
  )
)
