(: This script is the entry point for all HTTP requests to the Admin server.
   You must configure your server to use this script as the URL rewriter.
:)
import module namespace param="http://marklogic.com/rundmc/params"
       at "../../controller/modules/params.xqy";

let $params  := param:params()

let $path            := xdmp:get-request-path()

let $doc-url         := concat('/admin', $path, ".xml")
let $orig-url        := xdmp:get-request-url()
let $query-string    := substring-after($orig-url, '?')

return

     (: Static files in the database :)
     if (starts-with($path,'/media/'))   then concat("/controller/get-db-file.xqy?uri=", $path)

     (: Admin home page :)
else if ($path eq "/")                   then concat("/admin/controller/transform.xqy?src=/admin/index")

     (: create.xqy is special; we may need to send an error message without doing an external redirect
        in the event that a user tries to create a document that already exists at the desired URI. :)
else if ($path eq "/admin/controller/create.xqy")
                                         then let $doc-slug    := string($params[@name eq '~new_doc_slug'])
                                              let $new-doc-url := concat($params[@name eq '~uri_prefix'], $doc-slug, '.xml')
                                              let $slug-provided := normalize-space($doc-slug)
                                           return
                                           (: If the document doesn't already exist, we're good. Dispatch to create.xqy as intended. :)
                                           if ($slug-provided and not(doc-available($new-doc-url))) then concat($orig-url, "?~new_doc_url=", $new-doc-url)

                                           else let $error-code := if (not($slug-provided)) then "no-slug" else "doc-exists"
                                             return
                                             (: But if the document *does* already exist or the user did not specify a slug, then re-generate the form, pre-populated
                                                with the values the user has already supplied, and tell the renderer to include an appropriate error message :)
                                                  concat("/admin/controller/transform.xqy?src=/admin", $params[@name eq '~edit_form_url'], "&amp;~orig_path=",
                                                                                                       $params[@name eq '~edit_form_url'], "&amp;~error_code=", $error-code)
     (: If it's an admin page, then render it :)
else if (doc-available($doc-url))        then concat("/admin/controller/transform.xqy?src=/admin", $path, "&amp;", $query-string, "&amp;~orig_path=", $path)

     (: Otherwise, it must be some other file, e.g., CSS or JS :)
                                         else $orig-url
