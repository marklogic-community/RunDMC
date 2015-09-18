xquery version "1.0-ml";

module namespace u="http://marklogic.com/rundmc/util";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace search = "http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

import module namespace prop = "http://xqdev.com/prop" at "/lib/properties.xqy";

import module namespace s = "http://marklogic.com/rundmc/server-urls" at "/controller/server-urls.xqy";

declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace em =    "URN:ietf:params:email-xml:";
declare namespace ml =    "http://developer.marklogic.com/site/internal";
declare namespace rf =    "URN:ietf:params:rfc822:";

(:
 : @author Eric Bloch
 : @date 21 April 2010
 :)

declare variable $OPTS-MODULES-DB := (
  <options xmlns="xdmp:eval">
    <database>{ xdmp:modules-database() }</database>
  </options>) ;

(:
 : @param $path /-prefixed string that is path to the file
 : that represents the document
 :
 : @return document read in from the give path, which is relative
 : to the current ML modules root
 : return empty sequence if no such file exists
 :)
declare function u:get-doc($path as xs:string)
  as node()?
{
  if (xdmp:modules-database() gt 0) then xdmp:invoke-function(
    function() {
      doc(
        replace(
          xdmp:modules-root()
          ||(if (ends-with($path, '/')) then '' else '/')
          ||$path,
          '//+', '/')) },
      $OPTS-MODULES-DB)
  else (
    let $apath := concat(xdmp:modules-root(), $path)
    where xdmp:filesystem-file-exists($apath)
    return xdmp:document-get($apath))
};

(:
 : @param $path /-prefixed string that is path to the XML file
 : that represents the document
 :
 : @return length of file
 :)
declare function u:get-doc-length($path as xs:string, $doc as node()?)
  as xs:unsignedLong?
{
  if (xdmp:modules-database() eq 0) then xdmp:filesystem-file-length(
    concat(xdmp:modules-root(), $path))
  else (
    typeswitch($doc)
    case binary() return xdmp:binary-size($doc)
    case text() return string-length($doc)
    default return string-length(xdmp:quote($doc)))
};

(:
 : @param $dir-uri
 :
 : @return true if the uri is a directory in the current DB
 : to the current ML modules root
 :)
declare function u:is-directory($uri as xs:string) as xs:boolean {
    xdmp:exists(xdmp:directory($uri, 'infinity'))
};

declare function u:strip-version-from-path($path as xs:string) {
  replace($path,'/[0-9]+\.[0-9]+/','/')
};

(:
 : @param $v millis since epoch
 :
 : convert epoch seconds to dateTime
 :)
declare function u:epoch-seconds-to-dateTime($v)
  as xs:dateTime
{
  xs:dateTime("1970-01-01T00:00:00-00:00") + xs:dayTimeDuration(concat("PT", $v, "S"))
};

declare function u:send-email($email, $name, $from-email, $from-name, $subject, $body)
{
    try {

        xdmp:email(

        <em:Message xmlns:em="URN:ietf:params:email-xml:" xmlns:rf="URN:ietf:params:rfc822:">
            <rf:subject>{$subject}</rf:subject>
            <rf:from>
                <em:Address>
                    <em:name>{$from-name}</em:name>
                    <em:adrs>{$from-email}</em:adrs>
                </em:Address>
            </rf:from>
            <rf:to>
                <em:Address>
                    <em:name>{$name}</em:name>
                    <em:adrs>{$email}</em:adrs>
                </em:Address>
            </rf:to>
            <em:content>{$body}</em:content>
        </em:Message>

        )
    } catch ($e) {
        xdmp:log(concat("FAILEDEMAIL:  Unable to send confirming e-mail to ", $email))
    }

};

declare function u:string-normalize($str as xs:string)
as xs:string
{
  lower-case(
    normalize-space(
      translate($str, '&#160;', ' ')))
};

declare function u:string-extract-first-sentence($str as xs:string)
  as xs:string
{
  let $pat := '^(.*?\.)\s.*$'
  let $str := normalize-space($str)
  return (
    if (not(matches($str, $pat, 's'))) then $str
    else replace($str, $pat, '$1', 's'))
};

declare function u:get-full-url()
  as xs:string
{
  xdmp:get-request-protocol() || ":" ||
    $s:main-server ||
    xdmp:get-original-url()
};

declare function u:get-page-title($content)
  as xs:string?
{
  (
    $content/ml:Post/ml:title/fn:string(),
    $content/ml:page/ml:product-info/@name,
    $content/ml:page/xhtml:h1,
    $content/ml:page/xhtml:h2
  )[1]
};

declare function u:get-page-description($content)
  as xs:string?
{
  (
    $content/ml:Post/ml:short-description/fn:string(),
    ($content//xhtml:p)[1]
  )[1]
};

(: util-2.xqy :)

