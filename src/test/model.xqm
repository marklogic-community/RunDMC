xquery version "1.0-ml";
(: Test module for main model :)

module namespace t="http://github.com/robwhitby/xray/test";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace at="http://github.com/robwhitby/xray/assertions"
  at "/xray/src/assertions.xqy";

import module namespace ml="http://developer.marklogic.com/site/internal"
  at "/model/data-access.xqy";

declare %t:case function t:category-from-guide-installation()
{
  at:equal(
    ml:category-for-doc(
      "/8.0/guide/installation/intro.xml",
      document{
        <chapter original-dir="/8.0/xml/install_all/"
        guide-uri="/apidoc/8.0/guide/installation.xml"
        previous="/apidoc/8.0/guide/installation.xml"
        next="/apidoc/8.0/guide/installation/procedures.xml"
        number="1">
        <guide-title>Installation Guide for All Platforms</guide-title>
      </chapter> }),
    ('guide', 'guide/installation'))
};

declare %t:case function t:category-from-guide-cc()
{
  at:equal(
    ml:category-for-doc(
      "/apidoc/6.0/guide/cc.xml",
      document{
        <guide guide-uri="/apidoc/6.0/guide/cc.xml"
        next="/apidoc/6.0/guide/cc/intro.xml">
          <guide-title>Common Criteria Evaluated Configuration Guide</guide-title>
        </guide> }),
    ('guide', 'guide/cc'))
};

(: test/model.xqm :)