/*
 * TwitStream - A jQuery plugin for the Twitter Search API
 * Version 1.2
 * http://kjc-designs.com/TwitStream
 * Copyright (c) 2009 Noah Cooper
 * Licensed under the GNU General Public License <http://www.gnu.org/licenses/>
*/
String.prototype.linkify=function(){
	return this.replace(/[A-Za-z]+:\/\/[A-Za-z0-9-_]+\.[A-Za-z0-9-_:%&;\?\/.=]+/g,function(m){
		return m.link(m);
	});
};
String.prototype.linkuser=function(){
	return this.replace(/[@]+[A-Za-z0-9-_]+/g,function(u){
		return u.link("http://twitter.com/"+u.replace("@",""));
	});
};
String.prototype.linktag=function(){
	return this.replace(/[#]+[A-Za-z0-9-_]+/g,function(t){
		return t.link("http://twitter.com/#search?q="+t.replace("#",""));
	});
};
var showTweetLinks='none';
function fetch_tweets(elem, num, offset){
	elem=$(elem);
	keyword=escape(elem.attr('title'));
	var url="http://search.twitter.com/search.json?q="+keyword+"&rpp="+num+"&callback=?";
	$.getJSON(url,function(json){
		$(json.results).each(function(index){
            if (offset-- > 0)
                return;
			var tTime=new Date(Date.parse(this.created_at));
			var cTime=new Date();
			var sinceMin=Math.round((cTime-tTime)/60000);
			if(sinceMin==0){
				var sinceSec=Math.round((cTime-tTime)/1000);
				if(sinceSec<10)
					var since='less than 10 seconds ago';
				else if(sinceSec<20)
					var since='less than 20 seconds ago';
				else
					var since='half a minute ago';
			}
			else if(sinceMin==1){
				var sinceSec=Math.round((cTime-tTime)/1000);
				if(sinceSec==30)
					var since='half a minute ago';
				else if(sinceSec<60)
					var since='less than a minute ago';
				else
					var since='1 minute ago';
			}
			else if(sinceMin<45)
				var since=sinceMin+' minutes ago';
			else if(sinceMin>44&&sinceMin<60)
				var since='about 1 hour ago';
			else if(sinceMin<1440){
				var sinceHr=Math.round(sinceMin/60);
				if(sinceHr==1)
					var since='about 1 hour ago';
				else
					var since='about '+sinceHr+' hours ago';
			}
			else if(sinceMin>1439&&sinceMin<2880)
				var since='1 day ago';
			else{
				var sinceDay=Math.round(sinceMin/1440);
				var since=sinceDay+' days ago';
			}
			var tweetBy='<a class="tweet-user" target="_blank" href="http://twitter.com/'+this.from_user+'">'+this.from_user+':</a> ';
			var tweetInfo = ' <div class="post_info"><span class="tweet-time">'+since+'</span> <span class="tweet-source">from '+this.source+'</span>&#160;' 
				+ '<a class="tweet-reply" target="_blank" title="Reply" href="https://twitter.com/intent/tweet?in_reply_to=' + this.id_str + '">Reply</a>&#160;' 
				+ '<a class="tweet-rt" target="_blank" title="Retweet" href="https://twitter.com/intent/retweet?tweet_id=' + this.id_str + '">Retweet</a>' 
                + '</div>';

			if(showTweetLinks.indexOf('reply')!=-1)
				tweetBy=tweetBy+' &middot; <a class="tweet-reply" target="_blank" href="http://twitter.com/?status=@'+this.from_user+' &in_reply_to_status_id='+this.id+'&in_reply_to='+this.from_user+'">Reply</a>';
			if(showTweetLinks.indexOf('view')!=-1)
				tweetBy=tweetBy+' &middot; <a class="tweet-view" target="_blank" href="http://twitter.com/'+this.from_user+'/statuses/'+this.id_str+'">View Tweet</a>';
			if(showTweetLinks.indexOf('rt')!=-1)
				tweetBy=tweetBy+' &middot; <a class="tweet-rt" target="_blank" href="http://twitter.com/?status=RT @'+this.from_user+' '+escape(this.text.replace(/&quot;/g,'"'))+'&in_reply_to_status_id='+this.id+'&in_reply_to='+this.from_user+'">RT</a>';

            var c = (index == 0) ? "tweet1" : "tweet2ormore";

			var tweet='<div class="' + c + ' tweet body"><!--div class="tweet-avatar"><a target="_blank" href="http://twitter.com/'+this.from_user+'"><img width="48" height="48" alt="'+this.from_user+' on Twitter" src="'+this.profile_image_url+'" /></a></div--><div class="tweet-content">'+tweetBy+this.text.linkify().linkuser().linktag().replace(/<a/g,'<a target="_blank"')+tweetInfo+'</div></div>';

			elem.append(tweet);
		});
	});
	return(false);
}
$(function(){
	showTweetLinks=showTweetLinks.toLowerCase();
	if(showTweetLinks.indexOf('all')!=-1)
		showTweetLinks='reply,view,rt';
	$('.twitStream').each(function(){
	    elem=$(this);
	    num=elem.attr('class').split(' ').slice(-1);
		fetch_tweets(this, num, 0);
	});

    $('.twitMore').each(function(){
        elem=$(this)
        elem.click(function() {
            moreTweets();
            return false;
        });
    });
});

function moreTweets() {
	$('.twitStream').each(function(){
	    elem=$(this);
	    num=elem.attr('class').split(' ').slice(-1);
        elem.removeClass(num);
        newNum = Number(num) + 5;
		fetch_tweets(this, newNum, num);
        elem.addClass(String(newNum));
	});
}
