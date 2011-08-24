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
    <h3><a href="/blog/nosql-now-2011">Come see us at NoSQL Now! in San Jose, CA Aug 23-25</a></h3>
    <div class="author">by Eric Bloch, August 19, 2011</div>
    <div class="message">
    <p>It's actually a little hard not to be aware these days that NoSQL technologies are being adopted by enterprise developers. This is happening for a number of reasons including scale, agility, performance, and the individual features of these new tools. In general, we at MarkLogic see this as a positive trend in software development. The NoSQL buzz has removed "blinders" that, in the past, has resulted in many developers using relational technology somewhat, well, blindly. From our vantage point, again, these changes are positive ones that serve to remind us to choose the best tools and models for our needs...</p>
    </div>
  </div>

  <div class="body">
    <h3><a href="/blog/learning-with-query-trace">Learning with xdmp:query-trace()</a></h3>
    <div class="author">by Evan Lenz, July 20, 2011</div>
    <div class="message">
    <p>One
    of the things I love to do is learn and help other people learn.
    I'm still relatively new to MarkLogic, so there's a lot I can't
    really write about, since I haven't learned it yet. But as long as
    I keep my learning one step ahead of my writing, then I (and you
    readers!) should be safe and not wildly misled. One
    tool I've been using to learn how MarkLogic evaluates queries is
    the xdmp:query-trace() function...</p>
    </div>
  </div>

  <div class="body">
    <h3><a href="/blog/good-xml-design-and-performance">Good XML design and performance</a></h3>
    <div class="author">by Evan Lenz, July 14, 2011</div>
    <div class="message">
    <p>MarkLogic has always tried to ensure that
    well-designed XML performs well "as is" in MarkLogic Server. For example, if your
    schema uses descriptive, unique element names, that is not only
    going to make your application code clean and readable but it will
    be fast too. On the other hand, if your schema contains a lot of
    generic element names (such as "item") used in multiple ways, then
    it's going to make for harder-to-read code (in XQuery or XSLT), and
    it might also require you to do some extra leg work to get the best
    performance...</p> 
    </div>
  </div>



{(:
  <div class="body">
    <a class="more" href="">+ Show more</a>
  </div>
:)}

</ml:widget>

