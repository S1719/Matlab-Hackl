function create_baseline()
% CREATE_BASELINE
% Erzeugt baseline/Hackl_Pilsen_Algo_baseline.mat
% mit Zeitverläufen für drei definierte Betriebspunkte.
%
% Gespeichert wird eine Struktur "baselineData" mit:
%   baselineData.model
%   baselineData.createdAt
%   baselineData.cases(k).name
%   baselineData.cases(k).n_mech
%   baselineData.cases(k).T_soll
%   baselineData.cases(k).time
%   baselineData.cases(k).id_ref
%   baselineData.cases(k).iq_ref
%   baselineData.cases(k).strategie

    clc;

    modelName  = 'Hackl_Pilsen_Algo';
    initScript = 'Messdaten_Interpoliert';
    repoRoot   = localGetRepoRoot();
    baselineDir  = fullfile(repoRoot, 'baseline');
    baselineFile = fullfile(baselineDir, [modelName '_baseline.mat']);

    if ~exist(baselineDir, 'dir')
        mkdir(baselineDir);
    end

    addpath(genpath(repoRoot));

    % Definierte Betriebspunkte
    testCases = [ ...
        struct('name','case_1','n_mech',2000,'T_soll',50), ...
        struct('name','case_2','n_mech',7000,'T_soll',80), ...
        struct('name','case_3','n_mech',10000,'T_soll',100) ...
    ];

    % Initialisierung
    if exist([initScript '.m'], 'file') ~= 2
        error('Init-Skript nicht gefunden: %s.m', initScript);
    end
    run(initScript);

    if exist([modelName '.slx'], 'file') ~= 4 && exist([modelName '.mdl'], 'file') ~= 4
        error('Modell nicht gefunden: %s.slx', modelName);
    end

    load_system(modelName);

    baselineData = struct();
    baselineData.model = modelName;
    baselineData.createdAt = string(datetime('now'));
    baselineData.cases = repmat(struct( ...
        'name', "", ...
        'n_mech', [], ...
        'T_soll', [], ...
        'time', [], ...
        'id_ref', [], ...
        'iq_ref', [], ...
        'strategie', []), 1, numel(testCases));

    for k = 1:numel(testCases)
        tc = testCases(k);

        fprintf('\n====================================================\n');
        fprintf('Erzeuge Baseline: %s | n_mech=%g | T_soll=%g\n', ...
            modelName, tc.n_mech, tc.T_soll);

        simIn = Simulink.SimulationInput(modelName);

        % Basisvariablen in den Model-Workspace / SimulationInput geben
        simIn = simIn.setVariable('n_mech', tc.n_mech);
        simIn = simIn.setVariable('T_soll', tc.T_soll);

        % Optional: Fast Restart / Logging kannst du bei Bedarf ergänzen
        simOut = sim(simIn);

        [t_id, y_id] = localExtractSignal(simOut, 'id_ref');
        [t_iq, y_iq] = localExtractSignal(simOut, 'iq_ref');
        [t_st, y_st] = localExtractSignal(simOut, 'strategie');

        % Gemeinsame Zeitbasis prüfen
        t = t_id;
        if ~isequal(size(t_id), size(t_iq)) || any(abs(t_id - t_iq) > 1e-12)
            error('Zeitvektoren von id_ref und iq_ref stimmen nicht überein.');
        end
        if ~isequal(size(t_id), size(t_st)) || any(abs(t_id - t_st) > 1e-12)
            error('Zeitvektoren von id_ref und strategie stimmen nicht überein.');
        end

        baselineData.cases(k).name      = string(tc.name);
        baselineData.cases(k).n_mech    = tc.n_mech;
        baselineData.cases(k).T_soll    = tc.T_soll;
        baselineData.cases(k).time      = t(:);
        baselineData.cases(k).id_ref    = y_id(:);
        baselineData.cases(k).iq_ref    = y_iq(:);
        baselineData.cases(k).strategie = y_st(:);

        fprintf('Gespeichert: %d Samples\n', numel(t));
        fprintf('  id_ref(end)    = %.6f\n', baselineData.cases(k).id_ref(end));
        fprintf('  iq_ref(end)    = %.6f\n', baselineData.cases(k).iq_ref(end));
        fprintf('  strategie(end) = %.6f\n', baselineData.cases(k).strategie(end));
    end

    save(baselineFile, 'baselineData');

    fprintf('\n====================================================\n');
    fprintf('Baseline-Datei erzeugt:\n%s\n', baselineFile);
    fprintf('Inhalt:\n');
    whos baselineData
    disp(baselineData)
end

function [t, y] = localExtractSignal(simOut, signalName)
% Extrahiert ein Signal robust aus logsout, yout oder direkt aus simOut.

    % 1) logsout
    if isprop(simOut, 'logsout') || ismember('logsout', simOut.who)
        try
            logsout = simOut.logsout;
            sig = logsout.getElement(signalName);
            if ~isempty(sig)
                v = sig.Values;
                [t, y] = localConvertTimeseriesLike(v);
                return;
            end
        catch
        end
    end

    % 2) yout
    if isprop(simOut, 'yout') || ismember('yout', simOut.who)
        try
            yout = simOut.yout;
            if isa(yout, 'Simulink.SimulationData.Dataset')
                sig = yout.getElement(signalName);
                if ~isempty(sig)
                    v = sig.Values;
                    [t, y] = localConvertTimeseriesLike(v);
                    return;
                end
            end
        catch
        end
    end

    % 3) Direkt aus SimulationOutput
    try
        candidate = simOut.get(signalName);
        [t, y] = localConvertTimeseriesLike(candidate);
        return;
    catch
    end

    error('Signal "%s" wurde weder in logsout noch in yout noch direkt im SimulationOutput gefunden.', signalName);
end

function [t, y] = localConvertTimeseriesLike(candidate)
% Wandelt timeseries / timetable / numerische Daten in Zeitvektor + Datenvektor um.

    if isa(candidate, 'timeseries')
        t = candidate.Time;
        y = candidate.Data;
        y = squeeze(y);
        return;
    end

    if istimetable(candidate)
        t = seconds(candidate.Properties.RowTimes - candidate.Properties.RowTimes(1));
        y = candidate{:,1};
        y = squeeze(y);
        return;
    end

    if isnumeric(candidate)
        y = squeeze(candidate);
        t = (0:numel(y)-1).';
        return;
    end

    if isobject(candidate) && isprop(candidate, 'Time') && isprop(candidate, 'Data')
        t = candidate.Time;
        y = candidate.Data;
        y = squeeze(y);
        return;
    end

    error('Signalformat konnte nicht verarbeitet werden.');
end

function repoRoot = localGetRepoRoot()
% Repository-Root bestimmen

    repoRoot = getenv('GITHUB_WORKSPACE');
    if isempty(repoRoot)
        thisFile = mfilename('fullpath');
        repoRoot = fileparts(thisFile);
    end
end
