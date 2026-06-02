function run_all_tests
% Zentrales Skript für lokale Testläufe und GitHub Actions.

thisFile = mfilename('fullpath');
testsDir = fileparts(thisFile);
repoRoot = fileparts(testsDir);

addpath(genpath(repoRoot));

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