classdef test_ModelParameters < matlab.unittest.TestCase
    % Prüft, ob die notwendigen Maschinenparameter existieren und gültig sind.

    properties (Constant)
        MODEL = 'Arbeitspunktsteuerung_Simulink_5_Runtime'

        BLK_Rs    = 'Pilsen_Algo_V2_f/Maschinendaten/Rs'
        BLK_Imax  = 'Pilsen_Algo_V2_f/Maschinendaten/I_max'
        BLK_p     = 'Pilsen_Algo_V2_f/Maschinendaten/p'
        BLK_Udc   = 'Pilsen_Algo_V2_f/Maschinendaten/U_dc'
        BLK_nmax  = 'Pilsen_Algo_V2_f/Maschinendaten/n_max'
    end

    methods (TestMethodSetup)
        function prepareModel(tc)
            load_system(tc.MODEL);
        end
    end

    methods (TestMethodTeardown)
        function closeModel(tc)
            if exist('bdIsLoaded','file') == 2
                if bdIsLoaded(tc.MODEL)
                    close_system(tc.MODEL, 0);
                end
            end
        end
    end

    methods (Static)
        function val = readConstant(blockPath)
            raw = get_param(blockPath, 'Value');
            val = str2double(raw);
        end
    end

    methods (Test)
        function test_required_parameters_exist(tc)
            tc.verifyTrue(ischar(get_param(tc.BLK_Rs,   'Value')) || isstring(get_param(tc.BLK_Rs,   'Value')));
            tc.verifyTrue(ischar(get_param(tc.BLK_Imax, 'Value')) || isstring(get_param(tc.BLK_Imax, 'Value')));
            tc.verifyTrue(ischar(get_param(tc.BLK_p,    'Value')) || isstring(get_param(tc.BLK_p,    'Value')));
            tc.verifyTrue(ischar(get_param(tc.BLK_Udc,  'Value')) || isstring(get_param(tc.BLK_Udc,  'Value')));
            tc.verifyTrue(ischar(get_param(tc.BLK_nmax, 'Value')) || isstring(get_param(tc.BLK_nmax, 'Value')));
        end

        function test_parameter_values_are_valid(tc)
            Rs    = tc.readConstant(tc.BLK_Rs);
            I_max = tc.readConstant(tc.BLK_Imax);
            p     = tc.readConstant(tc.BLK_p);
            U_dc  = tc.readConstant(tc.BLK_Udc);
            n_max = tc.readConstant(tc.BLK_nmax);

            tc.verifyTrue(isfinite(Rs),    'Rs konnte nicht numerisch gelesen werden.');
            tc.verifyTrue(isfinite(I_max), 'I_max konnte nicht numerisch gelesen werden.');
            tc.verifyTrue(isfinite(p),     'p konnte nicht numerisch gelesen werden.');
            tc.verifyTrue(isfinite(U_dc),  'U_dc konnte nicht numerisch gelesen werden.');
            tc.verifyTrue(isfinite(n_max), 'n_max konnte nicht numerisch gelesen werden.');

            tc.verifyGreaterThanOrEqual(Rs, 0, 'Rs muss >= 0 sein.');
            tc.verifyGreaterThan(I_max, 0, 'I_max muss > 0 sein.');
            tc.verifyGreaterThan(p, 0, 'p muss > 0 sein.');
            tc.verifyEqual(p, round(p), 'p muss ganzzahlig sein.');
            tc.verifyGreaterThan(U_dc, 0, 'U_dc muss > 0 sein.');
            tc.verifyGreaterThan(n_max, 0, 'n_max muss > 0 sein.');
        end
    end
end
