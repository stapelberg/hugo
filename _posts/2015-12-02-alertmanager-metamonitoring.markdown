---
layout: post
title:  "Prometheus Alertmanager meta-monitoring"
date:   2015-12-02 09:50:00
categories: Artikel
---

<p>
I’m happily using <a href="http://prometheus.io/">Prometheus</a> for monitoring
and alerting since about a year.
</p>

<p>
Regardless of the monitoring system, one problem that I was uncertain of how to
solve it in a good way used to be meta-monitoring: if you have a monitoring
system, how do you know that the monitoring system itself is running? You’ll
need another level of monitoring/alerting (hence “meta-monitoring”).
</p>

<p>
Recently, I realized that I could use Gmail for meta-monitoring: <a
href="https://www.google.com/script/start/">Google Apps Script</a> allows users
to run JavaScript code periodically that has access to Gmail and other Google
apps. That way, I can have a cronjob which looks for emails from my
monitoring/alerting infrastructure, and if there are none for 2 days, I get an
alert email from that script.
</p>

<p>
That’s a rather simple way of having an entirely different layer of monitoring
code, so that the two monitoring systems don’t suffer from a common bug.
Further, the code is running on Google servers, so hardware failures of my
monitoring system don’t affect it.
</p>

<p>
The rest of this article walks you through the setup, assuming you’re already
using Prometheus, Alertmanager and Gmail.
</p>

<h3>Installing the meta-monitoring Google Apps Script</h3>

<p>
See <a
href="https://developers.google.com/apps-script/overview#your_first_script">the
“Your first script”</a> instructions for how to create a new Google Apps Script
file. Then, use the following code, of course replacing the email addresses of
your Alertmanager instance and your own email address:
</p>

<pre>
// vim:ts=2:sw=2:et:ft=javascript
// Licensed under the Apache 2 license.
// © 2015 Google Inc.

// Runs every day between 07:00 and 08:00 in the local time zone.
function checkAlertmanager() {
  // Find all matching email threads within the last 2 days.
  // Should result in 2 threads, unless something went wrong.
  var search_atoms = [
    'from:alertmanager@example.org',
    'subject:daily alert test',
    'newer_than:2d',
  ];
  var threads = GmailApp.search(search_atoms.join(' '));
  if (threads.length === 0) {
    GmailApp.sendEmail(
      'michael@example.org',
      'ALERT: alertmanager test mail is missing for 2d',
      'Subject says it all');
  }
}
</pre>

<p>
In the menu, select “Resources → Current project’s triggers”. Click “Add a new
trigger”, select “Time-driven”, “Day timer” and set the time to “7am to 8am”.
This will make script run every day between 07:00 and 08:00. The time doesn’t
really matter, but you need to specify something. I went for the 07:00-08:00
timespan because that’s shortly before I typically get up, so likely I’ll be
presented with the freshest results just when I get up.
</p>

<p>
You can now either wait a day for the trigger to fire, or you can select the
<code>checkAlertmanager</code> function in the “Run” menu to run it right away.
You should end up with an email in your inbox, notifying you that the daily
alert test is missing, which is expected since we did not configure it yet :).
</p>

<h3>Configuring a daily test alert in Prometheus</h3>

<p>
Create a file called <code>dailytest.rules</code> with the following content:
</p>

<pre>
ALERT DailyTest
  IF vector(1) > 0
  FOR 1m
  LABELS {
    job = "dailytest",
  }
  ANNOTATIONS {
    summary = "daily alert test",
    description = "daily alert test",
  }
</pre>

<p>
Then, include it in your Prometheus config’s rules section. After restarting
Prometheus or sending it a <code>SIGHUP</code> signal, you should see the new
alert on the <code>/alerts</code> status page:
</p>

<img src="/Bilder/prometheus-daily-alert-lores.png" srcset="/Bilder/prometheus-daily-alert.png 2x" width="545" height="350" alt="prometheus daily alert">

<h3>Configuring Alertmanager</h3>

<p>
In your Alertmanager configuration, you’ll need to specify where that alert
should be delivered to and how often it should repeat. I suggest you add a
<code>notification_config</code> that you’ll use specifically for the daily
alert test and nothing else, so that you never accidentally change something:
</p>

<pre>
route:
  group_by: ['alertname']
  group_wait: 30s
  group_interval: 30s
  repeat_interval: 1h
  receiver: team-X-pager

  routes:
  - match:
      job: dailytest
    receiver: dailytest
    repeat_interval: 1d

receivers:
- name: 'dailytest'
  email_configs:
  - to: 'michael+alerts@example.org'
</pre>

<p>
Send Alertmanager a <code>SIGHUP</code> signal to make it reload its
configuration file. After Prometheus has been running for a minute, you should
see the following alert on your Alertmanager’s <code>/alerts</code> status
page:
</p>

<img src="/Bilder/alertmanager-daily-alert-lores.png" srcset="/Bilder/alertmanager-daily-alert.png 2x" width="422" height="189" alt="prometheus alertmanager alert">

<h3>Adding a Gmail filter to hide daily test alerts</h3>

<p>
Finally, once you verified everything is working, add a filter so that the
daily test alerts don’t clutter your Gmail inbox: put
“<code>from:(alertmanager@example.org) subject:(DailyTest)</code>” into
the search box, click the drop-down icon, click “Create filter with this
search”, select “Skip the Inbox”.
</p>

<img src="/Bilder/gmail-alert-filter-lores.png" srcset="/Bilder/gmail-alert-filter.png 2x" width="653" height="400" alt="gmail filter screenshot">
