classdef test_StrategySelection < matlab.unittest.TestCase
    % test_StrategySelection
    % Prüft die vier binären Fälle und den gewählten Arbeitspunkt (id*, iq*)
    % an typischen Referenzpunkten.

    properties (Constant)
        MODEL = 'Hackl_Pilsen_Algo'
        INIT_SCRIPT_DATA = 'Messdaten_Interpoliert'
        INIT_SCRIPT_LIMITS = 'Maschinendaten_Vorgabe'

        INPUT_SPEED_VAR  = 'n_mech'
        INPUT_TORQUE_VAR = 'T_soll'

        SIGNAL_ID_REF = 'id_ref'
        SIGNAL_IQ_REF = 'iq_ref'

        SIGNAL_OUT_IAT = 'out_iat'
        SIGNAL_OUT_ITV = 'out_itv'
        SIGNAL_OUT_IAC = 'out_iac'
        SIGNAL_OUT_ICV = 'out_icv'

        VAR_Imax = 'I_max'
        VAR_nmax = 'n_max'

        CASE_IAT = 1    % T* auf MTPC
        CASE_ITV = 2    % T* auf Spannungsgrenze
        CASE_IAC = 3    % MTPC und Imax, T* nicht erreichbar
        CASE_ICV = 4    % Imax und Umax, T* nicht erreichbar

        % T* auf MTPC
        N_IAT = 5000
        T_IAT = 50

        % T* auf Umax
        N_ITV = 10000
        T_ITV = 70

        % MTPC auf Imax, T* nicht erreichbar
        N_IAC = 1000
        T_IAC = 120

        % Schnittpunkt Imax und Umax, T* nicht erreichbar
        N_ICV = 11000    % n_max
        T_ICV = 120

        CURRENT_TOL = 1e-6

        USE_FAST_RESTART = true
    end

    properties
        RepoRoot
        I_max_cached
        n_max_cached
    end

    methods (TestClassSetup)
        function prepareSharedFixture(tc)
            tTotal = tic;
            fprintf('\n=== TestClassSetup: %s ===\n', tc.MODEL);

            tc.RepoRoot = localGetRepoRoot();
            modelFile = fullfile(tc.RepoRoot, [tc.MODEL '.slx']);
            dataScriptFile = fullfile(tc.RepoRoot, [tc.INIT_SCRIPT_DATA '.m']);
            limitsScriptFile = fullfile(tc.RepoRoot, [tc.INIT_SCRIPT_LIMITS '.m']);

            tc.assertTrue(isfile(modelFile), ...
                sprintf('Modell-Datei wurde nicht gefunden: %s', modelFile));
            tc.assertTrue(isfile(dataScriptFile), ...
                sprintf('Datenskript wurde nicht gefunden: %s', dataScriptFile));
            tc.assertTrue(isfile(limitsScriptFile), ...
                sprintf('Limits-Skript wurde nicht gefunden: %s', limitsScriptFile));
            tc.assertTrue(exist('load_system', 'file') == 2, ...
                'load_system ist nicht verfügbar.');
            tc.assertTrue(license('test', 'Simulink') == 1, ...
                'Es ist keine Simulink-Lizenz verfügbar.');

            oldFolder = pwd;
            tc.addTeardown(@() cd(oldFolder));
            cd(tc.RepoRoot);

            tInit = tic;
            run(tc.INIT_SCRIPT_DATA);
            run(tc.INIT_SCRIPT_LIMITS);
            fprintf('Initialisierungsskripte: %.3f s\n', toc(tInit));

            tc.assertTrue(evalin('base', sprintf('exist(''%s'',''var'')', tc.VAR_Imax)) == 1, ...
                'I_max fehlt im Base Workspace.');
            tc.assertTrue(evalin('base', sprintf('exist(''%s'',''var'')', tc.VAR_nmax)) == 1, ...
                'n_max fehlt im Base Workspace.');

            tc.I_max_cached = evalin('base', tc.VAR_Imax);
            tc.n_max_cached = evalin('base', tc.VAR_nmax);

            tLoad = tic;
            load_system(modelFile);
            fprintf('load_system: %.3f s\n', toc(tLoad));

            if tc.USE_FAST_RESTART
                try
                    set_param(tc.MODEL, 'FastRestart', 'on');
                    fprintf('Fast Restart: aktiviert\n');
                    tc.addTeardown(@() localSafeSetFastRestartOff(tc.MODEL));
                catch ME
                    fprintf('Fast Restart konnte nicht aktiviert werden: %s\n', ME.message);
                end
            end

            tc.addTeardown(@() localCloseModel(tc.MODEL));
            tc.addTeardown(@() evalin('base', 'clear I_max n_max'));

            fprintf('Gesamtes TestClassSetup: %.3f s\n', toc(tTotal));
            fprintf('===============================\n\n');
        end
    end

    methods (Static)
        function val = readWorkspaceVariable(varName)
            val = evalin('base', varName);
        end
    end

    methods (Test)
        function test_iat_reference_point(tc)
            out = localRunCase(tc, tc.N_IAT, tc.T_IAT, "test_iat_reference_point");
            tc.verifyEqual(out.out_iat, 1, ...
                'Am MTPC-Referenzpunkt wurde nicht Fall iat gewählt.');
            tc.verifyEqual(out.out_itv, 0);
            tc.verifyEqual(out.out_iac, 0);
            tc.verifyEqual(out.out_icv, 0);
            tc.verifyTrue(isfinite(out.id_ref) && isfinite(out.iq_ref), ...
                'iat-Test: id_ref oder iq_ref ist nicht endlich.');
            tc.verifyLessThanOrEqual(hypot(out.id_ref, out.iq_ref), ...
                out.I_max + tc.CURRENT_TOL, ...
                'iat-Test: gewählter Arbeitspunkt verletzt I_max.');
        end

        function test_itv_reference_point(tc)
            out = localRunCase(tc, tc.N_ITV, tc.T_ITV, "test_itv_reference_point");
            tc.verifyEqual(out.out_iat, 0);
            tc.verifyEqual(out.out_itv, 1, ...
                'Am Referenzpunkt wurde nicht Fall itv gewählt.');
            tc.verifyEqual(out.out_iac, 0);
            tc.verifyEqual(out.out_icv, 0);
            tc.verifyTrue(isfinite(out.id_ref) && isfinite(out.iq_ref), ...
                'itv-Test: id_ref oder iq_ref ist nicht endlich.');
            tc.verifyLessThanOrEqual(hypot(out.id_ref, out.iq_ref), ...
                out.I_max + tc.CURRENT_TOL, ...
                'itv-Test: gewählter Arbeitspunkt verletzt I_max.');
        end

        function test_iac_reference_point(tc)
            out = localRunCase(tc, tc.N_IAC, tc.T_IAC, "test_iac_reference_point");
            tc.verifyEqual(out.out_iat, 0);
            tc.verifyEqual(out.out_itv, 0);
            tc.verifyEqual(out.out_iac, 1, ...
                'Am Referenzpunkt wurde nicht Fall iac gewählt.');
            tc.verifyEqual(out.out_icv, 0);
            tc.verifyTrue(isfinite(out.id_ref) && isfinite(out.iq_ref), ...
                'iac-Test: id_ref oder iq_ref ist nicht endlich.');
            tc.verifyLessThanOrEqual(hypot(out.id_ref, out.iq_ref), ...
                out.I_max + tc.CURRENT_TOL, ...
                'iac-Test: gewählter Arbeitspunkt verletzt I_max.');
        end

        function test_icv_reference_point(tc)
            out = localRunCase(tc, tc.N_ICV, tc.T_ICV, "test_icv_reference_point");
            tc.verifyEqual(out.out_iat, 0);
            tc.verifyEqual(out.out_itv, 0);
            tc.verifyEqual(out.out_iac, 0);
            tc.verifyEqual(out.out_icv, 1, ...
                'Am Referenzpunkt wurde nicht Fall icv gewählt.');
            tc.verifyTrue(isfinite(out.id_ref) && isfinite(out.iq_ref), ...
                'icv-Test: id_ref oder iq_ref ist nicht endlich.');
            tc.verifyLessThanOrEqual(hypot(out.id_ref, out.iq_ref), ...
                out.I_max + tc.CURRENT_TOL, ...
                'icv-Test: gewählter Arbeitspunkt verletzt I_max.');
        end

        function test_speed_reference_below_n_max_for_reference_points(tc)
            n_max = tc.n_max_cached;
            tc.verifyTrue(isnumeric(n_max) && isscalar(n_max) && isfinite(n_max), ...
                'n_max konnte nicht numerisch gelesen werden.');
            tc.verifyLessThanOrEqual(tc.N_IAT, n_max);
            tc.verifyLessThanOrEqual(tc.N_ITV, n_max);
            tc.verifyLessThanOrEqual(tc.N_IAC, n_max);
            tc.verifyLessThanOrEqual(tc.N_ICV, n_max);
        end

        function test_exactly_one_case_active(tc)
            out = localRunCase(tc, tc.N_IAT, tc.T_IAT, "test_exactly_one_case_active");
            vals = [out.out_iat, out.out_itv, out.out_iac, out.out_icv];
            tc.verifyEqual(sum(vals), 1, 'Es muss genau ein Fall aktiv sein.');
            tc.verifyTrue(all(ismember(vals, [0 1])), ...
                'Die vier Ausgänge müssen binär sein.');
        end
    end
end

function out = localRunCase(tc, n_mech_value, T_soll_value, testName)
    if nargin < 4
        testName = "unnamed_test";
    end

    tCase = tic;
    fprintf('\n--- %s ---\n', testName);
    fprintf('Starte Strategie-Test-Simulation: %s | n_mech=%g | T_soll=%g\n', ...
        tc.MODEL, n_mech_value, T_soll_value);

    in = Simulink.SimulationInput(tc.MODEL);
    in = in.setVariable(tc.INPUT_SPEED_VAR, n_mech_value);
    in = in.setVariable(tc.INPUT_TORQUE_VAR, T_soll_value);

    if tc.USE_FAST_RESTART
        try
            in = in.setModelParameter('FastRestart', 'on');
        catch
        end
    end

    tSim = tic;
    simOut = sim(in);
    fprintf('Simulationszeit: %.3f s\n', toc(tSim));

    tRead = tic;
    out.id_ref  = double(localExtractLastValue(simOut, tc.SIGNAL_ID_REF));
    out.iq_ref  = double(localExtractLastValue(simOut, tc.SIGNAL_IQ_REF));
    out.out_iat = double(localExtractLastValue(simOut, tc.SIGNAL_OUT_IAT));
    out.out_itv = double(localExtractLastValue(simOut, tc.SIGNAL_OUT_ITV));
    out.out_iac = double(localExtractLastValue(simOut, tc.SIGNAL_OUT_IAC));
    out.out_icv = double(localExtractLastValue(simOut, tc.SIGNAL_OUT_ICV));
    out.I_max   = tc.I_max_cached;
    fprintf('Auslesezeit SimulationOutput: %.3f s\n', toc(tRead));

    fprintf('Gesamtzeit Testfall: %.3f s\n', toc(tCase));
end

function value = localExtractLastValue(simOut, sigName)
    data = [];

    if isprop(simOut, sigName)
        candidate = simOut.(sigName);
        data = localGetNumericData(candidate);
    end

    if isempty(data) && isprop(simOut, 'logsout')
        logs = simOut.logsout;
        if isa(logs, 'Simulink.SimulationData.Dataset') && ~isempty(logs)
            names = getElementNames(logs);
            idx = find(strcmp(names, sigName), 1);
            if ~isempty(idx)
                elem = logs.get(idx);
                data = localGetNumericData(elem.Values);
            end
        end
    end

    if isempty(data) && isprop(simOut, 'yout')
        yout = simOut.get('yout');
        if isa(yout, 'Simulink.SimulationData.Dataset')
            names = getElementNames(yout);
            idx = find(strcmp(names, sigName), 1);
            if ~isempty(idx)
                elem = yout.get(idx);
                data = localGetNumericData(elem.Values);
            end
        end
    end

    if isempty(data)
        error('Signal %s konnte nicht aus dem SimulationOutput gelesen werden.', sigName);
    end

    if isnumeric(data)
        value = data(end);
    else
        value = data;
    end
end

function data = localGetNumericData(candidate)
    data = [];

    if isa(candidate, 'timeseries')
        data = candidate.Data;
    elseif isa(candidate, 'Simulink.SimulationData.Signal')
        data = candidate.Values.Data;
    elseif isnumeric(candidate)
        data = candidate;
    elseif isstruct(candidate) && isfield(candidate, 'signals')
        data = candidate.signals.values;
    end
end

function repoRoot = localGetRepoRoot()
    thisFile = mfilename('fullpath');
    testsDir = fileparts(thisFile);
    repoRoot = fileparts(testsDir);
end

function localCloseModel(modelName)
    if exist('bdIsLoaded', 'file') == 2 && bdIsLoaded(modelName)
        close_system(modelName, 0);
    end
end

function localSafeSetFastRestartOff(modelName)
    try
        if exist('bdIsLoaded', 'file') == 2 && bdIsLoaded(modelName)
            set_param(modelName, 'FastRestart', 'off');
        end
    catch
    end
end
