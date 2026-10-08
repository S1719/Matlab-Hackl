classdef test_OperatingPoints < matlab.unittest.TestCase
    % test_OperatingPoints
    %
    % Prüft die Arbeitspunktsteuerung für ausgewählte Betriebspunkte.
    %
    % 1) 0 Nm                  -> T_ist ~= 0 Nm
    % 2) 30 Nm / 3000 rpm      -> MTPC, T_ist ~= 30 Nm
    % 3) 90 Nm / 2000 rpm      -> Stromgrenze eingehalten
    % 4) 90 Nm / 10000 rpm     -> Strom- und Spannungsgrenze eingehalten
    % 5) 50 Nm / 10000 rpm     -> Spannungsgrenze, T_ist ~= 50 Nm

    properties (Constant)
        MODEL = 'Model_Linearisierung_final';

        % Toleranz für Drehmoment
        TOL_TORQUE = 1;      % Nm

        % Kleine Toleranz für Strom-/Spannungsgrenze
        LIMIT_TOL = 1.01;
    end


    methods (Test)

        %% Test 1: T_soll = 0 Nm
        function test_ZeroTorque(tc)

            % Betriebspunkt setzen
            tc.setOperatingPoint(0, 3000);

            % Simulation
            simOut = sim(tc.MODEL);

            % Ausgang auslesen
            T_ist = simOut.T_ist;

            % Letzten Simulationswert verwenden
            T_ist = T_ist(end);

            % Prüfung
            tc.verifyTrue(isfinite(T_ist), ...
                'T_ist ist NaN oder Inf.');

            tc.verifyEqual(T_ist, 0, ...
                'AbsTol', tc.TOL_TORQUE, ...
                'Bei T_soll = 0 Nm soll T_ist ungefähr 0 Nm sein.');

        end


        %% Test 2: 30 Nm / 3000 rpm -> MTPC und Drehmomentvorgabe
        function test_MTPC_30Nm_3000rpm(tc)

            % Betriebspunkt setzen
            tc.setOperatingPoint(30, 3000);

            % Simulation
            simOut = sim(tc.MODEL);

            % Ergebnisse
            T_ist = simOut.T_ist(end);
            strategy = simOut.strategy_flag(end);

            % Gültige Ergebnisse
            tc.verifyTrue(isfinite(T_ist), ...
                'T_ist ist NaN oder Inf.');

            tc.verifyTrue(isfinite(strategy), ...
                'strategy_flag ist NaN oder Inf.');

            % MTPC Flag = 5
            tc.verifyEqual(strategy, 5, ...
                'Bei 30 Nm / 3000 rpm wird MTPC erwartet.');

            % Drehmoment
            tc.verifyEqual(T_ist, 30, ...
                'AbsTol', tc.TOL_TORQUE, ...
                'T_ist soll ungefähr 30 Nm erreichen.');

        end


        %% Test 3: 90 Nm / 2000 rpm -> Stromgrenze
        function test_CurrentLimit_90Nm_2000rpm(tc)

            % Betriebspunkt setzen
            tc.setOperatingPoint(90, 2000);

            % Simulation
            simOut = sim(tc.MODEL);

            % Ergebnisse
            T_ist = simOut.T_ist(end);
            I_ist = simOut.I_ist(end);

            % Imax aus Maschinendaten
            Imax = evalin('base', 'I_max');

            % Gültige Ergebnisse
            tc.verifyTrue(isfinite(T_ist), ...
                'T_ist ist NaN oder Inf.');

            tc.verifyTrue(isfinite(I_ist), ...
                'I_ist ist NaN oder Inf.');

            % Stromgrenze
            tc.verifyLessThanOrEqual(I_ist, Imax * tc.LIMIT_TOL, ...
                'Imax wird überschritten.');

            % Das Drehmoment muss nicht 90 Nm erreichen.
            % Deshalb wird hier nur geprüft, dass T_ist plausibel ist.
            tc.verifyGreaterThanOrEqual(T_ist, 0, ...
                'T_ist ist für diesen Betriebspunkt nicht plausibel.');

        end


        %% Test 4: 90 Nm / 10000 rpm -> Strom- und Spannungsgrenze
        function test_CurrentAndVoltageLimit_90Nm_10000rpm(tc)

            % Betriebspunkt setzen
            tc.setOperatingPoint(90, 10000);

            % Simulation
            simOut = sim(tc.MODEL);

            % Ergebnisse
            T_ist = simOut.T_ist(end);
            I_ist = simOut.I_ist(end);
            U_ist = simOut.U_ist(end);

            % Grenzwerte
            Imax = evalin('base', 'I_max');
            Umax = evalin('base', 'U_max');

            % Gültige Ergebnisse
            tc.verifyTrue(isfinite(T_ist), ...
                'T_ist ist NaN oder Inf.');

            tc.verifyTrue(isfinite(I_ist), ...
                'I_ist ist NaN oder Inf.');

            tc.verifyTrue(isfinite(U_ist), ...
                'U_ist ist NaN oder Inf.');

            % Stromgrenze
            tc.verifyLessThanOrEqual(I_ist, Imax * tc.LIMIT_TOL, ...
                'Imax wird überschritten.');

            % Spannungsgrenze
            tc.verifyLessThanOrEqual(U_ist, Umax * tc.LIMIT_TOL, ...
                'Umax wird überschritten.');

            % Drehmoment muss hier nicht 90 Nm erreichen.
            tc.verifyGreaterThanOrEqual(T_ist, 0, ...
                'T_ist ist für diesen Betriebspunkt nicht plausibel.');

        end


        %% Test 5: 50 Nm / 10000 rpm -> Spannungsgrenze
        function test_VoltageLimit_50Nm_10000rpm(tc)

            % Betriebspunkt setzen
            tc.setOperatingPoint(50, 10000);

            % Simulation
            simOut = sim(tc.MODEL);

            % Ergebnisse
            T_ist = simOut.T_ist(end);
            U_ist = simOut.U_ist(end);

            % Spannungsgrenze
            Umax = evalin('base', 'U_max');

            % Gültige Ergebnisse
            tc.verifyTrue(isfinite(T_ist), ...
                'T_ist ist NaN oder Inf.');

            tc.verifyTrue(isfinite(U_ist), ...
                'U_ist ist NaN oder Inf.');

            % Spannungsgrenze darf nicht überschritten werden
            tc.verifyLessThanOrEqual(U_ist, Umax * tc.LIMIT_TOL, ...
                'Umax wird überschritten.');

            % Sollmoment soll erreicht werden
            tc.verifyEqual(T_ist, 50, ...
                'AbsTol', tc.TOL_TORQUE, ...
                'Bei 50 Nm / 10000 rpm soll T_ist ungefähr 50 Nm sein.');

        end

    end


    methods (Access = private)

        function setOperatingPoint(tc, T_soll, n_soll)
            % Setzt die beiden Constant-Blöcke im Simulink-Modell.

            set_param( ...
                [tc.MODEL '/T_soll'], ...
                'Value', num2str(T_soll));

            set_param( ...
                [tc.MODEL '/n_soll'], ...
                'Value', num2str(n_soll));
        end

    end

end