---
permalink: /post/27
layout: post
date: 2010-09-01 23:52:29 +02:00
title: "
Wenn man DBus versteht (was a…"
---
<p>
Wenn man DBus versteht (was am Anfang nicht einfach ist, insbesondere wenn man
nur mal kurz reinschauen will) und insbesondere die DBus-API der
Programmiersprache der Wahl versteht, ist das ja ganz in Ordnung. Scheint
schnell zu sein und man kann damit recht stabil IPC bauen (auch wenn ich Teile
der schwarzen Magie in dem ganzen Konstrukt, was heutzutage einen Desktop
auszumachen scheint, noch nicht verstanden habe).
</p>

<p>
Nokia hingegen scheint DBus teilweise noch nicht wirklich verstanden zu haben.
Man braucht sich dazu nur mal die Internet Connectivity-APIs auf Maemo
anzusehen. Diese sind dafür da, eine Internetverbindung herzustellen, bei
Veränderungen der Konnektivität Anwendungen zu benachrichtigen oder Statistiken
über die derzeitige Verbindung bereitzustellen (per GPRS übertragenes
Datenvolumen z.B.).
</p>

<p>
Dieser IC-API fehlt nun leider die Möglichkeit, auf die derzeit vorhandenen
WLANs zuzugreifen. Ein Blick ins syslog offenbart allerdings, dass der
<code>wlancond</code> für die Verwaltung der WLAN-Verbindung zuständig ist.
Dieser spricht selbstverständlich via DBus mit dem <code>icd</code> (Internet
Connectivity Daemon). Also kann ich den <code>wlancond</code> auch von meiner
eigenen Anwendung aus ansprechen.
</p>

<p>
Zunächst fehlt dem <code>wlancond</code> leider die XML-Beschreibung über die
verfügbaren Pfade, Interfaces, Methoden und Signale. Würde diese Datei
existieren, könnte man zum einen leichter programmieren, zum anderen wäre Nokia
dann bestimmt auch aufgefallen, was für einen Müll sie eigentlich durch die
Gegend schicken. Hier mal ein Ausschnitt aus dem Code, den man braucht, um die
derzeit verfügbaren ESSIDs inklusive Signalstärke auszulesen:
</p>

<pre>
int main(int argc, char *argv[]) {
    QApplication a(argc, argv);

    QDBusConnection conn = QDBusConnection::systemBus();
    QDBusInterface wlancond(WLANCOND_SERVICE, WLANCOND_REQ_PATH, WLANCOND_REQ_INTERFACE, conn);
    /* Arguments are power level, SSID, length of SSID */
    QDBusMessage reply = wlancond.call(WLANCOND_SCAN_REQ, WLANCOND_TX_POWER10, QByteArray(""), 0);
    if (reply.type() == QDBusMessage::ErrorMessage)
        qDebug() << reply.errorMessage();

    conn.connect(
        WLANCOND_SERVICE,
        WLANCOND_SIG_PATH,
        WLANCOND_SIG_INTERFACE,
        WLANCOND_SCAN_RESULTS_SIG,
        &app,
        SLOT(scan_results(const QDBusMessage&))
    );

    return a.exec();
}

void app::scan_results(const QDBusMessage &msg) {
    QList<QVariant> args = msg.arguments();

    int networks = args.value(0).value < int > ();
    for (int c = 0; c < networks; c++) {
        qDebug() << "network" << c << "of" << networks << ":";
        int pos = 1 + (c * 5);
        qDebug() << "ESSID:" << args.value(pos).value < QByteArray > ();
        qDebug() << "RSSI:" << args.value(pos+2).value < int > ();
    }
}
</pre>

<p>
Für die weniger DBus-Bewanderten: Nachdem man den scan request gesendet hat
(<code>wlancond.call()</code>), der merkwürdigerweise den DBus-Datentyp string
ignoriert und stattdessen length-suffixed (!) byte arrays für die Übergabe der
SSID nutzt, bekommt man, sobald der Scan fertig ist, ein Signal mit den
gefundenen Netzen. Soweit ist das alles kein Problem. Der Clou ist jedoch, dass
dieses Signal <strong>direkt</strong> alle gefunden Netze als Argumente
enthält. Soll heißen am Anfang findet sich die Anzahl der gefundenen Netze,
anschließend folgt die ESSID als Byte-Array, dann die BSSID, dann die RSSI, der
Kanal, was das Netz kann und danach geht’s mit dem nächsten Netz weiter. Man
muss sich das also alles selber zusammenfummeln. Wie hübsch der Code aussieht,
sieht man ja.
</p>

<p>
Sinnvoller wäre gewesen, ein Array zu versenden (dann kann man nämlich auch
direkt die Signatur des Signals nutzen und Qt kann Typprüfung vornehmen),
welches pro Netz ein Dictionary enthält (dann muss man sich nicht selbst Stück
für Stück durch die Argumente wühlen).
</p>

<p>
Hoffentlich sieht Nokia in QtMobility eine einfachere Möglichkeit vor, sich die
verfügbaren Netze anzusehen…
</p>

