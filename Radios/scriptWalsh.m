clear; clc; close all; dbstop if error;

setPath();

%% Parameters

commParams = getCommParams("tx");
radioParams = getRadioParams("tx");
walshParams = getWalshParams();
colors = plotColors();

scrambler = comm.Scrambler( ...
    "CalculationBase", commParams.scramblerBase, ...
    "Polynomial", commParams.scramblerPolynomial, ...
    "InitialConditions", commParams.scramblerInitState, ...
    "ResetInputPort", commParams.scramblerResetPort);

msg = img2symbols(commParams, scrambler);
msgWalsh = img2walsh(commParams, walshParams, scrambler);


msgWalshRx = conv(msgWalsh, commParams.g);

msgUpsampled = upsample(msg, commParams.fse);
msgFiltered = conv(msgUpsampled, commParams.g);
msgRx = conv(msgFiltered, commParams.g);

msgWalshRxIntermTerms = [(msgWalshRx(1:end-1) + msgWalshRx(2:end))/2; 0];

msgWalshRxM = [msgWalshRx.';msgWalshRxIntermTerms.'];
msgWalshRxInterpolated = msgWalshRxM(:);

msgWalshRxInterpolatedDelayCompensated = [msgWalshRxInterpolated(3:2:end); 0];

Xw_msgFiltered = dwt(msgFiltered, walshParams.W, walshParams.order, true);
test = walsh(Xw_msgFiltered, walshParams.W, walshParams.Nfft, walshParams.osr);

timeAxis = (1:length(msgFiltered))/walshParams.fech;

%% AFFICHAGE

% Comparaison temporelle
figure("Name", "Time domain comparison", "Position", [1 1 1920 1080], "Resize", "off")
plot(timeAxis, real(msgFiltered), "DisplayName", "Transmitted signal", "LineWidth", 4);
hold on; grid on;
plot(timeAxis(1:walshParams.osr:end), ...
    real(msgFiltered(1:walshParams.osr:end)), ...
    "LineStyle", "none", ...
    "DisplayName", "Studied points", ...
    "Marker", "v", ...
    "MarkerSize", 16, ...
    "LineWidth", 4, ...
    "Color", colors("blue"));
plot(timeAxis, real(msgWalsh(1:length(msgFiltered))), ...
    "DisplayName", "Walsh transform", ...
    "LineWidth", 4, ...
    "Color", colors("red"));
axh = gca;
axh.XAxis.LineWidth = 3;
axh.YAxis.LineWidth = 3;
xlim([timeAxis(1200) timeAxis(1300)]);
legend(Interpreter="latex", FontSize=22);
xlabel("Time, s", interpreter="latex", fontsize=22);
ylabel("Amplitude", interpreter="latex", fontsize=22);
axh.FontSize=22;
exportgraphics(axh, "Walsh_transformed_QPSK_time_domain.pdf");

% Comparaison frequentielle
figure("Name", "Frequency domain comparison", "Position", [1 1 1920 1080], "Resize", "off")

plot(walshParams.freqAxis, abs(fftshift(fft(msgFiltered, walshParams.Nfft))), "DisplayName", "Original signal", "LineWidth", 4, "Color", colors("blue"));
hold on; grid on;
plot(walshParams.freqAxis, abs(fftshift(fft(msgWalsh, walshParams.Nfft))), "DisplayName", "Walsh signal", "LineWidth", 4, "Color", colors("red"));

axh = gca;
axh.XAxis.LineWidth = 3;
axh.YAxis.LineWidth = 3;
legend(Interpreter="latex", FontSize=22);
xlabel("Frequency, Hz", interpreter="latex", fontsize=22);
ylabel("Amplitude", interpreter="latex", fontsize=22);
axh.FontSize=22;
exportgraphics(axh, "Walsh_transformed_QPSK_freq_domain.pdf");

% Erreur de reconstruction
figure("Name", "Quadratic error", "Position", [1 1 1920 1080], "Resize", "off")
plot(timeAxis, (real(msgFiltered) - real(msgWalsh(1:length(msgFiltered)))).^2, "DisplayName", "Quadratic error", "LineWidth", 4);
hold on; grid on;
axh = gca;
axh.XAxis.LineWidth = 3;
axh.YAxis.LineWidth = 3;
axh.FontSize=22;
legend(Interpreter="latex", FontSize=22);
xlim([timeAxis(1) timeAxis(100)])
xlabel("Time, s", interpreter="latex", fontsize=22);
ylabel("Quadratic error amplitude", interpreter="latex", fontsize=22);
exportgraphics(axh, "Walsh_transformed_QPSK_quadratic_error.pdf");

% Comparaison au recepteur, en l'absence de bruit
timeAxisRx = (1:length(msgRx))/walshParams.fech;
figure("Name", "Rx", "Position", [1 1 1920 1080], "Resize", "off")
plot(timeAxisRx, real(msgRx), "DisplayName", "Rx original signal", "LineWidth", 4);
hold on; grid on;
plot(timeAxisRx(1:walshParams.osr:end), ...
    real(msgRx(1:walshParams.osr:end)), ...
    "LineStyle", "none", ...
    "DisplayName", "Studied points", ...
    "Marker", "v", ...
    "MarkerSize", 16, ...
    "LineWidth", 4, ...
    "Color", colors("blue"));
plot(timeAxisRx, real(msgWalshRx(1:length(msgRx))), ...
    "DisplayName", "Rx Walsh converted signal", ...
    "LineWidth", 4, ...
    "Color", colors("red"));
plot(timeAxisRx, real(msgWalshRxInterpolatedDelayCompensated(1:length(msgRx))), ...
    "DisplayName", 'Rx Walsh converted signal ("delay" compensated)', ...
    "LineWidth", 4, ...
    "Color", colors("purple"));
axh = gca;
axh.XAxis.LineWidth = 3;
axh.YAxis.LineWidth = 3;
xlim([timeAxis(1200) timeAxis(1300)]);
legend(Interpreter="latex", FontSize=22);
xlabel("Time, s", interpreter="latex", fontsize=22);
ylabel("Amplitude", interpreter="latex", fontsize=22);
axh.FontSize=22;
exportgraphics(axh, "Walsh_transformed_QPSK_time_domain_Rx.pdf");