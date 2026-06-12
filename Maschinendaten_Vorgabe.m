%% Maschinendaten
% Hier werden die Maschinendaten geladen
% Bei Verwendung eines anderen Motors bitte Kenndaten hier anpassen: 

scriptDir = fileparts(mfilename('fullpath'));

p = 3;                    % Polpaarzahl
Rs = 0.018;               % Statorwiderstand [Ohm]
I_max = 170;              % maximal zulässiger Strom [A]
U_dc = 560;               % Zwischenkreisspannung [V]
U_max = U_dc / sqrt(3);   % maximal zulässige Phasenspannung [V]
n_max = 11000;            % Maximaldrehzahl [U/min]

% save('Maschinendaten.mat', 'p', 'Rs', 'I_max', 'U_dc', 'U_max', 'n_max');
save(fullfile(scriptDir, 'Maschinendaten.mat'), 'p', 'Rs', 'I_max', 'U_dc', 'U_max', 'n_max');
