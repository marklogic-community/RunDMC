module namespace draft = "http://developer.marklogic.com/site/internal/filter-drafts";

(: TODO: Use a special server field with xdmp:get-server-field instead of hard-coding the server name :)
declare variable $public-docs-only := if ("CommunitySitePublic" eq xdmp:server-name(xdmp:server())) then fn:true()
                                                                                                    else fn:false();

(: Hide "Draft" documents, if applicable :)
declare function allow($doc) as element()?
{
  if ($public-docs-only) then $doc[fn:not(@status eq 'Draft')]
                         else $doc
};

declare function listed($doc) as element()?
{
  $doc[allow(.) and fn:not(@preview-only)]
};
