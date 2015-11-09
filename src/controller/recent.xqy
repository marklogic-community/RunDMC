xquery version "1.0-ml";

declare namespace ml = "http://developer.marklogic.com/site/internal";

declare variable $POST := xs:QName("xs:Post");

declare variable $PAGE-SIZE := 10;

declare variable $BLOG-COLL := 'category/blog';

xdmp:to-json(
  (
    for $doc in cts:search(fn:doc(), cts:collection-query($BLOG-COLL))
    let $uri := fn:base-uri($doc)
    let $collections := xdmp:document-get-collections($uri)
    order by $doc/ml:last-updated descending
    return map:new((
      map:entry('uri', fn:replace($uri, '.xml', '')),
      map:entry('title', $doc/node()/ml:title/fn:string()),
      map:entry('type',
        if ($collections eq ($BLOG-COLL)) then 'blog'
        else 'dunno'),
      map:entry('short', $doc/node()/ml:short-description/fn:string())
    ))
  )[1 to $PAGE-SIZE]
)
