---
layout: post
title:  "Prometheus: Using the blackbox exporter"
date:   2016-01-01 19:00:00
categories: Artikel
Aliases:
  - /Artikel/prometheus-blackbox-exporter
---

<p>
Up until recently, I used to use <a href="http://kanla.zekjur.net/">kanla</a>,
a simple alerting program that I wrote 4 years ago. Back then, delivering
alerts via XMPP (Jabber) to mobile devices like Android smartphones seemed like
the best course of action.
</p>

<p>
About a year ago, I’ve started using <a
href="http://prometheus.io/">Prometheus</a> for collecting monitoring data and
alerting based on that data. See <a
href="https://media.ccc.de/v/gpn15-6645-monitoring_mit_prometheus#video">„Monitoring
mit Prometheus“</a>, my presentation about the topic at GPN, for more details
and my experiences.
</p>

<h3>Motivation to switch to the Blackbox Exporter</h3>

<p>
Given that the Prometheus <a
href="https://github.com/prometheus/alertmanager">Alertmanager</a> is already
configured to deliver alerts to my mobile device, it seemed silly to rely on
two entirely different mechanisms. Personally, I’m using <a
href="https://pushover.net/">Pushover</a>, but Alertmanager integrates with
many popular providers, and it’s easy to add another one.
</p>

<p>
Originally, I considered extending kanla in such a way that it would talk to
Alertmanager, but then I realized that the Prometheus <a
href="https://github.com/prometheus/blackbox_exporter">Blackbox Exporter</a> is
actually a better fit: it’s under active development and any features that are
added to it benefit a larger number of people than the small handful of kanla
users.
</p>

<p>
Hence, I switched from having kanla probe my services to having the Blackbox
Exporter probe my services. The rest of the article outlines my configuration
in the hope that it’s useful for others who are in a similar situation.
</p>

<p>
I’m assuming that you are already somewhat familiar with Prometheus and just
aren’t using the Blackbox Exporter yet.
</p>

<h3>Blackbox Exporter: HTTP</h3>

<p>
The first service I wanted to probe is <a
href="https://codesearch.debian.net/">Debian Code Search</a>. The following
<code>blackbox.yml</code> configuration file defines a module called
“dcs_results” which, when called, downloads the specified URL via a HTTP GET
request. The probe is considered failed when the download doesn’t finish within
the timeout of 5 seconds, or when the resulting HTTP body does not contain the
text “load_font”.
</p>

<pre>
modules:
  dcs_results:
    prober: http
    timeout: 5s
    http:
      fail_if_not_matches_regexp:
      - "load_font"
</pre>

<p>
In my <code>prometheus.conf</code>, this is how I invoke the probe:
</p>

<pre>
- job_name: blackbox_dcs_results
  scrape_interval: 60s
  metrics_path: /probe
  params:
    module: [dcs_results]
    target: ['http://codesearch.debian.net/search?q=i3Font']
  scheme: http
  target_groups:
  - targets:
    - blackbox-exporter:9115
</pre>

<p>
As you can see, the search query is “i3Font”, and I know that “load_font” is
one of the results. In case Debian Code Search does not deliver the expected
search results, I know something is seriously broken. To make Prometheus
actually generate an alert when this probe fails, we need an alert definition
like the following:
</p>

<pre>
ALERT ProbeFailing
  IF probe_success < 1
  FOR 15m
  WITH {
    job="blackbox_exporter"
  }
  SUMMARY "probe {{ "{{$labels.job" }}}} failing"
  DESCRIPTION "probe {{ "{{$labels.job" }}}} failing"
</pre>

<h3>Blackbox Exporter: IRC</h3>

<p>
With the TCP probe module’s query/response feature, we can configure a module
that verifies an IRC server lets us log in:
</p>

<pre>
modules:
  irc_banner:
    prober: tcp
    timeout: 5s
    tcp:
      query_response:
      - send: "NICK prober"
      - send: "USER prober prober prober :prober"
      - expect: "PING :([^ ]+)"
        send: "PONG ${1}"
      - expect: "^:[^ ]+ 001"
</pre>

<h3>Blackbox Exporter: Git</h3>

<p>
The query/response feature can also be used for slightly more complex
protocols. To verify a Git server is available, we can use the following
configuration:
</p>

<pre>
modules:
  git_code_i3wm_org:
    prober: tcp
    timeout: 5s
    tcp:
      query_response:
      - send: "002bgit-upload-pack /i3\x00host=code.i3wm.org\x00"
      - expect: "^[0-9a-f]+ HEAD\x00"
</pre>

<p>
Note that the first characters are the ASCII-encoded hex length of the entire line:
</p>
<pre>
$ echo -en '0000git-upload-pack /i3\x00host=code.i3wm.org\x00' | wc -c
43
$ perl -E 'say sprintf("%04x", 43)'
002b
</pre>

<p>
The corresponding git URL for the example above is
<code>git://code.i3wm.org/i3</code>. You can read more about the git protocol
at <a
href="https://github.com/git/git/blob/master/Documentation/technical/pack-protocol.txt">Documentation/technical/pack-protocol.txt</a>.
</p>

<h3>Blackbox Exporter: Meta-monitoring</h3>

<p>
Don’t forget to add an alert that will fire if the blackbox exporter is not available:
</p>

<pre>
ALERT BlackboxExporterDown
  IF count(up{job="blackbox_dcs_results"} == 1) < 1
  FOR 15m
  WITH {
    job="blackbox_meta"
  }
  SUMMARY "blackbox-exporter is not up"
  DESCRIPTION "blackbox-exporter is not up"
</pre>
