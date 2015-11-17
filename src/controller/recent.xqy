xquery version "1.0-ml";

import module namespace ml="http://developer.marklogic.com/site/internal" at "/model/data-access.xqy" ;

declare variable $POST := xs:QName("xs:Post");

declare variable $PAGE-SIZE := 5;

declare variable $BLOG-COLL := 'category/blog';
declare variable $TUTORIAL-COLL := 'category/tutorial';
declare variable $CONTENT-COLLS := ($BLOG-COLL, $TUTORIAL-COLL);

xdmp:to-json(
  (
    let $query :=
      cts:and-query((
        cts:collection-query($CONTENT-COLLS),
        cts:element-attribute-value-query($ml:doc-element-names, QName("","status"), "Published")
      ))
    for $doc in cts:search(fn:doc(), $query)
    let $uri := fn:base-uri($doc)
    let $collections := xdmp:document-get-collections($uri)
    order by $doc/node()/ml:last-updated descending
    return map:new((
      map:entry('uri', fn:replace($uri, '.xml', '')),
      map:entry('title', $doc/node()/ml:title/fn:string()),
      map:entry('type',
        if ($collections eq $BLOG-COLL) then 'blog'
        else if ($collections eq $TUTORIAL-COLL) then 'tutorial'
        else 'unknown'),
      map:entry('short',
        ($doc/node()/ml:short-description/fn:string(),
         $doc/node()/ml:description/fn:string())[1])
    ))
  )[1 to $PAGE-SIZE]
)
