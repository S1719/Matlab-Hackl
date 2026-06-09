classdef test_ModelParameters < matlab.unittest.TestCase
    % test_ModelParameters
    % Prüft, ob die notwendigen Maschinenparameter im Simulink-Modell
    % vorhanden sind und sinnvolle numerische Werte besitzen.

    properties (Constant)
        % Name des Simulink-Modells 
        MODEL = 'Hackl_Pilsen_Algo'
        
        % Pfade zu den relevanten Konstantenblöcken im Modell
        BLK_Rs   = 'Hackl_Pilsen_Algo/Maschinendaten/Rs'
        BLK_Imax = 'Hackl_Pilsen_Algo/Maschinendaten/I_max'
        BLK_p    = 'Hackl_Pilsen_Algo/Maschinendaten/p'
        BLK_Udc  = 'Hackl_Pilsen_Algo/Maschinendaten/U_dc'
        BLK_nmax = 'Hackl_Pilsen_Algo/Maschinendaten/n_max'
    end

    methods (TestMethodSetup)
        function prepareModel(tc)
            rehash
            % Repository-Root bestimmen und Modellpfad absolut aufbauen.
            repoRoot = localGetRepoRoot();
            modelFile = fullfile(repoRoot, [tc.MODEL '.slx']);

            fprintf('DEBUG prepareModel repoRoot: %s\n', repoRoot);  % Debug-Ausgabe zur Überwachung
            fprintf('DEBUG prepareModel modelFile: %s\n', modelFile);
            fprintf('DEBUG prepareModel isfile(modelFile): %d\n', isfile(modelFile));
        
            % Vorbedingungen: Wenn Modell fehlt, soll Test fehlschlagen
            tc.assertTrue(logical(isfile(modelFile)), ...
                sprintf('Modell-Datei wurde nicht gefunden: %s', modelFile));

            tc.assertTrue(exist('load_system', 'file') == 2, ...
                'Die Funktion "load_system" ist nicht verfügbar. Simulink fehlt vermutlich.');

            tc.assertEqual(license('test', 'Simulink'), 1, ...
                'Es ist keine Simulink-Lizenz verfügbar.');

            load_system(modelFile);
        end
    end

    methods (TestMethodTeardown)
        function closeModel(tc)
            % Modell am Ende sauber schließen.
            if exist('bdIsLoaded', 'file') == 2
                if bdIsLoaded(tc.MODEL)
                    close_system(tc.MODEL, 0);
                end
            end
        end
    end


    methods (Static)
        function val = readConstant(blockPath)
            % Liest den Value-Parameter eines Konstantenblocks und wandelt
            % ihn in einen numerischen Wert um.
            raw = get_param(blockPath, 'Value');
            val = str2double(raw);
        end
    end

    methods (Test)
        function test_required_parameters_exist(tc)
            % Prüft, ob die Blockwerte grundsätzlich lesbar sind.
            tc.verifyTrue( ...
                ischar(get_param(tc.BLK_Rs, 'Value')) || isstring(get_param(tc.BLK_Rs, 'Value')), ...
                'Rs-Blockwert konnte nicht gelesen werden.');

            tc.verifyTrue( ...
                ischar(get_param(tc.BLK_Imax, 'Value')) || isstring(get_param(tc.BLK_Imax, 'Value')), ...
                'I_max-Blockwert konnte nicht gelesen werden.');

            tc.verifyTrue( ...
                ischar(get_param(tc.BLK_p, 'Value')) || isstring(get_param(tc.BLK_p, 'Value')), ...
                'p-Blockwert konnte nicht gelesen werden.');

            tc.verifyTrue( ...
                ischar(get_param(tc.BLK_Udc, 'Value')) || isstring(get_param(tc.BLK_Udc, 'Value')), ...
                'U_dc-Blockwert konnte nicht gelesen werden.');

            tc.verifyTrue( ...
                ischar(get_param(tc.BLK_nmax, 'Value')) || isstring(get_param(tc.BLK_nmax, 'Value')), ...
                'n_max-Blockwert konnte nicht gelesen werden.');
        end

        function test_parameter_values_are_valid(tc)
            % Liest die Maschinenparameter aus dem Modell
            Rs    = tc.readConstant(tc.BLK_Rs);
            I_max = tc.readConstant(tc.BLK_Imax);
            p     = tc.readConstant(tc.BLK_p);
            U_dc  = tc.readConstant(tc.BLK_Udc);
            n_max = tc.readConstant(tc.BLK_nmax);

            % Prüfen, ob alle Werte numerisch interpretierbar sind
            tc.verifyTrue(isfinite(Rs), ...
                'Rs konnte nicht numerisch gelesen werden.');
            tc.verifyTrue(isfinite(I_max), ...
                'I_max konnte nicht numerisch gelesen werden.');
            tc.verifyTrue(isfinite(p), ...
                'p konnte nicht numerisch gelesen werden.');
            tc.verifyTrue(isfinite(U_dc), ...
                'U_dc konnte nicht numerisch gelesen werden.');
            tc.verifyTrue(isfinite(n_max), ...
                'n_max konnte nicht numerisch gelesen werden.');

            % Plausibilitätsprüfungen
            tc.verifyGreaterThanOrEqual(Rs, 0, 'Rs muss >= 0 sein.');
            tc.verifyGreaterThan(I_max, 0, 'I_max muss > 0 sein.');
            tc.verifyGreaterThan(p, 0, 'p muss > 0 sein.');
            tc.verifyEqual(p, round(p), 'p muss ganzzahlig sein.');
            tc.verifyGreaterThan(U_dc, 0, 'U_dc muss > 0 sein.');
            tc.verifyGreaterThan(n_max, 0, 'n_max muss > 0 sein.');
        end
    end
end

function repoRoot = localGetRepoRoot()
    % Bestimmt aus dem Speicherort dieser Testdatei den Repository-Root
    thisFile = mfilename('fullpath');
    testsDir = fileparts(thisFile);
    repoRoot = fileparts(testsDir);
end
