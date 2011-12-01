(: This script is designed to be manually run just once
   in order to create the comments/conversation infrastructure
   that's needed for existing pages to be comment-enabled.

   New documents will automatically get the comments doc
   created as they're added via the Admin UI.

   It's probably best to set up a separate, temporary app
   server that doesn't use URL rewriting in order to easily
   run this script and other maintenance scripts like it.
:)

import module namespace ml = "http://developer.marklogic.com/site/internal"
       at "../model/data-access.xqy";

declare variable $docs := $ml:live-dmc-documents;

(: Get a preview of what we're getting :)
(: for $doc in $docs order by base-uri($doc) return base-uri($doc) :)

for $doc in $docs return (
  (: concat('/private/comments',base-uri($doc)):)

  ml:insert-comment-doc(base-uri($doc))
)
