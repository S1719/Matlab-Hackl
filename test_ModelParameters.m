classdef test_ModelParameters < matlab.unittest.TestCase
    % Prüft, ob die notwendigen Maschinenparameter existieren und gültig sind.

    properties (Constant)
        INIT_SCRIPT = 'Messdaten_Interpoliert'
        REQUIRED_PARAMS = {'p','Rs','I_max','U_dc','n_max'}
    end

    methods (TestMethodSetup)
        function runInitScript(tc)
            evalin('base', 'clear p Rs I_max U_dc U_max n_max n_mech T_soll');
            evalin('base', tc.INIT_SCRIPT);
        end
    end

    methods (Test)
        function test_required_parameters_exist(tc)
            for k = 1:numel(tc.REQUIRED_PARAMS)
                parName = tc.REQUIRED_PARAMS{k};
                tc.verifyTrue( ...
                    evalin('base', sprintf('exist(''%s'',''var'')', parName)) == 1, ...
                    sprintf('Parameter %s ist nicht vorgegeben.', parName));
            end

            hasUmax = evalin('base', 'exist(''U_max'',''var'')');
            tc.verifyTrue(hasUmax == 1 || evalin('base', 'exist(''U_dc'',''var'')') == 1, ...
                'Es muss mindestens U_dc oder U_max vorgegeben sein.');
        end

        function test_parameter_values_are_valid(tc)
            p     = evalin('base', 'p');
            Rs    = evalin('base', 'Rs');
            I_max = evalin('base', 'I_max');
            U_dc  = evalin('base', 'U_dc');
            n_max = evalin('base', 'n_max');

            tc.verifyTrue(isnumeric(p)     && isscalar(p)     && isfinite(p)     && isreal(p), 'p ist ungültig.');
            tc.verifyTrue(isnumeric(Rs)    && isscalar(Rs)    && isfinite(Rs)    && isreal(Rs), 'Rs ist ungültig.');
            tc.verifyTrue(isnumeric(I_max) && isscalar(I_max) && isfinite(I_max) && isreal(I_max), 'I_max ist ungültig.');
            tc.verifyTrue(isnumeric(U_dc)  && isscalar(U_dc)  && isfinite(U_dc)  && isreal(U_dc), 'U_dc ist ungültig.');
            tc.verifyTrue(isnumeric(n_max) && isscalar(n_max) && isfinite(n_max) && isreal(n_max), 'n_max ist ungültig.');

            tc.verifyGreaterThan(p, 0, 'p muss > 0 sein.');
            tc.verifyEqual(p, round(p), 'p muss ganzzahlig sein.');
            tc.verifyGreaterThanOrEqual(Rs, 0, 'Rs muss >= 0 sein.');
            tc.verifyGreaterThan(I_max, 0, 'I_max muss > 0 sein.');
            tc.verifyGreaterThan(U_dc, 0, 'U_dc muss > 0 sein.');
            tc.verifyGreaterThan(n_max, 0, 'n_max muss > 0 sein.');
        end

        function test_optional_u_max_if_available(tc)
            hasUmax = evalin('base', 'exist(''U_max'',''var'')');
            if hasUmax == 1
                U_max = evalin('base', 'U_max');
                U_dc  = evalin('base', 'U_dc');

                tc.verifyTrue(isnumeric(U_max) && isscalar(U_max) && isfinite(U_max) && isreal(U_max), ...
                    'U_max ist ungültig.');
                tc.verifyGreaterThan(U_max, 0, 'U_max muss > 0 sein.');
                tc.verifyLessThanOrEqual(U_max, U_dc, 'U_max sollte nicht größer als U_dc sein.');
            end
        end

        function test_requested_speed_not_above_n_max_if_present(tc)
            hasNmech = evalin('base', 'exist(''n_mech'',''var'')');
            if hasNmech == 1
                n_mech = evalin('base', 'n_mech');
                n_max  = evalin('base', 'n_max');

                tc.verifyTrue(isnumeric(n_mech) && isscalar(n_mech) && isfinite(n_mech) && isreal(n_mech), ...
                    'n_mech ist ungültig.');
                tc.verifyLessThanOrEqual(n_mech, n_max, 'Vorgabe n_mech ist größer als n_max.');
            end
        end
    end
end
