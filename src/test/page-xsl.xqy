xquery version "1.0-ml";

module namespace t="http://github.com/robwhitby/xray/test";

import module namespace at="http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

declare namespace ml="http://developer.marklogic.com/site/internal";

declare namespace xhtml = "http://www.w3.org/1999/xhtml";

declare variable $code-actual :=
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

declare variable $data-actual :=
  let $input :=
    <ml:code-tabs>
      <ml:code-tab lang="json">
        &#123;
          "foo"&#58; "bar"
        &#125;
      </ml:code-tab>
      <ml:code-tab lang="xml">
        &lt;root&gt;
          &lt;foo&gt;bar&lt;/foo&gt;
        &lt;/root&gt;
      </ml:code-tab>
    </ml:code-tabs>
  return xdmp:xslt-invoke("/view/page.xsl", $input);


declare %t:case function t:code-transform-happened()
{
  at:equal(fn:node-name($code-actual/node()), xs:QName("xhtml:div"))
};

declare %t:case function t:code-both-tabs-made()
{
  at:equal(
    fn:count($code-actual/xhtml:div/xhtml:ul/xhtml:li/xhtml:a[@role = "tab"]),
    2
  )
};

declare %t:case function t:code-first-content()
{
  at:true(
    fn:matches(
      $code-actual//xhtml:div[@role="tabpanel"]/xhtml:textarea[fn:matches(@class/fn:string(), "javascript")]/fn:string(),
      "\s*var foo = 'bar';\s*"
    )
  )
};

declare %t:case function t:code-second-content()
{
  at:true(
    fn:matches(
      $code-actual//xhtml:div[@role="tabpanel"]/xhtml:textarea[fn:matches(@class/fn:string(), "xquery")]/fn:string(),
      "\s*let \$foo := 'bar'\s*return \$foo\s*"
    )
  )
};

declare %t:case function t:code-js-ids-match()
{
  at:equal(
    $code-actual/xhtml:div/xhtml:ul/xhtml:li/xhtml:a[@aria-controls="javascript"]/@href/fn:string(),
    "#" || $code-actual//xhtml:div[@role="tabpanel"][./xhtml:textarea[fn:matches(@class/fn:string(), "javascript")]]/@id/fn:string()
  )
};

declare %t:case function t:data-transform-happened()
{
  at:equal(fn:node-name($data-actual/node()), xs:QName("xhtml:div"))
};

declare %t:case function t:data-both-tabs-made()
{
  at:equal(
    fn:count($data-actual/xhtml:div/xhtml:ul/xhtml:li/xhtml:a[@role = "tab"]),
    2
  )
};

declare %t:case function t:data-first-content()
{
  let $actual := $data-actual//xhtml:div[@role="tabpanel"]/xhtml:textarea[fn:matches(@class/fn:string(), "json")]/fn:string()
  return
    at:true(
      fn:matches(
        $actual,
        '\s*\{\s*"foo": "bar"\s*\}\s*'
      ),
      "Found: " || $actual
    )
};

declare %t:case function t:data-second-content()
{
  let $actual := $data-actual//xhtml:div[@role="tabpanel"]/xhtml:textarea[fn:matches(@class/fn:string(), "xml")]/fn:string()
  return
    at:true(
      fn:matches(
        $actual,
        "\s*<root>\s*<foo>bar</foo>\s*</root>\s*"
      ),
      "Found: " || $actual
    )
};

declare %t:case function t:data-js-ids-match()
{
  at:equal(
    $data-actual/xhtml:div/xhtml:ul/xhtml:li/xhtml:a[@aria-controls="json"]/@href/fn:string(),
    "#" || $data-actual//xhtml:div[@role="tabpanel"][./xhtml:textarea[fn:matches(@class/fn:string(), "json")]]/@id/fn:string()
  )
};
