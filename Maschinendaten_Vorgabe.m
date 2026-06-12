%% Maschinendaten
% Hier werden die Maschinendaten geladen
% Bei Verwendung eines anderen Motors bitte Kenndaten hier anpassen: 

p = 3;                    % Polpaarzahl
Rs = 0.018;               % Statorwiderstand [Ohm]
I_max = 170;              % maximal zulässiger Strom [A]
U_dc = 560;               % Zwischenkreisspannung [V]
U_max = U_dc / sqrt(3);   % maximal zulässige Phasenspannung [V]
n_max = 11000;            % Maximaldrehzahl [U/min]

save('Maschinendaten.mat', 'p', 'Rs', 'I_max', 'U_dc', 'U_max', 'n_max');

% Variablen hinzufügen zu base workspace 
assignin('base','p',p);
assignin('base','Rs',Rs);
assignin('base','I_max',I_max);
assignin('base','U_dc',U_dc);
assignin('base','U_max',U_max);
assignin('base','n_max',n_max);
