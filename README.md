# Matlab-Hackl
# Unit-Tests und CI für das Simulink-Modell

Dieses Repository enthält automatische MATLAB-/Simulink-Tests für die Arbeitspunktsteuerung mit MTPC, MTPF und MTPV.  
Die Tests prüfen bei jeder Änderung, ob Datenstrukturen, Parameter, Strategiewahl und das bisherige Modellverhalten weiterhin korrekt sind. [cite:133][cite:161]

## Inhalt der Tests

Die Tests decken aktuell vier Bereiche ab:

- **LUT-Konsistenz**: Prüft Größen, Monotonie, `meshgrid`-Orientierung sowie `NaN`/`Inf` in den Kennfeldern.
- **Modellparameter**: Prüft, ob Parameter wie `p`, `Rs`, `I_max`, `U_dc`, optional `U_max` und `n_max` vorhanden und gültig sind.
- **Strategiewahl**: Prüft an festen Referenzpunkten, ob die richtige Strategie (`MTPC`, `MTPF`, `MTPV`) gewählt wird.
- **Regressionstest**: Vergleicht `id_ref`, `iq_ref` und `strategie` mit einer gespeicherten Baseline-MAT-Datei. Baseline-Tests vergleichen aktuelle Simulationsergebnisse mit zuvor freigegebenen Referenzdaten. [cite:161][cite:180]

## Voraussetzungen

Für lokale Testläufe werden benötigt:

- MATLAB
- Simulink
- Zugriff auf das Modell `Arbeitspunktsteuerung_Simulink_5_Runtime`
- Das Initialisierungsskript `Messdaten_Interpoliert.m`
- Die Testdateien im Ordner `tests/`

Für GitHub CI wird zusätzlich ein GitHub-Repository mit aktivierten GitHub Actions benötigt. MATLAB- und Simulink-Tests lassen sich über die offiziellen MATLAB Actions in GitHub Actions ausführen. [cite:133][cite:176]

## Baseline zum ersten Mal erzeugen

Beim ersten Einrichten muss die Referenz-Baseline einmal lokal erzeugt und anschließend in Git gespeichert werden.

### Schritt 1: MATLAB im Repository-Ordner öffnen

MATLAB im Hauptordner des Repositories starten, sodass `tests/` und das Modell im Pfad liegen.

### Schritt 2: Baseline erzeugen

Im MATLAB Command Window ausführen:

```matlab
setenv('CREATE_BASELINE','1');
run('tests/run_all_tests.m');
setenv('CREATE_BASELINE','0');
```

Dabei wird eine MAT-Datei im Ordner `baseline/` erzeugt.  
Diese Datei enthält die freigegebenen Referenzverläufe für `id_ref`, `iq_ref` und `strategie`. MAT-Dateien sind ein üblicher Speicherort für Baseline-Daten in MATLAB- und Simulink-Tests. [cite:161][cite:171]

### Schritt 3: Baseline committen

Die neu erzeugte Datei im Ordner `baseline/` zu Git hinzufügen und committen.

Beispiel:

```bash
git add baseline/
git commit -m "Add initial regression baseline"
```

## Baseline bewusst aktualisieren

Wenn das Modell fachlich absichtlich geändert wurde und die neue Version die neue Referenz werden soll, kann die Baseline aktualisiert werden.

Dazu in MATLAB ausführen:

```matlab
setenv('UPDATE_BASELINE','1');
run('tests/run_all_tests.m');
setenv('UPDATE_BASELINE','0');
```

Anschließend die geänderte Baseline-Datei prüfen und committen.

**Wichtig:**  
Die Baseline sollte nur aktualisiert werden, wenn sicher ist, dass die Modelländerung fachlich korrekt und gewollt ist. Andernfalls würde ein echter Fehler versehentlich als neue Referenz gespeichert werden.

## Tests lokal starten

Ein kompletter lokaler Testlauf erfolgt mit:

```matlab
run('tests/run_all_tests.m');
```

Das Skript führt alle Testdateien im Ordner `tests/` aus und speichert ein JUnit-Ergebnisfile im Ordner `test-results/`. CI-kompatible Testergebnisse und Artefakte lassen sich in MATLAB automatisiert erzeugen. [cite:133]

Wenn ein Test fehlschlägt, beendet sich der Lauf mit einer Fehlermeldung.

## Bedeutung der wichtigsten Testdateien

| Datei | Zweck |
|------|------|
| `tests/test_LUT_Consistency.m` | Prüft Größen, Vektoren, Kennfelder und `meshgrid`-Konsistenz |
| `tests/test_ModelParameters.m` | Prüft Maschinenparameter und Grenzwerte |
| `tests/test_StrategySelection.m` | Prüft Strategiewahl an festen Referenzpunkten |
| `tests/test_ModelRegression.m` | Vergleicht Modellausgänge mit der Baseline |
| `tests/run_all_tests.m` | Startet alle Tests lokal und in CI |

## GitHub CI

Die Datei `.github/workflows/matlab-ci.yml` startet die Tests automatisch bei:

- Push auf `main` oder `master`
- Pull Requests auf `main` oder `master`
- manuellem Start über `workflow_dispatch`

GitHub Actions kann MATLAB-Tests automatisiert ausführen und Testergebnisse als Artefakte bereitstellen. [cite:133][cite:176]

## CI-Lauf interpretieren

Ein erfolgreicher CI-Lauf bedeutet:

- alle Tests wurden vollständig ausgeführt,
- keine Größen- oder Parameterfehler wurden gefunden,
- die Strategiewahl war an den Referenzpunkten korrekt,
- und das Modellverhalten stimmt noch mit der Baseline überein. [cite:161]

Ein fehlgeschlagener CI-Lauf bedeutet, dass mindestens einer dieser Punkte verletzt wurde.  
Typische Ursachen sind:

- Kennfeldgrößen passen nicht mehr zusammen,
- ein Parameter fehlt oder ist ungültig,
- eine Modelländerung hat die Strategiewahl verändert,
- `id_ref`, `iq_ref` oder `strategie` weichen von der Baseline ab,
- Signale wurden im Modell umbenannt und können nicht mehr aus dem `SimulationOutput` gelesen werden.

## Typische Fehlerbilder

### 1. `Baseline-Datei fehlt`
Die Regression kann nicht laufen, weil noch keine Referenz erzeugt wurde.

**Lösung:**  
Baseline lokal mit `CREATE_BASELINE=1` erzeugen und committen.

### 2. `Signal ... konnte nicht aus dem SimulationOutput gelesen werden`
Das Signal ist nicht mehr in `logsout`, `yout` oder direkt im `SimulationOutput` verfügbar.

**Lösung:**  
Signalnamen, Logging-Einstellungen oder Testkonstanten prüfen.

### 3. `Strategie-Signal stimmt nicht mit der Baseline überein`
Die Strategieauswahl hat sich gegenüber der freigegebenen Version geändert.

**Lösung:**  
Prüfen, ob die Änderung fachlich gewollt ist oder ein Fehler in der Logik vorliegt.

### 4. `Regressionsfehler in id_ref` oder `iq_ref`
Die berechneten Arbeitspunkte weichen von der Referenz ab.

**Lösung:**  
Modelländerung, Kennfelder, Parameter oder Interpolationslogik prüfen.

## Empfohlener Arbeitsablauf

1. Modell oder Kennfelder ändern.
2. Tests lokal mit `run('tests/run_all_tests.m')` ausführen.
3. Änderungen committen und pushen.
4. GitHub Actions prüfen.
5. Nur wenn die Änderung fachlich gewollt ist, Baseline bewusst aktualisieren.

## Optional: Badge im Repository

GitHub Actions kann als Badge im `README.md` angezeigt werden. Ein solcher Badge zeigt direkt im Repository an, ob der letzte Workflow erfolgreich war. [cite:175]

Beispiel:

```md
[
```
