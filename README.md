# Matlab-Hackl

Unit-Tests und CI für das Simulink-Modell zur arbeitspunktabhängigen Stromsollwertvorgabe einer Synchronmaschine.

Dieses Repository enthält automatische MATLAB-/Simulink-Tests für ein Simulink-Modell, in dem die analytischen Kennlinien und Schnittpunkte für die optimalen Betriebsstrategien auf Basis der Arbeiten von Christoph M. Hackl bzw. des zugehörigen OFTC-Ansatzes berechnet werden und die Auswahl des tatsächlich zu verwendenden Betriebspunkts gemäß dem Auswahlalgorithmus nach Antonín Glac, Václav Šmídl und Zdeněk Peroutka erfolgt.

Dabei werden insbesondere Strategien und Randkurven wie:
- MTPC (Maximum Torque per Current),
- MTPV (Maximum Torque per Voltage),
- MTPF (Maximum Torque per Flux),
- MC (Maximum Current) bzw. Stromgrenze,
- Voltage Ellipse bzw. Spannungsgrenze

verwendet, um für gegebene Sollwerte \(T^\*\) und \(n^\*\) einen physikalisch zulässigen und regelungstechnisch geeigneten Stromsollwertvektor \((i_d^\*, i_q^\*)\) zu bestimmen.

## Fachlicher Hintergrund

Die mathematischen Gleichungen zur Berechnung der charakteristischen Kurven und ihrer Schnittpunkte basieren auf dem analytischen OFTC-Ansatz nach Hackl bzw. den zugehörigen Veröffentlichungen zur optimalen Feedforward-Drehmomentregelung synchroner Maschinen. In diesem Ansatz werden die relevanten Optimierungsprobleme und Nebenbedingungen analytisch beschrieben, sodass Referenzströme für typische Betriebsstrategien wie MTPC, MTPV und MTPF bestimmt werden können. [web:135][web:137]

Die eigentliche Auswahl, welcher der berechneten Kandidatenpunkte im aktuellen Betrieb verwendet wird, orientiert sich in diesem Repository am Entscheidungsablauf nach Antonín Glac, Václav Šmídl und Zdeněk Peroutka, "Optimal Feedforward Torque Control of Synchronous Machines with Time-varying Parameters", IECON 2018. [web:136]

Der im Modell verwendete Auswahlalgorithmus folgt dabei sinngemäß diesem Ablauf:
1. Berechnung der relevanten Kurven und Schnittpunkte.
2. Bestimmung des Vorzeichens des Referenzmoments.
3. Berechnung von Kandidatenpunkten an den Schnittstellen von MTPC, MTPV, Stromkreis, Spannungsellipse und Drehmomenthyperbel.
4. Ermittlung eines zulässigen Zwischenkandidaten \(i_{feas}\).
5. Vergleich des angeforderten Moments mit den an den Grenzpunkten erreichbaren Momenten.
6. Auswahl des finalen Arbeitspunkts als einer der zulässigen Kandidaten, z. B. \(i_{feas}\), \(i_{tv}\) oder \(i_{at}\), abhängig von Spannungs-, Strom- und Momentgrenzen. [file:134]

Damit prüft dieses Repository nicht nur einfache Kennfeldgrößen, sondern die Konsistenz einer analytisch begründeten Arbeitspunktwahl im gesamten zulässigen Betriebsbereich. [web:135][file:134]

## Inhalt der Tests

Die Tests decken aktuell vier Bereiche ab:

- **LUT-Konsistenz:** Prüft Größen, Monotonie, `meshgrid`-Orientierung sowie `NaN`/`Inf` in den Kennfeldern.
- **Modellparameter:** Prüft, ob Parameter wie `p`, `Rs`, `I_max`, `U_dc` sowie optional `U_max` und `n_max` vorhanden und gültig sind.
- **Strategiewahl:** Prüft an festen Referenzpunkten, ob der vom Modell gewählte Betriebspunkt zur erwarteten Strategie bzw. zum erwarteten Betriebsbereich passt.
- **Regressionstest:** Vergleicht `id_ref`, `iq_ref` und `strategie` mit einer gespeicherten Baseline-MAT-Datei, um unbeabsichtigte Änderungen im Modellverhalten zu erkennen. Baseline-Tests vergleichen aktuelle Simulationsergebnisse mit zuvor freigegebenen Referenzdaten. [web:53][web:101]

## Modellidee

Das Simulink-Modell berechnet für gegebene Vorgaben wie Drehzahl und Drehmoment zunächst mehrere theoretisch relevante Kandidatenpunkte aus den analytisch beschriebenen Kurven. Dazu gehören insbesondere Schnittpunkte zwischen:
- MTPC und Stromgrenze,
- MTPV und Spannungsellipse,
- MTPC und Spannungsellipse,
- Stromgrenze und Spannungsellipse,
- sowie Grenzkurven mit der Drehmomenthyperbel. [file:134]

Aus diesen Kandidaten wird anschließend gemäß dem Entscheidungsbaum ein zulässiger und geeigneter Sollstromvektor ausgewählt. Der Algorithmus unterscheidet also zwischen:
- der **analytischen Berechnung** von Kennlinien und Schnittpunkten,
- und der **logischen Auswahl** des finalen Betriebspunkts. [web:135][file:134]

Diese Trennung ist wichtig, weil eine korrekte Berechnung einzelner Kennlinien allein noch nicht garantiert, dass im Betrieb auch der richtige Kandidat ausgewählt wird. Genau deshalb existieren neben Konsistenz- und Parametertests auch separate Strategietests.

## Voraussetzungen

Für lokale Testläufe werden benötigt:

- MATLAB
- Simulink
- Zugriff auf das Modell `Hackl_Pilsen_Algo.slx`
- Das Initialisierungsskript `Messdaten_Interpoliert.m`
- Die Testdateien im Ordner `tests/`

Für GitHub CI wird zusätzlich ein GitHub-Repository mit aktivierten GitHub Actions benötigt. MATLAB- und Simulink-Tests lassen sich über die offiziellen MATLAB Actions in GitHub Actions ausführen. [web:107]

## Baseline einmal erzeugen

Beim ersten Einrichten muss die Referenz-Baseline einmal lokal erzeugt und anschließend in Git gespeichert werden.

### Schritt 1: MATLAB im Repository-Ordner öffnen

MATLAB im Hauptordner des Repositories starten, sodass Modell, `baseline/` und `tests/` erreichbar sind.

### Schritt 2: Baseline erzeugen

Im MATLAB Command Window ausführen:

```matlab
addpath(genpath(pwd));
create_baseline
```

Dabei wird die Datei

```text
baseline/Hackl_Pilsen_Algo_baseline.mat
```

erzeugt.

Diese Datei enthält für definierte Referenz-Betriebspunkte die vollständigen Zeitverläufe von:
- `time`
- `id_ref`
- `iq_ref`
- `strategie`

sowie die zugehörigen Sollwerte wie `n_mech` und `T_soll`.

### Schritt 3: Baseline prüfen und committen

Die neu erzeugte Datei im Ordner `baseline/` zu Git hinzufügen und committen.

Beispiel:

```bash
git add baseline/Hackl_Pilsen_Algo_baseline.mat
git commit -m "Add initial regression baseline"
```

## Baseline bewusst aktualisieren

Wenn das Modell fachlich absichtlich geändert wurde und die neue Version die neue Referenz werden soll, wird die Baseline erneut mit `create_baseline` erzeugt und anschließend nach fachlicher Prüfung committed.

Wichtig:
Die Baseline sollte nur aktualisiert werden, wenn sicher ist, dass die Modelländerung fachlich korrekt und gewollt ist. Andernfalls würde ein echter Fehler versehentlich als neue Referenz gespeichert werden.

## Tests lokal starten

Ein kompletter lokaler Testlauf erfolgt mit:

```matlab
run('tests/run_all_tests.m');
```

Das Skript führt alle Testdateien im Ordner `tests/` aus. Wenn ein Test fehlschlägt, beendet sich der Lauf mit einer Fehlermeldung. MATLAB-Tests können lokal und automatisiert als Suite ausgeführt werden. [web:130][web:125]

## Bedeutung der wichtigsten Testdateien

| Datei | Zweck |
|---|---|
| `tests/test_LUT_Consistency.m` | Prüft Größen, Vektoren, Kennfelder und `meshgrid`-Konsistenz |
| `tests/test_ModelParameters.m` | Prüft Maschinenparameter und Grenzwerte |
| `tests/test_StrategySelection.m` | Prüft die Auswahl des Betriebspunkts an festen Referenzpunkten |
| `tests/test_ModelRegression.m` | Vergleicht Modellausgänge mit der gespeicherten Baseline |
| `tests/run_all_tests.m` | Startet alle Tests lokal und in CI |
| `create_baseline.m` | Erzeugt die Referenz-Baseline für den Regressionstest |

## GitHub CI

Die Datei `.github/workflows/matlab-ci.yml` startet die Tests automatisch bei:
- Push auf `main` oder `master`
- Pull Requests auf `main` oder `master`
- manuellem Start über `workflow_dispatch`

## CI-Lauf interpretieren

Ein erfolgreicher CI-Lauf bedeutet:
- alle Tests wurden vollständig ausgeführt,
- keine Größen- oder Parameterfehler wurden gefunden,
- die Strategiewahl war an den Referenzpunkten korrekt,
- und das Modellverhalten stimmt noch mit der Baseline überein.

Ein fehlgeschlagener CI-Lauf bedeutet, dass mindestens einer dieser Punkte verletzt wurde.

Typische Ursachen sind:
- Kennfeldgrößen passen nicht mehr zusammen,
- ein Parameter fehlt oder ist ungültig,
- eine Modelländerung hat die Strategiewahl verändert,
- `id_ref`, `iq_ref` oder `strategie` weichen von der Baseline ab,
- Signale wurden im Modell umbenannt und können nicht mehr aus dem `SimulationOutput` gelesen werden,
- oder in der CI-Umgebung ist keine Simulink-Lizenz verfügbar.

## Typische Fehlerbilder

### 1. Baseline-Datei fehlt

Die Regression kann nicht laufen, weil noch keine Referenz erzeugt wurde.

**Lösung:**  
Baseline lokal mit `create_baseline` erzeugen und committen.

### 2. Signal konnte nicht aus dem `SimulationOutput` gelesen werden

Das Signal ist nicht mehr in `logsout`, `yout` oder direkt im `SimulationOutput` verfügbar.

**Lösung:**  
Signalnamen, Logging-Einstellungen oder Testkonstanten prüfen.

### 3. Strategieauswahl stimmt nicht

Der vom Modell gewählte Betriebspunkt passt am Referenzpunkt nicht mehr zur erwarteten Strategie oder zum erwarteten Grenzfall.

**Lösung:**  
Prüfen, ob die Änderung fachlich gewollt ist oder ein Fehler in der Entscheidungslogik vorliegt.

### 4. Regressionsfehler in `id_ref` oder `iq_ref`

Die berechneten Arbeitspunkte oder deren Zeitverläufe weichen von der Referenz ab.

**Lösung:**  
Modelländerung, Kennfelder, Parameter, Schnittpunktberechnung oder Auswahlalgorithmus prüfen.

## Empfohlener Arbeitsablauf

1. Modell oder Kennfelder ändern.
2. Tests lokal mit `run('tests/run_all_tests.m')` ausführen.
3. Änderungen committen und pushen.
4. GitHub Actions prüfen.
5. Nur wenn die Änderung fachlich gewollt ist, Baseline bewusst mit `create_baseline` neu erzeugen.

## Quellenhinweis

Mathematischen Herleitungen der Kurven MTPC, MTPV, MTPF (Eldeeb, Hackl):  https://www.researchgate.net/publication/309738085_On_the_optimal_feedforward_torque_control_problem_of_anisotropic_synchronous_machines_Quadrics_quartics_and_analytical_solutions

Auswahlablauf des finalen Betriebspunkts (Glac, Šmídl, Peroutka): https://www.researchgate.net/publication/330487741_Optimal_Feedforward_Torque_Control_of_Synchronous_Machines_with_Time-Varying_Parameters 
