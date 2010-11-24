(: TODO: make this dynamic, using real data from the database :)
<ml:widget xmlns="http://www.w3.org/1999/xhtml" xmlns:ml="http://developer.marklogic.com/site/internal">
  <div class="head">
    <h2>Recent Blog Posts</h2>
    <a class="more" href="/blog">View all</a>
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

  <div class="body">
    <h3><a href="http://newsletter.marklogic.com/2010/10/fernando-mesa-presents-how-to-build-an-enterprise-grade-mobile-platform-with-marklogic/">Fernando Mesa Presents How to Build an Enterprise-Grade Mobile Platform with MarkLogic</a></h3>
    <div class="author">by Cleo Haynal, October 28, 2010</div>
    <br/>
    <div class="message"><i>I chose to sit on Fernando’s session because his enthusiasm is always worth a sit-in.  It is impossible to successfully deliver information for the user without asking the user what he or she wants</i> is the premise of his talk. As Chris Anderson had talked about in his session, we are now in a new era and the advent of the mobile application enables us to have new data....
    </div>
  </div>

{(:
  <div class="body">
    <a class="more" href="">+ Show more</a>
  </div>
:)}

</ml:widget>

