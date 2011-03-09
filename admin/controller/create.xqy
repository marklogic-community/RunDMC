(: This script handles the creation of new documents from the Admin UI;

   NOTE: the URL rewriter ensures that, if we get this far, that means
   there won't be any conflict with storing the new document at the
   given URI.
:)
import module namespace param="http://marklogic.com/rundmc/params"
       at "../../controller/modules/params.xqy";

import module namespace ml="http://developer.marklogic.com/site/internal"
       at "../../model/data-access.xqy";

let $params      := param:params()
let $new-doc-url := $params[@name eq '~new_doc_url']
let $map         := map:map()

(: Create the XML from the given POST parameters :)
let $new-doc     := xdmp:xslt-invoke("../model/form2xml.xsl",
                                     document{ <empty/> },
                                     (map:put($map, "params", $params),$map)
                                    )
return
(
  (: Insert the new document :)
  xdmp:document-insert($new-doc-url, $new-doc),

  (: Insert a container for corresponding conversations (comments) :)
  xdmp:document-insert(concat('/private/comments',$new-doc-url),
                       document{ <ml:Comments disqus_identifier="disqus-{$new-doc-url}"/> }),

  (: Invalidate the navigation cache :)
  ml:invalidate-cached-navigation(),

  (: Redirect to the Edit page for the newly created document :)
  xdmp:redirect-response(concat($params[@name eq '~edit_form_url'],
                                "?~doc_path=", $new-doc-url,

                                (: Include a timestamp showing when
                                   the document was last saved :)
                                "&amp;~updated=", current-dateTime())
                        )
)
