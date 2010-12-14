(: TODO: make this dynamic, using real data from the database :)
<ml:widget xmlns="http://www.w3.org/1999/xhtml" xmlns:ml="http://developer.marklogic.com/site/internal">
  <div class="head">
    <h2>Recent Blog Posts</h2>
    <a class="more" href="/blog">View blog</a>
  </div>

  <div class="body">
    <h3><a href="http://blog.jclark.com/2010/11/xml-vs-web_24.html">XML vs. the Web</a></h3>
    <div class="author">by Jim Clark, November 11, 2010</div>
    <br/>
    <div class="message">
        <p>
        Twitter and Foursquare recently removed XML support from their Web APIs, and now support only JSON.  This prompted Norman Walsh 
        to write an <a href="http://norman.walsh.name/2010/11/17/deprecatingXML">interesting post</a>, in which he summarised his reaction as 
        <a href="http://en.wikipedia.org/wiki/Meh">"Meh"</a>. I won't try to summarise his post; it's short and well-worth reading.
        </p>
        <p>
        From one perspective, it's hard to disagree.  If you're an XML wizard with a decade or two of experience...
        </p>
    </div>
  </div>

  <div class="body">
    <h3><a href="http://blogs.avalonconsult.com/blog/generic/realtime-push-with-marklogic-and-nodejs-via-websockets/">Realtime Push with MarkLogic and Node.js via Websockets</a></h3>
    <div class="author">by Mike Brevoort, November 16, 2010</div>
    <br/>
    <div class="message">
    <p>
MarkLogic has an awesome alerting feature that enables you to trigger an event when new or updated database content matches certain criteria. Once a rule’s criteria is met, an action is triggered that executes an arbitrary XQuery module. You can send an email, an SMS message, perhaps place a phone call with the <a href="http://www.twilio.com/">Twillio API</a>, modify other content in the database, whatever your heart desires. But what if you want to deliver realtime notifications to a user in a browser?
    </p>
    <p>
    Enter <a href="http://dev.w3.org/html5/websockets/">Websockets</a>...
    </p>
    </div>
  </div>

  <div class="body">
    <h3><a href="/blog/">Announcing the availability of MarkLogic Server 4.2 Standard Edition AMI for EC2</a></h3>
    <div class="author">by Dipti Borkar, November 9, 2010</div>
    <br/>
    <div class="message">We are pleased to announce the availability of <a href="/products/server-for-ec2">MarkLogic Server 4.2 Standard Edition AMI (Amazon Machine Image) on EC2</a>. MarkLogic Server 4.2 brings you increased agility...
    </div>
  </div>

{(:
  <div class="body">
    <a class="more" href="">+ Show more</a>
  </div>
:)}

</ml:widget>

