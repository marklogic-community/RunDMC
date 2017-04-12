xquery version "1.0-ml";

module namespace t = "http://github.com/robwhitby/xray/test";

import module namespace at="http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace atom = "http://www.marklogic.com/blog/atom" at "/lib/atom-lib.xqy";

declare option xdmp:mapping "false";

declare %t:case function t:next-link-first-page()
{
  at:equal(
    atom:next-link("http://dmc.com/recipe/atom.xml", fn:true(), 1),
    <link xmlns="http://www.w3.org/2005/Atom" href="http://dmc.com/recipe/atom.xml?page=2" rel="next"/>
  )
};

declare %t:case function t:next-link-second-page()
{
  at:equal(
    atom:next-link("http://dmc.com/recipe/atom.xml?page=2", fn:true(), 2),
    <link xmlns="http://www.w3.org/2005/Atom" href="http://dmc.com/recipe/atom.xml?page=3" rel="next"/>
  )
};

declare %t:case function t:next-link-second-page-no-more()
{
  at:equal(
    atom:next-link("http://dmc.com/recipe/atom.xml?page=2", fn:false(), 2),
    ()
  )
};

declare %t:case function t:prev-link-first-page()
{
  at:equal(
    atom:prev-link("http://dmc.com/recipe/atom.xml", 1),
    ()
  )
};

declare %t:case function t:prev-link-first-page-explicit()
{
  at:equal(
    atom:prev-link("http://dmc.com/recipe/atom.xml?page=1", 1),
    ()
  )
};

declare %t:case function t:prev-link-second-page()
{
  at:equal(
    atom:prev-link("http://dmc.com/recipe/atom.xml?page=2", 2),
    <link xmlns="http://www.w3.org/2005/Atom" href="http://dmc.com/recipe/atom.xml?page=1" rel="prev"/>
  )
};
