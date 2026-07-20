---
permalink: /post/25
layout: post
date: 2010-07-31 02:06:05 +02:00
title: "
In C++ gibt es Closures! Zwar…"
---
<p>
In C++ gibt es Closures! Zwar erst mit <a
href="http://en.wikipedia.org/wiki/C%2B%2B0x">C++0x</a> (wofür man g++ 4.5
braucht), aber immerhin. Damit wird das Erstellen asynchroner APIs endlich
annehmbar (in diesem Fall der CouchDB-Teil einer Qt-Anwendung, wegen Qt muss
ich überhaupt erst C++ nutzen).
</p>

<p>
Zum Vergleich mal die API vorher:
</p>

<pre>
void MainWindow::clickedTask() {
    TodoButton *btn = (TodoButton*)sender();

    /* Get the document from CouchDB */
    QNetworkReply *nreply = db->get_document(btn->ID());
    connect(nreply, SIGNAL(finished()), this, SLOT(recv_entry_edit()));
}

void MainWindow::recv_entry_edit() {
    QNetworkReply *reply = (QNetworkReply*)sender();
    QByteArray answer = reply->readAll();
    QJson::Parser p;
    bool ok;
    QVariant var = p.parse(answer, &ok);

    CouchDoc doc = var.toMap();

    QDialog dialog(this, Qt::Dialog);
    ui_dialog->setupUi(&dialog);
    ui_dialog->textLineEdit->setText(doc["text"].toString());
    dialog.exec();
}
</pre>

<p>
Was fällt dabei auf? Da <a
href="http://doc.trolltech.com/4.6/qnetworkaccessmanager.html">QNetworkAccessManager</a>
(die Klasse in Qt, die HTTP spricht) asynchron arbeitet (was ja prinzipiell
wünschenswert ist, aber bei dieser Anwendung wäre eine synchrone API einfacher
und ausreichend), muss man das finished-Signal mit dem
recv_entry_edit-Slot verbinden. Hier müssen wir also einen slot definieren (mit
Name, Eintrag im Headerfile, Unterbrechung des Leseflusses beim Verstehen des
Codes). Weiterhin habe ich mich entschieden, das JSON-Parsing nicht
wegzuabstrahieren, da ich dafür letztendlich einen Wrapper um QNetworkReply
hätte schreiben müssen, der dann genauso umständlich zu benutzen ist.
</p>

<p>
Hier also die viel bessere Variante mit Closures:
</p>

<pre>
void MainWindow::clickedTask() {
    TodoButton *btn = (TodoButton*)sender();

    db->get_document(btn->ID(),
        [](CouchDoc &doc) {
            QDialog dialog(this, Qt::Dialog);
            ui_dialog->setupUi(&dialog);
            ui_dialog->textLineEdit->setText(doc["text"].toString());
            dialog.exec();
        },
        [](QString &err) {
            cerr << "Could not receive doc: " << err.toStdString() << endl;
        });
}
</pre>

<p>
Was hier passiert, ist, dass die Code-Blöcke abgespeichert werden (sozusagen,
für Details verlinke ich unten auf ein Paper) und später mit den jeweiligen
Parametern aufgerufen werden. Wir müssen also keine Funktion definieren,
Signale verbinden und können auf Seite der API das JSON-Parsing hübsch
abstrahieren.  Wohlgemerkt haben wir hier auch Error Handling und der Code ist
trotzdem kürzer.
</p>

<p>
Hier noch zwei Links, die beim Einarbeiten helfen:
</p>

<ul>
<li>
<a href="http://www2.in.tum.de/hp/file?fid=452">Lambdafunktionen
(Seminarausarbeitung)</a>
</li>
<li>
<a
href="http://en.wikipedia.org/wiki/C%2B%2B0x#Lambda_functions_and_expressions">Wikipedia:
C++0x (Lambda functions and exrpessions)</a>
</li>
</ul>

