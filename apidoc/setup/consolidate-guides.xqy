xquery version "1.0-ml";

import module namespace api="http://marklogic.com/rundmc/api"
       at "../model/data-access.xqy";

import module namespace u="http://marklogic.com/rundmc/util"
       at "../../lib/util-2.xqy";

(: Directory in which to find all the guide XML for the requested server version :)
declare variable $guide-dir := concat("/",$api:version,"/xml/");

(: One sub-dir for each guide :)
declare variable $sub-dirs := xdmp:directory-properties($guide-dir)/prop:properties/prop:directory/base-uri(.);

declare variable $sub-dir-names := for $dir in $sub-dirs return local:dir-name($dir);

(: Just the name of each dir, not including the full path to it :)
declare function local:dir-name($dir) {
  substring-before(substring-after($dir, $guide-dir),"/")
};

(: Each configured guide that's applicable to the current version :)
declare variable $guide-list := u:get-doc("/apidoc/config/document-list.xml")/docs/guide[tokenize(@source-names,' ') = $sub-dir-names];

(: Use document order of config file :)
for $guide in $guide-list return
(
  (: Only one directory should match :)
  let $dir as xs:string := $sub-dirs[local:dir-name(.) = $guide/tokenize(@source-names,' ')]
  let $title-doc        := doc(concat($dir,'title.xml'))
  let $title            := $title-doc/XML/Title/normalize-space(.)
  let $target-url       := concat("/",$api:version,"/combined/",$guide/@url-name,".xml")
  return
  (
    xdmp:log(concat("Combining fragments into ",$target-url)),
    xdmp:document-insert($target-url,
      <guide>{
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
