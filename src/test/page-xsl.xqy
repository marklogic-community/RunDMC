xquery version "1.0-ml";

module namespace t="http://github.com/robwhitby/xray/test";

import module namespace at="http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

declare namespace ml="http://developer.marklogic.com/site/internal";

declare namespace xhtml = "http://www.w3.org/1999/xhtml";

declare variable $actual :=
  let $input :=
    <ml:code-tabs>
      <ml:code-tab lang="javascript">
        var foo = 'bar';
      </ml:code-tab>
      <ml:code-tab lang="xquery">
        let $foo := 'bar'
        return $foo
      </ml:code-tab>
    </ml:code-tabs>
  return xdmp:xslt-invoke("/view/page.xsl", $input);

(:
 : Expected output for the above:
  <div class="code-tabs" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns="http://www.w3.org/1999/xhtml">
    <ul class="nav nav-tabs" role="tablist">
      <li role="presentation" class="active">
        <a aria-controls="javascript" role="tab" href="#javascript-0">JavaScript</a>
      </li>
      <li role="presentation">
        <a aria-controls="xquery" role="tab" href="#xquery-0">XQuery</a>
      </li>
    </ul>
    <div class="tab-content">
      <div role="tabpanel" class="tab-pane active" id="javascript-0">
        <textarea class="code-tab javascript">
          var foo = 'bar';
        </textarea>
      </div>
      <div role="tabpanel" class="tab-pane" id="xquery-0">
        <textarea class="code-tab xquery">
          let $foo := 'bar'
          return $foo
        </textarea>
      </div>
    </div>
  </div>
 :)

declare %t:case function t:transform-happened()
{
  at:equal(fn:node-name($actual/node()), xs:QName("xhtml:div"))
};

declare %t:case function t:both-tabs-made()
{
  at:equal(
    fn:count($actual/xhtml:div/xhtml:ul/xhtml:li/xhtml:a[@role = "tab"]),
    2
  )
};

declare %t:case function t:first-content()
{
  at:true(
    fn:matches(
      $actual//xhtml:div[@role="tabpanel"]/xhtml:textarea[fn:matches(@class/fn:string(), "javascript")]/fn:string(),
      "\s*var foo = 'bar';\s*"
    )
  )
};

declare %t:case function t:second-content()
{
  at:true(
    fn:matches(
      $actual//xhtml:div[@role="tabpanel"]/xhtml:textarea[fn:matches(@class/fn:string(), "xquery")]/fn:string(),
      "\s*let \$foo := 'bar'\s*return \$foo\s*"
    )
  )
};

declare %t:case function t:js-ids-match()
{
  at:equal(
    $actual/xhtml:div/xhtml:ul/xhtml:li/xhtml:a[@aria-controls="javascript"]/@href/fn:string(),
    "#" || $actual//xhtml:div[@role="tabpanel"][./xhtml:textarea[fn:matches(@class/fn:string(), "javascript")]]/@id/fn:string()
  )
};
