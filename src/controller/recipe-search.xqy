xquery version "1.0-ml";

declare namespace ml = "http://developer.marklogic.com/site/internal";

xdmp:set-response-content-type("application/json"),

let $query := cts:directory-query("/recipe/", "infinity")
let $total := xdmp:estimate(cts:search(fn:doc(), $query))
let $results :=
  cts:search(
    fn:doc(),
    $query
  )[1 to 10]
return object-node {
  "total": $total,
  "recipes": array-node {
    for $recipe in $results
    return
      object-node {
        "title": fn:normalize-space($recipe/ml:Recipe/ml:title/fn:string()),
        "url": fn:replace(fn:base-uri($recipe), ".xml", ""),
        "problem": fn:normalize-space($recipe/ml:Recipe/ml:problem/fn:string()),
        "minVersion": fn:normalize-space($recipe/ml:Recipe/ml:min-server-version/fn:string()),
        "maxVersion": fn:normalize-space($recipe/ml:Recipe/ml:max-server-version/fn:string()),
        "tags": array-node {
          $recipe/ml:Recipe/ml:tags/ml:tag/fn:string()
        }
      }
  }
}
