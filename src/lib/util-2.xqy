xquery version "1.0-ml";

module namespace u="http://marklogic.com/rundmc/util";

import module namespace search = "http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace em =    "URN:ietf:params:email-xml:";
declare namespace rf =    "URN:ietf:params:rfc822:";

(:
 : @author Eric Bloch
 : @date 21 April 2010
 :)

declare default function namespace "http://www.w3.org/2005/xpath-functions";

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
  let $root := xdmp:modules-root()
  let $apath := fn:concat($root, $path)
  where xdmp:filesystem-file-exists($apath)
  return xdmp:document-get($apath)
};

(:
 : @param $path /-prefixed string that is path to the XML file
 : that represents the document
 :
 : @return length of file
 :)
declare function u:get-doc-length($path as xs:string)
  as xs:unsignedLong
{
  xdmp:filesystem-file-length(fn:concat(xdmp:modules-root(), $path))
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

declare function u:highlight-doc($doc, $highlight-search as xs:string, $external-uri) {
  cts:highlight($doc, cts:query(search:parse($highlight-search, search:get-default-options())),
                      <span class="hit_highlight"
                            xmlns="http://www.w3.org/1999/xhtml">{$cts:text}</span>)
};

declare function u:strip-version-from-path($path as xs:string) {
  fn:replace($path,'/[0-9]+\.[0-9]+/','/')
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

(: util-2.xqy :)