xquery version "1.0-ml";

module namespace so="http://marklogic.com/stackoverflow";

import module namespace json="http://marklogic.com/json" at "../../lib/mljson/lib/json.xqy";

(: 
 : @author Eric Bloch
 : @date 27 October 2011
 :)

declare default function namespace "http://www.w3.org/2005/xpath-functions";

(:
:)
declare function so:widget($query as xs:string, $num as xs:int) {
(
    let $json := fn:doc("/private/stack-overflow.json")/text()
    return
      <article>
        <h4><a href="">xquery performance &amp; patterns resources</a></h4>
        <div>Can anyone suggest me some good reading about Xquery performance and design patterns.... <span class="author_date">2011-08-29 <a href="">mbrevoort</a> <strong>1463</strong></span></div>
        <div class="votes">
          1 vote
          <div>2 answers</div>
        </div>
      </article>,
      <article>
        <h4><a href="">Marklogic Xquery fn:data(hello world) giving Invalid lexical value error</a></h4>
        <div>Lorem ipsum dolor sit amet, consectetur adipiscing elit... <span class="author_date">2011-08-29 <a href="">mbrevoort</a> <strong>1463</strong></span></div>
        <div class="votes">
          1 vote
          <div>2 answers</div>
        </div>
      </article>,
      <article>
        <h4><a href="">xquery performance &amp; patterns resources</a></h4>
        <div>Can anyone suggest me some good reading about Xquery performance and design patterns.... <span class="author_date">2011-08-29 <a href="">mbrevoort</a> <strong>1463</strong></span></div>
        <div class="votes">
          1 vote
          <div>2 answers</div>
        </div>
      </article>
)
};
