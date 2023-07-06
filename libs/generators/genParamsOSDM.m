function [params] = genParamsOSDM(BW_fmin, BW_fmax, BW_len, SIM_fmin, SIM_fmax, SIM_fstep, order, Nfft_order, nBitsAmp, troncature, fech, fWalsh, NRefresh)
%GENPARAMSOSDM cree une structure 'params' avec les parametres specifies.
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
%   - NRefresh:   Nombre de rafraichissements a generer
%
% RETOUR:
%   - params: Structure comprenant tous les parametres necessaires a la simulation
%
% Note:
%  Tous les champs de la structure ne sont pas utilises par tous les scripts.

%% Parametres Walsh
params.order         = order;              % Ordre de la transformee de Walsh
params.nCoeffs       = 2^params.order;     % Nombre de coefficients
params.nBitsAmp      = nBitsAmp;           % type amplitudes : int8
params.nAmp          = 2^params.nBitsAmp;  % Nombre d'amplitudes possibles
params.maxBin        = params.nAmp/2 - 1;  % Amplitude maximale
params.Amp           = 10;                 % Amplification du signal
params.W             = genWalsh(params.order); % Matrice de Walsh
params.troncature    = troncature;         % Nombre de coefficients tronques (false = aucun)
params.sparsify_amnt = 32;     
%% Parametres frequentiels

params.BW.span             = [BW_fmin, BW_fmax]; % bande visee, Hz


params.BW.usedLength         = BW_len; % Largeur de bande, MHz

% Parametres relatifs au masque de la bande n53
params.BW.middleFreq = (BW_fmax - BW_fmin)/2 + BW_fmin;             % milieu de la bande visee
params.BW.usedInterval        = [params.BW.middleFreq - params.BW.usedLength/2,...
                  params.BW.middleFreq + params.BW.usedLength/2];          % Bande utilisee, en nb de points de la fft

% Canaux adjacents
params.BW.first_oob  = [params.BW.usedInterval(1) - 1e6, params.BW.usedInterval(2) + 1e6]; % 1MHz autour de la bande
params.BW.second_oob = [params.BW.first_oob(1) - 4e6, params.BW.first_oob(2) + 4e6];   % 4 MHz autour de la bande
params.BW.third_oob  = [params.BW.second_oob(1) - 5e6, params.BW.second_oob(2) + 5e6]; % 5 MHz autour de la bande
params.BW.last_oob   = [params.BW.third_oob(1) - 5e6, params.BW.third_oob(2) + 5e6];   

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

params.freqAxis      = -params.fech/2:params.fech/params.Nfft:params.fech/2-params.fmax/params.Nfft;
params.norm_freqAxis = params.freqAxis/params.fech;


%% Parametres temporels
params.Tech_s     = 1/params.fech;     % s
params.TWalsh_s   = 1/params.fWalsh;   % s
params.TRefresh_s = 1/params.fRefresh; % s

params.Tech_e     = params.Tech_s * params.fech;     % echantillons
params.TWalsh_e   = params.TWalsh_s * params.fech;   % echantillons
params.TRefresh_e = params.TRefresh_s * params.fech; % echantillons


%% PARAMETRES CONFORMATION

params.rounded_BW1 = floor(params.BW.usedInterval(1)*params.freqAxis(end))/params.freqAxis(end);
params.rounded_BW2 = floor(params.BW.usedInterval(2)*params.freqAxis(end))/params.freqAxis(end);
params.diff_BW     = params.rounded_BW2 - params.rounded_BW1;

params.bw_axis                = params.rounded_BW1:params.fech/params.Nfft:params.rounded_BW2; % toutes les frequences a utiliser
params.duration_per_frequency = 1./params.bw_axis * params.fech;

params.nWalsh = NRefresh;

params.duration = params.nWalsh * params.TWalsh_s * params.nCoeffs; % s
params.Nech     = params.duration/params.Tech_s; % Nb d'echantillons
params.Tse      = 1/params.osr;      % temps entre deux ech. de Walsh

params.timeAxis                                                                     = 0:params.Tech_s:params.duration-params.Tech_s;
params.walsh_timeAxis                                                               = 0:params.TWalsh_s:params.duration - params.TWalsh_s;

% Pour afficher le masque sur les plots
params.BW_visible                                                                    = -25*ones(size(params.freqAxis));
params.BW_visible( params.freqAxis > params.BW.span(1) & params.freqAxis < params.BW.span(2)) = 0;
params.BW_visible((params.freqAxis > params.BW.span(2)            & params.freqAxis < params.BW.first_oob(2))  | (params.freqAxis < params.BW.span(1) & params.freqAxis            > params.BW.first_oob(1)))  = -13;
params.BW_visible((params.freqAxis > params.BW.first_oob(2)  & params.freqAxis < params.BW.second_oob(2)) | (params.freqAxis < params.BW.first_oob(1) & params.freqAxis  > params.BW.second_oob(1))) = -10;
params.BW_visible((params.freqAxis > params.BW.second_oob(2) & params.freqAxis < params.BW.third_oob(2))  | (params.freqAxis < params.BW.second_oob(1) & params.freqAxis > params.BW.third_oob(1)))  = -13;

params.max_coeff = zeros(size(params.bw_axis));    % coeff max par frequence

params.middle = find(params.freqAxis == 0);
params.start  = find(params.freqAxis > params.BW.span(1), 1);
params.stop   = find(params.freqAxis > params.BW.span(2), 1) - 1;
params.fs2    = find(params.freqAxis > params.fWalsh/2, 1) - 1;

%% PARAMETRES OSDM

% Mapping pour la 64 QAM
params.maps = genMapsQam64(params.BW.middleFreq, params);

% Nombre de coefficients a moduler
params.nModulatedCoeffs = 32;

end

