function run_all_tests
% Zentrales Skript für lokale Testläufe und GitHub Actions.

repoRoot = fileparts(mfilename('fullpath'));
testsDir = fullfile(repoRoot, 'tests');

addpath(testsDir);

% Überprüfung, welche Dateien durchlaufen werden
disp('--- DEBUG ---');
which run_all_tests -all
which test_ModelParameters -all
which test_StrategySelection -all

disp('--- DEBUG: resolved test files ---');
which test_LUT_Consistency -all
which test_ModelParameters -all
which test_ModelRegression -all
which test_StrategySelection -all

resultsDir = fullfile(repoRoot, 'test-results');
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

import matlab.unittest.TestRunner
import matlab.unittest.TestSuite
import matlab.unittest.Verbosity
import matlab.unittest.plugins.XMLPlugin

suite = TestSuite.fromFolder(testsDir, 'IncludingSubfolders', true);

runner = TestRunner.withTextOutput('OutputDetail', Verbosity.Detailed);
runner.addPlugin(XMLPlugin.producingJUnitFormat(fullfile(resultsDir, 'junit_results.xml')));

results = runner.run(suite);

disp(table({results.Name}', [results.Passed]', [results.Failed]', [results.Incomplete]', ...
    'VariableNames', {'Test', 'Passed', 'Failed', 'Incomplete'}));

if any([results.Failed]) || any([results.Incomplete])
    error('CI:TestsFailed', 'Mindestens ein MATLAB-/Simulink-Test ist fehlgeschlagen.');
end
end
