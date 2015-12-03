xquery version "1.0-ml";

module namespace s="http://marklogic.com/rundmc/api/static";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace api="http://marklogic.com/rundmc/api";
declare namespace h="http://www.w3.org/1999/xhtml";

declare option xdmp:mapping "false";

declare function s:static(
  $class as xs:string,
  $limitpfx as xs:string*
) as element(h:html)
{
  let $functions := /api:function-page[api:function/@class = $class
                                       or api:function/@mode = $class]

  (: for debugging, rename to $functions :)
  let $xfunctions := $functions[api:function-name =
                                  ("admin:appserver-copy",
                                   "xdmp:document-insert",
                                   "cts:word-query")
                               ]

  let $prefixes := distinct-values(for $prefix in ($functions/api:function/@prefix,
                                                   $functions/api:function/@object)
                                   where normalize-space($prefix) ne ''
                                   return
                                     $prefix)

  (: N.B. If you specify limitpfx, then some intra-function links may
     not resolve correctly.
  :)
  let $prefixes := if (empty($limitpfx))
                   then $prefixes
                   else $prefixes[. = $limitpfx]

  (: Sort them :)
  let $prefixes := for $prefix in $prefixes
                   order by $prefix
                   return $prefix

  let $html := xdmp:xslt-invoke("/apidoc/view/page.xsl",
                                document { $functions[1] })/*
  let $head := $html/h:head
  return
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>MarkLogic {$class} functions</title>
        { $head/node() except ($head/h:title | $head/h:script | $head/h:style) }
        <link href="/css/static.css" rel="stylesheet" type="text/css"/>
      </head>
      <body>
        <section id="static_content">
          <h1>MarkLogic {$class} functions</h1>
          <div class="toc">
            { if (count($prefixes) gt 1)
              then
                <p class="quicktoc">
                  <span class="qth">Quick toc: </span>
                  { for $prefix at $index in $prefixes
                    return
                      (if ($index gt 1) then " |&#160;" else (),
                       <a href="#toc.{$prefix}">{$prefix}</a>)
                  }
                </p>
              else
                ()
            }
            <dl>
              { for $prefix in $prefixes
                let $pfuncs := $functions[api:function/@prefix = $prefix
                                          or api:function/@object = $prefix]
                return
                  (<dt id="toc.{$prefix}">
                     <a href="#sec.{$prefix}">{ $prefix }</a>
                   </dt>,
                   <dd>
                     <ul>
                       { for $func in $pfuncs
                         order by $func/api:function-name
                         return
                           <li>
                             <a href="#{$func/api:function-name}">
                               { string($func/api:function-name) }
                             </a>
                           </li>
                       }
                     </ul>
                   </dd>)
              }
            </dl>
          </div>
          <div class="content">
            { for $prefix in $prefixes
              let $pfuncs := $functions[api:function/@prefix = $prefix
                                        or api:function/@object = $prefix]
              return
                <div class="prefix" id="sec.{$prefix}">
                  <h2>{$prefix} functions</h2>

                  <ul>
                    { for $func in $pfuncs
                      order by $func/api:function-name
                      return
                        <li>
                          <a href="#{$func/api:function-name}">
                            { string($func/api:function-name) }
                          </a>
                        </li>
                    }
                  </ul>

                  { for $func in $pfuncs
                    order by $func/api:function-name
                    return
                      <div class="function" id="{$func/api:function-name}">
                        { let $html := xdmp:xslt-invoke("/apidoc/view/page.xsl",
                                                        document { $func })
                          let $content := xdmp:xslt-invoke("filter.xsl", $html)
                          return
                            $content
                        }
                      </div>
                  }
                </div>
            }
          </div>
        </section>
        <div id="copyright">
          { substring-before(string($html/h:body//h:div[@id='copyright']), " | ") }
        </div>
      </body>
    </html>
};
