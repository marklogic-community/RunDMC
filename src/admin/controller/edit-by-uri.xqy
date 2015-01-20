import module namespace param="http://marklogic.com/rundmc/params"
       at "../../controller/modules/params.xqy";
import module namespace ml="http://developer.marklogic.com/site/internal"
       at "../../model/data-access.xqy";

let $params   := param:params()
let $uri      := string($params[@name eq 'edit_uri'])

return
  if(fn:doc-available($uri)) then
    (: Determine the type of doc based on its root element :)
    let $root-qname := fn:node-name(fn:doc($uri)/*)

    let $path :=
      if($root-qname = xs:QName("ml:Announcement")) then
        "news"
      else if($root-qname = xs:QName("ml:Article") or $root-qname = xs:QName("ml:Tutorial")) then
        "learn"
      else if($root-qname = xs:QName("ml:Event")) then
        "events"
      else if($root-qname = xs:QName("ml:page")) then
        "pages"
      else if($root-qname = xs:QName("ml:Post")) then
        "blog"
      else if($root-qname = xs:QName("ml:Project")) then
        "code"
      else
        ()

    (: Redirect the user to the appropriate edit page, or display an error :)
    return
      if($path) then
        let $redirect := fn:concat("/", $path, "/edit?~doc_path=", $uri)
        return xdmp:redirect-response($redirect)
      else
        "Cannot edit this document in the Admin app"
  else
    "Document does not exist for this URI"
