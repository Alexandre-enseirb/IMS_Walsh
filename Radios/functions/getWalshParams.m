function [params] = getWalshParams()
%GETWALSHPARAMETERS genere les parametres pour communiquer via Walsh
% /!\ Fait pour fonctionner avec des radios ayant une masterClockRate a 10 MHz et un facteur
% d'interpolation/decimation a 4

params = struct();

params.fWalsh = 1.25e6;
params.fech = 2.5e6;

params.order = 6;
params.nCoeffs = 2^params.order;

params.fRefresh = params.fWalsh/(2^(params.order-1));
params.osr      = ceil(params.fech/params.fWalsh);

params.NfftOrder = 14;
params.Nfft = 2^params.NfftOrder;

params.freqAxis = -params.fech/2:params.fech/params.Nfft:params.fech/2-params.fech/params.Nfft;

params.BW.start = 3.8789e5;
params.BW.end = 3.89843e5;

params.BW.span = [params.BW.start params.BW.end];

params.BW.usedLength = 1562.5;

params.BW.middleFreq = (params.BW.end - params.BW.start)/2 + params.BW.start;
params.BW.usedInterval = [params.BW.middleFreq - params.BW.usedLength/2,...
    params.BW.middleFreq + params.BW.usedLength/2];
params.nFreqs = 10; % frequences dans la bande a utiliser


params.nBitsAmp = 8;
params.nAmp = 2^params.nBitsAmp;

params.maxBin = params.nAmp/2 - 1;

params.W = genWalsh(params.order);

% Canaux adjacents
params.BW.first_oob  = [params.BW.span(1) - 156.25, params.BW.span(2) + 156.25]; % 10 kHz autour de la bande
params.BW.second_oob = [params.BW.first_oob(1) - 625, params.BW.first_oob(2) + 625];   % 40 kHz autour de la bande
params.BW.third_oob  = [params.BW.second_oob(1) - 781.25, params.BW.second_oob(2) + 781.25]; % 50 kHz autour de la bande
params.BW.last_oob   = [params.BW.third_oob(1) - 781.25, params.BW.third_oob(2) + 781.25];   

% Pour afficher le masque sur les plots
params.BW_visible = -25*ones(size(params.freqAxis));
params.BW_visible( params.freqAxis > params.BW.span(1) & params.freqAxis < params.BW.span(2)) = 0;
params.BW_visible((params.freqAxis > params.BW.span(2) & params.freqAxis < params.BW.first_oob(2))  | (params.freqAxis < params.BW.span(1) & params.freqAxis > params.BW.first_oob(1)))  = -13;
params.BW_visible((params.freqAxis > params.BW.second_oob(2)  & params.freqAxis < params.BW.second_oob(2)) | (params.freqAxis < params.BW.first_oob(1) & params.freqAxis  > params.BW.second_oob(1))) = -10;
params.BW_visible((params.freqAxis > params.BW.second_oob(2) & params.freqAxis < params.BW.third_oob(2))  | (params.freqAxis < params.BW.second_oob(1) & params.freqAxis > params.BW.third_oob(1)))  = -13;

params.Tech_s     = 1/params.fech;     % s
params.TWalsh_s   = 1/params.fWalsh;   % s
params.TRefresh_s = 1/params.fRefresh; % s

params.Tech_e     = params.Tech_s * params.fech;     % echantillons
params.TWalsh_e   = params.TWalsh_s * params.fech;   % echantillons
params.TRefresh_e = params.TRefresh_s * params.fech; % echantillons

params.rounded_BW1 = floor(params.BW.usedInterval(1)*params.freqAxis(end))/params.freqAxis(end);
params.rounded_BW2 = floor(params.BW.usedInterval(2)*params.freqAxis(end))/params.freqAxis(end);
params.diff_BW     = params.rounded_BW2 - params.rounded_BW1;

params.bw_axis                = params.rounded_BW1:params.fech/params.Nfft:params.rounded_BW2; % toutes les frequences a utiliser
params.duration_per_frequency = 1./params.bw_axis * params.fech; % duree d'une periode par frequence


% Nombre de rafraichissements necessaires pour transformer un nombre rond de periodes de sinusoides
params.nWalsh = max(lcm(ceil(params.duration_per_frequency), ...
                          ceil(params.TRefresh_e)));

params.duration = params.nWalsh * params.TWalsh_s * params.nCoeffs; % duree du signal, s
params.Nech     = params.duration/params.Tech_s; % Nb d'echantillons
params.Tse      = 1/params.osr;      % temps entre deux ech. de Walsh

params.timeAxis = 0:params.Tech_s:params.duration-params.Tech_s;

params.rounded_BW1 = floor(params.BW.usedInterval(1)*params.freqAxis(end))/params.freqAxis(end);
params.rounded_BW2 = floor(params.BW.usedInterval(2)*params.freqAxis(end))/params.freqAxis(end);
params.diff_BW     = params.rounded_BW2 - params.rounded_BW1;

params.bw_axis                = params.rounded_BW1:params.fech/params.Nfft:params.rounded_BW2; % toutes les frequences a utiliser
params.duration_per_frequency = 1./params.bw_axis * params.fech;

params.nWalsh = 400;

params.duration = params.nWalsh * params.TWalsh_s * params.nCoeffs; % s
params.Nech     = params.duration/params.Tech_s; % Nb d'echantillons
params.Tse      = 1/params.osr;      % temps entre deux ech. de Walsh

params.middle = find(params.freqAxis == 0);
params.start  = find(params.freqAxis > params.BW.span(1), 1);
params.stop   = find(params.freqAxis > params.BW.span(2), 1) - 1;
params.fs2    = find(params.freqAxis > params.fWalsh/2, 1) - 1;

end

