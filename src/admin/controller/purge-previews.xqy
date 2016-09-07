(: This script deletes all the preview docs that were created before the current day.

   It should be invoked periodically, e.g., at 3am every day using a cron script with wget.

ASSUMPTION: Each preview doc is stored in /preview, and its file name starts with the
            date at the time the preview was created.
:)

let $today := current-date()
let $preview-docs := collection()/*[@preview-only eq 'yes']
let $deleted-docs :=
  for $p in $preview-docs
  let $uri      := base-uri($p)
  let $filename := substring-after($uri,"/preview/")
  let $date     := xs:date(substring($filename,1,10))
  return
    if ($date lt $today) then (
      xdmp:document-delete($uri),
      concat("Deleted: ",$uri, "&#x20;")
    )
    else ()
return
  (
    if ($deleted-docs) then
      xdmp:log($deleted-docs)
    else
      xdmp:log("All preview docs before today have already been purged.")
  )
