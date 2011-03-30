(: stripped-down version of docapp code for initial TOC mockup purposes :)
xquery version "1.0-ml";

declare namespace apidoc="http://marklogic.com/xdmp/apidoc";

declare boundary-space preserve;

declare variable $guideroot as xs:string := fn:concat($root, "xml/")  ;

declare variable $order as xs:string+ :=
("admin", "adminAPI", "dev_guide", "search-dev-guide", "appbuilder", 
 "info_studio", "security","cpf", "gs", "xcc", "xquery", "cluster", 
 "performance", "replication", "ec2", "SharePoint-Connector", "install_all", 
 "messages", "relnotes", "shared", "MarkLogic Built-In Functions", 
 "XQuery Library Modules"  )
 ;

declare variable $dir as xs:string* := 
    let $uris := for $x in xdmp:directory-properties($guideroot) 
                 return xdmp:node-uri($x)
    for $z in $uris
    let $name := fn:substring-before(fn:substring-after($z, $guideroot), "/")
    order by $guideroot, index-of($order, $name)
    return $z 
;

declare variable $modcats as xs:string* :=
  for $i in cts:element-attribute-values(xs:QName("apidoc:function"),
     xs:QName("category"), "",
     ("collation=http://marklogic.com/collation//S1/T00BB/AS"),
     cts:directory-query($apidir, "infinity"))       
  order by $i
  return fn:normalize-space($i)
;


declare variable $version as xs:string := "4.2" ;

declare variable $root as xs:string :=
   fn:concat("http://pubs/", $version, "doc/") 
 ;
declare variable $apidir as xs:string := fn:concat($root, "apidoc/")  ;

declare variable $buckets as xs:string* :=
  if ( fn:contains(xdmp:version(), "4.0")  )
  then ( "MarkLogic Built-In Functions" )
  else () ,  
  for $i in cts:element-attribute-values(xs:QName("apidoc:function"),
     xs:QName("bucket"), "", 
     ("collation=http://marklogic.com/collation//S1/T00BB/AS"), 
     cts:directory-query($apidir))       
  order by fn:index-of($order, $i)
  return fn:normalize-space($i)
 ;

declare function local:guide-tree()
as element(top)
{
element top {
   attribute label {"Dev and Admin Guides"},
   attribute uri { "start.xqy" },
     for $bookdir in $dir
     let $uri := fn:concat($bookdir, "title.xml")
     return
     element sections {
        attribute label {fn:doc($uri)//Title},
	attribute uri { fn:concat("display.xqy?fname=", 
                                   xdmp:url-encode($uri))},
        let $page-uris := 
           for $doc in xdmp:directory($bookdir)
           where fn:ends-with(xdmp:node-uri($doc), ".xml")
           order by xs:integer(fn:normalize-space(fn:string-join(
                          $doc//pagenum/text(),"")))
           return xdmp:node-uri($doc)
        for $node in $page-uris[fn:position() > 1]
        let $sec := fn:doc($node)/XML/Heading-1-root
        return 
        element section {
           attribute label { fn:data($sec/Heading-1) },
           attribute uri { $node },
         
           for $sub in fn:doc($node)/XML/Heading-1-root/Heading-2-root
           return (
           element subsection {
             attribute label {fn:data($sub/Heading-2)},
             attribute uri { fn:concat( $node, xdmp:url-encode("#"), 
                 fn:data(($sub/Heading-2/A/@ID)[fn:last()])) },
             
             for $frag in $sub/Heading-3-root
             return
             element fragment {
              attribute label {fn:data($frag/Heading-3)},
              attribute uri { fn:concat(xdmp:node-uri($frag), 
                   xdmp:url-encode("#"), 
                   fn:data(($frag/Heading-3/A/@ID)[fn:last()]) ) }
             } (: fragment :)
           } (: subsection :) )
         }  (: section :)  
       } (: sections :) 
   } (:top :)
 } ;



declare function local:api-tree()
as element(top)
{

element top {
  attribute label {"XQuery &amp; XSLT API Reference"},
   attribute uri { "functionSummary.xqy" },
    for $group in $buckets
    return (
      element sections {
        attribute label { $group },
	attribute uri { fn:concat("functionSummary.xqy?bucket=", $group) },
	   for $category in $modcats 
	   let $lib := fn:string( (xdmp:directory($apidir, "infinity")
             /apidoc:module/apidoc:function[@category eq 
                  xs:string($category)])[1]/@lib )
           where if ( $group eq "MarkLogic Built-In Functions" and
                      fn:contains(xdmp:version(), "4.0") )
                 then  (  $category = 
                          (for $x in xdmp:directory($apidir, "infinity")
                          /apidoc:module/apidoc:function[fn:not(@bucket)]
                          [@lib ne "fn"]/@category return fn:string($x) ) )
                 else (
                 $category = 
                 (: the lexicon call below replaces the following XPath:
                   xdmp:directory($g:apidir, "infinity")
                          /apidoc:module/apidoc:function[@bucket eq $group]
                          /@category 
                          return fn:string($x)
                 :)
                 cts:element-attribute-values(xs:QName("apidoc:function"), 
                   xs:QName("category"), (), 
                   ("collation=http://marklogic.com/collation//S1/T00BB/AS"),
                   cts:and-query((
                     cts:element-attribute-value-query(
                       xs:QName("apidoc:function"), xs:QName("bucket"), 
                       $group),
                     cts:directory-query($apidir, "infinity"),
                     cts:element-attribute-value-query(
                       xs:QName("apidoc:function"), xs:QName("hidden"), 
                       "false")
                   )) )
                 )
	   return
              let $excluded := ("LastLogin.xml", "GeospatialBuiltins.xml", 
                                "Crypt.xml")
              (: the following correspond to the list above to replace names :)
              let $replace-with := ("Extension.xml", "SearchBuiltins.xml",
                                    "Extension.xml")
              let $caturi := fn:concat(
                xdmp:node-uri((xdmp:directory($apidir, "infinity")
                /apidoc:module/apidoc:function
                       [@category eq xs:string($category)]
           (: exclude document-get-collections, because it is from Security :)
                       [fn:string(@name) ne "document-get-collections"])[1]),
                "&amp;category=", $category)
              let $null := 
                  for $name at $i in $excluded
                  return (xdmp:set($caturi, 
                        fn:replace($caturi, $name, $replace-with[$i]))) 
              return 
              element section {
                attribute label { 
                  if ( fn:ends-with($category, "Builtins") )
                  then ( fn:concat(fn:substring-before($category, "Builtins"), 
		       " (", $lib,":",")") )
                  else ( fn:concat($category, 
                     if ( $category = ("Geospatial Supporting Functions",
                                       "Modular Documents") ) 
                     then ("") else (fn:concat(" (", $lib, ":", ")"))  ) ) },
                attribute uri { $caturi },
                let $functions := xdmp:directory($apidir, "infinity")
                    /apidoc:module/apidoc:function[@category eq 
                          xs:string($category)][fn:not(@hidden eq fn:true())]
                let $subcats := 
                  cts:element-attribute-values(xs:QName("apidoc:function"), 
                   xs:QName("subcategory"), (), 
                   ("collation=http://marklogic.com/collation//S1/T00BB/AS"),
                   cts:and-query((
                     cts:element-attribute-value-query(
                       xs:QName("apidoc:function"), xs:QName("category"), 
                       $category),
                     cts:directory-query($apidir, "infinity") 
                   )) )
                      (: fn:distinct-values($functions/@subcategory) :)
                return
                if ( not($subcats) )
                then (
                for $func in $functions
                let $fullname := fn:string($func/@fullname)
                order by $fullname
                return (
                   element subsection {
                       attribute label { $fullname },
                       attribute id { $fullname },
                       attribute uri { fn:concat($caturi, "&amp;function=", 
                                                  $fullname) } 
			} (: subsection :) ) )
                else (
                for $sub in $subcats
                order by $sub
                return (
                   element subsection {
                       attribute label { if ( fn:contains($sub, ":" ) )
                          then ( fn:concat($sub, " Functions") )
                          else ( fn:concat(fn:upper-case(
                          fn:substring($sub, 1, 1)), fn:substring($sub, 2), 
                                " Functions") ) },
                       attribute id { $sub },
                       attribute uri { 
                          fn:concat($caturi, "&amp;sub=", $sub) },
                       for $func in $functions[@subcategory eq xs:string($sub)]
                       let $fullname := fn:string($func/@fullname)
                       order by $fullname
                       return
                       element subsubsection { 
                          attribute label { $fullname },
                          attribute id { $fullname },
                          attribute uri { fn:concat($caturi, "&amp;function=", 
                                                  $fullname) }
			} (: subsubsection :)  
		}  (: subsection :) ) ) 
	      }  (: sections :)
	   } ) (: section :)
	} (: top :)
} ;

<all>{
local:guide-tree(),
local:api-tree()
}</all>
