function [synchronizedSig] = coarseFreqSync(signal, startingSample, oversamplingRate)

alpha      = 1;      % constante de la boucle a verouillage de phase
beta       = 1e-2;   % constante de la boucle a verouillage de phase

loop_filter_b = beta;    % coeff du numérateur pour le filtre de boucle
loop_filter_a = [1 -1];  % coeff du dénominateur du filtre de boucle
int_filter_b  = [0 1];   % coeff du numérateur du filtre intégrateur
int_filter_a  = [1 -1];  % coeff du dénominateur du filtre intégrateur
M = 4;

rn = signal(startingSample:oversamplingRate:end); % Sous-echantillonnage minimisant l'IES
rn_M = rn.^M;                         % signal "rabattu"

phases = zeros(length(rn_M), 1);        % phase de chaque symbole
phases_exp = zeros(length(rn_M), 1);    % phase, comme exponentielle
phases_exp_q = zeros(length(rn_M),1);   % quart de la phase
en     = zeros(length(rn_M), 1);        % valeurs de en
vn     = zeros(length(rn_M), 1);        % valeurs de vn
reg_loop=0;                           % registres
reg_int=0;                            % registres
% Boucle
for i=1:length(rn_M)

    if i==1
        en(i) = imag(rn_M(i));
    else
        en(i) = imag(rn_M(i) * conj(phases_exp(i-1)));
    end

    % filtre de boucle
    [vn1, reg_loop] = filter(loop_filter_b, loop_filter_a, en(i), reg_loop);
    [vn2] = filter(alpha,1,en(i));
    vn(i) = vn1+vn2;

    % filtre intégrateur (/!\ phase = M * phi)
    [phase, reg_int] = filter(int_filter_b, int_filter_a, vn(i), reg_int);
    phases(i) = phase;
    phases_exp(i) = exp(1j * phase);
    phases_exp_q(i) = exp(-1j * phase/M);
end
% 
synchronizedSig = rn .* phases_exp_q.';