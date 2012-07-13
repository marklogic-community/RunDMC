xquery version "1.0-ml";
(: These functions filter out draft and/or preview-only documents, when applicable. :)
module namespace draft = "http://developer.marklogic.com/site/internal/filter-drafts";

(: TODO: Find a better mechanism than checking the server name, if possible :)
declare variable $public-docs-only := let $server-name := xdmp:server-name(xdmp:server())
                                      return fn:not(fn:contains($server-name,'Draft') or
                                                    fn:contains($server-name,'draft') or
                                                    fn:contains($server-name,'Admin') or
                                                    fn:contains($server-name,'admin'));

(: Hide "Draft" documents, if applicable :)
declare function allow($doc) as element()?
{
  if ($public-docs-only) then $doc[(@status eq 'Published') and fn:not(@preview-only)]
                         else $doc
};

(: Hide preview-only docs from being listed on the site and admin interface :)
declare function listed($doc) as element()?
{
  $doc[allow(.) and fn:not(@preview-only)]
};
