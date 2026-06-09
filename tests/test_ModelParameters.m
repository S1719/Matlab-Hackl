classdef test_ModelParameters < matlab.unittest.TestCase
    % test_ModelParameters
    % Prüft, ob die notwendigen Maschinenparameter im Simulink-Modell
    % vorhanden sind und sinnvolle numerische Werte besitzen.

    properties (Constant)
        % Name des Simulink-Modells 
        MODEL = 'Hackl_Pilsen_Algo'
        
        % Initialisierungsskripte
        DATA_SCRIPT_1 = 'Messdaten_Interpoliert.m'
        DATA_SCRIPT_2 = 'Maschinendaten_Vorgabe.m'

        % Erwartete Variablennamen im Workspace
        VAR_Rs   = 'Rs'
        VAR_Imax = 'I_max'
        VAR_p    = 'p'
        VAR_Udc  = 'U_dc'
        VAR_Umax = 'U_max'
        VAR_nmax = 'n_max'
    end

    methods (TestMethodSetup)
        function prepareModel(tc)
            rehash

            % Repository-Root bestimmen
            repoRoot = localGetRepoRoot();
            modelFile = fullfile(repoRoot, [tc.MODEL '.slx']);
            dataScriptFile1 = fullfile(repoRoot, tc.DATA_SCRIPT_1);
            dataScriptFile2 = fullfile(repoRoot, tc.DATA_SCRIPT_2);

            fprintf('DEBUG prepareModel repoRoot: %s\n', repoRoot);
            fprintf('DEBUG prepareModel dataScriptFile1: %s\n', dataScriptFile1);
            fprintf('DEBUG prepareModel dataScriptFile2: %s\n', dataScriptFile2);

            % Vorbedingungen hart prüfen
            tc.assertEqual(isfile(modelFile), true, ...
                sprintf('Modell-Datei wurde nicht gefunden: %s', modelFile));

            tc.assertEqual(isfile(dataScriptFile1), true, ...
                sprintf('Datenskript wurde nicht gefunden: %s', dataScriptFile1));

            tc.assertEqual(isfile(dataScriptFile2), true, ...
                sprintf('Datenskript wurde nicht gefunden: %s', dataScriptFile2));

            tc.assertEqual(exist('load_system', 'file') == 2, true, ...
                'Die Funktion "load_system" ist nicht verfügbar. Simulink fehlt vermutlich.');

            tc.assertEqual(license('test', 'Simulink'), 1, ...
                'Es ist keine Simulink-Lizenz verfügbar.');

            % Initialisierungsskripte im Repository-Root ausführen
            oldFolder = pwd;
            cleanupObj = onCleanup(@() cd(oldFolder)); %#ok<NASGU>
            cd(repoRoot);

            run(tc.DATA_SCRIPT_1);
            run(tc.DATA_SCRIPT_2);

            % Modell laden
            load_system(modelFile);
        end
    end

   methods (TestMethodTeardown)
        function closeModel(tc)
            if exist('bdIsLoaded', 'file') == 2
                if bdIsLoaded(tc.MODEL)
                    close_system(tc.MODEL, 0);
                end
            end

            evalin('base', 'clear Rs I_max p U_dc U_max n_max');
        end
    end

    methods (Static)
        function val = readWorkspaceVariable(varName)
            val = evalin('base', varName);
        end
    end

    methods (Test)
        function test_required_parameters_exist(tc)
            tc.verifyEqual(evalin('base', sprintf('exist(''%s'',''var'')', tc.VAR_Rs)), 1, ...
                'Variable Rs fehlt im Base Workspace.');

            tc.verifyEqual(evalin('base', sprintf('exist(''%s'',''var'')', tc.VAR_Imax)), 1, ...
                'Variable I_max fehlt im Base Workspace.');

            tc.verifyEqual(evalin('base', sprintf('exist(''%s'',''var'')', tc.VAR_p)), 1, ...
                'Variable p fehlt im Base Workspace.');

            tc.verifyEqual(evalin('base', sprintf('exist(''%s'',''var'')', tc.VAR_Udc)), 1, ...
                'Variable U_dc fehlt im Base Workspace.');

            tc.verifyEqual(evalin('base', sprintf('exist(''%s'',''var'')', tc.VAR_Umax)), 1, ...
                'Variable U_max fehlt im Base Workspace.');

            tc.verifyEqual(evalin('base', sprintf('exist(''%s'',''var'')', tc.VAR_nmax)), 1, ...
                'Variable n_max fehlt im Base Workspace.');
        end

        function test_parameter_values_are_valid(tc)
            Rs    = tc.readWorkspaceVariable(tc.VAR_Rs);
            I_max = tc.readWorkspaceVariable(tc.VAR_Imax);
            p     = tc.readWorkspaceVariable(tc.VAR_p);
            U_dc  = tc.readWorkspaceVariable(tc.VAR_Udc);
            U_max = tc.readWorkspaceVariable(tc.VAR_Umax);
            n_max = tc.readWorkspaceVariable(tc.VAR_nmax);

            tc.verifyTrue(isnumeric(Rs) && isscalar(Rs) && isfinite(Rs), ...
                'Rs muss numerisch, skalar und endlich sein.');

            tc.verifyTrue(isnumeric(I_max) && isscalar(I_max) && isfinite(I_max), ...
                'I_max muss numerisch, skalar und endlich sein.');

            tc.verifyTrue(isnumeric(p) && isscalar(p) && isfinite(p), ...
                'p muss numerisch, skalar und endlich sein.');

            tc.verifyTrue(isnumeric(U_dc) && isscalar(U_dc) && isfinite(U_dc), ...
                'U_dc muss numerisch, skalar und endlich sein.');

            tc.verifyTrue(isnumeric(U_max) && isscalar(U_max) && isfinite(U_max), ...
                'U_max muss numerisch, skalar und endlich sein.');

            tc.verifyTrue(isnumeric(n_max) && isscalar(n_max) && isfinite(n_max), ...
                'n_max muss numerisch, skalar und endlich sein.');

            tc.verifyGreaterThanOrEqual(Rs, 0, 'Rs muss >= 0 sein.');
            tc.verifyGreaterThan(I_max, 0, 'I_max muss > 0 sein.');
            tc.verifyGreaterThan(p, 0, 'p muss > 0 sein.');
            tc.verifyEqual(p, round(p), 'p muss ganzzahlig sein.');
            tc.verifyGreaterThan(U_dc, 0, 'U_dc muss > 0 sein.');
            tc.verifyGreaterThan(U_max, 0, 'U_max muss > 0 sein.');
            tc.verifyGreaterThan(n_max, 0, 'n_max muss > 0 sein.');
        end
    end
end

function repoRoot = localGetRepoRoot()
    thisFile = mfilename('fullpath');
    testsDir = fileparts(thisFile);
    repoRoot = fileparts(testsDir);
end
