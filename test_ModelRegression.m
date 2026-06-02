classdef test_ModelRegression < matlab.unittest.TestCase
    % Regressionstest fuer das Simulink-Modell.
    % Vergleicht id_ref, iq_ref und strategie gegen eine gespeicherte
    % Baseline-MAT-Datei.
    %
    % Verwendung:
    % 1) Erste Baseline erzeugen:
    %    setenv('CREATE_BASELINE','1');
    %    run_all_tests
    %    setenv('CREATE_BASELINE','0');
    %
    % 2) Baseline spaeter bewusst aktualisieren:
    %    setenv('UPDATE_BASELINE','1');
    %    run_all_tests
    %    setenv('UPDATE_BASELINE','0');
    %
    % Erwartete Struktur der Baseline-Datei:
    % baseline.model
    % baseline.signals.id_ref.time
    % baseline.signals.id_ref.data
    % baseline.signals.iq_ref.time
    % baseline.signals.iq_ref.data
    % baseline.signals.strategie.time
    % baseline.signals.strategie.data

    properties (Constant)
        MODEL = 'Arbeitspunktsteuerung_Simulink_5_Runtime'
        INIT_SCRIPT = 'Messdaten_Interpoliert'

        SIGNALS = {'id_ref','iq_ref','strategie'}

        INPUT_SPEED_VAR  = 'n_mech'
        INPUT_TORQUE_VAR = 'T_soll'

        % Feste Regressionstestpunkte
        N_TEST = [2000, 7000, 10000]
        T_TEST = [50,   80,   100]

        ABS_TOL_IDIQ = 1e-6
        REL_TOL_IDIQ = 1e-4
        ABS_TOL_STRAT = 0
        TIME_TOL = 1e-12
    end

    methods (Test)
        function test_regression_against_baseline(tc)
            repoRoot = localGetRepoRoot();
            baselineDir = fullfile(repoRoot, 'baseline');
            baselineFile = fullfile(baselineDir, [tc.MODEL '_baseline.mat']);

            tc.assumeTrue(exist([tc.INIT_SCRIPT '.m'], 'file') == 2, ...
                'Initialisierungsskript %s.m wurde nicht gefunden.', tc.INIT_SCRIPT);

            tc.assumeTrue(exist([tc.MODEL '.slx'], 'file') == 2 || exist([tc.MODEL '.mdl'], 'file') == 2, ...
                'Modell %s wurde nicht gefunden.', tc.MODEL);

            current = localRunAllCases(tc);

            createBaseline = strcmpi(getenv('CREATE_BASELINE'), '1');
            updateBaseline = strcmpi(getenv('UPDATE_BASELINE'), '1');

            if createBaseline || updateBaseline
                if ~exist(baselineDir, 'dir')
                    mkdir(baselineDir);
                end
                baseline = current; %#ok<NASGU>
                save(baselineFile, 'baseline');
                tc.assertTrue(exist(baselineFile, 'file') == 2, ...
                    'Baseline-Datei konnte nicht geschrieben werden: %s', baselineFile);
                return;
            end

            tc.assertTrue(exist(baselineFile, 'file') == 2, ...
                ['Baseline-Datei fehlt: ' baselineFile newline ...
                 'Erzeuge sie einmal lokal mit CREATE_BASELINE=1.']);

            S = load(baselineFile, 'baseline');
            tc.assertTrue(isfield(S, 'baseline'), ...
                'Baseline-Datei enthält keine Variable "baseline".');

            baseline = S.baseline;

            tc.verifyEqual(current.model, baseline.model, ...
                'Baseline passt nicht zum aktuell getesteten Modell.');

            tc.verifyEqual(numel(current.cases), numel(baseline.cases), ...
                'Anzahl der Testfälle stimmt nicht mit der Baseline überein.');

            for i = 1:numel(current.cases)
                curCase = current.cases(i);
                refCase = baseline.cases(i);

                tc.verifyEqual(curCase.n_mech, refCase.n_mech, ...
                    'n_mech des Testfalls stimmt nicht mit der Baseline überein.');
                tc.verifyEqual(curCase.T_soll, refCase.T_soll, ...
                    'T_soll des Testfalls stimmt nicht mit der Baseline überein.');

                for k = 1:numel(tc.SIGNALS)
                    sigName = tc.SIGNALS{k};

                    tc.verifyTrue(isfield(refCase.signals, sigName), ...
                        'Signal %s fehlt in der Baseline.', sigName);

                    tCur = curCase.signals.(sigName).time(:);
                    yCur = curCase.signals.(sigName).data;
                    tRef = refCase.signals.(sigName).time(:);
                    yRef = refCase.signals.(sigName).data;

                    tc.verifyEqual(size(tCur), size(tRef), ...
                        'Zeitvektor von %s hat eine andere Größe als in der Baseline.', sigName);

                    tc.verifyLessThanOrEqual(max(abs(tCur - tRef)), tc.TIME_TOL, ...
                        sprintf('Zeitvektor von %s unterscheidet sich von der Baseline.', sigName));

                    tc.verifyEqual(size(yCur), size(yRef), ...
                        'Signal %s hat eine andere Größe als in der Baseline.', sigName);

                    if strcmp(sigName, 'strategie')
                        tc.verifyEqual(yCur, yRef, ...
                            'AbsTol', tc.ABS_TOL_STRAT, ...
                            sprintf('Strategie-Signal %s stimmt nicht mit der Baseline überein.', sigName));
                    else
                        refScale = max(1, max(abs(yRef(:))));
                        absTol = tc.ABS_TOL_IDIQ + tc.REL_TOL_IDIQ * refScale;
                        absErr = max(abs(yCur(:) - yRef(:)));

                        tc.verifyLessThanOrEqual(absErr, absTol, ...
                            sprintf('Regressionsfehler in %s: max |Delta| = %.6g', sigName, absErr));
                    end
                end
            end
        end
    end
end

function current = localRunAllCases(tc)
current = struct();
current.model = tc.MODEL;
current.cases = struct([]);

load_system(tc.MODEL);

for i = 1:numel(tc.N_TEST)
    nVal = tc.N_TEST(i);
    tVal = tc.T_TEST(i);

    evalin('base', tc.INIT_SCRIPT);
    assignin('base', tc.INPUT_SPEED_VAR, nVal);
    assignin('base', tc.INPUT_TORQUE_VAR, tVal);

    in = Simulink.SimulationInput(tc.MODEL);
    in = in.setVariable(tc.INPUT_SPEED_VAR, nVal);
    in = in.setVariable(tc.INPUT_TORQUE_VAR, tVal);

    simOut = sim(in);

    c = struct();
    c.n_mech = nVal;
    c.T_soll = tVal;
    c.signals = struct();

    for k = 1:numel(tc.SIGNALS)
        sigName = tc.SIGNALS{k};
        [t, y] = localExtractSignal(simOut, sigName);

        if isempty(y)
            error('Signal %s konnte nicht aus dem SimulationOutput gelesen werden.', sigName);
        end

        c.signals.(sigName).time = t;
        c.signals.(sigName).data = y;
    end

    current.cases(i) = c; %#ok<AGROW>
end

close_system(tc.MODEL, 0);
end

function [t, y] = localExtractSignal(simOut, sigName)
t = [];
y = [];

% 1) logsout
try
    logs = simOut.logsout;
    if ~isempty(logs)
        elem = logs.get(sigName);
        if ~isempty(elem)
            vals = elem.Values;
            t = vals.Time;
            y = vals.Data;
            return;
        end
    end
catch
end

% 2) yout
try
    yout = simOut.get('yout');
    if isa(yout, 'Simulink.SimulationData.Dataset')
        elem = yout.getElement(sigName);
        if ~isempty(elem)
            vals = elem.Values;
            t = vals.Time;
            y = vals.Data;
            return;
        end
    end
catch
end

% 3) Direkt gespeicherte Variable
try
    candidate = simOut.get(sigName);
    [t, y] = localConvertCandidate(candidate);
    if ~isempty(y)
        return;
    end
catch
end

error('Signal %s wurde weder in logsout noch in yout noch direkt im SimulationOutput gefunden.', sigName);
end

function [t, y] = localConvertCandidate(candidate)
t = [];
y = [];

if isa(candidate, 'timeseries')
    t = candidate.Time;
    y = candidate.Data;
    return;
end

if isa(candidate, 'Simulink.SimulationData.Signal')
    vals = candidate.Values;
    t = vals.Time;
    y = vals.Data;
    return;
end

if isnumeric(candidate)
    y = candidate;
    t = (0:numel(candidate)-1).';
    return;
end
end

function repoRoot = localGetRepoRoot()
thisFile = mfilename('fullpath');
testsDir = fileparts(thisFile);
repoRoot = fileparts(testsDir);
end