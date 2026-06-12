function run_all_tests
% run_all_tests führt alle MATLAB-/Simulink-Tests des Repositorys aus.
% Diese Funktion ist der zentrale Einstiegspunkt für lokale Testläufe
% und für GitHub Actions.

    repoRoot = fileparts(mfilename('fullpath'));
    testsDir = fullfile(repoRoot, 'tests');
    resultsDir = fullfile(repoRoot, 'test-results');
    xmlFile = fullfile(resultsDir, 'junit_results.xml');

    % Aufruf des Skriptes, um Maschinendaten in Workspace zu laden
    cd(repoRoot);
    run('Maschinendaten_Vorgabe.m');
    run('Messdaten_Interpoliert.m');

    % Relevante Pfade hinzufügen
    addpath(repoRoot);
    addpath(testsDir);

    if ~isfolder(testsDir)     % Prüfung, ob Testordner vorhanden
        error('run_all_tests:MissingTestsFolder', ...
            'Der Ordner "%s" wurde nicht gefunden.', testsDir);
    end

    % Ergebnisordner zuverlässig erzeugen
    if ~isfolder(resultsDir)
        [status, msg, msgID] = mkdir(resultsDir);
        if ~status
            error('run_all_tests:CreateResultsFolderFailed', ...
                'Der Ordner "%s" konnte nicht angelegt werden. MATLAB-Meldung: %s (%s)', ...
                resultsDir, msg, msgID);
         end
    end

    % Zusätzliche Prüfung 
    if ~isfolder(resultsDir)
        error('run_all_tests:ResultsFolderMissing', ...
            'Der Ergebnisordner "%s" existiert nach mkdir weiterhin nicht.', resultsDir);
    end

% Debug-Ausgaben zur Pfadauflösung
disp('--- DEBUG: resolved files ---');
disp(which('run_all_tests', '-all'));
disp(which('test_LUT_Consistency', '-all'));
disp(which('test_ModelParameters', '-all'));
disp(which('test_ModelRegression', '-all'));
disp(which('test_StrategySelection', '-all'));

% Debug-Ausgabe, ob alle nötigen Files im Repository liegen
disp('--- DEBUG: repository files ---');
disp(fullfile(repoRoot, 'Hackl_Pilsen_Algo.slx'));
disp(fullfile(repoRoot, 'Messdaten_Interpoliert.m'));
disp(fullfile(repoRoot, 'Maschinendaten_Vorgabe.m'));
disp(fullfile(repoRoot, 'daten_nichtlinear_interpoliert.mat'));
disp(fullfile(repoRoot, 'Maschinendaten.mat'));

% Debug, ob alle nötigen Pfade existieren
disp('--- DEBUG: result paths ---');
fprintf('resultsDir exists: %d -> %s\n', isfolder(resultsDir), resultsDir);
fprintf('xmlFile target: %s\n', xmlFile);

import matlab.unittest.TestRunner
import matlab.unittest.TestSuite
import matlab.unittest.Verbosity
import matlab.unittest.plugins.XMLPlugin

suite = TestSuite.fromFolder(testsDir, 'IncludingSubfolders', true);

runner = TestRunner.withTextOutput('OutputDetail', Verbosity.Detailed);
runner.addPlugin( ...    % Plugin erst hinzufügen, nachdem der Zielordner sicher existiert
    XMLPlugin.producingJUnitFormat(fullfile(resultsDir, 'junit_results.xml')));

results = runner.run(suite);

disp(table({results.Name}', [results.Passed]', [results.Failed]', ...
    [results.Incomplete]', ...
    'VariableNames', {'Test', 'Passed', 'Failed', 'Incomplete'}));

    if any([results.Failed]) 
        error('CI:TestsFailed', ...
         'Mindestens ein MATLAB-/Simulink-Test ist fehlgeschlagen.');
    end
end
