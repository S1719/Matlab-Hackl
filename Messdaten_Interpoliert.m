%% 2D-Interpolation der LUT-Daten und Export für das Simulink-Modell
% Diese Datei lädt die ursprüngliche LUT, interpoliert alle relevanten
% Kennfelder auf ein feineres Gitter und speichert die aufbereiteten
% Daten für die weitere Verwendung im Simulink-Modell.
%
% Eingabedatei:
%   - LUT_BRUSA_jax_grad.mat
%
% Ausgabedatei:
%   - daten_nichtlinear_interpoliert.mat

%% 1. LUT laden 
load('LUT_BRUSA_jax_grad.mat'); % alle Werte anpassen auf double (statt int16)  

id_vec = double(i_d_vec);       % id-Achse 
iq_vec = double(i_q_vec);       % iq-Achse

Ldd1 = double(L_dd);             % size = [id x iq]
Lqq1 = double(L_qq);             % size = [id x iq]
Ldq1 = double(L_dq);             % size = [id x iq]
Lqd1 = double(L_qd);             % size = [id x iq]
Psid1 = double(Psi_d);           % size = [id x iq]
Psiq1 = double(Psi_q);           % size = [id x iq]

%% 2. Interpolation der Matrizen Ld, Lq, Psid, Psiq erzeugen 
% Felder: Spalten =  id (später x-Achse), Zeilen = iq (Später y-Achse);

F_Ldd  = griddedInterpolant({iq_vec, id_vec}, Ldd1, 'spline', 'nearest');
F_Lqq  = griddedInterpolant({iq_vec, id_vec}, Lqq1, 'spline', 'nearest');
F_Ldq  = griddedInterpolant({iq_vec, id_vec}, Ldq1, 'spline', 'nearest');
F_Lqd  = griddedInterpolant({iq_vec, id_vec}, Lqd1, 'spline', 'nearest');
F_psid = griddedInterpolant({iq_vec, id_vec}, Psid1,'spline', 'nearest');
F_psiq = griddedInterpolant({iq_vec, id_vec}, Psiq1,'spline', 'nearest');

%% 3. Feines Gitter 200 x 200
% Erweitern der Achse
id_fine = linspace(min(id_vec), max(id_vec), 100);   
iq_fine = linspace(min(iq_vec), max(iq_vec), 100);

[ID, IQ] = meshgrid(id_fine, iq_fine);

%% 4. Interpolierte Werte auf feinem Gitter
Ldd_fine  = reshape(F_Ldd(IQ(:), ID(:)), size(IQ)); 
Lqq_fine  = reshape(F_Lqq(IQ(:), ID(:)), size(IQ));
Ldq_fine  = reshape(F_Ldq(IQ(:), ID(:)), size(IQ)); 
Lqd_fine  = reshape(F_Lqd(IQ(:), ID(:)), size(IQ));
Psid_fine = reshape(F_psid(IQ(:), ID(:)), size(IQ));
Psiq_fine = reshape(F_psiq(IQ(:), ID(:)), size(IQ));

%% 6. Parameter formatieren und exportieren  
% Abspeichern der berechneten Werte in einheitlichen Parametern
Psid = Psid_fine;
Psiq = Psiq_fine;
Ldd = Ldd_fine;
Lqq = Lqq_fine;
Ldq = Ldq_fine;
Lqd = Lqd_fine;
p = 3;
delta_id = id_fine(2)-id_fine(1);
delta_iq = iq_fine(2)-iq_fine(1);

% PSIQ formatieren: leichter Offset aus LUT (ca 5A, iq=0 Zeile wird auf 0
% gezogen)
% [~, iq0_idx] = min(abs(iq_fine));
% Psiq = Psiq2 - Psiq2(iq0_idx,:);   % zieht die iq=0-Zeile spaltenweise auf 0

% Exportieren der interpolierten Daten in 'daten_nichtlinear_interpoliert.mat'
save('daten_nichtlinear_interpoliert.mat', 'Psid', 'Psiq', 'Ldd', 'Lqq','Ldq', 'Lqd', 'id_fine', 'iq_fine', 'ID', 'IQ', 'F_psid','F_psiq','delta_id', 'delta_iq');

