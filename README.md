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
Drehmomenthyperbel:
```math
T(m_{\mathrm{ref}}) := \mathbf{i}_s^\mathsf{T}\,\mathbf{T}\,\mathbf{i}_s
+ 2\,\mathbf{t}^\mathsf{T}\mathbf{i}_s
+ \tau(m_{\mathrm{ref}}) = 0
```

MTPC-Kennlinie:
```math
\mathrm{MTPC} := \mathbf{i}_s^\mathsf{T}\,\mathbf{M}_c\,\mathbf{i}_s
+ 2\,\mathbf{m}_c^\mathsf{T}\mathbf{i}_s = 0
```

MTPV-Kennlinie:
```math
\mathrm{MTPV} := \mathbf{i}_s^\mathsf{T}\,\mathbf{M}_v(\omega)\,\mathbf{i}_s
+ 2\,\mathbf{m}_v(\omega)^\mathsf{T}\mathbf{i}_s
+ \mu_v(\omega) = 0
```

MTPF-Kennlinie:
```math
\mathrm{MTPF} := \mathbf{i}_s^\mathsf{T}\,\mathbf{M}_f\,\mathbf{i}_s
+ 2\,\mathbf{m}_f^\mathsf{T}\mathbf{i}_s
+ \mu_f = 0
```

  
## Fachlicher Hintergrund - Auswahlalgorithmus Betriebspunkt
Der im Modell verwendete Auswahlalgorithmus nach Glac, Šmídl und Peroutka folgt sinngemäß diesem Ablauf:
1. Berechnung der relevanten Kurven und Schnittpunkte.
2. Bestimmung des Vorzeichens des Referenzmoments.
3. Berechnung von Kandidatenpunkten an den Schnittstellen von MTPC, MTPV, Stromkreis, Spannungsellipse und Drehmomenthyperbel.
4. Ermittlung eines zulässigen Zwischenkandidaten \(i_{feas}\).
5. Vergleich des angeforderten Moments mit den an den Grenzpunkten erreichbaren Momenten.
6. Auswahl des finalen Arbeitspunkts als einer der zulässigen Kandidaten, z. B. \(i_{feas}\), \(i_{tv}\) oder \(i_{at}\), abhängig von Spannungs-, Strom- und Momentgrenzen. 

## Modellidee

Das Simulink-Modell berechnet für gegebene Vorgaben wie Drehzahl und Drehmoment zunächst mehrere theoretisch relevante Kandidatenpunkte aus den analytisch beschriebenen Kurven. Dazu gehören insbesondere Schnittpunkte zwischen:
- MTPC und Stromgrenze (i_ac),
- MTPV und Spannungsellipse (i_vv),
- MTPC und Spannungsellipse (i_ac),
- Stromgrenze und Spannungsellipse (i_cv),
- sowie Grenzkurven mit der Drehmomenthyperbel (i_tv, i_at). 

Aus diesen Kandidaten wird anschließend gemäß dem Entscheidungsbaum ein zulässiger und geeigneter Sollstromvektor ausgewählt. 

## Inhalt der Tests

Die Tests decken aktuell drei Bereiche ab:

- **LUT-Konsistenz:** Prüft Größen, `meshgrid`-Orientierung sowie `NaN`/`Inf` in den Kennfeldern.
- **Modellparameter:** Prüft, ob feste Parameter wie `p`, `Rs`, `I_max`, `U_dc` sowie optional `U_max` und `n_max` vorhanden und gültig sind.
- **Strategiewahl:** Prüft an festen Referenzpunkten, ob der vom Modell gewählte Betriebspunkt zur erwarteten Strategie bzw. zum erwarteten Betriebsbereich passt.

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
- Signale wurden im Modell umbenannt und können nicht mehr aus dem `SimulationOutput` gelesen werden,
- oder in der CI-Umgebung ist keine Simulink-Lizenz verfügbar.

## Typische Fehlerbilder
[......]

## Quellenhinweis

Mathematischen Herleitungen der Kurven MTPC, MTPV, MTPF (Eldeeb, Hackl):  https://www.researchgate.net/publication/309738085_On_the_optimal_feedforward_torque_control_problem_of_anisotropic_synchronous_machines_Quadrics_quartics_and_analytical_solutions

Auswahlablauf des finalen Betriebspunkts (Glac, Šmídl, Peroutka): https://www.researchgate.net/publication/330487741_Optimal_Feedforward_Torque_Control_of_Synchronous_Machines_with_Time-Varying_Parameters 
