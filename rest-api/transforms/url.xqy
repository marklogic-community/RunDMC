xquery version "1.0-ml";
module namespace trns = "http://marklogic.com/rest-api/transform/url";

declare namespace roxy = "http://marklogic.com/roxy";

declare namespace search = "http://marklogic.com/appservices/search";

(: REST API transforms managed by Roxy must follow these conventions:

1. Their filenames must reflect the name of the transform.

For example, an XQuery transform named add-attr must be contained in a file named add-attr.xqy
and have a module namespace of "http://marklogic.com/rest-api/transform/add-attr".

2. Must declare the roxy namespace with the URI "http://marklogic.com/roxy".

declare namespace roxy = "http://marklogic.com/roxy";

3. Must annotate the transform function with the transform parameters:

%roxy:params("uri=xs:string", "priority=xs:int")

These can be retrieved with map:get($params, "uri"), for example.

:)

declare function trns:change($node)
{
  typeswitch($node)
  case element(search:result) return
    element search:result {
      $node/@*,
      attribute url {
        let $uri := $node/@uri
        return
          if (fn:starts-with($uri, '/www.marklogic.com')) then
            fn:replace(fn:replace($uri, '/www.marklogic.com', '//www.marklogic.com'), '.xml', '/')
          else if (fn:starts-with($uri, '/apidoc/')) then
            "//docs.marklogic.com" || $uri
          else
            "//developer.marklogic.com" || $uri
      },
      $node/*
    }
  case element() return
    element { fn:node-name($node) } {
      $node/@*,
      $node/node() ! trns:change(.)
    }
  case document-node() return
    document {
      $node/node() ! trns:change(.)
    }
  default return $node
};

declare function trns:transform(
  $context as map:map,
  $params as map:map,
  $content as document-node()
) as document-node()
{
  trns:change($content)
};
