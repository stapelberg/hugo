---
layout: post
title:  "CoreOS and Docker: first steps"
date:   2013-12-07 20:00:00
categories: Artikel
---


<p>
<a href="http://coreos.com/">CoreOS</a> is a minimal operating system based on
Linux, <a href="http://www.freedesktop.org/wiki/Software/systemd/">systemd</a>
and <a href="http://www.docker.io/">Docker</a>. In this post I describe how I
see CoreOS/Docker and how my first steps with it went.
</p>

<h2>What is Docker and why is it a good idea?</h2>

<p>
Finding the right words to describe all of this to someone who has not worked
with any of it is hard, but let me try. With docker, you can package software
into “containers”, which can then be run either on your own server(s) or at
some cloud infrastructure provider (<a
href="https://www.dotcloud.com/">dotcloud</a>, <a
href="https://stackdock.com/">stackdock</a>, <a
href="https://www.digitalocean.com/">digitalocean</a>). An example for software
could be <a href="http://git.zx2c4.com/cgit/about/">cgit</a>, a fast git web
interface.  Docker spawns each container in a separate <a
href="http://en.wikipedia.org/wiki/LXC">Linux container (LXC)</a>, mostly for a
clean and well-defined environment, not primarily for security. As far as the
software is concerned, it is PID 1, with a dynamic hostname, dynamic IP address
and a clean filesystem.
</p>

<p>
Why is this a good idea? It automates deployment and abstracts away from
machines. When I have multiple servers, I can run the same, unmodified Docker
container on any of them, and the software (I’ll write cgit from here on)
doesn’t care at all because the environment that Docker provides is exactly the
same. This makes migration painless — be it in a planned upgrade to newer
hardware, when switching to a different hoster or because there is an outage at
one provider.
</p>

<p>
Now you might say that we have had such a thing for years with <a
href="http://aws.amazon.com/ec2/">Amazon’s EC2</a> and similar cloud offerings.
Superficially, it seems very similar, the only difference being that you send
EC2 a virtual machine instead of a Docker container. These are the two biggest
differences for me:
</p>
<ol>
<li>
Docker is more modular: whereas having a separate VM for each application you
deploy is economically unattractive and cumbersome, with Docker’s light-weight
containers it becomes possible.
</li>

<li>
There is a different mental model in working with Docker. Instead of having a
virtualized long-running server that you need to either manually or
automatically (with Puppet etc.) keep running, you stop caring about servers
and start thinking in terms of software/applications.
</li>
</ol>

<h2>Why CoreOS?</h2>

<p>
CoreOS has several attractive features. It is running read-only, except for the
“state partition”, in which you mostly store systemd unit files that launch and
supervise your docker containers, plus docker’s local cache of container images
and their persistent state. I like read-only environments because they tend to
be fairly stable and really hard to break. Furthermore, CoreOS is auto-updating
and reuses ChromeOS’s proven updater. There are also some interesting
clustering features, like <a href="https://github.com/coreos/etcd">etcd, a
highly-available key-value store for service configuration and discovery</a>,
which is based on the <a href="http://raftconsensus.github.io/">raft consensus
algorithm</a>. This should make master election easy, but at the time of
writing it’s not quite there yet.
</p>

<p>
Of course, if you prefer, you could also just install your favorite Linux
distribution and install Docker there, which should be reasonable
straight-forward (but took me a couple of hours due to <a
href="http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=731574">Debian’s old
mount(8) version, which has a bug</a>). Personally, I found it an interesting
exercise to run in an environment that has very similar constraints to what
paid Docker hosting provides. That is, you get to run Docker containers and
nothing else.
</p>

<h2>Conventions throughout this article</h2>

<p>
For hostnames, <code>home</code> represents your computer at home or work where
you build Docker containers before deploying them on your server(s).
<code>d0</code> (d0.zekjur.net) represents a machine running CoreOS or any
other operating system with Docker up and running. A dollar sign ($) represents
a command executed as the default unprivileged user <code>core</code>, the hash
sign (#) represents a command executed as root (use <code>sudo -s</code> to get
a root shell on CoreOS).
</p>

<p>
Note that I assume you have Docker working on <code>home</code>, too.
</p>

<h2>Step 1: Dockerizing cgit</h2>

<p>
To create a docker container one can either manually run commands interactively
or use a Dockerfile. Since the former approach is very unreliable and
error-prone, I recommend using Dockerfiles only for anything more than quick
experiments. A Dockerfile starts off of a base image, which can be a tiny
environment (<a href="https://index.docker.io/_/busybox/">busybox</a>) or, more
typically, a Linux distribution’s minimal installation like <a
href="https://index.docker.io/u/tianon/debian/">tianon/debian</a> in our case.
</p>

<p>
After specifying the base image, you can run arbitrary commands with the RUN
directive and add files with the ADD directive. The interface between a
container and the rest of the world is one or more TCP ports. In the modern
world, this is typically port 80 for HTTP. The final thing to specify is the
ENTRYPOINT, which is what Docker will execute when you run the container.
The Dockerfile we use for cgit looks like this:
</p>
<pre>
FROM tianon/debian:sid

RUN apt-get update
RUN apt-get dist-upgrade -y
RUN apt-get install -y lighttpd

ADD cgit /usr/bin/cgit
ADD cgit.css /var/www/cgit/cgit.css
ADD cgit.png /var/www/cgit/cgit.png

ADD lighttpd-cgit.conf /etc/lighttpd/lighttpd-cgit.conf

ADD cgitrc /etc/cgitrc

EXPOSE 80
ENTRYPOINT ["/usr/sbin/lighttpd", "-f", "/etc/lighttpd/lighttpd-cgit.conf", "-D"]
</pre>

<p>
On my machine, this file lives in <code>~/Dockerfiles/cgit/Dockerfile</code>.
Right next to it in the cgit directory, I have the cgit-0.9.2 source and copied
the files cgit, cgit.css and cgit.png out of the build tree. lighttpd-cgit.conf
is fairly simple:
</p>
<pre>
server.modules = (
	"mod_access",
	"mod_alias",
	"mod_redirect",
	"mod_cgi",
)

mimetype.assign = (
	".css" => "text/css",
	".png" => "image/png",
)

server.document-root = "/var/www/cgit/"

# Note that serving cgit under the /git location is not a requirement in
# general, but obligatory in my setup due to historical reasons.
url.redirect = (
	"^/$" => "/git"
)
alias.url = ( "/git" => "/usr/bin/cgit" )
cgi.assign = ( "/usr/bin/cgit" => "" )
</pre>

<p>
Note that the only reason we compile cgit manually is because there is no
Debian package for it yet (the compilation process is a bit… special). To
actually build the container and tag it properly, run <code>docker build
-t="stapelberg/cgit" .</code>:
</p>
<pre>
home $ docker build -t="stapelberg/cgit" .
Uploading context 46786560 bytes
Step 1 : FROM tianon/debian:sid
 ---> 6bd626a5462b
Step 2 : RUN apt-get update
 ---> Using cache
 ---> 3702cc3eb5c9
Step 3 : RUN apt-get dist-upgrade -y
 ---> Using cache
 ---> 1fe67f64b1a9
Step 4 : RUN apt-get install -y lighttpd
 ---> Using cache
 ---> d955c6ff4a60
Step 5 : ADD cgit /usr/bin/cgit
 ---> e577c8c27dbf
Step 6 : ADD cgit.css /var/www/cgit/cgit.css
 ---> 156dbad760f4
Step 7 : ADD cgit.png /var/www/cgit/cgit.png
 ---> 05533fd04978
Step 8 : ADD lighttpd-cgit.conf /etc/lighttpd/lighttpd-cgit.conf
 ---> b592008d759b
Step 9 : ADD cgitrc /etc/cgitrc
 ---> 03a38cfd97f4
Step 10 : EXPOSE 80
 ---> Running in 24cea04396f2
 ---> de9ecca589c8
Step 11 : ENTRYPOINT ["/usr/sbin/lighttpd", "-f", "/etc/lighttpd/lighttpd-cgit.conf", "-D"]
 ---> Running in 6796a9932dd0
 ---> d971ba82cb0a
Successfully built d971ba82cb0a
</pre>

<h2>Step 2: Pushing to the registry</h2>

<p>
Docker pulls images from the registry, a service that is by default provided by
Docker, Inc. Since containers may include confidential configuration like
passwords or other credentials, putting images into the public registry is not
always a good idea. There are services like <a
href="http://www.dockify.io/">dockify.io</a> and <a
href="https://quay.io/">quay.io</a> which offer a private registry, but you can
also run your own. Note that when running your own, you are responsible for its
availability. Be careful not to end up in a situation where you need to
transfer docker containers to your new rigestry via your slow DSL connection.
An alternative is to run your own registry, but store the files on <a
href="http://aws.amazon.com/s3/">Amazon S3</a>, which also comes with
additional cost.
</p>

<p>
Running your own registry in the default configuration (storing data only in
the container’s /tmp directory, no authentication) is as easy as running:
</p>
<pre>
d0 $ docker run -p 5000:5000 samalba/docker-registry
</pre>

<p>
Then, you can tag and push the image we built in step 1:
</p>
<pre>
docker tag stapelberg/cgit d0.zekjur.net:5000/cgit
docker push d0.zekjur.net:5000/cgit
</pre>

<h2>Step 3: Running cgit on CoreOS</h2>

<p>
To simply run the cgit container we just created and pushed, use:
</p>
<pre>
d0 $ docker run d0.zekjur.net:5000/cgit
2013-12-07 18:46:16: (log.c.166) server started
</pre>

<p>
But that’s not very useful yet, port 80 is exposed by the docker container, but
not provided to the outside world or any other docker container. You can use
<code>-p 80</code> to expose the container’s port 80 as a random port on the
host, but for a more convenient test, let’s use port 4242:
</p>
<pre>
d0 $ docker run -p 4242:80 d0.zekjur.net:5000/cgit
</pre>

<p>
When connecting to http://d0.zekjur.net:4242/ with your browser, you should now
see cgit. However, even if you specified git repositories in your
<code>cgitrc</code>, those will not work, because there are no git repositories
inside the container. The most reasonable way to make them available is to
provide a volume, in this case read-only, to the container. Create
/media/state/_CUSTOM/git and place your git repositories in there, then re-run
the container:
</p>
<pre>
d0 # mkdir -p /media/state/_CUSTOM/git
d0 # cd /media/state/_CUSTOM/git
d0 # git clone git://github.com/stapelberg/godebiancontrol
d0 $ docker run -v /media/state/_CUSTOM/git:/git:ro \
  -p 4242:80 d0.zekjur.net:5000/cgit
</pre>

<p>
You should be able to see the repositories now in cgit. Now we should add a
unit file to make sure this container comes up when the machine reboots:
</p>
<pre>
d0 # cat >/media/state/units/cgit.service <<'EOT'
[Unit]
Description=cgit
After=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker run \
    -v /media/state/_CUSTOM/git:/git:ro \
    -p 4242:80 \
    d0.zekjur.net:5000/cgit

[Install]
WantedBy=local.target
EOT
d0 # systemctl daemon-reload
</pre>

<h2>Step 4: Running nginx in front of containers</h2>

<p>
You might have noticed that we did not expose cgit on port 80 directly. While
there might be setups in which you have one public IP address per service, the
majority of setups probably does not. Therefore, and for other benefits such as
seamless updates (start the new cgit version on a separate port, test, redirect
traffic by reloading nginx), we will deploy nginx as a reverse proxy for all
the other containers.
</p>

<p>
The process to dockerize nginx is very similar to the one for cgit above, just
with less manual compilation:
</p>
<pre>
home $ mkdir -p ~/Dockerfiles/nginx
home $ cd ~/Dockerfiles/nginx
home $ cat >Dockerfile <<'EOT'
FROM tianon/debian:sid

RUN apt-get update
RUN apt-get dist-upgrade -y
RUN apt-get install -y nginx-extras

EXPOSE 80
ENTRYPOINT ["/usr/sbin/nginx", "-g", "daemon off;"]
EOT
home $ docker build -t=stapelberg/nginx .
home $ docker tag stapelberg/nginx d0.zekjur.net:5000/nginx
home $ docker push d0.zekjur.net:5000/nginx
</pre>

<p>
Now, instead of exposing cgit directly to the world, we bind its port 4242 onto
the docker0 bridge interface, which can be accessed be all other containers,
too:
</p>
<pre>
d0 $ docker run -v /media/state/_CUSTOM/git:/git:ro \
  -p 172.17.42.1:4242:80 d0.zekjur.net:5000/cgit
</pre>

<p>
I decided to not include the actual vhost configuration in the nginx container,
but rather keep it in <code>/media/state/_CUSTOM/nginx</code>, so that it can
be modified (perhaps automatically in the future) and nginx can be simply
reloaded by sending it the SIGHUP signal:
</p>
<pre>
d0 # mkdir -p /media/state/_CUSTOM/nginx
d0 # cat >/media/state/_CUSTOM/nginx/cgit <<'EOT'
server {
        root /usr/share/nginx/www;
        index index.html index.htm;

        server_name d0.zekjur.net;

        location / {
                proxy_pass http://172.17.42.1:4242/;
        }
}
EOT
</pre>

<p>
As the final step, run the nginx container like that:
</p>
<pre>
d0 $ docker run -v /media/state/_CUSTOM/nginx:/etc/nginx/sites-enabled:ro \
  -p 80:80 dock0.zekjur.net:5000/nginx
</pre>

<p>
And finally, when just addressing d0.zekjur.net in your browser, you’ll be
greeted by cgit!
</p>

<h2>Pain point: data replication</h2>

<p>
If you read this carefully, you surely have noticed that we actually have state
that is stored on each docker node: the git repositories, living in
<code>/media/state/_CUSTOM/git</code>. While git repositories are fairly easy
to replicate and back up, with other applications this is much harder: imagine
a typical <a href="http://trac.edgewall.org/">trac</a> installation, which
needs a database and a couple of environment files where it stores attachment
files and such.
</p>

<p>
Neither Docker nor CoreOS address this issue, it is one that you have to solve
yourself. Options that come to mind are <a href="http://www.drbd.org/">DRBD</a>
or rsync for less consistent, but perhaps easier replication. On the database
side, there are plenty of solutions for PostgreSQL and MySQL.
</p>

<h2>Pain point: non-deterministic builds</h2>

<p>
With the Dockerfiles I used above, both the base image
(<code>tianon/debian</code>) and what’s currently in Debian might change any
second. An Dockerfile that I built just fine on my computer today may not work
for you tomorrow. The result is that docker images are actually really
important to keep around on reliable storage. I talked about the registry
situation in step 2 already and there are <a
href="http://3ofcoins.net/2013/10/08/distributing-confidential-docker-images/">other
posts about the registry situation</a>, too.
</p>

<h2>Pain point: read-write containers</h2>

<p>
What makes me personally a little nervous when dockerizing software is that
containers are read-writable, and there is no way to run a container in
read-only mode. This means that you need to get the volumes right, otherwise
whatever data the software writes to disk is lost when you deploy a new docker
container (or the old one dies). If read-only containers were possible, the
software would not even be able to store any data, except when you properly set
up a volume backed by persistent (and hopefully replicated/backed up) storage
on the host.
</p>

<p>
<a href="https://github.com/dotcloud/docker/pull/2710">I sent a Pull Request
for read-only containers</a>, but so far upstream does not seem very
enthusiastic to merge it.
</p>

<h2>Pain point: CoreOS automatic reboots</h2>

<p>
At the time of writing, CoreOS automatically reboots after every update. Even if
you have another level of load-balancing with health checks in front of your
CoreOS machine, this means a brief service interruption. To work around it, <a
href="https://groups.google.com/forum/#!topic/coreos-dev/pgsGFiE-arA">use an
inhibitor</a> and reboot manually from time to time after properly failing over
all services away from that machine.
</p>

<h2>Conclusion</h2>

<p>
Docker feels like a huge step in the right direction, but there definitely will
still be quite a number of changes in all the details before we arrive at a
solution that is tried and trusted.
</p>

<p>
Ideally, there will be plenty of providers who will run your Docker containers
for not a lot of money, so that one can eventually get rid of dedicated servers
entirely. Before that will be possible, we also need a solution to migrate
Docker containers and their persistent state from one machine to another
automatically and bring up Docker containers on new machines should a machine
become unavailable.
</p>
