function [params] = defaultParams()
%GENPARAMS permet de generer les parametres par defaut pour faire des simulations
%d'OSDM dans la bande n53.

% Valeurs par defaut pour la bande n53

BW_fmin = 2.4825e9; % Debut de la bande passante
BW_fmax = 2.495e9;  % Fin de la bande passante
BW_len  = 10e6;     % Largeur de bande utilisee dans la bande allouee
SIM_fmin = 1e9;     % Frequence minimale a generer  
SIM_fmax = 8e9;     % Frequence maximale a generer
SIM_fstep = 250e6;  % Pas de frequences
ordre = 6;          % Ordre de la matrice de Walsh
Nfft_order = 14;    % Ordre de la fft
nBitsAmp = 8;       % Nombre de bits de quantification
troncature = false; % Nombre de coeffs à tronquer (false = aucun)
fech = 8e9;         % Freq. d'echantillonnage
fwalsh = 8e9;       % Freq. de Walsh

params = genParams(BW_fmin, BW_fmax, BW_len, SIM_fmin, SIM_fmax, SIM_fstep, ordre, Nfft_order, nBitsAmp, troncature, fech, fwalsh);

end
%{ 
+=============+
| ANCIEN CODE |
+=============+

%% Parametres Walsh
params.order    = 6;    % Ordre de la transformee de Walsh
params.nCoeff   = 2^params.order;
params.nBitsAmp = 8;    % type amplitudes : int8
params.nAmp     = 2^params.nBitsAmp;
params.max_bin  = params.nAmp/2 - 1;
params.Amp      = 10;
params.W        = genWalsh(params.order);
%% Parametres frequentiels

params.BW    = [BW_fmin, BW_fmax]; % Hz
params.fmin  = SIM_fmin; % Hz
params.fmax  = SIM_fmax; % Hz
params.fstep = SIM_fstep; % Hz

params.fRange = params.fmin:params.fstep:params.fmax;

params.fWalsh   = 8e9;    % Hz
params.fRefresh = params.fWalsh/params.nCoeff;
params.fech     = 16e9;   % Hz
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

params.Nfft_order = 12;
params.Nfft       = 2^params.Nfft_order;

params.freq_axis      = -params.fech/2:params.fech/params.Nfft:params.fech/2-params.fmax/params.Nfft;
params.norm_freq_axis = params.freq_axis/params.fech;


%% Parametres temporels
params.Tech_s     = 1/params.fech;     % s
params.TWalsh_s   = 1/params.fWalsh;   % s
params.TRefresh_s = 1/params.fRefresh; % s

params.Tech_e     = params.Tech_s * params.fech;
params.TWalsh_e   = params.TWalsh_s * params.fech;
params.TRefresh_e = params.TRefresh_s * params.fech;

params.duration_per_frequency = 1./params.fRange * params.fech;

params.NWalsh = max(lcm(ceil(params.duration_per_frequency), ...
                          params.TRefresh_e));

params.duration = params.NWalsh * params.TWalsh_s * params.nCoeff; % s
params.Nech     = params.duration/params.Tech_s; % Nb echantillons
params.Tse      = 1/params.osr;      % temps entre deux ech. de Walsh

params.time_axis       = 0:params.Tech_s:params.duration-params.Tech_s;
params.walsh_time_axis = 0:params.TWalsh_s:params.duration - params.TWalsh_s;

%% PARAMETRES CONFORMATION
params.depth    = 5;  % coefficients a chercher
params.sfdr_in  = 10; % dB
params.sfdr_out = 40; % dB

size_bw = params.BW(2) - params.BW(1);

params.bw_axis = params.BW(1):size_bw/params.Nfft:params.BW(2); % toutes les frequences a utiliser

params.max_coeff = zeros(size(params.bw_axis));    % coeff max par frequence
end

%}