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
    end

    methods (TestMethodSetup)
        function prepareModel(tc)
            rehash
            repoRoot = localGetRepoRoot();
            modelFile = fullfile(repoRoot, [tc.MODEL '.slx']);
            dataScriptFile = fullfile(repoRoot, [tc.INIT_SCRIPT_DATA '.m']);
            limitsScriptFile = fullfile(repoRoot, [tc.INIT_SCRIPT_LIMITS '.m']);

            tc.assertTrue(isfile(modelFile), sprintf('Modell-Datei wurde nicht gefunden: %s', modelFile));
            tc.assertTrue(isfile(dataScriptFile), sprintf('Datenskript wurde nicht gefunden: %s', dataScriptFile));
            tc.assertTrue(isfile(limitsScriptFile), sprintf('Limits-Skript wurde nicht gefunden: %s', limitsScriptFile));
            tc.assertTrue(exist('load_system', 'file') == 2, 'load_system ist nicht verfügbar.');
            tc.assertTrue(license('test', 'Simulink') == 1, 'Es ist keine Simulink-Lizenz verfügbar.');

            oldFolder = pwd;
            cleanupObj = onCleanup(@() cd(oldFolder)); %#ok<NASGU>
            cd(repoRoot);

            run(tc.INIT_SCRIPT_DATA);
            run(tc.INIT_SCRIPT_LIMITS);

            tc.assertTrue(evalin('base', sprintf('exist(''%s'',''var'')', tc.VAR_Imax)) == 1, 'I_max fehlt im Base Workspace.');
            tc.assertTrue(evalin('base', sprintf('exist(''%s'',''var'')', tc.VAR_nmax)) == 1, 'n_max fehlt im Base Workspace.');

            load_system(modelFile);
        end
    end

    methods (TestMethodTeardown)
        function closeModel(tc)
            if exist('bdIsLoaded', 'file') == 2 && bdIsLoaded(tc.MODEL)
                close_system(tc.MODEL, 0);
            end
            evalin('base', 'clear I_max n_max');
        end
    end

    methods (Static)
        function val = readWorkspaceVariable(varName)
            val = evalin('base', varName);
        end
    end

    methods (Test)
        function test_iat_reference_point(tc)
            out = localRunCase(tc, tc.N_IAT, tc.T_IAT);
            tc.verifyEqual(out.out_iat, 1, 'Am MTPC-Referenzpunkt wurde nicht Fall iat gewählt.');
            tc.verifyEqual(out.out_itv, 0);
            tc.verifyEqual(out.out_iac, 0);
            tc.verifyEqual(out.out_icv, 0);
            tc.verifyTrue(isfinite(out.id_ref) && isfinite(out.iq_ref), ...
                'iat-Test: id_ref oder iq_ref ist nicht endlich.');
            tc.verifyLessThanOrEqual(hypot(out.id_ref, out.iq_ref), out.I_max + tc.CURRENT_TOL, ...
                'iat-Test: gewählter Arbeitspunkt verletzt I_max.');
        end

        function test_itv_reference_point(tc)
            out = localRunCase(tc, tc.N_ITV, tc.T_ITV);
            tc.verifyEqual(out.out_iat, 0);
            tc.verifyEqual(out.out_itv, 1, 'Am Referenzpunkt wurde nicht Fall itv gewählt.');
            tc.verifyEqual(out.out_iac, 0);
            tc.verifyEqual(out.out_icv, 0);
            tc.verifyTrue(isfinite(out.id_ref) && isfinite(out.iq_ref), ...
                'itv-Test: id_ref oder iq_ref ist nicht endlich.');
            tc.verifyLessThanOrEqual(hypot(out.id_ref, out.iq_ref), out.I_max + tc.CURRENT_TOL, ...
                'itv-Test: gewählter Arbeitspunkt verletzt I_max.');
        end

        function test_iac_reference_point(tc)
            out = localRunCase(tc, tc.N_IAC, tc.T_IAC);
            tc.verifyEqual(out.out_iat, 0);
            tc.verifyEqual(out.out_itv, 0);
            tc.verifyEqual(out.out_iac, 1, 'Am Referenzpunkt wurde nicht Fall iac gewählt.');
            tc.verifyEqual(out.out_icv, 0);
            tc.verifyTrue(isfinite(out.id_ref) && isfinite(out.iq_ref), ...
                'iac-Test: id_ref oder iq_ref ist nicht endlich.');
            tc.verifyLessThanOrEqual(hypot(out.id_ref, out.iq_ref), out.I_max + tc.CURRENT_TOL, ...
                'iac-Test: gewählter Arbeitspunkt verletzt I_max.');
        end

        function test_icv_reference_point(tc)
            out = localRunCase(tc, tc.N_ICV, tc.T_ICV);
            tc.verifyEqual(out.out_iat, 0);
            tc.verifyEqual(out.out_itv, 0);
            tc.verifyEqual(out.out_iac, 0);
            tc.verifyEqual(out.out_icv, 1, 'Am Referenzpunkt wurde nicht Fall icv gewählt.');
            tc.verifyTrue(isfinite(out.id_ref) && isfinite(out.iq_ref), ...
                'icv-Test: id_ref oder iq_ref ist nicht endlich.');
            tc.verifyLessThanOrEqual(hypot(out.id_ref, out.iq_ref), out.I_max + tc.CURRENT_TOL, ...
                'icv-Test: gewählter Arbeitspunkt verletzt I_max.');
        end

        function test_speed_reference_below_n_max_for_reference_points(tc)
            n_max = tc.readWorkspaceVariable(tc.VAR_nmax);
            tc.verifyTrue(isnumeric(n_max) && isscalar(n_max) && isfinite(n_max), ...
                'n_max konnte nicht numerisch gelesen werden.');
            tc.verifyLessThanOrEqual(tc.N_IAT, n_max);
            tc.verifyLessThanOrEqual(tc.N_ITV, n_max);
            tc.verifyLessThanOrEqual(tc.N_IAC, n_max);
            tc.verifyLessThanOrEqual(tc.N_ICV, n_max);
        end

        function test_exactly_one_case_active(tc)
            out = localRunCase(tc, tc.N_IAT, tc.T_IAT);
            vals = [out.out_iat, out.out_itv, out.out_iac, out.out_icv];
            tc.verifyEqual(sum(vals), 1, 'Es muss genau ein Fall aktiv sein.');
            tc.verifyTrue(all(ismember(vals, [0 1])), 'Die vier Ausgänge müssen binär sein.');
        end
    end
end

function out = localRunCase(tc, n_mech_value, T_soll_value)
    repoRoot = localGetRepoRoot();
    oldFolder = pwd;
    cleanupObj = onCleanup(@() cd(oldFolder)); %#ok<NASGU>
    cd(repoRoot);

    run(tc.INIT_SCRIPT_DATA);
    run(tc.INIT_SCRIPT_LIMITS);

    I_max = evalin('base', tc.VAR_Imax);

    in = Simulink.SimulationInput(tc.MODEL);
    in = in.setVariable(tc.INPUT_SPEED_VAR, n_mech_value);
    in = in.setVariable(tc.INPUT_TORQUE_VAR, T_soll_value);

    disp("Starte Strategie-Test-Simulation: " + tc.MODEL + ...
        " | n_mech=" + num2str(n_mech_value) + ...
        " | T_soll=" + num2str(T_soll_value));

    simOut = sim(in);

    out.id_ref = double(localExtractLastValue(simOut, tc.SIGNAL_ID_REF));
    out.iq_ref = double(localExtractLastValue(simOut, tc.SIGNAL_IQ_REF));
    out.out_iat = double(localExtractLastValue(simOut, tc.SIGNAL_OUT_IAT));
    out.out_itv = double(localExtractLastValue(simOut, tc.SIGNAL_OUT_ITV));
    out.out_iac = double(localExtractLastValue(simOut, tc.SIGNAL_OUT_IAC));
    out.out_icv = double(localExtractLastValue(simOut, tc.SIGNAL_OUT_ICV));
    out.I_max = I_max;
end

function value = localExtractLastValue(simOut, sigName)
    data = [];
    value = [];

    try
        logs = simOut.logsout;
        if ~isempty(logs)
            elem = logs.get(sigName);
            if ~isempty(elem)
                data = elem.Values.Data;
            end
        end
    catch
    end

    if isempty(data)
        try
            yout = simOut.get('yout');
            if isa(yout, 'Simulink.SimulationData.Dataset')
                elem = yout.getElement(sigName);
                if ~isempty(elem)
                    data = elem.Values.Data;
                end
            end
        catch
        end
    end

    if isempty(data)
        try
            candidate = simOut.get(sigName);
            if isa(candidate, 'timeseries')
                data = candidate.Data;
            elseif isa(candidate, 'Simulink.SimulationData.Signal')
                data = candidate.Values.Data;
            elseif isnumeric(candidate)
                data = candidate;
            end
        catch
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

function repoRoot = localGetRepoRoot()
    thisFile = mfilename('fullpath');
    testsDir = fileparts(thisFile);
    repoRoot = fileparts(testsDir);
end
