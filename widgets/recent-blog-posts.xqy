(: TODO: make this dynamic, using real data from the database :)
<ml:widget xmlns="http://www.w3.org/1999/xhtml" xmlns:ml="http://developer.marklogic.com/site/internal">
  <div class="head">
    <h2>Recent Blog Posts</h2>
    <a class="more" href="/blog">View blog</a>
  </div>


  <div class="body">
    <h3><a href="http://blakeley.com/wordpress/archives/560" target="_blank">Group By in XQuery 1.0 for MarkLogic Server</a></h3>
    <div class="author">by Michael Blakeley, August 23, 2011</div>
    <div class="message">
    <p>XQuery 3.0 introduces new syntax for “group by”. At this time, MarkLogic Server 4.2 is the latest release, and it doesn’t have support for that syntax. So how can we implement “group by” when writing XQuery for MarkLogic? Let’s start with the W3C use cases. First, let’s fetch the sample data and put it into MarkLogic...</p>
    </div>
  </div>

  <div class="body">
    <h3><a href="http://xquerywebappdev.wordpress.com/2011/08/23/technical-details-on-techniques-used-in-the-development-competition/" target="_blank">Technical details on techniques used in the development competition</a></h3>
    <div class="author">by Ryan Semerau, August 23, 2011</div>
    <div class="message">
    <p>The <a title="MarkLogic decidedly wins development competition" target="_blank" href="http://xquerywebappdev.wordpress.com/2011/08/20/marklogic-decidedly-wins-development-competition/">post on winning the development competition</a> has generated a lot of interest (relative to my other posts) so I&#8217;d thought I&#8217;d go into more detail about the technology we used. First, there are some guiding principles that I follow when it comes to xquery web apps on MarkLogic. They are not set in stone, and individual projects may deviate. But these are my starting points...</p> 
    </div>
  </div>

  <div class="body">
    <h3><a href="/blog/nosql-now-2011">Come see us at NoSQL Now! in San Jose, CA Aug 23-25</a></h3>
    <div class="author">by Eric Bloch, August 19, 2011</div>
    <div class="message">
    <p>It's actually a little hard not to be aware these days that NoSQL technologies are being adopted by enterprise developers. This is happening for a number of reasons including scale, agility, performance, and the individual features of these new tools. In general, we at MarkLogic see this as a positive trend in software development. The NoSQL buzz has removed "blinders" that, in the past, has resulted in many developers using relational technology somewhat, well, blindly. From our vantage point, again, these changes are positive ones that serve to remind us to choose the best tools and models for our needs...</p>
    </div>
  </div>

  <div class="body">
    <h3><a href="http://blog.davidcassel.net/2011/08/unparsing-a-custom-facet/" target="_blank">Unparsing a custom facet</a></h3>
    <div class="author">by David Cassel, August 13, 2011</div>
    <div class="message">
    <p>In many search applications, when we show the results of a user’s search, we also want to display the search that was done by putting the query string into a text box, especially if the search is built up from an advanced search screen. In some cases, we might want to modify the search before displaying it. For instance, part of your UI might be a control that removes a constraint from the current search. It’s pretty straightforward to convert the query string to cts:query elements, remove the particular constraint, and then convert the cts:query elements back to a query string. App Builder applications do this. But in order for that to work, your custom constraint needs to contain the information needed to unparse it...</p>
    </div>
  </div>



{(:
  <div class="body">
    <a class="more" href="">+ Show more</a>
  </div>
:)}

</ml:widget>

