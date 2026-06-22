% create_baseline.m
% Baseline für test_ModelRegression einmal lokal erzeugen

CREATE_BASELINE = 1;

repoRoot = getenv('GITHUB_WORKSPACE');
if isempty(repoRoot)
    repoRoot = pwd;
end
cd(repoRoot);

addpath(genpath(pwd));

% Nur den Regressionstest laufen lassen
testResults = runtests('tests/test_ModelRegression.m');
disp(testResults);