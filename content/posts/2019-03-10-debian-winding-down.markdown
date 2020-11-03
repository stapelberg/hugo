---
layout: post
date: 2019-03-10
title: "Winding down my Debian involvement"
categories: Artikel
tags:
- debian
---

This post is hard to write, both in the emotional sense but also in the “I would
have written a shorter letter, but I didn’t have the time” sense. Hence, please
assume the best of intentions when reading it—it is not my intention to make
anyone feel bad about their contributions, but rather to provide some insight
into why my frustration level ultimately exceeded the threshold.

Debian has been in my life for well over 10 years at this point.

A few weeks ago, I have visited some old friends at the Zürich Debian meetup
after a multi-year period of absence. On my bike ride home, it occurred to me
that the topics of our discussions had remarkable overlap with my last visit. We
had a discussion about the merits of systemd, which took a detour to respect in
open source communities, returned to processes in Debian and eventually
culminated in democracies and their theoretical/practical failings. Admittedly,
that last one might be a Swiss thing.

I say this not to knock on the Debian meetup, but because it prompted me to
reflect on what feelings Debian is invoking lately and whether it’s still a good
fit for me.

So I’m finally making a decision that I should have made a long time ago: I am
winding down my involvement in Debian to a minimum.

## What does this mean?

Over the coming weeks, I will:

* transition packages to be team-maintained where it makes sense
* remove myself from the `Uploaders` field on packages with other maintainers
* orphan packages where I am the sole maintainer

I will try to keep up best-effort maintenance of the
[manpages.debian.org](https://manpages.debian.org/) service and the
[codesearch.debian.net](https://codesearch.debian.net/) service, but any help
would be much appreciated.

For all intents and purposes, please treat me as permanently on vacation. I will
try to be around for administrative issues (e.g. permission transfers) and
questions addressed directly to me, permitted they are easy enough to answer.

## Why?

When I joined Debian, I was still studying, i.e. I had luxurious amounts of
spare time. Now, over 5 years of full time work later, my day job taught me a
lot, both about what works in large software engineering projects and how I
personally like my computer systems. I am very conscious of how I spend the
little spare time that I have these days.

The following sections each deal with what I consider a major pain point, in no
particular order. Some of them influence each other—for example, if changes
worked better, we could have a chance at transitioning packages to be more
easily machine readable.

### Change process in Debian

The last few years, my current team at work conducted various smaller and larger
refactorings across the entire code base (touching thousands of projects), so we
have learnt a lot of valuable lessons about how to effectively do these
changes. It irks me that Debian works almost the opposite way in every regard. I
appreciate that every organization is different, but I think a lot of my points
do actually apply to Debian.

In Debian, packages are nudged in the right direction by a document called the
[Debian Policy](https://www.debian.org/doc/debian-policy/), or its programmatic
embodiment, lintian.

While it is great to have a lint tool (for quick, local/offline feedback), it is
even better to not require a lint tool at all. The team conducting the change
(e.g. the C++ team introduces a new hardening flag for all packages) should be
able to do their work transparent to me.

Instead, currently, all packages become lint-unclean, all maintainers need to
read up on what the new thing is, how it might break, whether/how it affects
them, manually run some tests, and finally decide to opt in. This causes a lot
of overhead and manually executed mechanical changes across packages.

Notably, the **cost of each change** is distributed onto the package maintainers in
the Debian model. At work, we have found that the opposite works better: if the
team behind the change is put in power to do the change for as many users as
possible, they can be significantly more efficient at it, which reduces the
total cost and time a lot. Of course, exceptions (e.g. a large project abusing a
language feature) should still be taken care of by the respective owners, but
the important bit is that the default should be the other way around.

Debian is **lacking tooling for large changes**: it is hard to programmatically
deal with packages and repositories (see the section below). The closest to
“sending out a change for review” is to open a bug report with an attached
patch. I thought the workflow for accepting a change from a bug report was too
complicated and started [mergebot](/posts/2016-07-17-mergebot/), but only Guido
ever signaled interest in the project.

Culturally, reviews and reactions are slow. There are no deadlines. I literally
sometimes get emails notifying me that a patch I sent out a few years ago (!!)
is now merged. This turns projects from a small number of weeks into many years,
which is a huge demotivator for me.

Interestingly enough, you can see artifacts of the slow online activity manifest
itself in the offline culture as well: I don’t want to be discussing systemd’s
merits 10 years after I first heard about it.

Lastly, changes can easily be slowed down significantly by holdouts who refuse
to collaborate. My canonical example for this is rsync, whose maintainer refused
my patches to make the package use debhelper purely out of personal preference.

Granting so much personal freedom to individual maintainers prevents us as a
project from raising the abstraction level for building Debian packages, which
in turn makes tooling harder.

How would things look like in a better world?

1. As a project, we should strive towards more unification. Uniformity still
   does not rule out experimentation, it just changes the trade-off from easier
   experimentation and harder automation to harder experimentation and easier
   automation.
1. Our culture needs to shift from “this package is my domain, how dare you
   touch it” to a shared sense of ownership, where anyone in the project can
   easily contribute (reviewed) changes without necessarily even involving
   individual maintainers.

To learn more about how successful large changes can look like, I recommend [my
colleague Hyrum Wright’s talk “Large-Scale Changes at Google: Lessons Learned
From 5 Yrs of Mass Migrations”](https://www.youtube.com/watch?v=TrC6ROeV4GI).

### Fragmented workflow and infrastructure

Debian generally seems to prefer decentralized approaches over centralized
ones. For example, individual packages are maintained in separate repositories
(as opposed to in one repository), each repository can use any SCM (git and svn
are common ones) or no SCM at all, and each repository can be hosted on a
different site. Of course, what you do in such a repository also varies subtly
from team to team, and even within teams.

In practice, non-standard hosting options are used rarely enough to not justify
their cost, but frequently enough to be a huge pain when trying to automate
changes to packages. Instead of using GitLab’s API to create a merge request,
you have to design an entirely different, more complex system, which deals with
intermittently (or permanently!) unreachable repositories and abstracts away
differences in patch delivery (bug reports, merge requests, pull requests,
email, …).

Wildly diverging workflows is not just a temporary problem either. I
participated in long discussions about different git workflows during DebConf
13, and gather that there were similar discussions in the meantime.

Personally, I cannot keep enough details of the different workflows in my
head. Every time I touch a package that works differently than mine, it
frustrates me immensely to re-learn aspects of my day-to-day.

After noticing workflow fragmentation in the Go packaging team (which I
started), I tried fixing this with the [workflow changes
proposal](https://go-team.pages.debian.net/workflow-changes.html), but did not
succeed in implementing it. The lack of effective automation and slow pace of
changes in the surrounding tooling despite my willingness to contribute time and
energy killed any motivation I had.

### Old infrastructure: package uploads

When you want to make a package available in Debian, you upload GPG-signed files
via anonymous FTP. There are several batch jobs (the queue daemon, `unchecked`,
`dinstall`, possibly others) which run on fixed schedules (e.g. `dinstall` runs
at 01:52 UTC, 07:52 UTC, 13:52 UTC and 19:52 UTC).

Depending on timing, I estimated that you might wait for over 7 hours (!!)
before your package is actually installable.

What’s worse for me is that feedback to your upload is asynchronous. I like to
do one thing, be done with it, move to the next thing. The current setup
requires a many-minute wait and costly task switch for no good technical
reason. You might think a few minutes aren’t a big deal, but when all the time I
can spend on Debian per day is measured in minutes, this makes a huge difference
in perceived productivity and fun.

The last communication I can find about speeding up this process is [ganneff’s
post](https://lists.debian.org/debian-project/2008/12/msg00014.html) from 2008.

How would things look like in a better world?

1. Anonymous FTP would be replaced by a web service which ingests my package and
   returns an authoritative accept or reject decision in its response.
1. For accepted packages, there would be a status page displaying the build
   status and when the package will be available via the mirror network.
1. Packages should be available within a few minutes after the build completed.

### Old infrastructure: bug tracker

I dread interacting with the Debian bug
tracker. [debbugs](https://en.wikipedia.org/wiki/Debbugs) is a piece of software
(from 1994) which is only used by Debian and the GNU project these days.

Debbugs processes emails, which is to say it is asynchronous and cumbersome to
deal with. Despite running on the fastest machines we have available in Debian
(or so I was told when the subject last came up), its web interface loads very
slowly.

Notably, the web interface at bugs.debian.org is read-only. Setting up a working
email setup for
[`reportbug(1)`](https://manpages.debian.org/stretch/reportbug/reportbug.1.en.html)
or manually dealing with attachments is a rather big hurdle.

For reasons I don’t understand, every interaction with debbugs results in [many
different email _threads_](https://twitter.com/zekjur/status/1027995569770442752).

Aside from the technical implementation, I also can never remember the different
ways that Debian uses pseudo-packages for bugs and processes. I need them rarely
enough to establish a mental model of how they are set up, or working memory of
how they are used, but frequently enough to be annoyed by this.

How would things look like in a better world?

1. Debian would switch from a custom bug tracker to a (any) well-established
   one.
1. Debian would offer automation around processes. It is great to have a
   paper-trail and artifacts of the process in the form of a bug report, but the
   primary interface should be more convenient (e.g. a web form).

### Old infrastructure: mailing list archives

It baffles me that in 2019, we still don’t have a conveniently browsable
threaded archive of mailing list discussions. Email and threading is more widely
used in Debian than anywhere else, so this is somewhat
ironic. [Gmane](https://en.wikipedia.org/wiki/Gmane) used to paper over this
issue, but Gmane’s availability over the last few years has been spotty, to say
the least (it is down as I write this).

I tried to contribute a threaded list archive, but our listmasters didn’t seem
to care or want to support the project.

### Debian is hard to machine-read

While it is obviously possible to deal with Debian packages programmatically,
the experience is far from pleasant. Everything seems slow and cumbersome. I
have picked just 3 quick examples to illustrate my point.

[debiman](https://github.com/Debian/debiman/) needs [help from
piuparts](https://github.com/Debian/debiman/issues/12) in analyzing the
alternatives mechanism of each package to display the manpages of
e.g. [`psql(1)`](https://manpages.debian.org/stretch/postgresql-client-9.6/psql.1.en.html). This
is because maintainer scripts modify the alternatives database by calling shell
scripts. Without actually installing a package, you cannot know which changes it
does to the alternatives database.

[pk4](https://github.com/Debian/pk4) needs to maintain its own cache to look up
package metadata based on the package name. Other tools parse the apt database
from scratch on every invocation. A proper database format, or at least a binary
interchange format, would go a long way.

[Debian Code Search](https://github.com/Debian/dcs/) wants to ingest new
packages as quickly as possible. There used to be a
[fedmsg](https://github.com/fedora-infra/fedmsg) instance for Debian, but it no
longer seems to exist. It is unclear where to get notifications from for new
packages, and where best to fetch those packages.

### Complicated build stack

See my [“Debian package build tools”](/posts/2016-11-25-build-tools/) post. It
really bugs me that the sprawl of tools is not seen as a problem by others.

### Developer experience pretty painful

Most of the points discussed so far deal with the experience in *developing
Debian*, but as I recently described in my post [“Debugging experience in
Debian”](/posts/2019-02-15-debian-debugging-devex/), the experience when
*developing using Debian* leaves a lot to be desired, too.

### I have more ideas

At this point, the article is getting pretty long, and hopefully you got a rough
idea of my motivation.

While I described a number of specific shortcomings above, the final nail in the
coffin is actually the lack of a positive outlook. I have more ideas that seem
really compelling to me, but, based on how my previous projects have been going,
I don’t think I can make any of these ideas happen within the Debian project.

I intend to publish a few more posts about specific ideas for improving
operating systems here. Stay tuned.

Lastly, I hope this post inspires someone, ideally a group of people, to improve
the developer experience within Debian.
