function [params] = genParams(BW_fmin, BW_fmax, BW_len, SIM_fmin, SIM_fmax, SIM_fstep, order, Nfft_order, nBitsAmp, troncature, fech, fWalsh)
%GENPARAMS cree une structure 'params' avec les parametres specifies.
%
% ARGS:
%   - BW_fmin:    frequence minimale de la bande visee, en Hz
%   - BW_fmax:    frequence maximale de la bande visee, en Hz
%   - BW_len:     Largeur de bande utile dans la bande visee, en Hz
%   - SIM_fmin:   frequence minimale simulee, en Hz
%   - SIM_fmax:   frequence maximale simulee, en Hz
%   - SIM_fstep:  Pas de frequence de la simulation, en Hz
%   - order:      Ordre de la transformee de Walsh
%   - Nfft_order: Ordre de la transformee de Fourier
%   - nBitsAmp:   Nombre de bits d'amplitude
%   - fech:       Frequence d'echantillonnage, Hz
%   - fWalsh:     Frequence des echantillons de Walsh, Hz
%
% RETOUR:
%   - params: Structure comprenant tous les parametres necessaires a la simulation

%% Parametres Walsh
params.order         = order;              % Ordre de la transformee de Walsh
params.nCoeff        = 2^params.order;     % Nombre de coefficients
params.nBitsAmp      = nBitsAmp;           % type amplitudes : int8
params.nAmp          = 2^params.nBitsAmp;  % Nombre d'amplitudes possibles
params.max_bin       = params.nAmp/2 - 1;  % Amplitude maximale
params.Amp           = 10;                 % Amplification du signal
params.W             = genWalsh(params.order); % Matrice de Walsh
params.troncature    = troncature;         % Nombre de coefficients tronques (false = aucun)
params.sparsify_amnt = 32;                 
%% Parametres frequentiels

params.BW             = [BW_fmin, BW_fmax]; % bande visee, Hz


params.BW_len         = BW_len; % Largeur de bande, MHz

% Parametres relatifs au masque de la bande n53
params.BW_middle_freq = (BW_fmax - BW_fmin)/2 + BW_fmin;             % milieu de la bande visee
params.BW_used        = [params.BW_middle_freq - params.BW_len/2,...
                  params.BW_middle_freq + params.BW_len/2];          % Bande utilisee, en nb de points de la fft

% Canaux adjacents
params.BW_first_oob  = [params.BW_used(1) - 1e6, params.BW_used(2) + 1e6]; % 1MHz autour de la bande
params.BW_second_oob = [params.BW_first_oob(1) - 4e6, params.BW_first_oob(2) + 4e6];   % 4 MHz autour de la bande
params.BW_third_oob  = [params.BW_second_oob(1) - 5e6, params.BW_second_oob(2) + 5e6]; % 5 MHz autour de la bande
params.BW_last_oob   = [params.BW_third_oob(1) - 5e6, params.BW_third_oob(2) + 5e6];   

params.fmin   = SIM_fmin;  % Hz
params.fmax   = SIM_fmax;  % Hz
params.fstep  = SIM_fstep; % Hz

params.nFreqs = 10; % frequences dans la bande a utiliser

params.fRange = params.fmin:params.fstep:params.fmax;

params.fWalsh   = fWalsh;    % frequence des coeffs de Walsh, Hz
params.fRefresh = params.fWalsh/(2^(params.order-1)); % Frequence de rafraichissement des coeffs de Walsh, Hz
params.fech     = fech; % frequence d'echantillonnage, Hz
params.osr      = ceil(params.fech/params.fWalsh);


if params.fmin < 0
    error("Frequence minimale invalide (doit etre positive)");
end

if params.fmin > params.fmax
    error("La frequence minimale doit etre inferieure a la frequence maximale");
end

if params.fmax > params.fWalsh
    error("La frequence maximale doit etre au maximum la frequence de Walsh (8 GHz)");
end

params.Nfft_order = Nfft_order;
params.Nfft       = 2^params.Nfft_order;

params.freq_axis      = -params.fech/2:params.fech/params.Nfft:params.fech/2-params.fmax/params.Nfft;
params.norm_freq_axis = params.freq_axis/params.fech;


%% Parametres temporels
params.Tech_s     = 1/params.fech;     % s
params.TWalsh_s   = 1/params.fWalsh;   % s
params.TRefresh_s = 1/params.fRefresh; % s

params.Tech_e     = params.Tech_s * params.fech;     % echantillons
params.TWalsh_e   = params.TWalsh_s * params.fech;   % echantillons
params.TRefresh_e = params.TRefresh_s * params.fech; % echantillons

%% PARAMETRES CONFORMATION
params.depth    = 5;  % coefficients a chercher
params.sfdr_in  = -10; % dB
params.sfdr_out = -3; % dB

params.rounded_BW1 = floor(params.BW_used(1)*params.freq_axis(end))/params.freq_axis(end);
params.rounded_BW2 = floor(params.BW_used(2)*params.freq_axis(end))/params.freq_axis(end);
params.diff_BW     = params.rounded_BW2 - params.rounded_BW1;

params.bw_axis                = params.rounded_BW1:params.fech/params.Nfft:params.rounded_BW2; % toutes les frequences a utiliser
params.duration_per_frequency = 1./params.bw_axis * params.fech; % duree d'une periode par frequence

% Nombre de rafraichissements necessaires pour transformer un nombre rond de periodes de sinusoides
params.nWalsh = max(lcm(ceil(params.duration_per_frequency), ...
                          ceil(params.TRefresh_e)));

params.duration = params.nWalsh * params.TWalsh_s * params.nCoeff; % duree du signal, s
params.Nech     = params.duration/params.Tech_s; % Nb d'echantillons
params.Tse      = 1/params.osr;      % temps entre deux ech. de Walsh

params.time_axis                                                                     = 0:params.Tech_s:params.duration-params.Tech_s;
params.walsh_time_axis                                                               = 0:params.TWalsh_s:params.duration - params.TWalsh_s;

% Pour afficher le masque sur les plots
params.BW_visible                                                                    = -25*ones(size(params.freq_axis));
params.BW_visible( params.freq_axis > params.BW(1) & params.freq_axis < params.BW(2)) = 0;
params.BW_visible((params.freq_axis > params.BW(2)            & params.freq_axis < params.BW_first_oob(2))  | (params.freq_axis < params.BW(1) & params.freq_axis            > params.BW_first_oob(1)))  = -13;
params.BW_visible((params.freq_axis > params.BW_first_oob(2)  & params.freq_axis < params.BW_second_oob(2)) | (params.freq_axis < params.BW_first_oob(1) & params.freq_axis  > params.BW_second_oob(1))) = -10;
params.BW_visible((params.freq_axis > params.BW_second_oob(2) & params.freq_axis < params.BW_third_oob(2))  | (params.freq_axis < params.BW_second_oob(1) & params.freq_axis > params.BW_third_oob(1)))  = -13;

params.max_coeff = zeros(size(params.bw_axis));    % coeff max par frequence

params.middle = find(params.freq_axis == 0);
params.start  = find(params.freq_axis > params.BW(1), 1);
params.stop   = find(params.freq_axis > params.BW(2), 1) - 1;
params.fs2    = find(params.freq_axis > params.fWalsh/2, 1) - 1;

end

