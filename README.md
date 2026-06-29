# Matlab Hackl-Glac

Simulink-Modell zur arbeitspunktabhängigen Stromsollwert-Vorgabe einer Synchronmaschine (PMSM).

In diesem Repository befindet sich ein Simulink-Modell, welches nach Vorgabe des Wunschdrehmoment `T*` und der Wunschdrehzahl `n*` die erforderlichen Ströme `id*` und `id*` für den Arbeitspunkt berechnet.
Die analytischen Kennlinien MTPC, MTPV, MTPF sowie die Strom- und Spannungsgrenze des Motormodells werden auf Basis der Arbeiten von Christoph M. Hackl bzw. des zugehörigen OFTC-Ansatzes berechnet. 
Die Auswahl des tatsächlich zu verwendenden Betriebspunktes erfolgt gemäß des Auswahlalgorithmus nach Antonín Glac, Václav Šmídl und Zdeněk Peroutka.

Verwendete Kennlinien bzw Erklärung der Abkürzungen:
- MTPC (Maximum Torque per Current),
- MTPV (Maximum Torque per Voltage),
- MTPF (Maximum Torque per Flux),
- MC (Maximum Current) bzw. Stromgrenze,
- Voltage Ellipse bzw. Spannungsgrenze

## Fachlicher Hintergrund - Quadratische Gleichungen nach Hackl
- Drehmomenthyperbel: `T(m_ref) := (is)^T * T* is + 2*t^T*is + tau(m_ref) = 0`
- MTPC-Kennlinie: MTPC := (is)^T * Mc* is + 2*mc^T*is = 0
- MTPV-Kennlinie: MTPV := (is)^T * Mv(omega)* is + 2*mv(omega)^T*is + µv(omega) = 0
- MTPF-Kennlinie: MTPF := (is)^T * Mf* is + 2*mf^T*is +µf = 0

  
## Fachlicher Hintergrund - Auswahlalgorithmus Betriebspunkt
Der im Modell verwendete Auswahlalgorithmus folgt sinngemäß diesem Ablauf:
1. Berechnung der relevanten Kurven und Schnittpunkte.
2. Bestimmung des Vorzeichens des Referenzmoments.
3. Berechnung von Kandidatenpunkten an den Schnittstellen von MTPC, MTPV, Stromkreis, Spannungsellipse und Drehmomenthyperbel.
4. Ermittlung eines zulässigen Zwischenkandidaten \(i_{feas}\).
5. Vergleich des angeforderten Moments mit den an den Grenzpunkten erreichbaren Momenten.
6. Auswahl des finalen Arbeitspunkts als einer der zulässigen Kandidaten, z. B. \(i_{feas}\), \(i_{tv}\) oder \(i_{at}\), abhängig von Spannungs-, Strom- und Momentgrenzen. 


## Inhalt der Tests

Die Tests decken aktuell drei Bereiche ab:

- **LUT-Konsistenz:** Prüft Größen, `meshgrid`-Orientierung sowie `NaN`/`Inf` in den Kennfeldern.
- **Modellparameter:** Prüft, ob feste Parameter wie `p`, `Rs`, `I_max`, `U_dc` sowie optional `U_max` und `n_max` vorhanden und gültig sind.
- **Strategiewahl:** Prüft an festen Referenzpunkten, ob der vom Modell gewählte Betriebspunkt zur erwarteten Strategie bzw. zum erwarteten Betriebsbereich passt.

## Modellidee

Das Simulink-Modell berechnet für gegebene Vorgaben wie Drehzahl und Drehmoment zunächst mehrere theoretisch relevante Kandidatenpunkte aus den analytisch beschriebenen Kurven. Dazu gehören insbesondere Schnittpunkte zwischen:
- MTPC und Stromgrenze (i_ac),
- MTPV und Spannungsellipse (i_vv),
- MTPC und Spannungsellipse (i_ac),
- Stromgrenze und Spannungsellipse (i_cv),
- sowie Grenzkurven mit der Drehmomenthyperbel (i_tv, i_at). 

Aus diesen Kandidaten wird anschließend gemäß dem Entscheidungsbaum ein zulässiger und geeigneter Sollstromvektor ausgewählt. Der Algorithmus unterscheidet also zwischen:
- der **analytischen Berechnung** von Kennlinien und Schnittpunkten,
- und der **logischen Auswahl** des finalen Betriebspunkts. 

Diese Trennung ist wichtig, weil eine korrekte Berechnung einzelner Kennlinien allein noch nicht garantiert, dass im Betrieb auch der richtige Kandidat ausgewählt wird. Genau deshalb existieren neben Konsistenz- und Parametertests auch separate Strategietests.

## Voraussetzungen

Für lokale Testläufe werden benötigt:

- MATLAB
- Simulink
- Zugriff auf das Modell `Hackl_Pilsen_Algo.slx`
- Das Initialisierungsskript `Messdaten_Interpoliert.m` und `Maschinendaten.m` 
- Die Testdateien im Ordner `tests/`

Für GitHub CI wird zusätzlich ein GitHub-Repository mit aktivierten GitHub Actions benötigt. MATLAB- und Simulink-Tests lassen sich über die offiziellen MATLAB Actions in GitHub Actions ausführen. 


## Bedeutung der wichtigsten Testdateien

| Datei | Zweck |
|---|---|
| `tests/test_LUT_Consistency.m` | Prüft Größen, Vektoren, Kennfelder und `meshgrid`-Konsistenz |
| `tests/test_ModelParameters.m` | Prüft Maschinenparameter und Grenzwerte |
| `tests/test_StrategySelection.m` | Prüft die Auswahl des Betriebspunkts an festen Referenzpunkten |
| `tests/run_all_tests.m` | Startet alle Tests lokal und in CI |


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
