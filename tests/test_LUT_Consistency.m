classdef test_LUT_Consistency < matlab.unittest.TestCase
    % Prüft LUT-/Kennfelddaten auf Vollständigkeit, Größenkonsistenz und
    % meshgrid-Orientierung.
    %
    % Erwartete Variablen aus Messdaten_Interpoliert.m:
    % ID, IQ, PSID, PSIQ, Ld, Lq, Lm, id_fine, iq_fine

    properties (Constant)
        INIT_SCRIPT = 'Messdaten_Interpoliert'
        REQUIRED_MATRICES = {'ID','IQ','PSID','PSIQ','Ld','Lq','Lm'}
        REQUIRED_VECTORS  = {'id_fine','iq_fine'}
    end

    methods (TestMethodSetup)
        function runInitScript(tc)
            % Im Base Workspace ausführen, damit clear/clearvars im Skript
            % nicht das Testobjekt löschen.
            evalin('base', 'clear ID IQ PSID PSIQ Ld Lq Lm id_fine iq_fine');
            evalin('base', tc.INIT_SCRIPT);
        end
    end

    methods (Test)
        function test_required_variables_exist(tc)
            for k = 1:numel(tc.REQUIRED_MATRICES)
                varName = tc.REQUIRED_MATRICES{k};
                tc.verifyTrue(evalin('base', sprintf('exist(''%s'',''var'')', varName)) == 1, ...
                    'Variable %s existiert nicht.', varName);
                tc.verifyNotEmpty(evalin('base', varName), ...
                    'Variable %s ist leer.', varName);
            end

            for k = 1:numel(tc.REQUIRED_VECTORS)
                varName = tc.REQUIRED_VECTORS{k};
                tc.verifyTrue(evalin('base', sprintf('exist(''%s'',''var'')', varName)) == 1, ...
                    'Variable %s existiert nicht.', varName);
                tc.verifyNotEmpty(evalin('base', varName), ...
                    'Variable %s ist leer.', varName);
            end
        end

        function test_matrix_sizes_match(tc)
            ID   = evalin('base', 'ID');
            IQ   = evalin('base', 'IQ');
            PSID = evalin('base', 'PSID');
            PSIQ = evalin('base', 'PSIQ');
            Ld   = evalin('base', 'Ld');
            Lq   = evalin('base', 'Lq');
            Lm   = evalin('base', 'Lm');

            tc.verifyEqual(size(IQ),   size(ID), 'IQ hat nicht dieselbe Größe wie ID.');
            tc.verifyEqual(size(PSID), size(ID), 'PSID hat nicht dieselbe Größe wie ID.');
            tc.verifyEqual(size(PSIQ), size(ID), 'PSIQ hat nicht dieselbe Größe wie ID.');
            tc.verifyEqual(size(Ld),   size(ID), 'Ld hat nicht dieselbe Größe wie ID.');
            tc.verifyEqual(size(Lq),   size(ID), 'Lq hat nicht dieselbe Größe wie ID.');
            tc.verifyEqual(size(Lm),   size(ID), 'Lm hat nicht dieselbe Größe wie ID.');
        end

        function test_meshgrid_orientation(tc)
            ID      = evalin('base', 'ID');
            IQ      = evalin('base', 'IQ');
            id_fine = evalin('base', 'id_fine(:)');
            iq_fine = evalin('base', 'iq_fine(:)');

            tc.verifyEqual(size(ID), [numel(iq_fine), numel(id_fine)], ...
                'Matrixgröße passt nicht zur meshgrid-Konvention: Zeilen = iq_fine, Spalten = id_fine.');

            tc.verifyEqual(ID(1,:), id_fine.', ...
                'Bei meshgrid muss die erste Zeile von ID dem Vektor id_fine entsprechen.');

            tc.verifyEqual(IQ(:,1), iq_fine, ...
                'Bei meshgrid muss die erste Spalte von IQ dem Vektor iq_fine entsprechen.');
        end

        function test_vectors_are_monotonic(tc)
            id_fine = evalin('base', 'id_fine(:)');
            iq_fine = evalin('base', 'iq_fine(:)');

            did = diff(id_fine);
            diq = diff(iq_fine);

            tc.verifyTrue(all(did > 0) || all(did < 0), ...
                'id_fine muss streng monoton sein.');
            tc.verifyTrue(all(diq > 0) || all(diq < 0), ...
                'iq_fine muss streng monoton sein.');
        end

        function test_no_nan_inf_or_complex(tc)
            allVars = [tc.REQUIRED_MATRICES, tc.REQUIRED_VECTORS];
            for k = 1:numel(allVars)
                varName = allVars{k};
                A = evalin('base', varName);

                tc.verifyTrue(isnumeric(A), '%s muss numerisch sein.', varName);
                tc.verifyTrue(isreal(A), '%s enthält komplexe Werte.', varName);
                tc.verifyFalse(any(isnan(A(:))), '%s enthält NaN.', varName);
                tc.verifyFalse(any(isinf(A(:))), '%s enthält Inf.', varName);
            end
        end
    end
end