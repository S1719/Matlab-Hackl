clc
rehash
disp('=== MATLAB / Simulink CI Diagnose ===')

repoRoot = getenv('GITHUB_WORKSPACE');
if isempty(repoRoot)
    repoRoot = pwd;
end
cd(repoRoot)

fprintf('Aktueller Ordner: %s\n', pwd)

modelFile = fullfile(repoRoot, 'Hackl_Pilsen_Algo.slx');
initFile  = fullfile(repoRoot, 'Messdaten_Interpoliert.m');
initFile1 = fullfile(repoRoot, 'Maschinendaten_Vorgabe.m');
lutFile   = fullfile(repoRoot, 'LUT_BRUSA_jax_grad.mat');
dataFile  = fullfile(repoRoot, 'daten_nichtlinear_interpoliert.mat');
dataFile1 = fullfile(repoRoot, 'Maschinendaten.mat');
testsDir  = fullfile(repoRoot, 'tests');

fprintf('MATLAB Version: %s\n', version)
fprintf('load_system verfügbar: %d\n', exist('load_system', 'file') == 2)
fprintf('Simulink Lizenz verfügbar: %d\n', license('test', 'Simulink'))
fprintf('Modell vorhanden: %d -> %s\n', isfile(modelFile), modelFile)
fprintf('Init-Skript vorhanden: %d -> %s\n', isfile(initFile), initFile)
fprintf('Maschinen-Skript vorhanden: %d -> %s\n', isfile(initFile1), initFile1)
fprintf('LUT vorhanden: %d -> %s\n', isfile(lutFile), lutFile)
fprintf('Interpolierte Daten vorhanden: %d -> %s\n', isfile(dataFile), dataFile)
fprintf('Maschinendaten vorhanden: %d -> %s\n', isfile(dataFile1), dataFile1)
fprintf('Tests-Ordner vorhanden: %d -> %s\n', isfolder(testsDir), testsDir)

assert(exist('load_system','file') == 2, 'Simulink ist nicht verfügbar.')
assert(license('test','Simulink'), 'Simulink-Lizenz ist nicht verfügbar.')
assert(isfile(modelFile), 'Modell-Datei fehlt.')
assert(isfile(initFile), 'Messdaten_Interpoliert.m fehlt.')
assert(isfile(initFile1), 'Maschinendaten_Vorgabe.m fehlt.')
assert(isfolder(testsDir), 'tests-Ordner fehlt.')

load_system(modelFile)
fprintf('Modell erfolgreich geladen: %s\n', bdroot)
close_system(bdroot, 0)

disp('=== Diagnose erfolgreich abgeschlossen ===')