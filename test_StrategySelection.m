classdef test_StrategySelection < matlab.unittest.TestCase
    % Prüft die Strategiewahl und den gewählten Arbeitspunkt an typischen
    % Referenzpunkten.
  
    properties (Constant)
        MODEL = 'Arbeitspunktsteuerung_Simulink_5_Runtime'
        INIT_SCRIPT = 'Messdaten_Interpoliert'

        INPUT_SPEED_VAR  = 'n_mech'
        INPUT_TORQUE_VAR = 'T_soll'

        SIGNAL_ID_REF = 'id_ref'
        SIGNAL_IQ_REF = 'iq_ref'
        SIGNAL_STRAT  = 'strategie'

        % Strategiekodierung nach bisherigem Projektstand:
        STRAT_NONE         = 0
        STRAT_MTPC         = 1
        STRAT_T_U_MAX      = 2
        STRAT_MTPV         = 3
        STRAT_MTPF         = 4

        % Referenzpunkte
        N_MTPC = 2000
        T_MTPC = 50

        N_MTPF = 7000
        T_MTPF = 80

        N_MTPV = 10000
        T_MTPV = 100

        CURRENT_TOL = 1e-6
    end

    methods (TestMethodSetup)
        function prepareModel(tc)
            evalin('base', tc.INIT_SCRIPT);

            tc.assumeTrue(exist([tc.MODEL '.slx'], 'file') == 2 || exist([tc.MODEL '.mdl'], 'file') == 2, ...
                'Modell %s wurde nicht gefunden.', tc.MODEL);

            load_system(tc.MODEL);
        end
    end

    methods (TestMethodTeardown)
        function closeModel(tc)
            if bdIsLoaded(tc.MODEL)
                close_system(tc.MODEL, 0);
            end
        end
    end

    methods (Test)
        function test_MTPC_reference_point(tc)
            out = localRunCase(tc, tc.N_MTPC, tc.T_MTPC);

            tc.verifyEqual(out.strategie, tc.STRAT_MTPC, ...
                'Am MTPC-Referenzpunkt wurde nicht MTPC gewählt.');

            tc.verifyTrue(isfinite(out.id_ref) && isfinite(out.iq_ref), ...
                'MTPC-Test: id_ref oder iq_ref ist nicht endlich.');

            tc.verifyLessThanOrEqual(hypot(out.id_ref, out.iq_ref), out.I_max + tc.CURRENT_TOL, ...
                'MTPC-Test: gewählter Arbeitspunkt verletzt I_max.');
        end

        function test_MTPF_reference_point(tc)
            out = localRunCase(tc, tc.N_MTPF, tc.T_MTPF);

            tc.verifyEqual(out.strategie, tc.STRAT_MTPF, ...
                'Am MTPF-Referenzpunkt wurde nicht MTPF gewählt.');

            tc.verifyTrue(isfinite(out.id_ref) && isfinite(out.iq_ref), ...
                'MTPF-Test: id_ref oder iq_ref ist nicht endlich.');

            tc.verifyLessThanOrEqual(hypot(out.id_ref, out.iq_ref), out.I_max + tc.CURRENT_TOL, ...
                'MTPF-Test: gewählter Arbeitspunkt verletzt I_max.');
        end

        function test_MTPV_reference_point(tc)
            out = localRunCase(tc, tc.N_MTPV, tc.T_MTPV);

            tc.verifyEqual(out.strategie, tc.STRAT_MTPV, ...
                'Am MTPV-Referenzpunkt wurde nicht MTPV gewählt.');

            tc.verifyTrue(isfinite(out.id_ref) && isfinite(out.iq_ref), ...
                'MTPV-Test: id_ref oder iq_ref ist nicht endlich.');

            tc.verifyLessThanOrEqual(hypot(out.id_ref, out.iq_ref), out.I_max + tc.CURRENT_TOL, ...
                'MTPV-Test: gewählter Arbeitspunkt verletzt I_max.');
        end

        function test_speed_reference_below_n_max_for_reference_points(tc)
            n_max = evalin('base', 'n_max');

            tc.verifyLessThanOrEqual(tc.N_MTPC, n_max, 'MTPC-Referenzpunkt verletzt n_max.');
            tc.verifyLessThanOrEqual(tc.N_MTPF, n_max, 'MTPF-Referenzpunkt verletzt n_max.');
            tc.verifyLessThanOrEqual(tc.N_MTPV, n_max, 'MTPV-Referenzpunkt verletzt n_max.');
        end

        function test_strategy_signal_is_integer_like(tc)
            out = localRunCase(tc, tc.N_MTPC, tc.T_MTPC);

            tc.verifyEqual(out.strategie, round(out.strategie), ...
                'Strategie-Ausgang ist nicht ganzzahlig codiert.');
        end
    end
end

function out = localRunCase(tc, n_mech_value, T_soll_value)
    % Workspace vorbereiten
    evalin('base', tc.INIT_SCRIPT);

    I_max = evalin('base', 'I_max');

    in = Simulink.SimulationInput(tc.MODEL);
    in = in.setVariable(tc.INPUT_SPEED_VAR, n_mech_value);
    in = in.setVariable(tc.INPUT_TORQUE_VAR, T_soll_value);

    simOut = sim(in);

    out.id_ref    = localExtractLastValue(simOut, tc.SIGNAL_ID_REF);
    out.iq_ref    = localExtractLastValue(simOut, tc.SIGNAL_IQ_REF);
    out.strategie = localExtractLastValue(simOut, tc.SIGNAL_STRAT);
    out.I_max     = I_max;
end

function value = localExtractLastValue(simOut, sigName)
    data = [];
    value = [];

    % 1) logsout
    try
        logs = simOut.logsout;
        if ~isempty(logs)
            elem = logs.get(sigName);
            if ~isempty(elem)
                vals = elem.Values;
                data = vals.Data;
            end
        end
    catch
    end

    % 2) yout
    if isempty(data)
        try
            yout = simOut.get('yout');
            if isa(yout, 'Simulink.SimulationData.Dataset')
                elem = yout.getElement(sigName);
                if ~isempty(elem)
                    vals = elem.Values;
                    data = vals.Data;
                end
            end
        catch
        end
    end

    % 3) Direkt gespeicherte Variable
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