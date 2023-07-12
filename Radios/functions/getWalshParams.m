function [params] = getWalshParams(generousMode)
%GETWALSHPARAMETERS genere les parametres pour communiquer via Walsh
% /!\ Fait pour fonctionner avec des radios ayant une masterClockRate a 10 MHz et un facteur
% d'interpolation/decimation a 4

if ~exist("generousMode", "var")
    generousMode=false;
end

params = struct();

params.fech = 2.5e6;     % Frequence d'echantillonnage de la radio
params.ref.fech = 8e9;   % Frequence d'echantillonnage de reference (celle du convertisseur)


params.conversionFactor = params.fech/params.ref.fech; % Rapport des freq. d'echantillonnage

params.order = 6; % Ordre de la transformee de Walsh
params.nCoeffs = 2^params.order; % Nombre de coefficients de la transformee de Walsh
params.W = genWalsh(params.order); % Matrice de Walsh
params.osr      = 1; % Facteur de surechantillonnage voulu pour le developpement en series de Walsh

params.targetDs = 10e6 * params.conversionFactor; % Debit symbole vise
params.targetTs = 1/params.targetDs;
params.Te = 1/params.fech;
params.fse = ceil(params.targetTs/params.Te);
params.nRefreshPerOSDMSymb = params.fse/params.nCoeffs;

if mod(params.nRefreshPerOSDMSymb, 2) == 1 % Compensation des cas impairs
    params.nRefreshPerOSDMSymb = params.nRefreshPerOSDMSymb + 1;
    params.fse               = params.fse+params.nCoeffs;
end

params.realTs           = params.fse*params.Te;
params.realDs           = ceil(1/params.realTs);

params.nSymbOSDMPerFrame = 1;           % symbols per frame

params.totalDuration    = nextWalshLength(ceil((params.nSymbOSDMPerFrame/params.realDs)*params.fech), params.nCoeffs); % signal duration
params.OSDMSymbolDuration = ceil(params.totalDuration/(params.nCoeffs*params.osr));




params.fWalsh = params.fech/params.osr; % Frequence "d'echantillonnage" de Walsh
params.fRefresh = params.fWalsh/(2^(params.order-1)); % Frequence de rafraichissement des echantillons de Walsh

params.NfftOrder = 14; % log2 du nombre de points de la FFT
params.Nfft = 2^params.NfftOrder; % Nombre de points de la FFT

params.freqAxis = -params.fech/2:params.fech/params.Nfft:params.fech/2-params.fech/params.Nfft; % Axe frequentiel

params.BW.start = floor(2.4825e9/params.osr * params.conversionFactor); % Debut de la bande de frequences qui nous est allouee
params.BW.end = ceil(2.495e9/params.osr * params.conversionFactor); % Fin de la bande de frequences qui nous est allouee

params.BW.span = [params.BW.start params.BW.end]; % Bande de frequences allouee

params.BW.usedLength = 10e6 * params.conversionFactor; % Bande utilisee dans la bande allouee

params.BW.middleFreq = (params.BW.end - params.BW.start)/2 + params.BW.start; % Milieu de la bande
params.BW.usedInterval = [params.BW.middleFreq - params.BW.usedLength/2,...
    params.BW.middleFreq + params.BW.usedLength/2]; % Bande utilisee autour de la frequence centrale
params.nFreqs = 10; % Nombre de frequences dans la bande a utiliser lors de l'estimation de coefficients porteurs

params.nBitsAmp = 8; % Nombre de bits d'amplitude dans le DAC
params.nAmp = 2^params.nBitsAmp; % Nombre d'amplitudes achevables par le DAC

params.maxBin = params.nAmp/2 - 1; % Plus grand entier signe atteignable sur nBitsAmp bits

firstOobLength  = 1e6 * (1+0.5*generousMode)/params.osr * params.conversionFactor; % Taille des bandes reglementaires autour de la bande qui nous est allouee 
secondOobLength = 4e6 * (1+0.5*generousMode)/params.osr * params.conversionFactor; % Taille des bandes reglementaires autour de la bande qui nous est allouee
thirdOobLength  = 5e6 * (1+0.5*generousMode)/params.osr * params.conversionFactor; % Taille des bandes reglementaires autour de la bande qui nous est allouee
lastOobLength   = thirdOobLength; % Taille des bandes reglementaires autour de la bande qui nous est allouee 

% "Mode genereux" : relache des contraintes sur les bandes de frequences (bande plus large, gabarit plus haut)
if generousMode
    warning("backtrace", "off");
    warning("Generous mode enabled. Frequency constraints are more relaxed.");
    warning("backtrace", "on");
end


generousModePenalty = 6;
firstOobMaxAmp = -13 + generousMode * generousModePenalty;  % Amplitude a ne pas depasser dans la bande adjacente associee
secondOobMaxAmp = -10 + generousMode * generousModePenalty; % Amplitude a ne pas depasser dans la bande adjacente associee
lastOobMaxAmp = -13 + generousMode * generousModePenalty;   % Amplitude a ne pas depasser dans la bande adjacente associee
spectrumMaxAmp = -25 + generousMode * generousModePenalty;  % Amplitude a ne pas depasser dans la bande adjacente associee

% Canaux adjacents
params.BW.first_oob  = [params.BW.span(1) - firstOobLength, params.BW.span(2) + firstOobLength]; 
params.BW.second_oob = [params.BW.first_oob(1) - secondOobLength, params.BW.first_oob(2) + secondOobLength];   
params.BW.third_oob  = [params.BW.second_oob(1) - thirdOobLength, params.BW.second_oob(2) + thirdOobLength]; 
params.BW.last_oob   = [params.BW.third_oob(1) - lastOobLength, params.BW.third_oob(2) + lastOobLength];   

% Pour afficher le masque sur les plots
params.BW_visible = spectrumMaxAmp*ones(size(params.freqAxis));
params.BW_visible( params.freqAxis > params.BW.span(1) & params.freqAxis < params.BW.span(2) ) = 0;
params.BW_visible( (params.freqAxis > params.BW.first_oob(1) & params.freqAxis < params.BW.span(1)) | ...
 (params.freqAxis > params.BW.span(2) & params.freqAxis < params.BW.first_oob(2)) )  = firstOobMaxAmp;
params.BW_visible( (params.freqAxis > params.BW.second_oob(1) & params.freqAxis < params.BW.first_oob(1)) | ...
 (params.freqAxis > params.BW.first_oob(2) & params.freqAxis < params.BW.second_oob(2))) = secondOobMaxAmp;
params.BW_visible( (params.freqAxis > params.BW.third_oob(1) & params.freqAxis < params.BW.second_oob(1)) | ...
 (params.freqAxis > params.BW.second_oob(2) & params.freqAxis < params.BW.third_oob(2)))  = lastOobMaxAmp;

params.Tech_s     = 1/params.fech;     % duree d'un echantillon, s
params.TWalsh_s   = 1/params.fWalsh;   % duree d'un "echantillon de Walsh", s
params.TRefresh_s = 1/params.fRefresh; % duree entre deux rafraichissements des coefficients de Walsh, s

params.Tech_e     = params.Tech_s * params.fech;     % duree d'un echantillon, en echantillons
params.TWalsh_e   = params.TWalsh_s * params.fech;   % duree d'un "echantillon de Walsh", en echantillons
params.TRefresh_e = params.TRefresh_s * params.fech; % duree entre deux rafraichissements des coefficients de Walsh, en echantillons

params.rounded_BW1 = floor(params.BW.usedInterval(1)*params.freqAxis(end))/params.freqAxis(end); % Arrondi des limites de la bande allouee sur les points de la FFT 
params.rounded_BW2 = floor(params.BW.usedInterval(2)*params.freqAxis(end))/params.freqAxis(end); % Arrondi des limites de la bande allouee sur les points de la FFT
params.diff_BW     = params.rounded_BW2 - params.rounded_BW1; % Longueur de la bande allouee sur notre axe frequentiel

params.bw_axis                = params.rounded_BW1:params.fech/params.Nfft:params.rounded_BW2; % bande allouee, sur l'axe frequentiel
params.duration_per_frequency = 1./params.bw_axis * params.fech; % duree d'une periode, pour chaque frequence de la bande


% Nombre de rafraichissements necessaires pour transformer un nombre rond de periodes de sinusoides
params.nWalsh = max(lcm(ceil(params.duration_per_frequency), ...
                          ceil(params.TRefresh_e)));

params.duration = params.nWalsh * params.TWalsh_s * params.nCoeffs; % duree du signal, s
params.Nech     = params.duration/params.Tech_s; % Nb d'echantillons
params.Tse      = 1/params.osr;      % temps entre deux ech. de Walsh

params.timeAxis = 0:params.Tech_s:params.duration-params.Tech_s; % Axe temporel

params.middle = find(params.freqAxis == 0); % Milieu de l'axe frequentiel
params.start  = find(params.freqAxis > params.BW.span(1), 1); % Indice de debut de la bande sur l'axe frequentiel
params.stop   = find(params.freqAxis > params.BW.span(2), 1) - 1; % Indice de fin de la bande sur l'axe frequentiel
params.fs2    = find(params.freqAxis > params.fWalsh/2, 1) - 1; % Frequence maximale du signal de Walsh sur la bande

% Mapping pour la 64 QAM
params.maps = genMapsQam64(params.BW.middleFreq, params);

end

