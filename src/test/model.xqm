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

declare %t:case function t:build-recipe()
{
  at:equal(
    ml:build-recipe(
      (),
      (
      <param name="~new_doc_url">/recipe/second.xml</param>,
      <param name="~edit_form_url">/recipe/edit</param>,
      <param name="~updated"/>,
      <param name="~uri_prefix">/recipe/</param>,
      <param name="~new_doc_slug">second</param>,
      <param name="status">Draft</param>,
      <param name="title">My Title</param>,
      <param name="author[1]">First Author</param>,
      <param name="author[2]">Second Author</param>,
      <param name="last_updated"/>,
      <param name="min_server_version">8</param>,
      <param name="tag[1]">tag1</param>,
      <param name="tag[2]">tag2</param>,
      <param name="description">here is the description</param>,
      <param name="problem">here is the problem</param>,
      <param name="solution">here is the &lt;p xmlns="http://www.w3.org/1999/xhtml"&gt;solution&lt;/p&gt;</param>,
      <param name="discussion">here is the discussion</param>,
      <param name="see-also">here is the see-also</param>
    )),
    document {
      <ml:Recipe xmlns="http://www.w3.org/1999/xhtml" status="Draft">
        <ml:title>My Title</ml:title>
        <ml:author>First Author</ml:author>
        <ml:author>Second Author</ml:author>
        <ml:created>{fn:current-dateTime()}</ml:created>
        <ml:last-updated>{fn:current-dateTime()}</ml:last-updated>
        <ml:min-server-version>8</ml:min-server-version>
        <ml:tags>
          <ml:tag>tag1</ml:tag>
          <ml:tag>tag2</ml:tag>
        </ml:tags>
        <ml:description>here is the description</ml:description>
        <ml:problem>here is the problem</ml:problem>
        <ml:solution>here is the <p>solution</p></ml:solution>
        <ml:discussion>here is the discussion</ml:discussion>
        <ml:see-also>here is the see-also</ml:see-also>
      </ml:Recipe>
    }
  )
};

declare %t:case function t:rebuild-recipe()
{
  at:equal(
    ml:build-recipe(
      document {
        <ml:Recipe xmlns="http://www.w3.org/1999/xhtml" status="Draft">
          <ml:title>Original Title</ml:title>
          <ml:author>Original First Author</ml:author>
          <ml:author>Original Second Author</ml:author>
          <ml:created>2016-12-13T16:40:35.077403-05:00</ml:created>
          <ml:last-updated>2016-12-14T16:40:35.077403-05:00</ml:last-updated>
          <ml:min-server-version>8</ml:min-server-version>
          <ml:tags>
            <ml:tag>original tag1</ml:tag>
            <ml:tag>original tag2</ml:tag>
          </ml:tags>
          <ml:description>here is the original description</ml:description>
          <ml:problem>here is the original problem</ml:problem>
          <ml:solution>here is the original solution</ml:solution>
          <ml:discussion>here is the original discussion</ml:discussion>
          <ml:see-also>here is the original see-also</ml:see-also>
        </ml:Recipe>
      },
      (
        <param name="~existing_doc_url">/recipe/second.xml</param>,
        <param name="~edit_form_url">/recipe/edit</param>,
        <param name="~updated"/>,
        <param name="~uri_prefix">/recipe/</param>,
        <param name="~new_doc_slug">second</param>,
        <param name="status">Published</param>,
        <param name="title">New Title</param>,
        <param name="author[1]">First Author</param>,
        <param name="author[2]">Second Author</param>,
        <param name="last_updated">2016-12-15T16:40:35.077403-05:00</param>,
        <param name="min_server_version">8</param>,
        <param name="tag[1]">tag1</param>,
        <param name="tag[2]">tag2</param>,
        <param name="description">here is the description</param>,
        <param name="problem">here is the problem</param>,
        <param name="solution">here is the solution</param>,
        <param name="discussion">here is the discussion</param>,
        <param name="see-also">here is the see-also</param>
      )
    ),
    document {
      <ml:Recipe xmlns="http://www.w3.org/1999/xhtml" status="Published">
        <ml:title>New Title</ml:title>
        <ml:author>First Author</ml:author>
        <ml:author>Second Author</ml:author>
        <ml:created>2016-12-13T16:40:35.077403-05:00</ml:created>
        <ml:last-updated>2016-12-15T16:40:35.077403-05:00</ml:last-updated>
        <ml:min-server-version>8</ml:min-server-version>
        <ml:tags>
          <ml:tag>tag1</ml:tag>
          <ml:tag>tag2</ml:tag>
        </ml:tags>
        <ml:description>here is the description</ml:description>
        <ml:problem>here is the problem</ml:problem>
        <ml:solution>here is the solution</ml:solution>
        <ml:discussion>here is the discussion</ml:discussion>
        <ml:see-also>here is the see-also</ml:see-also>
      </ml:Recipe>
    }
  )
};

declare %t:case function t:rebuild-recipe-no-updated-timestamp()
{
  at:equal(
    ml:build-recipe(
      document {
        <ml:Recipe xmlns="http://www.w3.org/1999/xhtml" status="Draft">
          <ml:title>Original Title</ml:title>
          <ml:author>Original First Author</ml:author>
          <ml:author>Original Second Author</ml:author>
          <ml:created>2016-12-13T16:40:35.077403-05:00</ml:created>
          <ml:last-updated>2016-12-14T16:40:35.077403-05:00</ml:last-updated>
          <ml:min-server-version>8</ml:min-server-version>
          <ml:tags>
            <ml:tag>original tag1</ml:tag>
            <ml:tag>original tag2</ml:tag>
          </ml:tags>
          <ml:description>here is the original description</ml:description>
          <ml:problem>here is the original problem</ml:problem>
          <ml:solution>here is the original solution</ml:solution>
          <ml:discussion>here is the original discussion</ml:discussion>
          <ml:see-also>here is the original see-also</ml:see-also>
        </ml:Recipe>
      },
      (
        <param name="~existing_doc_url">/recipe/second.xml</param>,
        <param name="~edit_form_url">/recipe/edit</param>,
        <param name="~updated"/>,
        <param name="~uri_prefix">/recipe/</param>,
        <param name="~new_doc_slug">second</param>,
        <param name="status">Published</param>,
        <param name="title">New Title</param>,
        <param name="author[1]">First Author</param>,
        <param name="author[2]">Second Author</param>,
        <param name="last_updated"/>,
        <param name="min_server_version">8</param>,
        <param name="max_server_version">9</param>,
        <param name="tag[1]">tag1</param>,
        <param name="tag[2]">tag2</param>,
        <param name="description">here is the description</param>,
        <param name="problem">here is the problem</param>,
        <param name="solution">here is the solution</param>,
        <param name="discussion">here is the discussion</param>,
        <param name="see-also">here is the see-also</param>
      )
    ),
    document {
      <ml:Recipe xmlns="http://www.w3.org/1999/xhtml" status="Published">
        <ml:title>New Title</ml:title>
        <ml:author>First Author</ml:author>
        <ml:author>Second Author</ml:author>
        <ml:created>2016-12-13T16:40:35.077403-05:00</ml:created>
        <ml:last-updated>{fn:current-dateTime()}</ml:last-updated>
        <ml:min-server-version>8</ml:min-server-version>
        <ml:max-server-version>9</ml:max-server-version>
        <ml:tags>
          <ml:tag>tag1</ml:tag>
          <ml:tag>tag2</ml:tag>
        </ml:tags>
        <ml:description>here is the description</ml:description>
        <ml:problem>here is the problem</ml:problem>
        <ml:solution>here is the solution</ml:solution>
        <ml:discussion>here is the discussion</ml:discussion>
        <ml:see-also>here is the see-also</ml:see-also>
      </ml:Recipe>
    }
  )
};

(: test/model.xqm :)
