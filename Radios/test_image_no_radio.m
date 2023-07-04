%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file aims to test image transmission without any radio.
%
% All the transmission is done locally, using the same parameters and code as with the radios, but without any
% hazards due to the radio's circuits.
%
% The channel is supposed to be a AWGN with a high SNR (> 15 dB). This value can be tuned later to test edge cases
% for the synchronization.
%
% A scrambler is added compared to the current radio code to test whether it is more effective with or not.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; clc; close all; dbstop if error;

setPath();
%% PARAMETERS

load bitSynchro.mat;

commParamsTx = getCommParams('tx');
radioParamsTx = getRadioParams('tx');

radioParamsRx = getRadioParams('rx');
commParams  = getCommParams('rx');

M = 4;
phaseoffset = pi/4;

SNRdB = 15;
SNR = 10^(SNRdB/10);

bpi = 8; % uint8

%% TRANSMITTER

img = imread("walsh.png");
img = img(:,:,1);

img_v = img(:);
img_b = int2bit(img_v, bpi, true);

n0 = sum(img_b == 0);
n1 = sum(img_b == 1);

p0 = n0/numel(img_b);
p1 = n1/numel(img_b);

entropy = - (p0*log2(p0) + p1*log2(p1));

figure();
imagesc(reshape(reshape(img_b, 4, []), [], 128));
colormap gray;

img_b = reshape(img_b.', 2, []).';

msg = pskmod(img_b.', M, phaseoffset, InputType='bit').';

% preamble = repmat([0; 1; 2; 3], 25, 1);
preambleSymb = pskmod(bitSynchro, M, phaseoffset, InputType="bit");

symbs = [preambleSymb.'; msg];

symbsUpsampled = upsample(symbs, commParamsTx.fse);
symbsFiltered = conv(symbsUpsampled, commParamsTx.g);

% Traitement du signal avant l'envoi

tx_signal = symbsFiltered;
tx_signal_norm = tx_signal./max(max(real(tx_signal)), max(imag(tx_signal)));

%% CHANNEL

sigPower = 1/length(tx_signal_norm) * sum(abs(tx_signal_norm).^2);

noisePower = sigPower/SNR;

b = sqrt(noisePower)/2 * randn(size(tx_signal_norm)) + 1j * sqrt(noisePower)/2 * randn(size(tx_signal_norm));

%% RECEIVER

sig = tx_signal_norm + b;

params = getCommParams('rx'); % Params used during communication

fech      = params.samplingFreq;      % Sampling frequency, Hz
Nfft      = 2^14;                                   % fft points 
M = 4;

% g = rcosdesign(roll_off, span, sps, 'sqrt');
g = params.g;
freqAxis = -fech/2 : fech/Nfft : fech/2 - fech/Nfft; % Frequency axis

alpha      = 1e-8;      % constante de la boucle a verouillage de phase
beta       = 1e-4;   % constante de la boucle a verouillage de phase

loop_filter_b = beta;    % coeff du numérateur pour le filtre de boucle
loop_filter_a = [1 -1];  % coeff du dénominateur du filtre de boucle
int_filter_b  = [0 1];   % coeff du numérateur du filtre intégrateur
int_filter_a  = [1 -1];  % coeff du dénominateur du filtre intégrateur

sig = conv(sig, g);

clear b01 b02;

figure("Name", "Scatterplots", "Position", get(0, "ScreenSize"))
for i=1:params.fse
    subplot(2, 2, i)
    plot(real(sig(i+1000:params.fse:i+1300)./max(abs(sig))), imag(sig(i+1000:params.fse:i+1300)./max(abs(sig))), ' o');
    xlim([-1 1])
    ylim([-1 1])
    axis square
end
% figure("Name", "Sampling of received signal", "Position", get(0, "ScreenSize"))
% plot(real(sig), "DisplayName", "Rx signal");
% hold on; grid on;
% stem(real(upsample(sig(30:40:end), 10)), "DisplayName", "Kept samples");
% legend("Interpreter","latex", FontSize=22);
% xlabel("Samples", FontSize=22, Interpreter="latex");
% ylabel("Amplitude", FontSize=22, Interpreter="latex");
% xlim([50000 50100]);

sig = sig(1:params.fse:end); % clock, pps, no burst

% sig = sig(6:20:end); % clock, pps, burst


% sig = sig(5:10:end); % clock no pps
%% synchro frequentielle grossiere
% Inutile, la source de 10 MHz externe nous garantit une constellation "propre"

% freqSync = comm.CarrierSynchronizer("Modulation", "QPSK", "SamplesPerSymbol", 1);
% 
% sig_sync = freqSync(sig.');
% rn = sig.^M;                         % signal "rabattu"
% 
% phases = zeros(length(rn), 1);        % phase de chaque symbole
% phases_exp = zeros(length(rn), 1);    % phase, comme exponentielle
% phases_exp_q = zeros(length(rn),1);   % quart de la phase
% corr   = zeros(length(rn), 1);        % signal corrigé (inutilisé)
% en     = zeros(length(rn), 1);        % valeurs de en
% vn     = zeros(length(rn), 1);        % valeurs de vn
% reg_loop=0;                           % registres
% reg_int=0;                            % registres
% % Boucle
% for i=1:length(rn)
% 
%     if i==1
%         en(i) = imag(rn(i));
%     else
%         en(i) = imag(rn(i) * conj(phases_exp(i-1)));
%     end
% 
%     % filtre de boucle
%     [vn1, reg_loop] = filter(loop_filter_b, loop_filter_a, en(i), reg_loop);
%     [vn2] = filter(alpha,1,en(i));
%     vn(i) = vn1+vn2;
% 
%     % filtre intégrateur (/!\ phase = M * phi)
%     [phase, reg_int] = filter(int_filter_b, int_filter_a, vn(i), reg_int);
%     phases(i) = phase;
%     phases_exp(i) = exp(1j * phase);
%     phases_exp_q(i) = exp(-1j * phase/M);
% end
% 
% bup = sig;
% sig = sig .* phases_exp_q.';
% 
% scatterplot(sig);
% comm.CoarseFrequencyCompensator
%% SYNCHRO TEMPORELLE FINE

M=4;
phaseoffset = pi/4;

% preamble = repmat([0; 1; 2; 3], 25, 1);
preambleSymb = pskmod(bitSynchro, M, phaseoffset, InputType="bit").';
N = length(preambleSymb);
p = intercorr(sig,preambleSymb);
[mval,midx] = max(abs(p));
% midx=50; % tmp

% récupération des 65536 symboles
pilote_rx = sig(midx:midx + N-1);
sig_rx = sig(midx+N:end);
err = 1/N * sum(pilote_rx .* conj(preambleSymb)./abs(preambleSymb).^2);
phase_orig = angle(err);

sig_rx = sig_rx(1:65536);

vals = pskdemod(sig_rx, M, phaseoffset+phase_orig, "gray");
% test = test(1:min(65536, 8*fix(length(test)/8)));

% conversion symbole -> bit
hatB = int2bit(vals, 2, true);

% compensation de matlab
Bt = hatB.';
Bt = Bt(:).';

% affichage
hatMatBitImg = reshape(Bt(:),[],8);
matImg = bit2int(hatMatBitImg, 8, true);
Img = reshape(matImg,128,128);

% padding = 16384 - length(test_d);
% 
% if padding > 0
%     test_d = [test_d; zeros(padding, 1)];
% else
%     test_d = test_d(1:16384);
% end

% img_rx = reshape(test_d, 128, 128);

figure
imshow(uint8(Img));