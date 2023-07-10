%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ce script realise la synchronisation manuelle d'un signal recu module en QPSK.
%
% Le signal recu doit contenir une trame avec les informations d'intensite en niveaux de gris d'une image 128x128
% pixels. Si la trame est plus courte, l'imag esera zero-paddee. Si elle est trop longue, elle sera tronquee.
%
% La synchronisation manuelle se fait en plusieurs etapes :
%
%   - La selection d'un point de depart pour le signal dans l'un des deux buffers du recepteur. Ce point de depart
%   doit etre choisi a moins de 2000 echantillons du preambule pour des resultats optimaux (zoomer et choisir un
%   indice d'echantillon le plus proche possible)
%   - La synchronisation temporelle grossiere : a partir des parametres de surechantillonnage fournis a la radio
%   emetteur, le script propose des constellations pour chaque instant de surechantillonnage, et l'utilisateur
%   choisit l'instant proposant la constellation la plus proche. Cela permet de minimiser l'Interference Entre Symboles
%   (IES)
%   - La synchronisation frequentielle grossiere consiste en une PLL "magique" qui elimine le decalage de phase sur le
%   signal.
%   - La synchronisation temporelle fine utilise le preambule (bitSynchro.mat) pour detecter le debut du signal par
%   une formule d'intercorrelation simplifiee. /!\ En fonction de la facon dont a ete genere bitSynchro.mat, il est
%   possible que ce preambule se retrouve dans le signal, creant un "faux positif" pour la detection du preambule.
%   - La synchronisation frequentielle fine utilise le preambule detecte et le compare au preambule genere via
%   bitSynchro.mat pour calculer le dephasage entre les deux constellations. Ce dephasage doit etre applique lors de la
%   demodulation pour retrouver les symboles originaux.
%
% Enfin, l'image est restauree via une conversion des bits estimes en nouveaux pixels.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; clc; close all; dbstop if error;

setPath();

%% CHOIX DU DEBUT DU SIGNAL

load bitSynchro.mat
file = "img_rx_no_clock_no_pps_rrc";

load(file, "buffer1", "buffer2", "commParams");

% Affichage des parties reelles et imaginaires des deux buffers.
% Cette etape permet aussi de verifier qu'il n'y a pas eu saturation de l'ADC au recepteur
% (amplitude du signal egale a 1), et d'ajuster en consequence le gain du recepteur.
figure();
subplot(2, 2, 1)
plot(real(buffer1(:)));
title("RealB1");

subplot(2, 2, 2)
plot(real(buffer2(:)));
title("RealB2");

subplot(2,2,3)
plot(imag(buffer1(:)));
title("ImB1");

subplot(2,2,4)
plot(imag(buffer2(:)));
title("ImB2");

%%
close all; % Fermeture du premier plot

startIdx = 2686720; % A REMPLACER PAR LA VALEUR LUE DANS LA PREMIERE "PARTIE"

sig = buffer2;
sig = sig(startIdx:end);

%% CHARGEMENT DES PARAMETRES ET SYNCHRONISATION TEMPORELLE GROSSIERE

% Version "ancien recepteur" 
if ~exist("commParams", "var")
    commParams = getCommParams('rx'); % Parametres de la communication
end

% Version "nouveau recepteur"
% Rien a faire, commParams est deja dans le fichier de sauvegarde

fech      = commParams.samplingFreq;  % frequence d'echantillonnage, Hz
Nfft      = 2^14;                     % Nb de points de la FFT
M = 4;                                % Ordre de la modulation (QPSK = 4)

% Instantiation du descrambler
descrambler = comm.Descrambler( ...
    "CalculationBase", commParams.scramblerBase, ...         % Base de calcul (binaire, base 10...)
    "Polynomial", commParams.scramblerPolynomial, ...        % Polynome du descrambler (branchement des memoires)
    "InitialConditions", commParams.scramblerInitState, ...  % Contenu des memoires lors de l'instantiation du descrambler
    "ResetInputPort", commParams.scramblerResetPort);        % Ajout d'un port "RESET" au descrambler


g = commParams.g; % Filtre de mise en forme utilise lors de la transmission
freqAxis = -fech/2 : fech/Nfft : fech/2 - fech/Nfft; % Axe frequentiel pour la FFT

alpha      = 1;      % constante de la boucle a verouillage de phase
beta       = 1e-2;   % constante de la boucle a verouillage de phase

loop_filter_b = beta;    % coeff du numérateur pour le filtre de boucle
loop_filter_a = [1 -1];  % coeff du dénominateur du filtre de boucle
int_filter_b  = [0 1];   % coeff du numérateur du filtre intégrateur
int_filter_a  = [1 -1];  % coeff du dénominateur du filtre intégrateur

% Filtrage adapte du signal recu
sig = conv(sig, g);

clear b01 b02; % liberation memoire

% Synchro temporelle grossiere
figure("Name", "Scatterplots", "Position", get(0, "ScreenSize"))
for i=1:commParams.fse
    subplot(4, 4, i) % /!\ les deux premieres valeurs du subplot doivent etre changees pour que leur produit soit inferieur ou egal a commParams.fse

    % Affichage de la constellation, normalisee
    % les ".^M" sont un test et peuvent etre retires
    % Si le ".^M" est laisse, il faut voir l'instant ou un seul groupe de points est present
    % S'il est retire, il faut en voir 4, comme dans une constellation de QPSK classique
    plot(real(sig(i+1000:commParams.fse:i+1300).^M./max(abs(sig.^M))), ...
         imag(sig(i+1000:commParams.fse:i+1300).^M./max(abs(sig.^M))), ' o');
    xlim([-1 1])
    ylim([-1 1])
    axis square
end

idxSurech = 1; % REMPLACER PAR L'INDICE MINIMISANT L'IES

sig = sig(idxSurech:4:end); % sous-echantillonnage du signal recu a l'instant Ts

%% SYNCHRO FREQUENTIELLE GROSSIERE
% Gere par une PLL
% cf. TS218, Cours 2 (https://rtajan.github.io/ts218/)

rn = sig.^M;                          % signal "rabattu"

phases = zeros(length(rn), 1);        % phase de chaque symbole
phases_exp = zeros(length(rn), 1);    % phase, comme exponentielle
phases_exp_q = zeros(length(rn),1);   % quart de la phase
en     = zeros(length(rn), 1);        % valeurs de en
vn     = zeros(length(rn), 1);        % valeurs de vn
reg_loop=0;                           % registres
reg_int=0;                            % registres

% Boucle
for i=1:length(rn)

    if i==1
        en(i) = imag(rn(i));
    else
        en(i) = imag(rn(i) * conj(phases_exp(i-1)));
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

sig = sig .* phases_exp_q.';

scatterplot(sig);

%% SYNCHRO TEMPORELLE FINE

phaseoffset = pi/4; % Decalage de phase pour la modulation QPSK

preambleSymb = pskmod(bitSynchro, M, phaseoffset, InputType="bit"); % Preambule module
N = length(preambleSymb);

p = intercorr(sig,preambleSymb); % Calcul d'intercorrelation simplifie entre le signal et le preambule genere
[mval,midx] = max(abs(p));       % Recherche du maximum d'intercorrelation


% récupération des 65536 symboles de l'image
pilote_rx = sig(midx:midx + N-1); % Extraction du pilote
sig_rx = sig(midx+N:end);         % Extraction de ce que l'on suppose etre l'image

%% SYNCHRO FREQUENTIELLE FINE
% Calcul du decalage de phase entre la sequence pilote extraite et generee
% Moyennage de ce decalage pour en obtenir une valeur fiable
err = 1/N * sum(pilote_rx .* conj(preambleSymb)./abs(preambleSymb).^2);
phase_orig = angle(err);

% Fenetrage sur notre image
sig_rx = sig_rx(1:65536);

% Conversion du signal extrait en image
Img = symbols2img(sig_rx, descrambler, phase_orig, commParams);

% Affichage, et on est contents
figure
imshow(uint8(Img));