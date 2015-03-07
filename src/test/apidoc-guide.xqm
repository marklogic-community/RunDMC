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

declare %t:case function t:body-not-in-output()
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

declare %t:case function t:bulleted-output-as-li()
{
  <chapter>
    <XML>
<Body>
<A ID="pgfId-1074855"></A>
Transactions have either update or query type.</Body>
<BulletedList>
<Bulleted>
<A ID="pgfId-1074856"></A>
Query transactions use a system timestamp instead of locks.</Bulleted>
<Bulleted>
<A ID="pgfId-1074857"></A>
Update transactions acquire locks.</Bulleted>
</BulletedList>
  </XML></chapter>
  ! document { . }
  ! at:true(
    guide:transform(guide:normalize(., false())/*/XML,
      'fubar', document { () }, 'baz')/self::ul/cts:contains(., 'locks'))
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

declare %t:case function t:glossary-term-links-to-self()
{
<Body>
<A ID="pgfId-929578"></A>
<Bold>
JavaScript</Bold>
<A ID="78892"></A>
</Body>
  ! guide:transform-element(
    ., '/fubar/baz/glossary.xml', document { () }, 'fubar')
  ! at:true(child::a[@id eq 'JavaScript']
    and child::a[@href eq '#JavaScript'])
};

declare %t:case function t:glossary-term-produces-valid-id()
{
<Body>
<A ID="pgfId-929578"></A>
<Bold>
Distinguished Name (DN)</Bold>
<A ID="78892"></A>
</Body>
  ! at:empty(
    guide:transform-element(
      ., '/fubar/baz/glossary.xml', document { () }, 'fubar')
    /a/@id[not(. castable as xs:ID)])
};

declare %t:case function t:ordered-list-stops-at-heading()
{
  <chapter>
    <XML>
<Heading-3>
<A ID="pgfId-1058315"></A>
<A ID="70912"></A>
Creating a New App Server</Heading-3>
<Body>
<A ID="pgfId-1059368"></A>
In this section, you create a new HTTP App Server. An App Server is used to evaluate XQuery code against a MarkLogic database and return the results to a browser. This App Server uses the Documents database, which is installed as part of the MarkLogic Serverinstallation process. In <A href="xquery.xml#id(15787)" xml:link="simple" show="replace" actuate="user" CLASS="XRef">'Sample XQuery Application that Runs Directly Against an App Server' on page&#160;17</A>, you use this App Server to run a sample XQuery application. </Body>
<Body>
<A ID="pgfId-1059375"></A>
To create a new App Server, complete the following steps:</Body>
<Number1>
<A ID="pgfId-1059376"></A>
Open a new browser window or tab.</Number1>
<NumberList>
<Number>
<A ID="pgfId-1059377"></A>
Open the Admin Interface by navigating to the following URL (substitute your hostname if MarkLogic is not running on your local machine):</Number>
</NumberList>
<Body-indent>
<A ID="pgfId-1059379"></A>
<Hyperlink>
<A href="http://localhost:8001" xml:link="simple" show="replace" actuate="user" CLASS="URL">http://localhost:8001/</A></Hyperlink>
</Body-indent>
<NumberList>
<Number>
<A ID="pgfId-1059380"></A>
Log in with your admin username and password.</Number>
<Number>
<A ID="pgfId-1059381"></A>
Click the Groups icon on the left.</Number>
<Number>
<A ID="pgfId-1059382"></A>
Click on the Default icon within the Groups branch.</Number>
<Number>
<A ID="pgfId-1059383"></A>
Click on the App Servers icon within the Default group.</Number>
<Number>
<A ID="pgfId-1059384"></A>
Click the Create HTTP tab.</Number>
<Number>
<A ID="pgfId-1059385"></A>
Go to the HTTP Server Name field and enter TestServer.</Number>
</NumberList>
<Body-indent>
<A ID="pgfId-1059386"></A>
This is the name that the Admin Interface uses to reference your server on display screens and in user interface controls.</Body-indent>
<NumberList>
<Number>
<A ID="pgfId-1059387"></A>
Go to the Root directory field and enter Test.</Number>
</NumberList>
<Body-indent>
<A ID="pgfId-1059391"></A>
By default, the software looks for this directory in your MarkLogic Server program directory, as specified in the <Emphasis>
Installation Guide</Emphasis>
. You can also specify an absolute path (such as <code>
C:\MarkLogicFiles\Test</code>
 on a Windows platform or <code>
/space/test</code>
 on a Linux platform).</Body-indent>
<NumberList>
<Number>
<A ID="pgfId-1059395"></A>
Go to the Port field and enter 8005.</Number>
</NumberList>
<Body-indent>
<A ID="pgfId-1059396"></A>
The following screen shows an HTTP server with these values:</Body-indent>
<Graphic>
<A ID="pgfId-1059400"></A>
<IMAGE xml:link="simple" href="images/httpAdd.gif" show="embed" actuate="auto"/>
</Graphic>
<NumberList>
<Number>
<A ID="pgfId-1059401"></A>
Scroll down to Authentication and select <code>
application-level</code>
.</Number>
<Number>
<A ID="pgfId-1059402"></A>
Choose an admin user (it has the word <code>
admin</code>
 in parenthesis) as the Default User.</Number>
<Number>
<A ID="pgfId-1059403"></A>
Leave the privilege field blank.</Number>
</NumberList>
<Body-indent>
<A ID="pgfId-1059404"></A>
The following screen shows an HTTP server with these values</Body-indent>
<GraphicIndent>
<A ID="pgfId-1059408"></A>
<IMAGE xml:link="simple" href="images/authentication.gif" show="embed" actuate="auto"/>
</GraphicIndent>
<NumberList>
<Number>
<A ID="pgfId-1059409"></A>
Scroll to the top or bottom and click OK.</Number>
<Number>
<A ID="pgfId-1059410"></A>
See that TestServer is added to the HTTP Server branch.</Number>
</NumberList>
<Heading-3>
<A ID="pgfId-1059350"></A>
<A ID="72236"></A>
Creating the Sample XQuery Application</Heading-3>
  </XML></chapter>
  ! document { . }
  ! at:equal(count(guide:normalize(., false())//Heading-3), 2)
};

declare %t:case function t:ordered-list-through-code()
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

declare %t:case function t:ordered-list-through-graphic()
{
  <chapter>
    <XML>
<Heading-3>
<A ID="pgfId-1058315"></A>
<A ID="70912"></A>
Creating a New App Server</Heading-3>
<Body>
<A ID="pgfId-1059368"></A>
In this section, you create a new HTTP App Server. An App Server is used to evaluate XQuery code against a MarkLogic database and return the results to a browser. This App Server uses the Documents database, which is installed as part of the MarkLogic Serverinstallation process. In <A href="xquery.xml#id(15787)" xml:link="simple" show="replace" actuate="user" CLASS="XRef">'Sample XQuery Application that Runs Directly Against an App Server' on page&#160;17</A>, you use this App Server to run a sample XQuery application. </Body>
<Body>
<A ID="pgfId-1059375"></A>
To create a new App Server, complete the following steps:</Body>
<Number1>
<A ID="pgfId-1059376"></A>
Open a new browser window or tab.</Number1>
<NumberList>
<Number>
<A ID="pgfId-1059377"></A>
Open the Admin Interface by navigating to the following URL (substitute your hostname if MarkLogic is not running on your local machine):</Number>
</NumberList>
<Body-indent>
<A ID="pgfId-1059379"></A>
<Hyperlink>
<A href="http://localhost:8001" xml:link="simple" show="replace" actuate="user" CLASS="URL">http://localhost:8001/</A></Hyperlink>
</Body-indent>
<NumberList>
<Number>
<A ID="pgfId-1059380"></A>
Log in with your admin username and password.</Number>
<Number>
<A ID="pgfId-1059381"></A>
Click the Groups icon on the left.</Number>
<Number>
<A ID="pgfId-1059382"></A>
Click on the Default icon within the Groups branch.</Number>
<Number>
<A ID="pgfId-1059383"></A>
Click on the App Servers icon within the Default group.</Number>
<Number>
<A ID="pgfId-1059384"></A>
Click the Create HTTP tab.</Number>
<Number>
<A ID="pgfId-1059385"></A>
Go to the HTTP Server Name field and enter TestServer.</Number>
</NumberList>
<Body-indent>
<A ID="pgfId-1059386"></A>
This is the name that the Admin Interface uses to reference your server on display screens and in user interface controls.</Body-indent>
<NumberList>
<Number>
<A ID="pgfId-1059387"></A>
Go to the Root directory field and enter Test.</Number>
</NumberList>
<Body-indent>
<A ID="pgfId-1059391"></A>
By default, the software looks for this directory in your MarkLogic Server program directory, as specified in the <Emphasis>
Installation Guide</Emphasis>
. You can also specify an absolute path (such as <code>
C:\MarkLogicFiles\Test</code>
 on a Windows platform or <code>
/space/test</code>
 on a Linux platform).</Body-indent>
<NumberList>
<Number>
<A ID="pgfId-1059395"></A>
Go to the Port field and enter 8005.</Number>
</NumberList>
<Body-indent>
<A ID="pgfId-1059396"></A>
The following screen shows an HTTP server with these values:</Body-indent>
<Graphic>
<A ID="pgfId-1059400"></A>
<IMAGE xml:link="simple" href="images/httpAdd.gif" show="embed" actuate="auto"/>
</Graphic>
<NumberList>
<Number>
<A ID="pgfId-1059401"></A>
Scroll down to Authentication and select <code>
application-level</code>
.</Number>
<Number>
<A ID="pgfId-1059402"></A>
Choose an admin user (it has the word <code>
admin</code>
 in parenthesis) as the Default User.</Number>
<Number>
<A ID="pgfId-1059403"></A>
Leave the privilege field blank.</Number>
</NumberList>
<Body-indent>
<A ID="pgfId-1059404"></A>
The following screen shows an HTTP server with these values</Body-indent>
<GraphicIndent>
<A ID="pgfId-1059408"></A>
<IMAGE xml:link="simple" href="images/authentication.gif" show="embed" actuate="auto"/>
</GraphicIndent>
<NumberList>
<Number>
<A ID="pgfId-1059409"></A>
Scroll to the top or bottom and click OK.</Number>
<Number>
<A ID="pgfId-1059410"></A>
See that TestServer is added to the HTTP Server branch.</Number>
</NumberList>
<Heading-3>
<A ID="pgfId-1059350"></A>
<A ID="72236"></A>
Creating the Sample XQuery Application</Heading-3>
  </XML></chapter>
  ! document { . }
  ! at:equal(count(guide:normalize(., false())//ol), 1)
};

declare %t:case function t:order-list-through-note()
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

declare %t:case function t:ordered-list-through-sequence()
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

declare %t:case function t:ordered-list-through-table()
{
  <chapter>
    <XML>
<Heading-3>
<A ID="pgfId-1059350"></A>
<A ID="72236"></A>
Creating the Sample XQuery Application</Heading-3>
<Body>
<A ID="pgfId-1059437"></A>
To create and run the sample XQuery application, complete the following steps:</Body>
<Number1>
<A ID="pgfId-1057605"></A>
Use the following table to locate your MarkLogic Server <code>
Apps</code>
 directory (<Emphasis>
&lt;marklogic-dir&gt;/Apps</Emphasis>
):</Number1>
<TableAnchor>
<A ID="pgfId-1040803"></A>
</TableAnchor>
<TABLE>
<ROW>
<TH ROWSPAN="1" COLSPAN="1">
<CellHeading>
<A ID="pgfId-1050062"></A>
Platform</CellHeading>
</TH>
<TH ROWSPAN="1" COLSPAN="1">
<CellHeading>
<A ID="pgfId-1050064"></A>
Installation Directory</CellHeading>
</TH>
</ROW>
<ROW>
<CELL ROWSPAN="1" COLSPAN="1">
<CellBody>
<A ID="pgfId-1040792"></A>
Microsoft Windows</CellBody>
</CELL>
<CELL ROWSPAN="1" COLSPAN="1">
<CodeLeft>
<A ID="pgfId-1040794"></A>
C:\Program Files\MarkLogic\Apps</CodeLeft>
</CELL>
</ROW>
<ROW>
<CELL ROWSPAN="1" COLSPAN="1">
<CellBody>
<A ID="pgfId-1040796"></A>
Red Hat Linux</CellBody>
</CELL>
<CELL ROWSPAN="1" COLSPAN="1">
<CodeLeft>
<A ID="pgfId-1040798"></A>
/opt/MarkLogic/Apps</CodeLeft>
</CELL>
</ROW>
<ROW>
<CELL ROWSPAN="1" COLSPAN="1">
<CellBody>
<A ID="pgfId-1040800"></A>
Sun Solaris</CellBody>
</CELL>
<CELL ROWSPAN="1" COLSPAN="1">
<CodeLeft>
<A ID="pgfId-1040802"></A>
/opt/MARKlogic/Apps</CodeLeft>
</CELL>
</ROW>
<ROW>
<CELL ROWSPAN="1" COLSPAN="1">
<CellBody>
<A ID="pgfId-1058281"></A>
Mac OS X</CellBody>
</CELL>
<CELL ROWSPAN="1" COLSPAN="1">
<CodeLeft>
<A ID="pgfId-1058283"></A>
~/Library/MarkLogic/Apps</CodeLeft>
</CELL>
</ROW>
</TABLE>
<NumberList>
<Number>
<A ID="pgfId-1040805"></A>
Go to the <code>
Apps</code>
 directory (<Emphasis>
&lt;marklogic-dir&gt;/Apps</Emphasis>
) and create a new directory called <code>
Test</code>
.</Number>
<Number>
<A ID="pgfId-1040807"></A>
Open a text editor and create a new file called <code>
load.xqy</code>
 in the <code>
Test</code>
 directory. </Number>
<Number>
<A ID="pgfId-1049701"></A>
Copy and save the following code into this <code>
.xqy</code>
 file:</Number>
</NumberList>
<Code>
<A ID="pgfId-1058538"></A>
xquery version &quot;1.0-ml&quot;;
(: load.xqy :)
xdmp:document-insert(&quot;books.xml&quot;,
&lt;books xmlns=&quot;http://www.marklogic.com/ns/gs-books&quot;&gt;
&lt;book bookid=&quot;1&quot;&gt;
&lt;title&gt;A Quick Path to an Application&lt;/title&gt;
&lt;author&gt;
&lt;last&gt;Smith&lt;/last&gt;
&lt;first&gt;Jim&lt;/first&gt;
&lt;/author&gt;
&lt;publisher&gt;Scribblers Press&lt;/publisher&gt;
&lt;isbn&gt;1494-3930392-3&lt;/isbn&gt;
&lt;abstract&gt;This book describes in detail the power of how to use XQuery to build powerful web applications that are built on the MarkLogic Server platform.&lt;/abstract&gt;
&lt;/book&gt;
&lt;/books&gt;
),
&lt;html xmlns=&quot;http://www.w3.org/1999/xhtml&quot;&gt;
&lt;head&gt;
&lt;title&gt;Database loaded&lt;/title&gt;
&lt;/head&gt;
&lt;body&gt;
&lt;b&gt;Source XML Loaded&lt;/b&gt;
&lt;p&gt;The source XML has been successfully loaded into the database&lt;/p&gt;
&lt;/body&gt;
&lt;/html&gt;</Code>
<NumberList>
<Number>
<A ID="pgfId-1040810"></A>
Create another file called <code>
dump.xqy</code>
 in the <code>
Test</code>
 directory.</Number>
<Number>
<A ID="pgfId-1040811"></A>
Copy and save the following code into this <code>
.xqy</code>
 file:</Number>
</NumberList>
<Code>
<A ID="pgfId-1058569"></A>
xquery version &quot;1.0-ml&quot;;
(: dump.xqy :)
declare namespace bk = &quot;http://www.marklogic.com/ns/gs-books&quot;;
&lt;html xmlns=&quot;http://www.w3.org/1999/xhtml&quot;&gt;
&lt;head&gt;
&lt;title&gt;Database dump&lt;/title&gt;
&lt;/head&gt;
&lt;body&gt;
&lt;b&gt;XML Content&lt;/b&gt;
{{
for $book in doc('books.xml')/bk:books/bk:book
return
&lt;pre&gt;
Title: {{ $book/bk:title/text() }}
Author: {{ ($book/bk:author/bk:first/text(), ' ',
$book/bk:author/bk:last/text()) }}
Publisher: {{ $book/bk:publisher/text() }}
&lt;/pre&gt;
}}
&lt;a href='update-form.xqy'&gt;Update Publisher&lt;/a&gt;
&lt;/body&gt;
&lt;/html&gt;</Code>
<NumberList>
<Number>
<A ID="pgfId-1040813"></A>
Create another file called <code>
update-form.xqy</code>
 in the <code>
Test</code>
 directory.</Number>
<Number>
<A ID="pgfId-1040814"></A>
Copy and save the following code into this <code>
.xqy</code>
 file:</Number>
</NumberList>
<Code>
<A ID="pgfId-1058467"></A>
xquery version '1.0-ml';
(: update-form.xqy :)
declare namespace bk='http://www.marklogic.com/ns/gs-books';</Code>
<Code>
<A ID="pgfId-1058468"></A>
&lt;html xmlns='http://www.w3.org/1999/xhtml'&gt;
&lt;head&gt;
&lt;title&gt;Change Publisher&lt;/title&gt;
&lt;/head&gt;
&lt;body&gt;
{{
let $book := doc('books.xml')/bk:books/bk:book[1]
return
&lt;form action='update-write.xqy'&gt;
&lt;input type='hidden' name='bookid' value='{{ $book/@bookid }}'/&gt;
&lt;p&gt;&lt;b&gt;
Change publisher for book &lt;i&gt;{{ $book/bk:title/text() }}&lt;/i&gt;:
&lt;/b&gt;&lt;/p&gt;
&lt;input type='text' name='publisher'
value='{{ $book/bk:publisher/text() }}'/&gt;
&lt;input type='submit' value='Update publisher'/&gt;
&lt;/form&gt;
}}
&lt;/body&gt;
&lt;/html&gt;</Code>
<NumberList>
<Number>
<A ID="pgfId-1040816"></A>
Create another file called <code>
update-write.xqy</code>
 in the <code>
Test</code>
 directory.</Number>
<Number>
<A ID="pgfId-1040817"></A>
Copy and save the following code into this <code>
.xqy</code>
 file:</Number>
</NumberList>
<Code>
<A ID="pgfId-1058505"></A>
xquery version '1.0-ml';
(: update-write.xqy :)
declare namespace bk='http://www.marklogic.com/ns/gs-books';
declare function local:updatePublisher()
{{
if (doc('books.xml')) then
let $bookid := xdmp:get-request-field('bookid')
let $publisher := xdmp:get-request-field('publisher')
let $b := doc('books.xml')/bk:books/bk:book[@bookid = $bookid]
return
if ($b) then
(
xdmp:node-replace($b/bk:publisher,
&lt;bk:publisher&gt;{{ $publisher }}&lt;/bk:publisher&gt;)
,
xdmp:redirect-response('dump.xqy')
)
else
&lt;span&gt;Could not locate book with bookid {{ $bookid }}.&lt;/span&gt;
else
&lt;span&gt;Unable to access parent XML document.&lt;/span&gt;
}};
&lt;html xmlns='http://www.w3.org/1999/xhtml'&gt;
&lt;head&gt;
&lt;title&gt;Update In Process&lt;/title&gt;
&lt;/head&gt;
&lt;body&gt;
Attempting to complete update and redirect browser to detail page.
&lt;p&gt;
If you are seeing this page, either the redirect has failed
or the update has failed.  The update has failed if there is
a reason provided below:
&lt;br/&gt;
{{ local:updatePublisher() }}
&lt;/p&gt;
&lt;/body&gt;
&lt;/html&gt;</Code>
<NumberList>
<Number>
<A ID="pgfId-1040819"></A>
Confirm that you have the following new files in your <code>
Test</code>
 directory:</Number>
</NumberList>
<Body-bullet-2>
<A ID="pgfId-1040820"></A>
<code>
load.xqy</code>
</Body-bullet-2>
<Body-bullet-2>
<A ID="pgfId-1040821"></A>
<code>
dump.xqy</code>
</Body-bullet-2>
<Body-bullet-2>
<A ID="pgfId-1040822"></A>
<code>
update-form.xqy</code>
</Body-bullet-2>
<Body-bullet-2>
<A ID="pgfId-1040823"></A>
<code>
update-write.xqy</code>
</Body-bullet-2>
<NumberList>
<Number>
<A ID="pgfId-1040824"></A>
Confirm that all files end with the <code>
.xqy</code>
 extension, not the <code>
.txt</code>
 extension.</Number>
<Number>
<A ID="pgfId-1040825"></A>
Using these files, continue to the following procedures:</Number>
</NumberList>
<Body-bullet-2>
<A ID="pgfId-1040829"></A>
<A href="xquery.xml#id(31370)" xml:link="simple" show="replace" actuate="user" CLASS="XRef"><Hyperlink>
Loading the Source XML</Hyperlink>
</A></Body-bullet-2>
<Body-bullet-2>
<A ID="pgfId-1040833"></A>
<A href="xquery.xml#id(26869)" xml:link="simple" show="replace" actuate="user" CLASS="XRef"><Hyperlink>
Generating a Simple Report</Hyperlink>
</A></Body-bullet-2>
<Body-bullet-2>
<A ID="pgfId-1040837"></A>
<A href="xquery.xml#id(49941)" xml:link="simple" show="replace" actuate="user" CLASS="XRef"><Hyperlink>
Submitting New Information</Hyperlink>
</A></Body-bullet-2>
<Body-indent>
<A ID="pgfId-1040838"></A>
Be sure to complete these procedures in order.</Body-indent>
<Heading-4>
<A ID="pgfId-1040839"></A>
<A ID="31370"></A>
Loading the Source XML</Heading-4>
  </XML></chapter>
  ! document { . }
  ! at:equal(count(guide:normalize(., false())//ol), 1)
};

declare %t:case function t:order-list-through-text-node()
{
  <chapter>
    <XML>
<Heading-2>
<A ID="pgfId-1119613"></A>
<A ID="28962"></A>
Installing MarkLogic Server</Heading-2>
<Body>
<A ID="pgfId-1119620"></A>
This section describes the procedure for installing MarkLogic Server on each platform. Perform the procedure corresponding to the platform to which you are installing. </Body>
<Body>
<A ID="pgfId-1134459"></A>
If you are upgrading a cluster to a new release, see <A href="../cluster/config_cluster.xml#id(21237)" xml:link="simple" show="replace" actuate="user" CLASS="XRef"><Hyperlink>
Upgrading a Cluster to a New Maintenance Release of MarkLogic Server</Hyperlink>
</A> in the <Emphasis>
Scalability, Availability, and Failover Guide</Emphasis>
. The security database and the schemas database must be on the same host, and that host should be the first host you upgrade when upgrading a cluster.</Body>
<TableAnchor>
<A ID="pgfId-1120817"></A>
</TableAnchor>
<TABLE>
<ROW>
<TH ROWSPAN="1" COLSPAN="1">
<CellHeading>
<A ID="pgfId-1120800"></A>
Platform</CellHeading>
</TH>
<TH ROWSPAN="1" COLSPAN="1">
<CellHeading>
<A ID="pgfId-1120802"></A>
Perform the following:</CellHeading>
</TH>
</ROW>
<ROW>
<CELL ROWSPAN="1" COLSPAN="1">
<CellBody>
<A ID="pgfId-1120804"></A>
Windows x64</CellBody>
</CELL>
<CELL ROWSPAN="1" COLSPAN="1">
<Number1>
<A ID="pgfId-1120821"></A>
Shut down and uninstall the previous release of MarkLogic Server (if you are upgrading from 6.0, 5.0, or 4.2, see <A href="procedures.xml#id(49978)" xml:link="simple" show="replace" actuate="user" CLASS="XRef">'Upgrading from Release 6.0, 5.0,or 4.2' on page&#160;11</A>, if you are upgrading from 7.0-1 or later, see <A href="procedures.xml#id(53295)" xml:link="simple" show="replace" actuate="user" CLASS="XRef">'Removing MarkLogic Server' on page&#160;26</A>).</Number1>
fubar
<NumberList>
<Number>
<A ID="pgfId-1121081"></A>
Download the MarkLogic Server installation package to your desktop. The latest installation packages are available from <Hyperlink>
<A href="http://developer.marklogic.com" xml:link="simple" show="replace" actuate="user" CLASS="URL">http://developer.marklogic.com</A></Hyperlink>
.</Number>
<Number>
<A ID="pgfId-1120822"></A>
Double click the <code>
MarkLogic-7.0-1-amd64.msi</code>
 icon to start the installer.</Number>
</NumberList>
<Note>
<A ID="pgfId-1120823"></A>
If you are installing a release other than 7.0-1, double-click on the appropriately named installer icon.</Note>
<NumberList>
<Number>
<A ID="pgfId-1120824"></A>
The Welcome page displays. Click Next.</Number>
<Number>
<A ID="pgfId-1120826"></A>
Select Typical.</Number>
<Number>
<A ID="pgfId-1120827"></A>
Click Install.</Number>
<Number>
<A ID="pgfId-1120828"></A>
Click Finish.</Number>
</NumberList>
</CELL>
</ROW>
</TABLE>
  </XML></chapter>
  ! document { . }
  ! at:equal(count(guide:normalize(., false())//ol), 1)
};

declare %t:case function t:ordered-list-through-warning()
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