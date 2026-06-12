classdef test_ModelRegression < matlab.unittest.TestCase
    % test_ModelRegression
    % Regressionstest für das Simulink-Modell Hackl_Pilsen_Algo.
    % Vergleicht id_ref, iq_ref und strategie gegen eine gespeicherte
    % Baseline-MAT-Datei.

    properties (Constant)
        MODEL = 'Hackl_Pilsen_Algo'
        
        INIT_SCRIPT_1 = 'Messdaten_Interpoliert.m'
        INIT_SCRIPT_2 = 'Maschinendaten_Vorgabe.m'

        SIGNALS = {'id_ref', 'iq_ref', 'strategy'}

        INPUT_SPEED_VAR  = 'n_mech'
        INPUT_TORQUE_VAR = 'T_soll'

        % Feste Regressionstestpunkte
        N_TEST = [2000, 7000, 10000]
        T_TEST = [50, 80, 100]

        ABS_TOL_IDIQ = 1e-6
        REL_TOL_IDIQ = 1e-4
        ABS_TOL_STRAT = 0
        TIME_TOL = 1e-12
    end

    methods (Test)
        function test_regression_against_baseline(tc)
            repoRoot = localGetRepoRoot();
            modelFile = fullfile(repoRoot, [tc.MODEL '.slx']);
            initScriptFile1 = fullfile(repoRoot, tc.INIT_SCRIPT_1);
            initScriptFile2 = fullfile(repoRoot, tc.INIT_SCRIPT_2);
            baselineDir = fullfile(repoRoot, 'baseline');
            baselineFile = fullfile(baselineDir, [tc.MODEL '_baseline.mat']);

            tc.assertEqual(isfile(modelFile), true, ...
                sprintf('Modell-Datei wurde nicht gefunden: %s', modelFile));

            tc.assertEqual(isfile(initScriptFile1), true, ...
                sprintf('Initialisierungsskript wurde nicht gefunden: %s', initScriptFile1));

            tc.assertEqual(isfile(initScriptFile2), true, ...
                sprintf('Initialisierungsskript wurde nicht gefunden: %s', initScriptFile2));

            tc.assertEqual(exist('load_system', 'file') == 2, true, ...
                'Die Funktion "load_system" ist nicht verfügbar. Simulink fehlt vermutlich.');

            tc.assertEqual(license('test', 'Simulink'), 1, ...
                'Es ist keine Simulink-Lizenz verfügbar.');

            current = localRunAllCases(tc, repoRoot, modelFile);

            createBaseline = strcmpi(getenv('CREATE_BASELINE'), '1');
            updateBaseline = strcmpi(getenv('UPDATE_BASELINE'), '1');

            if createBaseline || updateBaseline
                if ~isfolder(baselineDir)
                    mkdir(baselineDir);
                end

                baseline = current; %#ok<NASGU>
                save(baselineFile, 'baseline');

                tc.assertEqual(isfile(baselineFile), true, ...
                    sprintf('Baseline-Datei konnte nicht geschrieben werden: %s', baselineFile));
                return;
            end

            tc.assertEqual(isfile(baselineFile), true, ...
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
                        sprintf('Signal %s fehlt in der Baseline.', sigName));

                    tCur = curCase.signals.(sigName).time(:);
                    yCur = curCase.signals.(sigName).data;
                    tRef = refCase.signals.(sigName).time(:);
                    yRef = refCase.signals.(sigName).data;

                    tc.verifyEqual(size(tCur), size(tRef), ...
                        sprintf('Zeitvektor von %s hat eine andere Größe als in der Baseline.', sigName));
                    tc.verifyLessThanOrEqual(max(abs(tCur - tRef)), tc.TIME_TOL, ...
                        sprintf('Zeitvektor von %s unterscheidet sich von der Baseline.', sigName));
                    tc.verifyEqual(size(yCur), size(yRef), ...
                        sprintf('Signal %s hat eine andere Größe als in der Baseline.', sigName));

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

function current = localRunAllCases(tc, repoRoot, modelFile)
    % Führt die Simulation für alle definierten Testfälle aus
    % und sammelt die relevanten Ausgangssignale ein.
    current = struct();
    current.model = tc.MODEL;
    current.cases = struct([]);

    addpath(repoRoot);
    load_system(modelFile);
    cleanupObj = onCleanup(@() close_system(tc.MODEL, 0)); %#ok<NASGU>

    for i = 1:numel(tc.N_TEST)
        nVal = tc.N_TEST(i);
        tVal = tc.T_TEST(i);

        % Initialisierungsskripte vor jedem Testfall erneut ausführen,
        % damit eine saubere Ausgangsbasis entsteht.
        evalin('base', 'clear Rs I_max p U_dc U_max n_max');
        oldFolder = pwd;
        cleanupObj2 = onCleanup(@() cd(oldFolder)); %#ok<NASGU>
        cd(repoRoot);

        run(tc.INIT_SCRIPT_1);
        run(tc.INIT_SCRIPT_2);

        in = Simulink.SimulationInput(tc.MODEL);
        in = in.setVariable(tc.INPUT_SPEED_VAR, nVal);
        in = in.setVariable(tc.INPUT_TORQUE_VAR, tVal);

        disp("Starte Regressionstest-Simulation: " + tc.MODEL + ...
            " | n_mech=" + num2str(nVal) + " | T_soll=" + num2str(tVal));

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

        if isempty(current.cases)
            current.cases = c;
        else
            current.cases(end + 1) = c; %#ok<AGROW>
        end
    end
end

function [t, y] = localExtractSignal(simOut, sigName)
    % Extrahiert ein Signal aus simOut, bevorzugt aus logsout,
    % alternativ aus yout oder direkt gespeicherten Variablen.
    t = [];
    y = [];

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
