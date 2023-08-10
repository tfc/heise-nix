Wäre es nicht schön, wenn man auf allen Linux-Distributionen, unter macOS, in Docker Images und der Windows WSL einfach die selben Pakete aus der weltgrößten Paketsammlung benutzen könnte? Ohne, dass auf allen Systemen andere Paketversionen laufen und Ärger machen? Genau das ermöglicht uns der Paketmanager nix, welcher alle Linux-Distributionen und macOS unterstützt und mit der größten Open Source Paketsammlung der Welt kommt.
Wer bis jetzt noch nicht von nix gehört hat, wird überrascht sein, dass die Technologie dieses Jahr ihr 20 jähriges Jubiläum gefeiert hat und letztes Jahr auf der GitHub Universe Konferenz in den Top 10 der Open Source Projekte auf GitHub (nach Anzahl der Contributors) gelistet wurde. Das mag daran liegen, dass nix Paketmanagement in vielen Hinsichten völlig anders denkt, als die bekannten Lösungen.
In diesem Artikel wagen wir unsere ersten Schritte mit nix!

## Installation

Um nix zu installieren, haben wir zwei Möglichkeiten:
Entweder wir befolgen die Schritte auf https://nixos.org, oder wir benutzen den Installer von https://determinate.systems, welcher noch etwas schneller ist, ein paar sinnvolle Default-Einstellungen auswählt und auch leichter wieder zu deinstallieren ist - Das ist super, wenn wir einfach erst einmal schnuppern wollen.
Die Installation mit dem Installer von Determinate Systems wird mit folgendem Befehl gestartet, den wir in unsere Shell eingeben:

```shell
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Der Installationsprozess erklärt übersichtlich die Installationsschritte, fragt uns dann nach unserer Zustimmung und bittet uns gegebenenfalls noch um die Eingabe des `sudo`-Passworts.
Einige Linux-Distributionen bieten auch ein eigenes nix-Paket an. Von deren Verwendung ist allerdings abzuraten, da nix sich am besten selbst verwaltet und konfiguriert.
Typischerweise sollte man nach der Installation eine neue Shell starten und schon ist der Nix-Befehl verfügbar, was sich sehr leicht testen lässt:

```shell
nix run nixpkgs#cowsay "Hallo c't Leser!"
```

Dieser Befehl lädt zunächst die neueste Version der Paketliste (`nixpkgs`) herunter und wählt das Paket `cowsay` aus, welches eine ulkige ASCII-Darstellung einer Kuh verwandelt, die in einer Sprechblase genau das sagt, was wir ihr als Kommandozeilen-Parameter mitgegeben haben.
Die erste Ausführung dauert einen Moment, da alles heruntergeladen werden muss. Ab dem zweiten Mal geht es viel schneller.
Probieren Sie es auch mit anderen Paketen aus: `python3`, `nodejs`, `git`, und so weiter!

## Erste Schritte

Wie wir willkürliche Programme ohne vorherige Installation starten können, haben wir ja gerade beim ersten Test gesehen: nix run macht genau dies. Nur woher weiß man, dass es Pakete wie `cowsay` unter genau diesem Namen in der Paketliste gibt?
Der mit Abstand bequemste Weg, ein Paket zu finden, ist die Paket-Suchmaschine https://search.nixos.org. Aber wir können auch ohne Browser in der Shell nach Paketen suchen:

```shell
nix search nixpkgs cowsay
```

Wenn wir Befehle häufiger verwenden, dann wollen wir sie natürlich dauerhaft installieren.
Wollen wir zum Beispiel Python 3 dauerhaft installieren, so geht das folgendermaßen:

```shell
nix profile install nixpkgs#python3
```

Installierte Pakete listen wir so auf:

```shell
nix profile list
```

Die Deinstallation ist ebenfalls einfach, auch wenn der Befehl noch etwas sperrig aussieht:

```shell
nix profile remove ".*python3"
```

Alle installierten Pakete lassen sich wie folgt updaten:

```shell
nix profile upgrade ".*"
```

Egal, mit welcher Linux-Distribution wir unterwegs sind, oder ob es ein Mac ist:
Wir haben jetzt mit allen diesen Systemen Zugriff auf die gleichen Pakete aus der grössten und aktuellsten Paketsammlung der Welt!
Wer also oft mit verschiedenen Systemen unterwegs ist, muss sich jetzt nicht mehr merken, wie die gleichen Pakete in den unterschiedlichen Distributionen heißen und wie die verschiedenen Befehle funktionieren.
Leider funktionieren nicht alle Pakete auf allen Betriebssystemen - manche sind nur für Linux verfügbar, manche für macOS.
Die Überschneidung ist allerdings sehr groß.

> Folgende Bilder/Screenshots im Artikel zeigen?

- Link zu Repology-Graph: https://repology.org/repositories/graphs
- Video von GitHub Universe 2022: https://www.youtube.com/watch?app=desktop&v=lTisOy1qcPQ&t=1710s

## Pakete ohne Installation ausprobieren

Anstatt ein Paket fest zu installieren, können wir auch einfach eine neue Shell starten, in der Pakete vorhanden sind - bis wir sie wieder beenden:

```sh
nix shell nixpkgs#{git,curl,python3}
```

Dieser `nix shell` Aufruf startet eine neue Shell, in der die Pakete `git`, `curl` und `python3` in den neuesten Versionen installiert sind.
Nach getaner Arbeit können wir die Shell mit `ctrl-D` oder `exit` wieder verlassen, und die Tools sind wieder weg.
Das hat uns Docker auch schon gebracht, allerdings können wir hier beliebige Pakete miteinander kombinieren und sogar nix Shells schachteln - bei Docker muss es diese Paketkombination entweder schon geben, oder wir müssen doch das Image ändern.

## Wo landen die Pakete auf meinem System?

Wenn wir `cowsay` mittels des Befehls `nix shell nixpkgs#cowsay` temporär installieren, dann speichert `nix` die Paket-Inhalte unter `/nix/store/...` auf unserer Festplatte.
Wir können nachschauen, wie unsere Shell diese Befehle nun findet:

```sh
$ which git
/nix/store/y0gvg44jdsbn8hnnr27ixjf102nk7a9x-git-2.41.0/bin/git

$ echo $PATH
/nix/store/y0gvg44jdsbn8hnnr27ixjf102nk7a9x-git-2.41.0/bin:/nix/store/sccz3pqzlqi455hq870j7hfacv4xin1w-curl-8.1.1-man/bin:/nix/store/mf1gdlyxi0avdiyicn7s26dq2mwjhj3x-curl-8.1.1-bin/bin:/nix/store/1r6n7v2wam7gkr18gxccpg7p5ywgw551-python3-3.10.12/bin:...
```

Die Ausgabe des `echo $PATH` Befehls zeigt, dass jedes der eben genannten Pakete im `/nix/store` Pfad referenziert wird, und zwar genauer gesagt deren `bin`-Unterordner, die die ausführbaren Tools enthalten.
`nix shell` fügt diese also einfach der `$PATH`-Umgebungsvariable in der neuen Shell hinzu, welche wieder verfällt, wenn wir diese Shell schließen.

Programme, die wir mittels `nix profile install` installieren, landen hingegen unter `~/.nix-profile/bin`:

```sh
$ nix profile install nixpkgs#git
$ which git
/home/user/.nix-profile/bin/git
$ s -l ~/.nix-profile/bin
...
lrwxrwxrwx 1 root root 67 Jan  1  1970 curl -> /nix/store/mf1gdlyxi0avdiyicn7s26dq2mwjhj3x-curl-8.1.1-bin/bin/curl
lrwxrwxrwx 1 root root 62 Jan  1  1970 git -> /nix/store/y0gvg44jdsbn8hnnr27ixjf102nk7a9x-git-2.41.0/bin/git
...
```

Die `nix profile` Befehle pflegen also den Inhalt dieses Verzeichnisses für uns.
Allerdings enthält es nur symbolische Links in den Nix-Store, welcher alle Pakete enthält, die wir temporär oder dauerhaft installiert haben.

## Aufräumen mit dem Garbage-Collector

Im Nix-Store tummeln sich auf Dauer viele Daten: Wenn wir Pakete updaten oder deinstallieren, sind die alten Versionen dort immer noch vorhanden.
Das ist auch der Grund, aus dem der zweite Aufruf von `nix shell` oder `nix profile install` viel schneller geht, als der erste.
Man sagt auch, dass der lokale Nix-Store ein grosser Paket-*Cache* ist.
Tatsächlich kann man das eine System mit dem Nix-Store aus einem anderen System versorgen - nichts anderes passierte eigentlich, als wir eben Pakete installieren, die von `cache.nixos.org` heruntergeladen wurden.

Wir können regelmäßig alte Pakete wieder loswerden, indem wir den nix *Garbage Collector* starten:

```sh
$ nix-collect-garbage -d
...
deleting unused links...
note: currently hard linking saves 10347.70 MiB
71663 store paths deleted, 97999.21 MiB freed
```

Dieser Befehl löscht alle Pakete, die nicht von einem aktuell gültigen nix Profil referenziert werden.
Der `-d` Parameter löscht dabei auch unsere alten Profile, die wir vorher mit `nix profile history` auflisten und mit `nix profile rollback` selektiv wieder aktivieren könnten.

## Reproduzierbare Entwicklungsumgebungen

Die Idealvorstellung beim Entwickeln von Software im Team ist, dass jeder Mitarbeiter sein Laptop nach den eigenen Vorstellungen einrichten kann, aber die gemeinsamen Projekte mit exakt den gleichen Toolchains auf jedem Rechner entwickelt können - dann ist Schluss mit Aussagen wie "Bei mir funktioniert es aber!".
Typischerweise wird dann in virtuellen Maschinen oder Docker Images entwickelt, was mit seinen eigenen Vor- und Nachteilen kommt - erst recht, wenn dann mal Toolchains aktualisiert werden sollen.
Das Konzept der Nix-Shell kann uns in dieser Situation sehr viel Arbeit und Sorgen abnehmen.

Um die Vorzüge zu demonstrieren, erstellen wir jetzt Schritt für Schritt ein beispielhaftes Projekt, in dem wir mehrere verschiedene Toolchains brauchen: C++ und Rust.

Wir legen zunächst einen neuen Ordner an, z.b. `heise-nix` und dort drin führen wir den Befehl `nix flake init` aus, welcher uns eine neue Datei `flake.nix` anlegt.
Diese sieht nun so aus:

```nix
{
  description = "A very basic flake";

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    packages.x86_64-linux.default = self.packages.x86_64-linux.hello;
  };
}
```

Aus dieser Datei geht hervor, dass dieses Projekt ein Paket namens `hello` anbietet. Die Eingabe von `nix build` ohne weitere Parameter führt dann zum Bau des `default` Paketes.
Das dauert beim ersten Mal etwas länger, weil nix uns eine `flake.lock` Datei anlegt, die genau spezifiziert, von welchem Stand wir die `nixpkgs` Paketsammlung, die in unserer Flake-Datei referenziert wird, verwenden wollen.
Wenn wir diese Lock-Datei mit unserem Code in ein Repository mit-committen, dann werden unsere Kollegen und die CI exakt die gleichen Versionen von allen Abhängigkeiten und unseren Paketen bauen, wie wir beim Anlegen oder Ändern der Lock-Datei - auch Jahre später!
`nix build .#hello` sagt etwas spezifischer, dass aus dem aktuellen Projekt (das sagt der Punkt als Zeichen) das Paket `hello` gebaut werden soll.
Die Trennung des Pfads zur Flake-Datei und dem Paket-namen mittels des Raute-Symbols ist dabei typische Nix-Flake-Nomenklatur, die wir wir ja schon beim `nix shell` Befehl gesehen haben.

Wir erweitern diese Flake-Datei jetzt schrittweise, indem wir die Standard-Pakete entfernen und uns eine Entwicklungsumgebung anstatt Paketen definieren.
Pakete kommen dann später auch wieder hinzu:

```nix
{
  description = "Heise Nix Example Project";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.x86_64-linux.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          boost
          cmake
        ];
      };
    };
}
```

Dem aufmerksamen Leser fallt auf, dass wir nun kein Paket namens `default` mehr anbieten, sondern ein `devShells` Attribut.
Alle Attribute, die nicht zur Kategorie `packages`, sondern `devShells` gehoeren, lassen sich mit dem Befehl `nix develop` bauen und als Entwicklungsumgebung aktivieren.
MacOS-Benutzer sollten allerdings vorher die `system`-Zeile anpassen: `"x86_64-darwin"` für Intel-Macs und `"aarch64-darwin"` fuer die neueren Macs mit ARM-Prozessor.
Probieren wir es aus - auf meinem System ist global weder `cmake` noch ein C++-Compiler installiert, aber innerhalb der `nix develop` Umgebung stehen sie zur Verfügung:

```sh
$ c++ --version
c++: command not found
$ cmake --version
cmake: command not found

$ nix develop

$ c++ --version
g++ (GCC) 12.3.0
$ cmake --version
cmake version 3.26.4
```

Das tolle an dieser Umgebung ist, dass sie *nicht* in einer Art Docker-Container oder ähnlichem läuft - alle Tools, die bereits auf unserem System installiert sind, stehen ebenfalls zur Verfügung!

Wir können nun ein halbwegs sinnvolles Beispiel-C++ Projekt anlegen, indem wir die beiden folgenden Dateien im Unterordner `cpp` erstellen:

`cpp/CMakeLists.txt`:

```
cmake_minimum_required(VERSION 3.26)
project(hello-cpp VERSION 1.0 LANGUAGES CXX)

find_package(Boost 1.79)

add_executable(hello-cpp main.cpp)
target_link_libraries(hello-cpp PRIVATE Boost::boost)

install(TARGETS hello-cpp DESTINATION bin)
```

`cpp/main.cpp`:
```cpp
#include <boost/lexical_cast.hpp>
#include <iostream>

int main() {
  std::cout << "Hello c't Leser!\n"
            << "Boost: "
            << (BOOST_VERSION / 100000) << '.'
            << (BOOST_VERSION / 100 % 1000) << '.'
            << (BOOST_VERSION % 100) << '\n';
}
```

Innerhalb unserer Shell-Umgebung koennen wir nun die fuer C++ Entwickler gewohnten Befehle starten:

```sh
$ mkdir build && cd build
$ cmake ..
$ cmake --build .
$  ./hello-cpp
Hello c't Leser!
Boost: 1.79.0
```

So, das funktioniert! Wenn unser Editor oder IDE diese Befehle auf Knopfdruck für uns eingibt, dann ist es wichtig, dass diese aus der Nix-Shell heraus gestartet wird, um die Tools ebenfalls in der `PATH`-Variable zu haben. Es gibt auch Plugins für z.B. Visual Studio Code, die mit Nix Flakes entsprechend umgehen können.

Um dieses Projekt völlig automatisch zu bauen und als Paket zur Verfügung zu stellen, können wir jetzt folgende Passage in unsere flake.nix Datei hinzufügen, und zwar direkt nach dem `devShells... { ... };` Block:

```nix
packages.${system} = {
  hello-cpp = pkgs.stdenv.mkDerivation {
    name = "hello-cpp";
    src = ./cpp;
    nativeBuildInputs = [ pkgs.cmake ];
    buildInputs = [ pkgs.boost ];
  };
};
```

Damit haben wir nun wieder ein Attribut in unserer Flake-Datei, das der `packages` Kategorie entspricht.
Der Block sagt aus, dass wir eine sogenannte "Derivation" beschreiben, die nix als Paket mit dem Namen `hello-cpp` bauen kann.
Der Sourcecode des Pakets liegt im Unterordner `./cpp`, und dann geben wir noch zwei verschiedene Arten von Abhängigkeit an:
`cmake` ist ein sogenannter "native" Build-Input, was bedeutet, dass es sich um ein Tool handelt, das während der Übersetzungszeit ausgeführt wird.
`boost` hingegen ist ein Build-Input, welcher später auch zur Laufzeit der Applikation eine Abhängigkeit darstellen kann.

Die Eingabe von `nix build .#hello-cpp` führt nun dazu, dass das komplette Projekt in einer abgeschlossenen Sandbox gebaut wird.
Wir können es entweder direkt ausführen, indem wir `./result/bin/hello-cpp` ausführen (`nix build` verlinkt immer unter `result` im lokalen Ordner mit den Build-Ergebnissen), oder indem wir `nix run .#hello-cpp` ausführen.
Unsere Kollegen und unsere CI müssen also im Prinzip nur noch `nix build` auf den Attributen ausführen, die wir gebaut und getestet haben wollen, nachdem unsere Pakete entsprechend definiert wurden.

Probieren wir nun dasselbe mit einem kleinen Rust-Projekt. Dazu fügen wir einfach die Pakete `rustc` und `cargo` zu unserer Liste in dem `devShells`-Eintrag in der flake.nix Datei hinzu und laden unsere Shell von neuem.
Nun haben wir alles um ein Rust Projekt anzulegen:

```sh
$ mkdir rust && cd rust
$ cargo init --name hello-rust
$ cargo build
$ cargo run
Hello, world!
```

Um dieses Projekt ebenfalls als ein ausführbares Paket anzubieten, fügen wir nun folgende Passage zu unserer flake.nix Datei hinzu, und zwar nach dem `hello-cpp`-Block, noch innerhalb des `packages.${system}` Blocks:

```nix
hello-rust = pkgs.rustPlatform.buildRustPackage {
  name = "hello-rust";
  src = ./rust;
  cargoLock.lockFile = ./rust/Cargo.lock;
};
```

Nun können wir, wie bei den anderen Paketen auch, mit `nix build .#hello-rust` und `nix run .#hello-rust` dieses Paket bauen und ausführen, ohne uns noch dafür interessieren zu müssen, in welcher Sprache das Projekt überhaupt geschrieben ist, und was wir dafür installieren müssen.

Entwickler und Benutzer dieses Projekts, die sich nicht weiter fuer dessen Struktur interessieren, koennen einfach abfragen, was das Projekt so zu bieten hat:

```sh
$ nix flake show
git+file:///home/tfc/src/heise-nix?ref=refs%2fheads%2fmain&rev=c1c45b1621281beec93f846928331ffdf98d747c
├───devShells
│   └───x86_64-linux
│       └───default: development environment 'nix-shell'
└───packages
    └───x86_64-linux
        ├───hello-cpp: package 'hello-cpp'
        └───hello-rust: package 'hello-rust'
```

Sämtliche Befehle funktionieren auch, ohne das Projekt lokal mit `git` auschecken zu müssen:

```sh
$ nix flake show github:tfc/heise-nix
github:tfc/heise-nix/...
───devShells
│   └───x86_64-linux
│       └───default: development environment 'nix-shell'
└───packages
    └───x86_64-linux
        ├───hello-cpp: package 'hello-cpp'
        └───hello-rust: package 'hello-rust'
$ nix run github:tfc/heise-nix#hello-cpp
Hello c't Leser!
Boost: 1.79.0
$ nix run github:tfc/heise-nix#hello-rust
Hello, world!
```

Obendrein können wir Benutzern auch anbieten, unser Projekt einfach mit `nix shell github:tfc/heise-nix#hello-rust` temporär in eine Shell zu ziehen, oder dauerhaft mittels `nix profile install github:tfc/heise-nix#hello-rust` zu installieren.

Als Maintainer des Projekts können wir nun regelmäßig `nix flake update` eingeben, damit die Toolchain updaten und committen, was alle Abhängigkeiten aktuell hält.
Sollte ein Update Breaking-Changes enthalten, so können wir das Update der Lock-Datei gemeinsam mit unseren Korrekturen committen - so bauen unsere Commits auch Jahre später noch zuverlässig.

## Fazit und Ausblick

So, das war es erst einmal mit neuen Konzepten in diesem Artikel.
Nix als Paketmanager alleine installiert, aktualisiert und deinstalliert uns Pakete, wie die meisten anderen Paketmanager auch, allerdings bietet es Zugang zu einer noch größeren und aktuelleren Paketsammlung, als alle anderen.
Hinzu kommt, dass wir beliebige Shells mit bestimmten Tools ad-hoc kurz mal eben ohne Installation heraufbeschwören können - ganz ohne Docker.
Das Beispielprojekt bietet nun die Möglichkeit, eine C++ und eine Rust Toolchain, die genau passen, mit nur einem Befehl einzurichten.
Mit nur einem weiteren Befehl können alle Pakete und sonstigen Abhängigkeiten aktualisiert werden.
Welche Versionen wovon gebraucht werden, steht in den flake.nix und flake.lock Dateien, welche stets zusammen ins Git Repository committed werden.
Das führt dann dazu, dass jeder Entwickler exakt die gleiche Entwicklungsumgebung erhält - und das auch noch in Jahren!
Abgesehen von der Entwicklungsumgebung bietet das Repository auch die Möglichkeit, die Pakete direkt für Benutzer zu bauen und zu installieren, auch ohne vorher das Repository geklont haben zu müssen.

Für nix war das aber erst der Anfang:
Auf Basis dieser Flake-Datei werden wir in der nächsten Ausgabe unsere Pakete und Entwicklungsumgebungen für verschiedene Betriebssysteme (Linux und macOS) und Prozessor-Architekturen gleichzeitig anbieten.
Beim Einbau in die GitHub CI wird dann auffallen, dass es besonders einfach ist, Nix-Pakete von der CI bauen zu lassen.
Dabei verwenden wir auch Rust-Tooling, um automatisiert Rust Dependency Audit Checks zu machen.
Hinzu kommen automatische pre-commit-Checks, die Code-Formatter und Linter bei jedem Commit ausführen.