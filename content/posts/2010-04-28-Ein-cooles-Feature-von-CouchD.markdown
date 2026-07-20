---
permalink: /post/10
layout: post
date: 2010-04-28 19:00:12 +02:00
title: "
Ein cooles Feature von CouchD…"
---
<p>
Ein cooles Feature von <a href="http://www.couchdb.org/">CouchDB</a> sind
<a href="http://books.couchdb.org/relax/reference/change-notifications">Change
Notifications</a>: Anstatt wiederholt zu pullen, ob neue Daten da sind, kann
man sich von CouchDB benachrichtigen lassen („continuous polling”). Besonders
in Kombination mit Replikation ist das eine nette Sache und integriert sich
nahtlos in ein event-basiertes Programm (man kann natürlich auch blockierend
effizient pollen).
</p>

<p>
Als Beispiel nehmen wir eine Datenbank, welche Termine enthält. Diese
Datenbank enthält ebenfalls zu erledigende Aufgaben, unser Programm ist aber
nur an Terminen interessiert. Hier können wir einen Filter erstellen, den
wir später nutzen (ID „_design/date”):
</p>

<pre>
{
  "_id": "_design/date",
  "filters": {
    "dates_only": "function(doc, req) { return (doc.type == \"date\"); }"
  }
}
</pre>

<p>
Um also beispielsweise alle neuen Termine aus einer CouchDB-Datenbank in einem
Programm zu verarbeiten und dabei Replikation zu unterstützen, könnte man
folgendermaßen vorgehen (mit <a
href="http://live.gnome.org/LibSoup">libsoup</a> und <a
href="http://live.gnome.org/JsonGlib">json-glib</a>, alternativ könnte man
<a href="http://curl.haxx.se/">libcurl</a> und <a
href="http://lloyd.github.com/yajl/">yajl</a> benutzen, die ich aber beide
nur in einem anderen Kontext ausprobiert habe):
</p>

<pre>
#include &lt;stdio.h&gt;
#include &lt;stdlib.h&gt;
#include &lt;string.h&gt;
#include &lt;err.h&gt;

#include &lt;libsoup/soup.h&gt;
#include &lt;json-glib/json-glib.h&gt;

/* dieser Callback sollte niemals aufgerufen werden, es sei denn CouchDB
 * wurde gerade beendet (die Verbindung wird andernfalls nicht zugemacht */
void done(SoupSession *session, SoupMessage *msg, gpointer user_data) {
    errx(EXIT_FAILURE, "Your CouchDB just went away\n");
}

void chunk(SoupMessage *msg, SoupBuffer *chunk, gpointer user_data) {
    /* keepalives (zeilen ohne inhalt, aber mit line-endings) ignorieren */
    if (chunk-&gt;length &lt; 3)
        return;

    JsonParser *parser = json_parser_new();
    if (!json_parser_load_from_data(parser, chunk-&gt;data, chunk-&gt;length, NULL))
        errx(EXIT_FAILURE, "CouchDB returned invalid JSON (%s)\n", chunk-&gt;data);

    JsonObject *root = json_node_get_object(json_parser_get_root(parser));
    const char *id = json_node_get_string(json_object_get_member(root, "id"));
    if (id == NULL)
        return;
    printf("New entry with id = %s\n", id);

    /* hier sollte man jetzt irgendwas mit dem neuen Eintrag machen, z.B.
     * ihn an irgendeine API übergeben */

    g_object_unref(G_OBJECT(parser));
}

int main() {
    g_type_init();
    g_thread_init(NULL);

    const char *url = "http://localhost:5984/calendar" \
    "/_changes?feed=continuous&filter=date/dates_only&heartbeat=30000";

    SoupSession *session = soup_session_async_new();

    SoupMessage *http_message = soup_message_new("GET", url);
    /* bei jedem Chunk einen Callback aufrufen */
    g_signal_connect(G_OBJECT(http_message), "got-chunk", G_CALLBACK(chunk), session);

    /* die empfangenen Chunks nicht speichern */
    soup_message_body_set_accumulate(http_message-&gt;response_body, FALSE);

    /* Nachricht versenden sobald möglich (in der mainloop) */
    soup_session_queue_message(session, http_message, done, NULL);

    GMainLoop *main_loop = g_main_loop_new(NULL, FALSE);
    g_main_loop_run(main_loop);
}
</pre>

<p>
Kompilieren kann man das Programm (quick and dirty) via:
</p>

<pre>gcc -std=c99 -Wall -o changes changes.c $(pkg-config --cflags --libs libsoup-2.4 json-glib-1.0)</pre>

<p>
Zu beachten ist hierbei der <code>heartbeat</code>-Parameter, der in
Millisekunden angibt, wie oft CouchDB bescheid sagen soll, dass die Verbindung
noch steht. Es ist wichtig, diesen Parameter anzugeben, da CouchDB sonst nach
<code>timeout</code> Millisekunden (standardmäßig 60000) die Verbindung
schließt.
</p>

<p>
Weiterhin machen wir uns zunutze, dass CouchDB für jede Änderung einen
HTTP/1.1 Chunk versendet. Während das „got-chunk”-Signal von libsoup zwar
strenggenommen nicht nur bei Chunks ausgelöst wird (sondern vermutlich auch,
wenn der Puffer voll ist bei langen Dokumenten, die am Stück ausgeliefert
werden), erfüllt es hier ganz gut seinen Zweck. Insbesondere erspart es uns,
selbst einen Parser zu bauen, der dann auch mit unvollständigen Chunks umgehen
muss (dafür braucht man dann wieder einen Buffer, State, …).
</p>

<p>
Auf der Leitung sehen diese Change Notifications übrigens folgendermaßen aus
(jede Zeile enthält ein eigenes JSON-Dokument, da ansonsten das Parsing unnötig
komplex wäre):
</p>

<pre>
{"seq":3,"id":"c6f6f836eec31a3c0b914b3c158ac1ee","changes":[{"rev":"1-2f663403820c8e698580f95a0a7f13aa"}]}     
{"seq":8,"id":"7aaa01d03bba5e7d1acf78af19be080c","changes":[{"rev":"3-694951f61d789a2e05c523afb3e23d9b"}]}
…
</pre>

<p>
Mehr Informationen gibt es <a
href="http://wiki.apache.org/couchdb/HTTP%5Fdatabase%5FAPI#Changes">im
CouchDB-Wiki</a>.
</p>

