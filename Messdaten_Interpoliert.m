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

Ldd = double(L_dd);             % size = [id x iq]
Lqq = double(L_qq);             % size = [id x iq]
Psid = double(Psi_d);           % size = [id x iq]
Psiq = double(Psi_q);           % size = [id x iq]

%% 2. Interpolation der Matrizen Ld, Lq, Psid, Psiq erzeugen 

F_Ldd  = griddedInterpolant({iq_vec, id_vec}, Ldd, 'spline', 'nearest');
F_Lqq  = griddedInterpolant({iq_vec, id_vec}, Lqq, 'spline', 'nearest');
F_psid = griddedInterpolant({iq_vec, id_vec}, Psid,'spline', 'nearest');
F_psiq = griddedInterpolant({iq_vec, id_vec}, Psiq,'spline', 'nearest');

%% 3. Feines Gitter 200 x 200
% Erweitern der Achse
id_fine = linspace(min(id_vec), max(id_vec), 100);   
iq_fine = linspace(min(iq_vec), max(iq_vec), 100);

[ID, IQ] = meshgrid(id_fine, iq_fine);

%% 4. Interpolierte Werte auf feinem Gitter
Ldd_fine  = reshape(F_Ldd(IQ(:), ID(:)), size(IQ)); 
Lqq_fine  = reshape(F_Lqq(IQ(:), ID(:)), size(IQ));
Psid_fine = reshape(F_psid(IQ(:), ID(:)), size(IQ));
Psiq_fine = reshape(F_psiq(IQ(:), ID(:)), size(IQ));

%% 5.1 Lm1 = d(Psi_d)/d(iq) 
d_iq = iq_fine(2) - iq_fine(1);

Lm_fine1 = zeros(size(Psid_fine));
for j = 1:length(id_fine)
    Lm_fine1(2:end-1,j) = (Psid_fine(3:end,j) - Psid_fine(1:end-2,j)) / (2*d_iq);
    Lm_fine1(1,j)       = (Psid_fine(2,j) - Psid_fine(1,j)) / d_iq;
    Lm_fine1(end,j)     = (Psid_fine(end,j) - Psid_fine(end-1,j)) / d_iq;
end

%% 5.2 Lm2 = d(Psi_q)/d(id) 
psi_fine2 = Psiq_fine;   % nur q-Achsenfluss!

d_id = id_fine(2) - id_fine(1);

Lm_fine2 = zeros(size(psi_fine2));

for i = 1:length(iq_fine)

    Lm_fine2(i,2:end-1) = (psi_fine2(i,3:end) - psi_fine2(i,1:end-2)) / (2*d_id);

    Lm_fine2(i,1)   = (psi_fine2(i,2) - psi_fine2(i,1)) / d_id;
    Lm_fine2(i,end) = (psi_fine2(i,end) - psi_fine2(i,end-1)) / d_id;

end



%% 6. Parameter formatieren und exportieren  
% Abspeichern der berechneten Werte in einheitlichen Parametern
PSID = Psid_fine;
PSIQ1 = Psiq_fine;
Ld = Ldd_fine;
Lq = Lqq_fine;
Lm = Lm_fine1;
p = 3;

% PSIQ formatieren: leichter Offset aus LUT (ca 5A, iq=0 Zeile wird auf 0
% gezogen)
[~, iq0_idx] = min(abs(iq_fine));
PSIQ = PSIQ1 - PSIQ1(iq0_idx,:);   % zieht die iq=0-Zeile spaltenweise auf 0

% Exportieren der interpolierten Daten in 'daten_nichtlinear_interpoliert.mat'
save('daten_nichtlinear_interpoliert.mat', 'PSID', 'PSIQ', 'Lm', 'Lm_fine2','Ld', 'Lq', 'id_fine', 'iq_fine', 'ID', 'IQ');

