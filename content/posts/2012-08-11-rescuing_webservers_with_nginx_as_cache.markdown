---
layout: post
title:  "Rescuing webservers with nginx as a cache"
date:   2012-08-11 03:04:00
categories: Artikel
Aliases:
  - /Artikel/rescuing_webservers_with_nginx_as_cache
---



<p>
First of all, I know that there already are a gazillion of websites out there
which praise nginx and other caching HTTP wonders. This one is a tad different
in that it contains a few nifty tricks (tl;dr: force caching, selective GET
parameter caching, iptables traffic redirection, monitoring nginx with
collectd)…
</p>

<h3>The situation</h3>

<p>
There is this website, and it’s using apache with <code>mod_php</code>, running
some rather badly engineered code which we cannot get rid of just now.
Depending on the time of the day, the server either reacted reasonably fast or
it was totally swamped. To figure out how bad it really was, aside from a
subjective impression using your web browser, I used <a
href="http://www.vanheusden.com/httping/"><code>httping</code></a>, a tool
which requests a website using HTTP and displays the latency until it gets a
response. The latency was ranging from 8 to 16 seconds and sometimes requests
were not handled at all. This is clearly not acceptable for any user.
</p>

<h3>Analyzing the situation</h3>

<p>
To analyze the situation, I primarily looked at apache’s <a
href="http://httpd.apache.org/docs/2.2/mod/mod_status.html">server status
page</a>. It shows you how many of its workers are currently doing what (like
reading a request, writing a response (this includes generating it), staying
open because of Keep-Alive or waiting for a new connection). It also lists the
currently active requests, so I just sampled a few times and noticed that many
connections were busy generating the same page. I also noticed that a lot of
connections were staying open in Keep-Alive for a few seconds, which is a bad
thing with this particular setup: Apache cannot use this slot for handling
other requests and keeps the (mostly virtual, but still) memory of the worker
allocated until the connection closes. Of course, you don’t just want to
disable Keep-Alive entirely because it massively speeds up page load times when
the page contains multiple assets like CSS, images, JavaScript…
</p>

<p>
So enter <a href="http://nginx.org/">nginx</a>, a webserver optimized for
handling <strong>a lot</strong> of concurrent connections with low CPU and
memory footprint. It would allow us to use apache’s 250 configured workers more
efficiently (handling actual requests, not staying blocked with Keep-Alive
connections) and it could certainly help us with caching.
</p>

<h3>The problem</h3>

<p>
The way the PHP software was built, all of these very similar requests go to
the same URL, but with different GET parameters. A request could go to
<code>/query?thing=this</code> or <code>/query?thing=that</code>. While that in
itself is not a problem for nginx (you can set up the cache_key in such a way
that it contains GET arguments, too), to make things worse, there also were
user-specific GET parameters: These are different for each (or many) requests,
but not relevant for caching the page.
</p>

<p>
The configuration to deal with this is the first nifty trick. The idea is that
we define a <code>location</code> block inside the nginx config which matches
<code>/query?thing=that&useless=394</code>, then rewrite it in such a way that
it will go to an easily cachable URL like <code>/query-cache/that</code> but
ignores the "useless" parameter:
</p>

<pre>
location ~ ^/query$ {
  if ($request_method = POST) {
    proxy_pass http://apache;
    break;
  }

  if ($args ~ thing=([0-9A-Za-z]+)) {
    set $thing $1;
  }

  rewrite ^ /query-cache/$thing;
}
</pre>

<p>
Of course, <code>/query-cache</code> should not already be used for something
else in the actual application. Users won’t do harm by visiting that URL
explicitly, but you want to avoid clashes. So, now we cache the hell out of
that URL, even though the upstream software specifies that it should not be
cached:
</p>

<pre>
location /query-cache/ {
  # Save the cache-URI, but rewrite it back to the original URI so that
  # upstream apache can deal with it.
  set $orig_uri $uri;
  rewrite /query-cache/ /query break;

  proxy_pass http://apache;
  # Enable HTTP/1.1, this gives us Keep-Alive to the upstream apache. We also
  # need to remove the Connection header so that clients cannot circumvent
  # that Keep-Alive.
  proxy_http_version 1.1;
  proxy_set_header Connection "";
  # The upstream software uses the Host header to generate absolute URLs, so
  # we really need to forward it.
  proxy_set_header Host $host;

  # Clean cookies.
  proxy_set_header cookie "";

  # Remove the session cookie we might get. Since we cache the response, this
  # would hand out the same session to many users.
  proxy_hide_header Set-Cookie;

  proxy_cache querycache;

  # Force caching, even though Set-Cookie, Expires and Cache-Control are set.
  proxy_ignore_headers Set-Cookie Expires Cache-Control;

  # cache HTTP/200 requests for 10 minutes.
  proxy_cache_valid 200 10m;

  # cache only by URI, not by args (they have been rewritten into the URI).
  proxy_cache_key $orig_uri;
}
</pre>

<p>
You can read at other sites on the web how to define the caching directives
accordingly. Here is our configuration:
</p>

<pre>
# inactive = 1440m -> data which is not accessed within one day gets kicked out
# max_size = 500m -> 500 MB of files tops
# 128MB memory for querycache keys
proxy_cache_path /var/cache/nginx/cache/ levels=1:2 keys_zone=querycache:128m max_size=500m inactive=1440m;
proxy_temp_path /var/cache/nginx/tmp;

upstream apache {
  server localhost:80;
  keepalive 16;
}
</pre>

<h3>Testing and diverting live traffic without downtime</h3>

<p>
Now we wanted to enable nginx without having to kill apache and start nginx.
Instead, we wanted to see if it works as we expect (without any impact on real
users) and then switch over with minimum effort. Also, having an easy way to
revert the change in case anything goes wrong is a nice additional feature.
</p>

<p>
So, we looked up our public IP address, let’s assume this is 1.2.3.4,
configured nginx to listen on port 9191 and added the following iptables rule
(the server is 192.168.0.1 in this example):
</p>

<pre>
iptables -t nat -A PREROUTING \
    -p tcp --dport 80 \
    -m state --state NEW \
    -s 1.2.3.4 -d 192.168.0.1 \
    -j DNAT --to-destination 192.168.0.1:9191
</pre>

<p>
This will divert all new TCP connections to port 80 on the server originating
from 1.2.3.4, our public IP, to port 9191 on the server. We tested everything
and it was still working fine. Additionally, httping clearly showed that page
loads for so-far uncached websites were taking quite a bit of time while
subsequent loads of the same page were blazingly fast due to caching.
</p>

<p>
After we were pretty sure we didn’t break anything, we replaced the rule above
by the same one, but without the <code>-s 1.2.3.4</code> restriction, thus
diverting the traffic for everyone.
</p>

<p>
The nice way to revert this change in case something goes wrong is to simply
delete the rule: <code>iptables -t nat -D PREROUTING 1</code>.
</p>

<p>
Of course I’m aware that iptables has a certain cost attached to it, but for
now this solution was very handy. In the future, you should of course migrate
nginx to port 80 and eliminate iptables for even better performance.
</p>

<h3>Keeping an eye on nginx</h3>

<p>
After successfully making the change and seeing our server load go down
massively, we wanted to look closer at nginx to be able to analyze further
hickups and just see how it was doing. Fortunately, nginx has a page which is
similar to the apache server status page. You can enable it by simply
configuring such a <code>location</code> (we only tested this with the nginx
version from Debian testing, so you might need to upgrade):
</p>

<pre>
location /nginx_status {
  stub_status on;
  access_log off;
  allow 127.0.0.1;
  deny all;
}
</pre>

<p>
For generating all kinds of graphs about the server behaviour, we already use
the excellent <a href="http://www.collectd.org/"><code>collectd</code></a> and
it ships with an nginx plugin to get pretty graphs like this one:
</p>

<img src="/Bilder/nginx.png" alt="nginx req/s and connections graph" width="721" height="415">

<p>
All you need to do is load the nginx plugin and tell it the URL of your status
page:
</p>

<pre>
LoadPlugin nginx

&lt;Plugin nginx&gt;
  URL "http://localhost:9191/nginx_status"
&lt;/Plugin&gt;
</pre>

<p>
See also <a
href="http://bethesignal.org/blog/2009/07/22/watching-nginx-upstreams-with-collectd/">"Watching
nginx upstreams with collectd"</a> for an article about an even more useful
graph of the latency to the upstream backend.
</p>

<p>
You can see that there are some hickups in this graph. Those are from the
software running very long-running queries. We fixed most of them so far, but
that will be the topic of a different post, maybe.
</p>
