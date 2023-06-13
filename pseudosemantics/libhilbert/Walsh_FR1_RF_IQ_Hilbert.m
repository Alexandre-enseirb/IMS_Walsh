close all
clear all

%% Génération des séquences de Walsh
Had   = 1;
order = 6;
N = 2^order;
OSR = 1;
for i=1:order
    Had = [Had  Had; Had -Had];
end

%Sort Hadamard Matrix by sign change growth to obtain Walsh sequences
index_sorted_Had = zeros(1, 2^order);
for j=2:N
    pos                 = Had(j,:)>0;
    changes             = xor(pos(1:end-1),pos(2:end));
    index_sorted_Had(j) = sum(changes);
end
Had = Had/sqrt(N);
[Sorted_Had, Had_to_Walsh] = sort(index_sorted_Had);
Had_1 = inv(Had);
W                       = Had(Had_to_Walsh,:); %Creates Walsh sequences
W_1 = inv(W);

%% Signaux
sampleRate      = 16e9;
samplingPeriod  = 1/sampleRate;
Fwalsh          = sampleRate/2;

load FR1_TM3_1_50MHz.mat

signal = waveStruct.waveform;
Fs = waveStruct.Fs;

x1 = resample(signal(1:5000), sampleRate, Fs);

Val = round(length(x1)/N);

x_bb = x1(1:N*(Val-1));

samplesPerFrame = length(x_bb);

amplitudeIFLO    = 1;
frequencyIFLO    = 500e6;

amplitudeRFLO    = 1;
frequencyRFLO    = 3.4e9;

carrier_IF        = dsp.SineWave(amplitudeIFLO, frequencyIFLO, 'SampleRate', sampleRate, 'SamplesPerFrame', samplesPerFrame, 'ComplexOutput', true);
carrier_if = carrier_IF();

carrier_RF        = dsp.SineWave(amplitudeRFLO, frequencyRFLO, 'SampleRate', sampleRate*OSR, 'SamplesPerFrame', samplesPerFrame*OSR, 'ComplexOutput', true);
carrier_rf = carrier_RF();


x_if = real(x_bb).*real(carrier_if)+imag(x_bb).*imag(carrier_if);


%% Transformée de Walsh de x
Xw_I                      = W*reshape(x_if, N,[]);


%% Filtrage de Hilbert 
signFrequency = linspace(-N/2, N/2, N);
Hf            = diag(1j*sign(signFrequency));

a                   = 0 : N-1;
b                   = transpose(a);
F                   = 1 / sqrt(N) * exp(-2 * pi  *1i / N).^(b * a);
F_1           = inv(F);
A                   = F_1 * Hf * F;
Hw                  = real(W_1 * A * W); %Get only real part of the matrix because the imaginary part is equal to 0 (magnitude order : e-15)
%Hw(abs(Hw) < 1e-10) = 0; %Get only the more weighted values (64 unique values)  because most of the coefficients are equal to 0 (magnitude order e-15)


%Xw_I             =  Xw_I;
Xw_Q             =  Hw*Xw_I;

Xw_Q2 = hilbertWalsh(Xw_I, W);
%Xw = Xw_I+1j*Xw_Q;


%% Quantification + DAC
W_time = zeros(N, N*OSR);
for n = 0:N-1
        W_time(:, 1+n*(OSR):(n+1)*OSR)= vect2time(W(:,n+1), OSR);
end

nbits = 32;
Walsh_frame = size(Xw_I);
Xw_b = zeros(Walsh_frame);

for f = 1:Walsh_frame(2)
    Xw_ib(:,f) = quantification(Xw_I(:,f), nbits);
    x_reconstruct_mat_i(:,f) = transpose(Xw_ib(:,f))*W_time;
end

for f = 1:Walsh_frame(2)
    Xw_qb(:,f) = quantification(Xw_Q(:,f), nbits);
    x_reconstruct_mat_q(:,f) = transpose(Xw_qb(:,f))*W_time;
end

x_reconstruct_i = reshape(x_reconstruct_mat_i, 1, []);
x_reconstruct_q = reshape(x_reconstruct_mat_q, 1, []);

x_reconstruct_i = x_reconstruct_i(:);
x_reconstruct_q = x_reconstruct_q(:);


x_rf = x_reconstruct_i.*real(carrier_rf)-x_reconstruct_q.*imag(carrier_rf);
x_rf = x_rf(:);


VS_plot(1:1:length(x_rf)/2, real(x_rf(1:samplesPerFrame*OSR/2)), '-', 2, 'non', 2,  [50 150 126]/255, 2, "Echantillons", "Amplitude", "Signal reconstruit", 1);

% NPSD_plot(awgn(x_if(:), 20, "measured"), 50, sampleRate*OSR, 1024, 0, [0 0 0], '--', 1, 'none', 10, 100, "Signal IF (voie I)", 2);
% hold on
% NPSD_plot(awgn(x_rf(:), 20, "measured"), 50, sampleRate*OSR, 1024, 0, [0 0 0], '-', 1, 'none', 10, 100, "Signal RF", 2);



