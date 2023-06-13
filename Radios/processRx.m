clear; clc; close all; dbstop if error;

%% PARAMS

params = getCommParams('rx'); % Params used during communication

fech = params.samplingFreq;      % Sampling frequency, Hz
Nfft = 2^14;                                   % fft points 
threshold = 500;                         % Minimal amplitude looked for

load("Rx_data_11.mat", "Data");

freqAxis = -fech/2 : fech/Nfft : fech/2 - fech/Nfft; % Frequency axis

%% PROCESSING

% Research of signal
goodIdx = find(Data > threshold);

% Start and end of signal
startIdx = goodIdx(20000);
endIdx  = goodIdx(end);

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