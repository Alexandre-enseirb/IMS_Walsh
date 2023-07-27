function [params] = getWalshParams(generousMode)
%GETWALSHPARAMETERS genere les parametres pour communiquer via Walsh
% /!\ Fait pour fonctionner avec des radios ayant une masterClockRate a 10 MHz et un facteur
% d'interpolation/decimation a 4

if ~exist("generousMode", "var")
    generousMode=false;
end

params = struct();

params.fech = 8e9;     % Frequence d'echantillonnage de la radio
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

%% Ancien masque
% Note : Je laisse cette partie du code pour afficher l'ancien masque.
% Ce masque est encore utilise par la majorite des scripts, notamment la variable BW_visible
% Cependant, ce n'est pas celui que l'on est senses respecter, puisqu'il est defini pour les appareils mobiles
% et non pour les stations de base.
% Le masque defini par la suite (excepte la version "generousMode", qui est laissee pour des raisons de compatibilite mais inutilisee)
% est issu du tableau 6.5.3.3.3.21-1, page 544 de la documentation de l'ETSI pour les equipements utilisateurs en 5G (2021-02)
% https://www.etsi.org/deliver/etsi_ts/138500_138599/13852101/16.06.00_60/ts_13852101v160600p.pdf

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

%% Nouveau masque
% Le nouveau masque est associe aux stations de base.
% Il s'agit du masque associe aux stations de base de categorie A (a puissance limitee), pour des communications
% a bande superieure a 1 GHz.
% Il est defini dans le tableau 6.6.4.2.1-1 de la documentation de l'ETSI relative aux stations de base en 5G (2019-05)
% https://www.etsi.org/deliver/etsi_ts/138100_138199/138104/15.05.00_60/ts_138104v150500p.pdf (page 56)

params.Mask.MeasurementBandwidth=100e3; % 100 kHz
params.Mask.BandsWidth = 5e6; % 5 MHz de bande pour les "oob"

distanceToLeftEdge = params.BW.start - params.freqAxis;
distanceToRightEdge = params.freqAxis - params.BW.end;

pointsInFirstOobLeft = find(distanceToLeftEdge < params.Mask.BandsWidth & distanceToLeftEdge > 0); % premiere bande a gauche de la bande passante 
pointsInFirstOobRight = find(distanceToRightEdge < params.Mask.BandsWidth & distanceToRightEdge > 0); % premiere bande a droite de la bande passante
slopeLeft = -7 - 7/5 * ( (distanceToLeftEdge(pointsInFirstOobLeft)) / 1e6 - 0.05 );
slopeRight = -7 - 7/5 * ( (distanceToRightEdge(pointsInFirstOobRight)) / 1e6 - 0.05 );

params.Mask.visible = -13 * ones(size(params.freqAxis));

params.Mask.visible(distanceToLeftEdge < 0 & distanceToRightEdge < 0) = Inf;
params.Mask.visible(pointsInFirstOobLeft) = slopeLeft;
params.Mask.visible(pointsInFirstOobRight) = slopeRight;
params.Mask.visible(distanceToLeftEdge < 2* params.Mask.BandsWidth & distanceToLeftEdge >= params.Mask.BandsWidth) = -14;
params.Mask.visible(distanceToRightEdge < 2* params.Mask.BandsWidth & distanceToRightEdge >= params.Mask.BandsWidth) = -14;

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

% Taille des clusters pour l'OSDM
params.cluster1Size = 4;
params.cluster2Size = 32;
params.cluster3Size = params.nCoeffs - params.cluster1Size - params.cluster2Size;
end

