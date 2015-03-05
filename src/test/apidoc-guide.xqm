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

declare %t:case function t:code-does-not-interrupt-ordered-list()
{
  <chapter>
    <XML>
<Body>
<A ID="pgfId-1043441"></A>
There are several ways to accomplish this:</Body>
<Number1>
<A ID="pgfId-1043442"></A>
You can use the Admin Interface's load utility to load schema documents directly into a schema database. Go to the Database screen for the schema database into which you want to load documents. Select the load tab at top-right and proceed to load your schema as you would load any other document.</Number1>
<NumberList>
<Number>
<A ID="pgfId-1043443"></A>
You can create an XQuery program that uses the <Hyperlink>
<A href="#display.xqy?function=xdmp:eval" xml:link="simple" show="replace" actuate="user" CLASS="URL">xdmp:eval</A></Hyperlink>
 built-in function, specifying the <code>
&lt;database&gt;</code>
 option to load a schema directly into the current database's schema database:</Number>
</NumberList>
<Code>
<A ID="pgfId-1047363"></A>
xdmp:eval('xdmp:document-load(&quot;sample.xsd&quot;)', (),
&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&lt;options xmlns=&quot;xdmp:eval&quot;&gt;
&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&lt;database&gt;{xdmp:schema-database()}&lt;/database&gt;
&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&lt;/options&gt;)</Code>
<NumberList>
<Number>
<A ID="pgfId-1047364"></A>
You can create an XDBC or HTTP Server that directly references the schema database in question as its document database, and then use any document insertion function to load one or more schemas into that schema database.  This approach should not be necessary.</Number>
<Number>
<A ID="pgfId-1051705"></A>
You can create a WebDAV Server that references the Schemas database and then drag-and-drop schema documents in using a WebDAV client.</Number>
</NumberList>
<Heading-2>
<A ID="pgfId-1043446"></A>
<A ID="70282"></A>
Referencing Your Schema</Heading-2>
  </XML></chapter>
  ! document { . }
  ! at:equal(count(guide:normalize(., false())//ol), 1)
};

declare %t:case function t:sequence-does-not-interrupt-ordered-list()
{
  <chapter>
    <XML>
<Heading-2>
<A ID="pgfId-1043455"></A>
<A ID="17666"></A>
Working With Your Schema</Heading-2>
<Body>
<A ID="pgfId-1043456"></A>
It is sometimes useful to be able to explicitly read a schema from the database, either to return it to the outside world or to drive certain schema-driven query processing activities.</Body>
<Body>
<A ID="pgfId-1043457"></A>
Schemas are treated just like any other document by the system.  They can be inserted, read, updated and deleted just like any other document.  The difference is that schemas are usually stored in a secondary schema database, not in the document database itself.</Body>
<Body>
<A ID="pgfId-1043458"></A>
The most common activity developers want to carry out with schema is to read them.  There are two approaches to fetching a schema from the server explicitly:</Body>
<Number1>
<A ID="pgfId-1043459"></A>
You can create an XQuery that uses <Hyperlink>
<A href="#display.xqy?function=xdmp:eval" xml:link="simple" show="replace" actuate="user" CLASS="URL">xdmp:eval</A></Hyperlink>
 with the <code>
&lt;database&gt;</code>
 option to read a schema directly from the current database's schema database.  For example, the following expression will return the schema document loaded in the code example given above:</Number1>
<Code>
<A ID="pgfId-1043460"></A>
xdmp:eval('doc(&quot;sample.xsd&quot;)', (),
&#160;&#160;&lt;options xmlns=&quot;xdmp:eval&quot;&gt;
&#160;&#160;&#160;&#160;&lt;database&gt;{xdmp:schema-database()}&lt;/database&gt;
&#160;&#160;&lt;/options&gt;)</Code>
<Body-indent>
<A ID="pgfId-1043461"></A>
The use of the <code>
xdmp:schema-database</code>
 built-in function ensures that the <code>
sample.xsd</code>
 document is read from the current database's schema database.</Body-indent>
<NumberList>
<Number>
<A ID="pgfId-1043462"></A>
You can create an XDBC or HTTP Server that directly references the schema database in question as its document database, and then submit any XQuery as appropriate to read, analyze, update or otherwise work with the schemas stored in that schema database.  This approach should not be necessary in most instances.</Number>
</NumberList>
<EndList-root>
<A ID="pgfId-1043463"></A>
Other tasks that involve working with schema can be accomplished similarly.  For example, if you need to delete a schema, an approach modeled on either of the above (using <code>
xdmp:document-delete(&quot;sample.xsd&quot;)</code>
) will work as expected.  </EndList-root>
<Heading-2>
<A ID="pgfId-1051548"></A>
<A ID="42480"></A>
Validating XML Against a Schema</Heading-2>
  </XML></chapter>
  ! document { . }
  ! at:equal(count(guide:normalize(., false())//ol), 1)
};

declare %t:case function t:note-does-not-interrupt-ordered-list()
{
  <chapter>
    <XML>
<Heading-3>
<A ID="pgfId-1038082"></A>
<A ID="24432"></A>
Configuring Text Indexes</Heading-3>
<Body>
<A ID="pgfId-1038083"></A>
To configure text indexes for a particular database, complete the following procedure:</Body>
<Number1>
<A ID="pgfId-1038084"></A>
Click on the Databases icon on the left tree menu.</Number1>
<NumberList>
<Number>
<A ID="pgfId-1048377"></A>
Locate the database for which you want to view text index configuration settings, either in the tree menu or in the Database Summary table.</Number>
<Number>
<A ID="pgfId-1048378"></A>
Click the name of the database for which you want to view the settings. </Number>
<Number>
<A ID="pgfId-1038088"></A>
Scroll down until the text indexing controls are visible.</Number>
<Number>
<A ID="pgfId-1038089"></A>
Configure the text indexes for this database by selecting the appropriate radio buttons for each index type.</Number>
</NumberList>
<Body-indent>
<A ID="pgfId-1038090"></A>
Click on the <code>
true</code>
 radio button for a particular text index type if you want that index to be maintained. Click on the <code>
false</code>
 radio button for a particular text index type if you do not want that index to be maintained.</Body-indent>
<Note>
<A ID="pgfId-1038091"></A>
If word searches and stemmed searches are disabled (that is, the <code>
false</code>
 radio button is selected for <code>
word searches</code>
 and off is selected for <code>
stemmed searches</code>
), the settings for the other text indexes are ignored, as explained above.</Note>
<NumberList>
<Number>
<A ID="pgfId-1038092"></A>
Leave the rest of the parameters unchanged.</Number>
<Number>
<A ID="pgfId-1038093"></A>
Scroll to the top or bottom of the right frame and click OK.</Number>
</NumberList>
<Body>
<A ID="pgfId-1038094"></A>
The database now has the new text indexing configurations.</Body>
  </XML></chapter>
  ! document { . }
  ! at:equal(count(guide:normalize(., false())//ol), 1)
};

declare %t:case function t:warning-does-not-interrupt-ordered-list()
{
  <chapter>
    <XML>
<Heading-3>
<A ID="pgfId-1061677"></A>
<A ID="72532"></A>
Modifying the Password Plugin</Heading-3>
<Body>
<A ID="pgfId-1061688"></A>
The following example shows how to use the sample plugins to check for a minimum password length and to ensure that it contains at least on numeric character. </Body>
<WarningList>
<Warning>
<A ID="pgfId-1062771"></A>
Any errors in a plugin module will cause all requests to hit the error. It is therefore extremely important to test your plugins before deploying them in a production environment.</Warning>
</WarningList>
<Body>
<A ID="pgfId-1062776"></A>
To use and modify the sample password plugins, perform the following steps:</Body>
<Number1>
<A ID="pgfId-1062777"></A>
Copy the <code>
&lt;marklogic-dir&gt;Samples/Plugins/password-check-*.xqy</code>
 files to the <code>
Plugins</code>
 directory. For example:</Number1>
<Code>
<A ID="pgfId-1061842"></A>
cd /opt/MarkLogic/Plugins
cp ../Samples/Plugins/password-check-*.xqy .</Code>
<Body-indent>
<A ID="pgfId-1061849"></A>
If desired, rename the files when you copy them.</Body-indent>
<NumberList>
<Number>
<A ID="pgfId-1063030"></A>
If you want to modify any of the files (for example, <code>
password-check-minimum-length</code>
), open them in a text editor.</Number>
<Number>
<A ID="pgfId-1061902"></A>
Make any changes you desire. For example, to change the minimum length, find the <code>
pwd:minimum-length</code>
 function and change the 4 to a 6 (or to whatever you prefer). When you are done, the body of the function looks as follows:</Number>
</NumberList>
<Code>
<A ID="pgfId-1062049"></A>
if (fn:string-length($password) &lt; 6)
then &quot;password too short&quot;
else ()</Code>
<Body-indent>
<A ID="pgfId-1062105"></A>
This checks that the password contains at least 6 characters.</Body-indent>
<NumberList>
<Number>
<A ID="pgfId-1063016"></A>
Optionally, if you have renamed the files, change the second parameter to <Hyperlink>
<A href="#display.xqy?function=plugin:register" xml:link="simple" show="replace" actuate="user" CLASS="URL">plugin:register</A></Hyperlink>
 to the name you called the plugin files in the first step. For example, if you named the plugin file <code>
my-password-plugin.xqy</code>
, change the <Hyperlink>
<A href="#display.xqy?function=plugin:register" xml:link="simple" show="replace" actuate="user" CLASS="URL">plugin:register</A></Hyperlink>
 call as follows:</Number>
</NumberList>
<Code>
<A ID="pgfId-1063062"></A>
plugin:register($map, &quot;my-password-plugin.xqy&quot;)</Code>
<NumberList>
<Number>
<A ID="pgfId-1062028"></A>
Save your changes to the file.</Number>
<Warning>
<A ID="pgfId-1063103"></A>
If you made a typo or some other mistake that causes a syntax error in the plugin, any request you make to any App Server will throw an exception. If that happens, edit the file to correct any errors.</Warning>
<Number>
<A ID="pgfId-1063108"></A>
If you are using a cluster, copy your plugin to the <code>
Plugins</code>
 directory on each host in your cluster.</Number>
<Number>
<A ID="pgfId-1063138"></A>
Test your code to make sure it works the way you intend.</Number>
</NumberList>
<Body>
<A ID="pgfId-1062377"></A>
The next time you try and change a password, your new checks will be run. For example, if you try to make a single-character password, it will be rejected.</Body>
  </XML></chapter>
  ! document { . }
  ! at:equal(count(guide:normalize(., false())//ol), 1)
};

(: test/apidoc-guide.xqm :)