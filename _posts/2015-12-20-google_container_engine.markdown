---
layout: post
title:  "(Not?) Hosting small projects on Container Engine"
date:   2015-12-20 22:35:00
categories: Artikel
---

<p>
Note: the postings on this site are my own and do not necessarily represent the postings, strategies or opinions of my employer.
</p>

<h3>Background</h3>
<p>
For the last couple of years, faq.i3wm.org was running on a dedicated server I rented. I partitioned that server into multiple virtual machines using KVM, and one of these VMs contained the faq.i3wm.org installation. In that VM, I directly used <code>pip</code> to install the <a href="https://www.djangoproject.com/">django</a>-based <a href="https://askbot.com/">askbot, a stack overflow-like questions &amp; answers web application</a>.
</p>

<p>
Every upgrade of askbot brought with it at least some small annoyances. For example, with the django 1.8 release, one had to <a href="https://github.com/ASKBOT/askbot-devel/pull/442">change the cache settings</a> (I would have expected compatibility, or at least a suggested/automated config file update). A new release of a library dependency <a href="https://github.com/ASKBOT/askbot-devel/pull/446">broke askbot installation</a>. The askbot 0.9.0 release <a href="https://github.com/ASKBOT/askbot-devel/commit/f1f49fe4af14d8e904b454a96c71d4d1939d6223">was not installable</a> on Debian-based systems. In conclusion, for every upgrade you’d need to plan a couple of hours for identifying and possibly fixing these numerous small issues.
</p>

<p>
Once <a href="https://www.docker.com/">Docker</a> was released, I started using askbot in Docker containers. I’ll talk a bit more about the advantages in the next section.
</p>

<p>
With the software upgrade burden largely mitigated by using Docker, I’ve had some time to consider bigger issues, namely disaster recovery and failure tolerance. The story for disaster recovery up to that point was daily off-site backups of the underlying PostgreSQL database. Because askbot was packaged in a Docker container, it became feasible to quickly get <strong>exactly the same version</strong> back up and running on a new server. But what about failure tolerance? If the server which runs the askbot Docker container suddenly dies, I would need to manually bring up the replacement instance from the most recent backup, and in the timespan between the hardware failure and my intervention, the FAQ would be unreachable.
</p>

<p>
The desire to make hardware failures a non-event for our users lead me to evaluate <a href="https://cloud.google.com/container-engine/">Google Container Engine (abbreviated GKE)</a> for hosting faq.i3wm.org. The rest of the article walks through the motivation behind each layer of technology that’s used when hosting on GKE, how exactly one would go about it, how much one needs to pay for such a setup and concludes with my overall thoughts on the experience.
</p>

<h3>Motivation behind each layer</h3>

<p>
Google Container Engine is a hosted version of <a href="http://kubernetes.io/">Kubernetes</a>, which in turn schedules Docker containers on servers and ensures that they are staying up. As an example, you can express “I always want to have one instance of the <code>prosody/prosody</code> Docker container running, with the Persistent Disk volume prosody-disk mounted at /var/lib/prosody” (prosody is an XMPP server). Or, you could make it 50 instances, just by changing a single number in your configuration file.
</p>

<p>
So, let’s dissect the various layers of technology that we’re using when we run containers on GKE and see what each of them provides, from the lowest layer upwards.
</p>

<h4>Docker</h4>

<p>
Docker combines two powerful aspects:
</p>

<ol>
<li>Docker allows us to package applications with a common interface. No matter which application I want to run on my server, all I need is to tell Docker the container name (e.g. <code>prom/prometheus</code>) and then configure a subset of volumes, ports, environment variables and links between the different containers.</li>
<li>Docker containers are self-contained and can (I think they should!) be treated as immutable snapshots of an application.</li>
</ol>

<p>
This results in a couple of nice properties:
</p>

<ul>
<li>
<strong>Moving applications between servers</strong>: Much like <a href="https://en.wikipedia.org/wiki/Live_migration">live-migration of Virtual Machines</a>, it becomes really easy to move an application from one server to another. This covers both: regular server migrations and emergency procedures.
</li>
<li>
<strong>Being able to easily test a new version and revert, if necessary</strong>: Much like filesystem snapshots, you can easily switch back and forth between different versions of the same software, just by telling Docker to start e.g. <code>prom/node-exporter:0.10.0</code> instead of <code>prom/node-exporter:0.9.0</code>. Notably, if you treat containers themselves as read-only and use volumes for storage, you might be able to revert to an older version without having to throw away the data that you have accumulated since you upgraded (provided there were no breaking changes in the data structure).
</li>
<li>
<strong>Upstream can provide official Docker images</strong> instead of relying on Linux distributions to package their software. Notably, this does away with the notion that Linux distributions provide value by integrating applications into their own configuration system or structure. Instead, software distribution gets unified across Linux distributions. This property also pushes out the responsibility for security updates from the Linux distribution to the application provider, which might be good or bad, depending on the specific situation and point of view.
</li>
</ul>

<h4>Kubernetes</h4>

<p>
Kubernetes is the layer which makes multiple servers behave like a single, big server. It abstracts individual servers away:
</p>

<ul>
<li>
<strong>Machine failures are no longer a problem</strong>: When a server becomes unavailable for whichever reason, the containers which were running on it will be brought up on a different server. Note that this implies some sort of machine-independent storage solution, like Persistent Disk, and also multiple failure domains (e.g. multiple servers) to begin with.
</li>
<li>
<strong>Updates of the underlying servers get easier</strong>, because Kubernetes takes care of re-scheduling the containers elsewhere.
</li>
<li>
<strong><a href="https://en.wikipedia.org/wiki/Scalability#Horizontal_and_vertical_scaling">Scaling out</a> a service becomes easier</strong>: you adjust the number of replicas, and Kubernetes takes care of bringing up that number of Docker containers.
</li>
<li>
<strong>Configuration gets a bit easier</strong>: Kubernetes has a declarative configuration language where you express your intent, and Kubernetes will make it happen. In comparison to running Docker containers with “docker run” from a systemd service file, this is an improvement because the number of edge-cases in reliably running a Docker container is fairly high.
</li>
</ul>

<h4>Google Container Engine</h4>

<p>
While one could rent some dedicated servers and run Kubernetes on them, Google Container Engine offers that as a service. GKE offers some nice improvements over a self-hosted Kubernetes setup:
</p>

<ul>
<li>
<strong>It’s a hosted environment</strong>, i.e. you don’t need to do updates and testing yourself, and you can escalate any problems.
</li>
<li>
<strong>Persistent Disk</strong>: your data will be stored on a <a href="https://en.wikipedia.org/wiki/Google_File_System">distributed file system</a> and you will not have to deal with dying disks yourself.
</li>
<li>
<strong>Persistent Disk snapshots</strong> are <a href="https://cloud.google.com/compute/docs/tutorials/compute-engine-disks-price-performance-and-persistence#copy_to_snapshots">globally replicated</a> (!), providing an additional level of data protection in case there is a catastrophical failure in an entire datacenter or region.
</li>
<li>
<strong>Logs are centrally collected</strong>, so you don’t need to set up and maintain your own central syslog installation.
</li>
<li>
<strong>Automatic live-migration</strong>: The underlying VMs (on Google Compute Engine) are automatically live-migrated before planned maintenance, so you should not see downtime unless unexpected events occur. This is not yet state of the art at every hosting provider, which is why I mention it.
</li>
</ul>

<p>
The common theme in all of these properties is that while you could do each of these yourself, it would be very expensive both in terms of actual money for the hardware and underlying services, but also in your time. When using Kubernetes as a small-scale user, I think going with a hosted service such as GKE makes a lot of sense.
</p>

<h3>Getting askbot up and running</h3>

<p>
Note that I expect you to have skimmed over the <a href="https://cloud.google.com/container-engine/docs/">official Container Engine documentation</a>, which also provides walkthroughs of how to set up e.g. WordPress.
</p>

<p>
I’m going to illustrate running a Docker container by just demonstrating the nginx-related part. It covers the most interesting aspects of how Kubernetes works, and packaging askbot is out of scope for this article. Suffice it to say that you’ll need containers for nginx, askbot, memcached and postgres.
</p>

<p>
Let’s start with the Replication Controller for nginx, which is a logical unit that creates new Pods (Docker containers) whenever necessary. For example, if the server which holds the nginx Pod goes down, the Replication Controller will create a new one on a different server. I defined the Replication Controller in <code>nginx-rc.yaml</code>:
</p>

<pre>
# vim:ts=2:sw=2:et
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx
  labels:
    env: prod
spec:
  replicas: 1
  selector:
    app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      restartPolicy: Always
      dnsPolicy: ClusterFirst
      containers:
      - name: nginx
        # Use nginx:1 in the hope that nginx will not break their
        # configuration file format without bumping the
        # major version number.
        image: nginx:1
        # Always do a docker pull when starting this pod, as the nginx:1
        # tag gets updated whenever there is a new nginx version.
        imagePullPolicy: Always
        ports:
        - name: nginx-http
          containerPort: 80
        - name: nginx-https
          containerPort: 443
        volumeMounts:
        - name: nginx-config-storage
          mountPath: /etc/nginx/conf.d
          readOnly: true
        - name: nginx-ssl-storage
          mountPath: /etc/nginx/i3faq-ssl
          readOnly: true
      volumes:
      - name: nginx-config-storage
        secret:
          secretName: nginx-config
      - name: nginx-ssl-storage
        secret:
          secretName: nginx-ssl
</pre>

<p>
You can see that I’m referring to two volumes which are called Secrets. This is because <a href="https://github.com/kubernetes/kubernetes/issues/13610">static read-only files</a> are not yet supported by Kubernetes. So, in order to bring the configuration and SSL certificates to the docker container, I’ve chosen to create a Secret for each of them. An alternative would be to create my own Docker container based on the official nginx container, and then add my configuration in there. I dislike that approach because it signs me up for additional maintenance: with the Secret injection method, I’ll just use the official nginx container, and nginx upstream will take care of version updates and security updates. For creating the Secret files, I’ve created a small Makefile:
</p>

<pre>
all: nginx-config-secret.yaml nginx-ssl-secret.yaml

nginx-config-secret.yaml: static/faq.i3wm.org.conf
	./gensecret.sh nginx-config >$@
	echo "  faq.i3wm.org.conf: $(shell base64 -w0 static/faq.i3wm.org.conf)" >> $@

nginx-ssl-secret.yaml: static/faq.i3wm.org.startssl256-combined.crt static/faq.i3wm.org.startssl256.key static/dhparams.pem
	./gensecret.sh nginx-ssl > $@
	echo "  faq.i3wm.org.startssl256-combined.crt: $(shell base64 -w0 static/faq.i3wm.org.startssl256-combined.crt)" >> $@
	echo "  faq.i3wm.org.startssl256.key: $(shell base64 -w0 static/faq.i3wm.org.startssl256.key)" >> $@
	echo "  dhparams.pem: $(shell base64 -w0 static/dhparams.pem)" >> $@
</pre>

<p>
The <code>gensecret.sh</code> script is just a simple file template:
</p>

<pre>
#!/bin/sh
# gensecret.sh &lt;name&gt;
cat &lt;&lt;EOT
# vim:ts=2:sw=2:et:filetype=conf
apiVersion: v1
kind: Secret
metadata:
  name: $1
type: Opaque
data:
  # TODO: once either of the following two issues is fixed,
  # migrate away from secrets for configs:
  # - https://github.com/kubernetes/kubernetes/issues/1553
  # - https://github.com/kubernetes/kubernetes/issues/13610
EOT
</pre>

<p>
Finally, we will also need a Service definition so that incoming connections can be routed to the Pod, regardless of where it lives. This will be <code>nginx-svc.yaml</code>:
</p>

<pre>
# vim:ts=2:sw=2:et
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  ports:
  - name: http
    port: 80
    targetPort: 80
  - name: https
    port: 443
    targetPort: 443
  selector:
    app: nginx
  type: LoadBalancer
</pre>

<p>
I then committed these files into the private git repository that GKE provides and used <code>kubectl</code> to bring it all up:
</p>

<pre>
$ make
$ kubectl create -f nginx-config-secret.yaml
$ kubectl create -f nginx-ssl-secret.yaml
$ kubectl create -f nginx-rc.yaml
$ kubectl create -f nginx-svc.yaml
</pre>

<p>
Because we’ve specified <code>type: LoadBalancer</code> in the Service
definition, a static IP address will be allocated and can be obtained by using
<code>kubectl describe svc nginx</code>. You should be able to access the nginx
server on that IP address now.
</p>

<h3>Cost</h3>

<p>
I like to split the cost of running askbot on GKE into four chunks: the underlying VM instances (biggest chunk), the network load balancing (surprisingly big chunk), storage and all the rest, like network traffic.
</p>

<h4>Cost: VM instances</h4>

<p>
The cheapest GKE cluster you can technically run consists of three f1-micro nodes. If you try to start one with fewer nodes, you’ll get an error message: “ERROR: (gcloud.container.clusters.create) ResponseError: code=400, message=One f1-micro instance is not sufficient for a cluster with logging and/or monitoring enabled. Please use a larger machine-type, at least three f1-micro instances, or disable both logging and monitoring.”
</p>

<p>
However, three f1-micro nodes will not be enough to successfully run a web application such as askbot. The f1-micro instances don’t have a reserved CPU core, so you are using left-over capacity, and sometimes that capacity might not be enough. I have seen cases where askbot would not even start up within 10 minutes on an f1-micro instance. I definitely recommend you skip f1-micro instances and directly go with g1-small instances, the next bigger instance type.
</p>

<p>
For the g1-small instances, you can go as low as two machines. Also be specific about how much disk the machines need, otherwise you will end up with the default disk size of 100 GB, which might be unnecessary for your use case. I’ve used this command to create my cluster:
</p>
<pre>
gcloud container clusters create i3-faq \
  --num-nodes=2 \
  --machine-type=g1-small \
  --disk-size=10
</pre>

<p>
At <a href="https://cloud.google.com/compute/pricing#predefined_machine_types">0.021 USD/hour</a> for a g1-small instance that you run continuously, the VM instances will add up to about 30 USD/month.
</p>

<h4>Cost: Network load balancing</h4>

<p>
As explained before, the only way to get a static IP address for a service to which you can point your DNS records is to use <a href="https://cloud.google.com/compute/docs/load-balancing/network/">Network Load Balancing</a>. At <a href="https://cloud.google.com/compute/pricing#network">0.025 USD/hour</a>, this adds up to about 18 USD/month.
</p>

<h4>Cost: Storage</h4>

<p>
While Persistent Disk comes in at <a href="https://cloud.google.com/compute/pricing#persistentdisk">0.04 USD/GB/month</a>, consider that a certain minimum size of a Persistent Disk volume is necessary in order to get a certain performance out of it: <a href="https://cloud.google.com/compute/docs/disks/#determine_the_size_of_a_persistent_disk">the Persistent Disk docs</a> explain how a 250 GB volume size might be required to match the performance of a typical 7200 RPM SATA drive if you’re doing small random reads.
</p>

<p>
I ended up paying for 196 Gibibyte-months, which adds up to 7.88 USD. This included daily snapshots, of which I created one per day and always kept five around.
</p>

<h4>Cost: Conclusion</h4>

<p>
The rest, mostly network traffic, added up to 1 USD, but keep in mind that this
instance was just set up and did not receive real user traffic.
</p>

<p>
In total, I was paying 57 USD/month.
</p>

<h3>Final thoughts</h3>

<p>
I thought my whole cloud experience was pretty polished overall, there were no big rough edges. Certainly, Kubernetes is usable right now (at least in its packaged form in Google Container Engine), and I have no doubts it will get better over time.
</p>

<p>
The features which GKE offers are exactly what I’m looking for, and Google offers them for a fraction of the price that it would cost me to build, and most importantly run, them myself. This applies to Persistent Disk, globally replicated snapshots, centralized logs, automatic live migration and more.
</p>

<p>
At the same time, I found it slightly too expensive for what is purely a hobby project. Especially the network load balancing increased the bill over the threshold of what I find acceptable for hosting a single application. If GKE becomes usable without the network load balancing or the prices will drop, I’d whole-heartedly recommend it for hobby projects.
</p>
