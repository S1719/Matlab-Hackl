classdef test_ZeroTorque < matlab.unittest.TestCase

    methods (Test)

        function test_ZeroTorque(tc)

            % Sollwerte im Simulink-Modell setzen
            set_param('Model_Linearisierung_final/T_soll', ...
                      'Value', '0');

            set_param('Model_Linearisierung_final/n_soll', ...
                      'Value', '2000');

            % Modell simulieren
            simOut = sim('Model_Linearisierung_final');

            % Ist-Drehmoment auslesen
            T_ist = simOut.T_ist;

            % T_ist muss gültig sein
            tc.verifyTrue(isfinite(T_ist), ...
                'T_ist ist NaN oder Inf.');

            % Bei T_soll = 0 muss T_ist ungefähr 0 sein
            tc.verifyEqual(T_ist, 0, ...
                'AbsTol', 1, ...
                'T_ist soll bei T_soll = 0 Nm ungefähr 0 Nm sein.');

        end

    end

end