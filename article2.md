
## Flake-Parts

Der bisherige Flake enthält funktionierende Pakete und eine Shell-Definition,
aber diese sind noch im Flake-Attributpfad auf eine bestimmte System-Architektur
festgelegt.
Das lässt sich sehr bequem mit einer Nix-Flake-Bibliothek namens Flake-Parts
ändern:
Diese kann folgendermaßen verwendet werden:

```nix
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    perSystem = { config, pkgs, system, ... }: {
      devShells.default = ...;
      packages = {
        hello-cpp = ...;
        hello-rust = ...;
      };
    };
  }
```

Alles, was in dem `perSystem` Attribut definiert wird, wird automatisch für alle
Architekturen, die in `systems` aufgelistet sind, in entsprechende Attributpfade
übersetzt:
Aus `packages.hello-cpp` wird `packages.x86_64-linux.hello-cpp`, `packages.aarch64-linux`, und so weiter.
Somit kann man sich darauf konzentrieren, portable Paketbeschreibungen zu
spezifizieren, um dann an einer zentralen Stelle des Flakes zu definieren,
welche Architekturen denn unterstützt werden.
Die Shell und die Pakete aus diesem Flake funktionieren nun unter Linux und
macOS auf verschiedenen Prozessor-Architekturen, ohne dass dafür noch etwas
geändert werden muss - vorausgesetzt, die verwendeten Pakete funktionieren auch
alle auf diesen Architekturen.

Erwähnenswert ist das `inputs` Attribut ganz oben:
Während `nixpkgs` vor dieser Änderung einfach "irgendwoher" kam, definiert die
nixpkgs Zeile nun, aus welchem Git-Repository und welchem Branch die `nixpkgs`
Paketdefinitionen sein sollen.
Dazu kommt noch die `flake-parts` Zeile, welche die Herkunft der Bibliothek
definiert, bevor sie überhaupt benutzt werden kann.
Im Laufe des Artikels kommen noch weitere Inputs dazu.

## Flake Check

Die nächste Verbesserung dieses Projekts bringt der Befehl `nix flake check`,
welcher prüft, ob die Flake-Datei bestimmten Regeln folgt und dazu noch
benutzerdefinierte Checks ausführen kann - zum Beispiel, ob noch alle Pakete
bauen.

Um dies zu nutzen, können die bisherigen Pakete einfach zu einem neuen `checks`
Attribut hinzugefügt werden:

```nix
  checks = {
    inherit (config.packages)
      hello-cpp
      hello-rust
      ;
  };
```

Die verwendete `inherit`-Syntax sagt aus:
Aus der Attribut-Menge `config.packages`, welche über die Selbstreferenz
`config` adressiert werden kann, sollen die danach genannten Attribute
übernommen werden.

Nun baut der Befehl `nix flake check` auch diese Pakete.
Die Checks-Menge wird ebenfalls noch im Laufe dieses Artikels erweitert.

## Shell-Vereinfachung

Die Definition der Development-Shell ist mittlerweile etwas redundant zu den
Paketdefinitionen der C++ und Rust Pakete.
Dies lässt sich nun sehr bequem verbessern:

```nix
  devShells.default = pkgs.mkShell {
    inputsFrom = builtins.attrValues config.checks;
  };
```

Der `inputsFrom` Parameter von `mkShell` nimmt eine Liste von Paketdefinitionen
auf.
Aus jedem der genannten Pakete werden dann die Abhängigkeiten extrahiert und als
Abhängigkeiten der Shell verwendet.
Die Funktion `builtins.attrValues` gibt eine Liste aller Werte in einer
Attribut-Menge zurück.

Somit sind nun alle Abhängigkeiten der beiden Unterprojekte beim jeweiligen
Projekt definiert und müssen nicht an mehreren Stellen gepflegt werden, um stets
eine aktuelle Shell anzubieten!

## GitHub CI

`.github/workflow/check.yml`

```yaml
name: CI

on:
  push:
  pull_request:

jobs:
  check:
    runs-on: ${{ matrix.os }}
    strategy:
        matrix:
            os: [ubuntu-latest, macos-latest]
    steps:
      - uses: actions/checkout@v3
      - uses: DeterminateSystems/nix-installer-action@main
      - uses: DeterminateSystems/magic-nix-cache-action@main
      - run: nix flake check
```

Diese Datei beschreibt einen GitHub-Workflow namens `CI`, der bei jedem git Push
und jedem Pull-Request gestartet wird.
Der eigentliche CI-Job wird nun auf GitHub Runner verteilt, die jeweils mit
Ubuntu und macOS laufen.
Auf dem Runner wird dann jeweils nix installiert sowie eine Caching-Action,
die den Nix Store bei jeder Ausführung aus dem GitHub Runner Cache der letzten
CI-Ausführung befüllt.
Dieser Cache wird dann nach dem CI-Job aktualisiert, was zu einer erheblichen
Beschleunigung konsekutiver CI-Jobs führt.

Der eigentliche CI Job besteht dann nur noch aus dem `nix flake check` Aufruf.
Es ist ab jetzt unerheblich, welche Pakete und Checks noch zu dem Projekt im
Flake hinzugefügt werden, die CI zieht automatisch mit.

Das Beste an dieser Art von CI ist:
Wenn mal ein Job aufgrund eines echten Fehlers nicht funktioniert, so kann der
Fehler auf jedem Entwickler-Laptop mit dem gleichen `nix flake check` Befehl
nachvollzogen werden.
Entwickler müssen nun nie wieder patchen, committen, pushen und hoffen, dass die
CI die Änderung akzeptiert, was in der Praxis eine erhebliche Verschwendung von
Arbeitszeit ist.

## Pre-commit-check

Das Tool [`pre-commit`](https://pre-commit.com/) wird gerne von Entwicklern
verwendet, um Code-Analyse und Formatierung bei jedem Commit automatisch
durchzuführen.
Auch hier ist es dann aber problematisch, wenn nicht exakt die gleichen
Versionen aller von `pre-commit` verwendeten Tools auf allen
Entwickler-Umgebungen laufen.
`pre-commit` kann zwar fehlende Tools installieren, aber was, wenn nicht mal der
gleiche Paketemanager für alle Tools auf allen Systemen zur Verfügung steht?
Hinzu kommt, dass der CI auch beigebracht werden muss, das Tool auszuführen.

Ohne das Rad neu zu erfinden, löst das Projekt
[`pre-commit-hooks.nix`](https://github.com/cachix/pre-commit-hooks.nix)
diese Herausforderungen sehr elegant:
Es generiert beim betreten der `nix develop` Umgebung eine `pre-commit`
Konfigurationsdatei, die Tools aus unseren nixpkgs Quellen verwendet.
Somit ist dies eine perfekt reproduzierbare Art und Weise, `pre-commit` auf
jedem Entwickler-Laptop und der CI zu verwenden.

Der Einbau erfolgt in drei Schritten:

Als erstes muss das `inputs` Attribut um die Flake des `pre-commit-hooks.nix`
Projekts erweitert werden:

```nix
  inputs = {
    # ...
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    # ...
  };
```

Jetzt, wo die Quellen zur Verfügung stehen, kann ein Flake-Check eingebaut
werden:

```nix
  checks = {
    # ... bisherige Checks ...

    pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
      src = ./.;
      hooks = {
        # Rust
        clippy.enable = true;
        rustfmt.enable = true;

        # Nix
        deadnix.enable = true;
        nixpkgs-fmt.enable = true;
        statix.enable = true;

        # Shell
        shellcheck.enable = true;
        shfmt.enable = true;
      };
      settings.rust.cargoManifestPath = "./rust/Cargo.toml";
    };
```

Wie in diesem Ausschnitt zu sehen, werden einfach verschiedene Check-Tools
"angeknipst", was zu deren Installation und ebenso Konfiguration in `pre-commit`
führt.
Lediglich die Rust-Tools müssen wissen, in welchem Order die Cargo-Dateien
liegen.
Eine Liste der verfügbaren Tools und weitere Anleitungen finden sich in der
[README.md des `git-precommit-hooks.nix` Projekts](https://github.com/cachix/pre-commit-hooks.nix/blob/master/README.md).

Alle Checks werden nun bei jedem `nix flake check` ausgeführt.
Das bedeutet, dass die CI dies nun automatisch auch tut!
Der dritte Schritt fehlt allerdings noch:
Wenn Entwickler committen, dann sollen die Checks ja ebenfalls laufen.
Dazu muss die folgende Zeile zum `devShells.default` Attribut hinzugefügt
werden:

```nix
  devShells.default = pkgs.mkShell {
    inputsFrom = builtins.attrValues config.checks;
    inherit (config.checks.pre-commit-check) shellHook;
  };
```

Der von der `pre-commit-hooks.nix` Bibliothek erzeugte Flake Check emittiert
ebenfalls ein Symbok `shellHook`, welches direkt in die Developer Shell
übernommen werden kann.
Das Betreten der `nix develop` Umgebung (oder erneute Betreten nach dieser
Änderung) erzeugt nun eine `.pre-commit-config.yaml` Datei, die entsprechend
`pre-commit` konfiguriert.
Diese sollte auch der `.gitignore` Liste hinzugefügt werden, da sie bei jedem
Betreten der Developer Shell neu generiert wird, wodurch sie immer aktuell ist.

Ob alles richtig funktioniert, lässt sich kurz ausprobieren.
Das "verschlimmbessern" der `main.rs` Datei im Rust-Projekt zu folgendem
schlecht eingerückten Format zum Beispiel...

```rust
fn main() {
println!("Hello, world!");
}
```

...führt beim Committen zu folgendem Fehler:

```sh
$ git add rust/src/main.rs
$ git commit
[WARNING] Unstaged files detected.
[INFO] Stashing unstaged files to /home/tfc/.cache/pre-commit/patch1691395282-158821.
clippy...................................................................Passed
deadnix..............................................(no files to check)Skipped
nixpkgs-fmt..........................................(no files to check)Skipped
rustfmt..................................................................Failed
- hook id: rustfmt
- files were modified by this hook
shellcheck...........................................(no files to check)Skipped
shfmt................................................(no files to check)Skipped
statix...............................................(no files to check)Skipped
[INFO] Restored changes from /home/tfc/.cache/pre-commit/patch1691395282-158821.
```

Praktisch ist nun, dass nicht nur die schlechte Formatierung bemängelt wird,
sondern auch korrigiert wird.
Die Korrekturen müssen nur noch vom Entwickler akzeptiert und zum git Index
hinzugefügt werden:

```sh
$ git add -p
diff --git a/rust/src/main.rs b/rust/src/main.rs
index f5c339a..e7a11a9 100644
--- a/rust/src/main.rs
+++ b/rust/src/main.rs
@@ -1,3 +1,3 @@
 fn main() {
-println!("Hello, world!");
+    println!("Hello, world!");
 }
(1/1) Stage this hunk [y,n,q,a,d,e,?]?
```

Es ist zwar jederzeit möglich, die git `pre-commit` Hooks zu deaktivieren, aber
dann werden sie spätestens in der CI trotzdem anschlagen!

## Rust Crane

Bisher wird die Paketbeschreibung fuer das Paket `hello-rust` mit der Funktion
`pkgs.rustPlatform.buildRustPackage` erzeugt, die direkt aus den `nixpkgs`
stammt.
`nixpkgs` bietet solche
[Helferfunktionen für insgesamt 39 Sprachen und
Skripting-Umgebungen](https://nixos.org/manual/nixpkgs/stable/#chap-language-support),
unter anderem auch für Java, Javascript, Python, usw.
Verschiedene Organisationen haben allerdings ihre eigenen Nix-Bibliotheken
entwickelt, um noch mehr aus dem entsprechenden Programmier-Ökosystem
herauszuholen, und haben diese auch open-sourced.

In diesem Kontext lohnt sich der Blick auf die [`crane`](https://github.com/ipetkov/crane)
Bibliothek, welche mit einer Vielzahl von Funktionen und Vorteilen gegenüber der
in `nixpkgs` eignebauten Variante der Rust-Funktionalität kommt.
Besonders auffällig ist die Geschwindigkeitsverbesserung von Builds bei `crane`:
Alle Rust-Abhängigkeiten müssen nun nicht mehr von `cargo` selbst gebaut werden,
sondern werden im Nix-Store gecached.
Dieser Vorteil ergibt sich auch für Nutzer der `nix develop` Umgebung, sofern
CI und Entwickler den gleichen Nix Binary Cache verwenden (was aber erst im
nächsten Artikel dran kommt).
Automatische `rustfmt` und `clippy` bietet `crane` an, allerdings sind diese nun
bereits über `pre-commit` abgedeckt.
Deswegen widmen wir uns nun dem Einbau von Sicherheitschecks über den gesamten
Abhängigkeitsbaum aller Rust-Bibliotheken, sowie Rust Dokumentations-Checks.

Dies erfolgt in drei Schritten:

Zunächst müssen mal wieder neue Inputs ganz oben in der Flake-Datei hinzugefügt
werden:

```nix
  inputs = {
    # ...
    advisory-db.url = "github:rustsec/advisory-db";
    advisory-db.flake = false;
    crane.url = "github:ipetkov/crane";
    crane.inputs.nixpkgs.follows = "nixpkgs";
  };
```

Der `advisory-db` Teil wird später nur für die Security-Checks über die
Rust-Abhängigkeiten gebraucht.
Beim `crane`-Teil ist interessant, dass diese mit ihrer eigenen `nixpkgs`
Selektion gebaut werden, aber es ohne weiteres möglich ist, die `nixpkgs` aus
unserem Flake zu "injizieren" (siehe zweite `crane` Zeile).

Der zweite Schritt ist der Umbau des `hello-rust` Pakets selbst.
Zunächst legen wir ein paar Helfer-Variablen an, die wir an verschiedenen
Stellen brauchen werden.
Dazu fügen wir eine `let ... in` Klausel in den Code ein, die einen neuen Scope
für Variablen öffnet:

```nix
 perSystem = { config, pkgs, system, ... }:
   let
     craneLib = inputs.crane.lib.${system};
     src = craneLib.cleanCargoSource (craneLib.path ./rust);
     cargoArtifacts = craneLib.buildDepsOnly { inherit src; };
   in
   {
     devShells.default = ...
```

Die Variable `craneLib` enthält nun eine Referenz auf die `crane` Bibliothek,
die nun an mehreren Stellen benutzt wird.
Als erstes wird der Sourcecode des Rust-Projekts nun mit den Funktionen `path`
und `cleanCargoSource` aus der `craneLib` von allem bereinigt, was für das Bauen
von Rust-Paketen nicht wesentlich ist.
Die Funktion `buildDepsOnly` baut alle von der `Cargo.toml` Datei erwähnten
Pakete, was später das Cachen von Rust-Abhängigkeiten über Host-Grenzen hinweg
erlaubt.

Schritt zwei wird durch den Umbau des eigentlichen `hello-rust` Pakets
vollendet:

```nix
hello-rust = craneLib.buildPackage { inherit cargoArtifacts src; };
```

Dies funktioniert nun sofort mit `nix build .#hello-rust`, sowohl lokal als auch
in der CI im `nix flake check` Aufruf, ohne dass dafür noch an anderen Stellen
etwas geändert werden müsste.

Nun folgen die Security- und Doc-Checks:

```nix
  checks = {
    inherit (config.packages)
      hello-cpp
      hello-rust
      ;

    hello-rust-doc = craneLib.cargoDoc {
      inherit cargoArtifacts src;
    };

    hello-rust-audit = craneLib.cargoAudit {
      inherit (inputs) advisory-db;
      inherit src;
    };
  # ...
  };
```

In den Aufrufen der `cargoDoc` und `cargoAudit` Funktionen ist schön zu sehen,
wie diese verschiedenen Funktionen den Source Code im `src` Attribut sowie die
`cargoArtifacts`, die die ganzen Abhängigkeiten enthalten, wiederverwenden.

Alle diese Checks laufen nun automatisch bei jedem CI-Run mit, oder wenn der
Entwickler lokal `nix flake check` ausführt.
Für nichts davon muss der Benutzer oder Admin der CI-Maschinen/VMs/Container
bescheid darüber wissen, was wo installiert werden muss.

Die Paketlisten des Security-Checks werden nun mit jedem `nix flake update`
automatisch ebenfalls aktualisiert.
Selbstverständlich können alle Flake-Inputs unabhängig voneinander aktualisiert
werden.

## Fazit und Ausblick

Dieses Repository konnte nach der letzten Ausgabe lediglich ein C++ und ein Rust
Paket bauen, sowie die zum Entwickeln nötige Shell zur Verfügung stellen.

Dies funktioniert nun auf Linux und macOS Systemen der `x86_64` und `aarch64`
Architektur gleichzeitig.
Die Shell-Definition wurde vereinfacht und dedupliziert: Sie holt sich jetzt die
Abhängigkeiten automatisch aus den Paket-Definitionen.
Hinzu kommt, dass bei jedem Commit das `pre-commit` Tool ausgeführt wird,
nachdem es beim Betreten der Entwickler-Shell automatisch dafür konfiguriert
wurde, die Rust-Tools `clippy` und `rustfmt` auf den letzten Änderungen
auszuführen, sowie auch die Nix-Tools `deadnix`, `nixpkgs-fmt` und `statix`.
Shell-Skripte werden ebenfalls automatisch mit dem Tools `shellcheck` und
`shfmt` gelintet und formatiert.
Der `nix flake check` Befehl testet nun nicht nur, ob die Pakete bauen, sondern
auch, ob das Dokumentationstooling des Rust-Projekts fehlerfrei läuft, ob die
Versionen der Rust-Abhängigkeiten bekannte Sicherheitslücken enthalten, sowie
ob die ganzen `pre-commit` Checks auf dem Projekt anschlagen.

Zu guter letzt laufen alle diese Checks nun auch automatisch in der GitHub CI
mit, wenn Änderungen gepusht werden.
Das Beste an den CI-Definitionsdateien ist, dass diese lediglich wissen müssen,
dass `nix flake check` verwendet wird.
Wenn das Projekt evolviert, muss die CI-Beschreibung nicht weiter angepasst
werden.
Alles, was in der CI fehlschlägt, kann trivial vom Benutzer lokal nachvollzogen
werden.

In der nächsten Ausgabe lernen wir, wie wir uns einen kostenlosen Binary Cache
für unsere Open Source Projekte einrichten, um Builds und Shells noch schneller
an Benutzer und Kollegen zu liefern.
Hinzu kommt, dass wir auch Cross-Builds unserer C++ und Rust Apps anbieten,
damit diese auch für Windows-User und z.B. Raspberry-Pis angeboten werden
können.
