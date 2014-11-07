xquery version "1.0-ml";

let $pubs := '/pubs/4.1' 

let $doit := xdmp:get-request-field("doit")
let $_ := xdmp:set-response-content-type("text/html")

let $x :=
    for $u in cts:uris($pubs)
    where starts-with($u, $pubs)
    return
        if ($doit = 'doit') 
        then
            xdmp:document-delete($u)
        else
            ($u, <br/>)


return if ($doit = 'doit') 
then
   <b>"They're gone"</b>
else
    <html>
    <body>
    Remove all of
    <pre> { $x } </pre>
    <form action="clean-pubs.xqy?doit=doit" method="get">
        <input type="submit" value="This is irreversible!  Really do it?" />
    </form>
    </body>
    </html>
