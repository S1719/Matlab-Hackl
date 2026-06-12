classdef test_StrategySelection < matlab.unittest.TestCase
    % test_StrategySelection
    % Prüft die Strategiewahl und den gewählten Arbeitspunkt an typischen
    % Referenzpunkten.

    % Strategie-Codes:
    %   1 = MTPC
    %   2 = Field-Weakening / torque on voltage ellipse
    %   3 = Boundary torque tracking
    %   4 = Saturation at i_feas

    properties (Constant)
        MODEL = 'Hackl_Pilsen_Algo'
        INIT_SCRIPT_DATA = 'Messdaten_Interpoliert'
        INIT_SCRIPT_LIMITS = 'Maschinendaten_Vorgabe'

        INPUT_SPEED_VAR  = 'n_mech'
        INPUT_TORQUE_VAR = 'T_soll'

        SIGNAL_ID_REF = 'id_ref'
        SIGNAL_IQ_REF = 'iq_ref'
        SIGNAL_STRAT  = 'strategy'

        VAR_Imax = 'I_max'
        VAR_nmax = 'n_max'

        % Strategie-Codes gemäß Entscheidungsbaum
        STRAT_MTPC              = 1  % T* und MTPC
        STRAT_FW_TORQUE_ELLIPSE = 2  % T* und Spannungsgrenze
        STRAT_BOUNDARY_TRACKING = 3  % Grenzverfolgung entlang einer Begrenzung, bevor harte Sättigung eintritt
        STRAT_SATURATION_IFEAS  = 4  % gewünschter Betriebspunkt nicht mehr erreichbar, 
                                     % daher Sättigung auf zulässigen Grenzpunkt 
                                     % (Spannungsgrenze und Stromgrenze)

        N_MTPC = 2000    % MTPC: Erwartet id* = -61.0106 A, 
        T_MTPC = 50      %                iq* =  52.7107 A

        N_FW_TORQUE_ELLIPSE = 7000 % XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
        T_FW_TORQUE_ELLIPSE = 80

        N_BOUNDARY_TRACKING = 9000 % Erwartet id* = -110.576172 A
        T_BOUNDARY_TRACKING = 90   %          iq* =   74.091035 A

        N_SATURATION_IFEAS = 11000 % Erwartet id* = -159.305873 A
        T_SATURATION_IFEAS = 120   %          iq* =   59.341652 A

        CURRENT_TOL = 1e-6
    end

    
    methods (TestMethodSetup)
        function prepareModel(tc)
            rehash
            % Initialisierungsskript ausführen, damit die Kennfelddaten
            % im Base Workspace verfügbar sind.
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
        function test_MTPC_reference_point(tc)
            out = localRunCase(tc, tc.N_MTPC, tc.T_MTPC);
            tc.verifyEqual(double(out.strategie), double(tc.STRAT_MTPC), ...
                'Am MTPC-Referenzpunkt wurde nicht Strategie 1 (MTPC) gewählt.');
            tc.verifyTrue(isfinite(out.id_ref) && isfinite(out.iq_ref), ...
                'MTPC-Test: id_ref oder iq_ref ist nicht endlich.');
            tc.verifyLessThanOrEqual(hypot(out.id_ref, out.iq_ref), out.I_max + tc.CURRENT_TOL, ...
                'MTPC-Test: gewählter Arbeitspunkt verletzt I_max.');
        end

        function test_field_weakening_torque_on_voltage_ellipse_reference_point(tc)
            out = localRunCase(tc, tc.N_FW_TORQUE_ELLIPSE, tc.T_FW_TORQUE_ELLIPSE);
            tc.verifyEqual(double(out.strategie), double(tc.STRAT_FW_TORQUE_ELLIPSE), ...
                'Am Referenzpunkt für Field-Weakening / torque on voltage ellipse wurde nicht Strategie 2 gewählt.');
            tc.verifyTrue(isfinite(out.id_ref) && isfinite(out.iq_ref), ...
                'FW-/Voltage-Ellipse-Test: id_ref oder iq_ref ist nicht endlich.');
            tc.verifyLessThanOrEqual(hypot(out.id_ref, out.iq_ref), out.I_max + tc.CURRENT_TOL, ...
                'FW-/Voltage-Ellipse-Test: gewählter Arbeitspunkt verletzt I_max.');
        end

        function test_boundary_torque_tracking_reference_point(tc)
            out = localRunCase(tc, tc.N_BOUNDARY_TRACKING, tc.T_BOUNDARY_TRACKING);
            tc.verifyEqual(double(out.strategie), double(tc.STRAT_BOUNDARY_TRACKING), ...
                'Am Referenzpunkt für Boundary torque tracking wurde nicht Strategie 3 gewählt.');
            tc.verifyTrue(isfinite(out.id_ref) && isfinite(out.iq_ref), ...
                'Boundary-Tracking-Test: id_ref oder iq_ref ist nicht endlich.');
            tc.verifyLessThanOrEqual(hypot(out.id_ref, out.iq_ref), out.I_max + tc.CURRENT_TOL, ...
                'Boundary-Tracking-Test: gewählter Arbeitspunkt verletzt I_max.');
        end

        function test_saturation_at_ifeas_reference_point(tc)
            out = localRunCase(tc, tc.N_SATURATION_IFEAS, tc.T_SATURATION_IFEAS);
            tc.verifyEqual(double(out.strategie), double(tc.STRAT_SATURATION_IFEAS), ...
                'Am Referenzpunkt für Saturation at i_feas wurde nicht Strategie 4 gewählt.');
            tc.verifyTrue(isfinite(out.id_ref) && isfinite(out.iq_ref), ...
                'i_feas-Sättigungs-Test: id_ref oder iq_ref ist nicht endlich.');
            tc.verifyLessThanOrEqual(hypot(out.id_ref, out.iq_ref), out.I_max + tc.CURRENT_TOL, ...
                'i_feas-Sättigungs-Test: gewählter Arbeitspunkt verletzt I_max.');
        end

        function test_speed_reference_below_n_max_for_reference_points(tc)
            n_max = tc.readWorkspaceVariable(tc.VAR_nmax);
            tc.verifyTrue(isnumeric(n_max) && isscalar(n_max) && isfinite(n_max), ...
                'n_max konnte nicht numerisch gelesen werden.');
            tc.verifyLessThanOrEqual(tc.N_MTPC, n_max, ...
                'MTPC-Referenzpunkt verletzt n_max.');
            tc.verifyLessThanOrEqual(tc.N_FW_TORQUE_ELLIPSE, n_max, ...
                'FW-/Voltage-Ellipse-Referenzpunkt verletzt n_max.');
            tc.verifyLessThanOrEqual(tc.N_BOUNDARY_TRACKING, n_max, ...
                'Boundary-Tracking-Referenzpunkt verletzt n_max.');
            tc.verifyLessThanOrEqual(tc.N_SATURATION_IFEAS, n_max, ...
                'i_feas-Sättigungs-Referenzpunkt verletzt n_max.');
        end

        function test_strategy_signal_is_integer_like(tc)
            out = localRunCase(tc, tc.N_MTPC, tc.T_MTPC);
            tc.verifyEqual(double(out.strategie), round(double(out.strategie)), ...
                'Strategie-Ausgang ist nicht ganzzahlig codiert.');
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
    out.strategie = double(localExtractLastValue(simOut, tc.SIGNAL_STRAT));
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
