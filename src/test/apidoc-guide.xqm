xquery version "1.0-ml";
(: Test module for apidoc/guide :)

module namespace t="http://github.com/robwhitby/xray/test";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace at="http://github.com/robwhitby/xray/assertions"
  at "/xray/src/assertions.xqy";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";
import module namespace guide="http://marklogic.com/rundmc/api/guide"
  at "/apidoc/setup/guide.xqm";

declare %t:case function t:Body-not-in-output()
{
  <chapter>
    <XML>
      <h3>
        <a href="#id_19340" class="sectionLink">
  Create the Range Indexes for the Valid and System Axes
        </a>
      </h3>
      <Body>
        <a id="id_pgfId-1070770">
        </a>
  The valid and system axis each make use of
  <code>
  dateTime
  </code>
  range indexes that define the start and end times. For example, the following query creates the element range indexes to be used to create the valid and system axes.
      </Body>
      <Body>
        <a id="id_pgfId-1074121">
        </a>
  JavaScript Example:
      </Body>
      <pre>
  var admin = require("/MarkLogic/admin.xqy");
  var config = admin.getConfiguration();
  var dbid = xdmp.database("Documents");

  var validStart = admin.databaseRangeElementIndex(
    "dateTime", "", "validStart", "", fn.false() );

  var validEnd = admin.databaseRangeElementIndex(
    "dateTime", "", "validEnd", "", fn.false() );

  var systemStart = admin.databaseRangeElementIndex(
    "dateTime", "", "systemStart", "", fn.false() );

  var systemEnd = admin.databaseRangeElementIndex(
    "dateTime", "", "systemEnd", "", fn.false() );

  config = admin.databaseAddRangeElementIndex(config, dbid, validStart);
  config = admin.databaseAddRangeElementIndex(config, dbid, validEnd);
  config = admin.databaseAddRangeElementIndex(config, dbid, systemStart);
  config = admin.databaseAddRangeElementIndex(config, dbid, systemEnd);

  admin.saveConfiguration(config);
      </pre>
  </XML></chapter>
  ! document { . }
  ! guide:normalize(., false())
  ! guide:transform(*/XML, 'fubar', ., 'baz')
  ! at:empty(descendant-or-self::*:Body)
};

declare %t:case function t:code-output-with-em()
{
  <chapter>
    <XML>
      <Heading-4>
        <A ID="pgfId-1146448"></A>
        <A ID="65730"></A>
  insert</Heading-4>
  <Body>
    <A ID="pgfId-1146449"></A>
  Lorem ipsum <code>
  insert</code>
  operation structure:</Body>
  <Code>
    <A ID="pgfId-1146450"></A>
  "insert":
  "context": <Emphasis>
  path-expr</Emphasis>
  </Code>
  </XML></chapter>
  ! document { . }
  ! guide:normalize(., false())
  ! at:not-empty(
    guide:transform(*/XML, 'fubar', ., 'baz')/em)
};

(: test/apidoc-guide.xqm :)