---
layout: post
title:  "Webfont loading with FOUT"
date:   2017-01-28 15:57:00
categories: Artikel
---
<p>
For <a href="https://manpages.debian.org">manpages.debian.org</a>, I looked at loading webfonts. I considered the following scenarios:
</p>

<table width="100%" style="margin-bottom: 1em">

<tr>
<th style="text-align: center">#</th>
<th style="text-align: center">local?</th>
<th style="text-align: center">cached?</th>
<th style="text-align: center">Network</th>
<th style="text-align: center">Expected</th>
<th style="text-align: center">Observed</th>
</tr>

<tr style="text-align: center">
<td>1</td>
<td>Yes</td>
<td>/</td>
<td>/</td>
<td>perfect render</td>
<td>perfect render</td>
</tr>

<tr style="text-align: center">
<td>2</td>
<td>No</td>
<td>Yes</td>
<td>/</td>
<td>perfect render</td>
<td>perfect render</td>
</tr>

<tr style="text-align: center">
<td>3</td>
<td>No</td>
<td>No</td>
<td>Fast</td>
<td>FOUT</td>
<td>FOIT</td>
</tr>

<tr style="text-align: center">
<td>4</td>
<td>No</td>
<td>No</td>
<td>Slow</td>
<td>FOUT</td>
<td>some FOUT, some FOIT</td>
</tr>

</table>

<p>
Scenario #1 and #2 are easy: the font is available, so if we inline the CSS into the HTML page, the browser should be able to render the page perfectly on the first try. Unfortunately, the more common scenarios are #3 and #4, since many people reach <a href="https://manpages.debian.org">manpages.debian.org</a> through a link to an individual manpage.
</p>

<p>
The default browser behavior, if we just specify a webfont using <code>@font-face</code> in our stylesheet, is the Flash Of Invisible Text (FOIT), i.e. the page loads, but text remains hidden until fonts are loaded. On a good 3G connection, this means users will have to wait 500ms to see the page content, which is far too long for my taste. The user experience becomes especially jarring when the font doesn’t actually load — users will just see a spinner and leave the site frustrated.
</p>

<p>
In comparison, when using the Flash Of Unstyled Text (FOUT), loading time is 250ms, i.e. cut in half! Sure, you have a page reflow after the fonts have actually loaded, but at least users will immediately see the content.
</p>

<h2>In an ideal world</h2>

<p>
In an ideal world, I could just specify <code>font-display: swap</code> in my <code>@font-face</code> definition, but <a href="https://tabatkins.github.io/specs/css-font-display/">the css-font-display spec</a> is unofficial and <a href="http://caniuse.com/#feat=css-font-rendering-controls">not available in any browser yet</a>.
</p>

<h2>Toolbox</h2>

<p>
To achieve FOUT when necessary and perfect rendering when possible, we make use of the following tools:
</p>

<dl>
<dt>
CSS font loading API
</dt>
<dd style="margin-bottom: 1em">
The font loading API allows us to request a font load before the DOM is even created, i.e. before the browser would normally start processing font loads. Since we can specify a callback to be run when the font is loaded, we can apply the style as soon as possible — if the font was cached or is installed locally, this means before the DOM is first created, resulting in a perfect render.<br>

This API is <a href="http://caniuse.com/#feat=font-loading">available in Firefox, Chrome, Safari, Opera</a>, but notably not in IE or Edge.
</dd>

<dt>
single round-trip asynchronous font loading
</dt>
<dd>
For the remaining browsers, we’ll need to load the fonts and only apply them after they have been loaded. The best way to do this is to create a stylesheet which contains the inlined font files as base64 data and the corresponding styles to enable them. Once the browser loaded the file, it will apply the font, which at that point is guaranteed to be present.<br>
In order to load that stylesheet without blocking the page load, we’ll use <a href="https://w3c.github.io/preload/">Preloading</a>.<br>
Native <code>&lt;link rel="preload"&gt;</code> support is <a href="http://caniuse.com/#feat=link-rel-preload">available only in Chrome and Opera</a>, but there are <a href="https://github.com/filamentgroup/loadCSS">polyfills for the remaining browsers</a>.<br>
Note that a downside of this technique is that we don’t distinguish between WOFF2 and WOFF fonts, we always just serve WOFF. This maximizes compatibility, but means that WOFF2-capable browsers will have to download more bytes than they had to if we offered WOFF2.
</dd>

</dl>

<h2>Combination</h2>

<p>
The following flow chart illustrates how to react to different situations:
</p>

<img src="/Bilder/font_loading.svg" width="400">

<h2>Putting it all together</h2>

<strong>Example fonts stylesheet:</strong> (base64 data removed for readability)
<pre>
@font-face {
  font-family: 'Inconsolata';
  src: local('Inconsolata'),
       url("data:application/x-font-woff;charset=utf-8;base64,[…]") format("woff");
}

@font-face {
  font-family: 'Roboto';
  font-style: normal;
  font-weight: 400;
  src: local('Roboto'),
       local('Roboto Regular'),
       local('Roboto-Regular'),
       url("data:application/x-font-woff;charset=utf-8;base64,[…]") format("woff");
}

body {
  font-family: 'Roboto', sans-serif;
}

pre, code {
  font-family: 'Inconsolata', monospace;
}
</pre>

<strong>Example document:</strong>
<pre>
&lt;head&gt;
&lt;style type="text/css"&gt;
/* Defined, but not referenced */

@font-face {
  font-family: 'Inconsolata';
  src: local('Inconsolata'),
       url(/Inconsolata.woff2) format('woff2'),
       url(/Inconsolata.woff) format('woff');
}   

@font-face {
  font-family: 'Roboto';
  font-style: normal;
  font-weight: 400;
  src: local('Roboto'),
       local('Roboto Regular'),
       local('Roboto-Regular'),
       url(/Roboto-Regular.woff2) format('woff2'),
       url(/Roboto-Regular.woff) format('woff');
}   
&lt;/style&gt;
&lt;script type="text/javascript"&gt;
if (!!document['fonts']) {
        /* font loading API supported */
        var r = "body { font-family: 'Roboto', sans-serif; }";
        var i = "pre, code { font-family: 'Inconsolata', monospace; }";
        var l = function(m) {
                if (!document.body) {
                        /* cached, before DOM is built */
                        document.write("&lt;style&gt;"+m+"&lt;/style&gt;");
                } else {
                        /* uncached, after DOM is built */
                        document.body.innerHTML+="&lt;style&gt;"+m+"&lt;/style&gt;";
                }
        };
        new FontFace('Roboto',
                     "local('Roboto'), " +
                     "local('Roboto Regular'), " +
                     "local('Roboto-Regular'), " +
                     "url(/Roboto-Regular.woff2) format('woff2'), " +
                     "url(/Roboto-Regular.woff) format('woff')")
                .load().then(function() { l(r); });
        new FontFace('Inconsolata',
                     "local('Inconsolata'), " +
                     "url(/Inconsolata.woff2) format('woff2'), " +
                     "url(/Inconsolata.woff) format('woff')")
                .load().then(function() { l(i); });
} else {
        var l = document.createElement('link');
        l.rel = 'preload';
        l.href = '/fonts-woff.css';
        l.as = 'style';
        l.onload = function() { this.rel = 'stylesheet'; };
        document.head.appendChild(l);
}
&lt;/script&gt;
&lt;noscript&gt;
  &lt;style type="text/css"&gt;
    body { font-family: 'Roboto', sans-serif; }
    pre, code { font-family: 'Inconsolata', monospace; }
  &lt;/style&gt;
&lt;/noscript&gt;
&lt;/head&gt;
&lt;body&gt;

[…content…]

&lt;script type="text/javascript"&gt;
/* inlined loadCSS.js and cssrelpreload.js from
   https://github.com/filamentgroup/loadCSS/tree/master/src */
(function(a){"use strict";var b=function(b,c,d){var e=a.document;var f=e.createElement("link");var g;if(c)g=c;else{var h=(e.body||e.getElementsByTagName("head")[0]).childNodes;g=h[h.length-1];}var i=e.styleSheets;f.rel="stylesheet";f.href=b;f.media="only x";function j(a){if(e.body)return a();setTimeout(function(){j(a);});}j(function(){g.parentNode.insertBefore(f,(c?g:g.nextSibling));});var k=function(a){var b=f.href;var c=i.length;while(c--)if(i[c].href===b)return a();setTimeout(function(){k(a);});};function l(){if(f.addEventListener)f.removeEventListener("load",l);f.media=d||"all";}if(f.addEventListener)f.addEventListener("load",l);f.onloadcssdefined=k;k(l);return f;};if(typeof exports!=="undefined")exports.loadCSS=b;else a.loadCSS=b;}(typeof global!=="undefined"?global:this));
(function(a){if(!a.loadCSS)return;var b=loadCSS.relpreload={};b.support=function(){try{return a.document.createElement("link").relList.supports("preload");}catch(b){return false;}};b.poly=function(){var b=a.document.getElementsByTagName("link");for(var c=0;c&lt;b.length;c++){var d=b[c];if(d.rel==="preload"&&d.getAttribute("as")==="style"){a.loadCSS(d.href,d);d.rel=null;}}};if(!b.support()){b.poly();var c=a.setInterval(b.poly,300);if(a.addEventListener)a.addEventListener("load",function(){a.clearInterval(c);});if(a.attachEvent)a.attachEvent("onload",function(){a.clearInterval(c);});}}(this));
&lt;/script&gt;
&lt;/body&gt;

</pre>
