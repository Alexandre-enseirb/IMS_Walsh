clear; clc; close all; dbstop if error;

%% PARAMS

params = getCommParams('rx'); % Params used during communication

fech      = params.samplingFreq;      % Sampling frequency, Hz
Nfft      = 2^14;                                   % fft points 
threshold = 500;                         % Minimal amplitude looked for
M = 4;
load("Rx_data_24.mat", "Data");
roll_off = 0.5;
span = 16;
sps = 10;
g = rcosdesign(roll_off, span, sps, 'sqrt');

freqAxis = -fech/2 : fech/Nfft : fech/2 - fech/Nfft; % Frequency axis

alpha      = 1;      % constante de la boucle a verouillage de phase
beta       = 1e-4;   % constante de la boucle a verouillage de phase

loop_filter_b = beta;    % coeff du numérateur pour le filtre de boucle
loop_filter_a = [1 -1];  % coeff du dénominateur du filtre de boucle
int_filter_b  = [0 1];   % coeff du numérateur du filtre intégrateur
int_filter_a  = [1 -1];  % coeff du dénominateur du filtre intégrateur

%% PROCESSING

TMP_start = 10469200;
TMP_end = 21539200;

% synchro temporelle grossiere
extractedData     = conv(Data(TMP_start:100*sps:TMP_end), g);


% synchro frequentielle grossiere
rn = extractedData.^M;                         % signal "rabattu"

phases       = zeros(length(rn), 1);        % phase de chaque symbole
phases_exp   = zeros(length(rn), 1);    % phase, comme exponentielle
phases_exp_q = zeros(length(rn),1);   % quart de la phase
corr         = zeros(length(rn), 1);        % signal corrigé (inutilisé)
en           = zeros(length(rn), 1);        % valeurs de en
vn           = zeros(length(rn), 1);        % valeurs de vn
reg_loop     = 0;                                % registres
reg_int      = 0;                                   % registres
% Boucle
for i=1:length(rn)
    
    if i==1
        en(i) = imag(rn(i));
    else
        en(i) = imag(rn(i) * conj(phases_exp(i-1)));
    end

    % filtre de boucle
    [vn1, reg_loop] = filter(loop_filter_b, loop_filter_a, en(i), reg_loop);
    [vn2]           = filter(alpha,1,en(i));
    vn(i)           = vn1+vn2;

    % filtre intégrateur (/!\ phase = M * phi)
    [phase, reg_int] = filter(int_filter_b, int_filter_a, vn(i), reg_int);
    phases(i)        = phase;
    phases_exp(i)    = exp(1j * phase);
    phases_exp_q(i)  = exp(-1j * phase/4);
end


% correction du signal reçu
sig      = extractedData .* phases_exp_q;
sig_down = sig;

display_sig(sig);

% synchro temporelle fine

% synchro frequentielle fine


% Data extraction
extractedData = Data(startIdx:endIdx);

% FFT
DataFFT = fftshift(fft(extractedData, Nfft));


%% DISPLAY

figure("Name", "Spectrum", "Position", get(0, "ScreenSize"))
plot(freqAxis, abs(DataFFT));
grid on;
xlabel("Frequency, Hz");
ylabel("Amplitude");

figure("Name", "Time domain", "Position", get(0, "ScreenSize"))
plot((1:length(extractedData))/fech, real(extractedData));
grid on; hold on;
% plot((1:length(Data))/fech, imag(Data)); 
xlabel("Time, s");
ylabel("Signal");