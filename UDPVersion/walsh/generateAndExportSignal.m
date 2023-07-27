function [] = generateAndExportSignal(entry, carrier, attenuation, name, name2, name3, params)
%GENERATESIGFROMDICTIONARY generates the modulated Walsh signal obtained via 'IMPROVEDCOEFFICIENTSSELECTION'.
%
%   [sig] = GENERATESIGFROMDICTIONARY(entry, carrier, params) takes a nxm array or a 1x1 cell-array containing a nxm array as
%   inputs. n is the quantity of modulated coefficients, m is the number of windows + 1. The first line indicates
%   the index of the modulated coefficients. Lines 2 to end indicate the value of the symbol.
%   carrier is a 64xN array where 64 is the number of Walsh coefficients and N is the number of windows. It
%   contains the default values of every coefficient to reach the desired bandwidth.
%   params is a struct containing all the necessary parameters, generated via 'genParams'.

if iscell(entry)
    entry = entry{1};
end

nCoeffs = size(entry, 2);

modulatedCoeffs = entry(1,:);
symbols = entry(2:end, :).';
Sk             = qam64_fast_fast(symbols, params.maps);
Sk             = reshape(Sk, nCoeffs, []);

coeffsCarrier = ones(1, size(carrier, 2));
coeffsCarrier(2:2:end) = 1j;



upsampledSymbols = zeros(nCoeffs, size(carrier, 2));
for i=1:nCoeffs
    upsampledSymbols(i,:) = upsample_(Sk(i,:), size(carrier, 2));
end

finalCoeffs = real(carrier);
finalCoeffs(modulatedCoeffs, :) = real(upsampledSymbols.*repmat(coeffsCarrier, 3, 1))/attenuation;

sig = walsh(finalCoeffs, params.W, params.Nfft, params.osr, false);
sig = analyze(sig, params.Nfft);

figurePos = getFigPosition();

figure("Name", "export", "Position", figurePos, "Resize", "off")
stem(1:64, sum(abs(finalCoeffs(1:64, :)), 2), "Color", "#0072BD", "LineWidth", 3, "DisplayName", "Carrier coefficients");
hold on; grid on;
stem(modulatedCoeffs, sum(abs(finalCoeffs(modulatedCoeffs, :)), 2), "Color", "#D95319", "LineWidth", 3, "DisplayName", "Modulated coefficients");
xlabel("Walsh coefficient", "Interpreter", "latex", "FontSize", 22);
ylabel("Summed absolute amplitudes", "Interpreter", "latex", "FontSize", 22);
legend("Interpreter", "latex","FontSize", 22)
xlim([-0.5 64.5]);
ylim([-250 14250]);
axh = gca;
axh.FontSize=22;
exportgraphics(axh, name);

figure("Name", "Spectrum", "Position", figurePos, "Resize", "off")
plot(params.freq_axis, sig.dB, "Color", "#0072BD", "LineWidth", 3, "DisplayName", "Spectrum");
hold on; grid on;
plot(params.freq_axis, params.BW_visible, "Color", "#EDB120", "LineWidth", 2, "LineStyle", "--", "DisplayName", "Mask");
xlabel("Frequency, Hz", "Interpreter", "latex", "FontSize", 22);
ylabel("Amplitude, dB", "Interpreter", "latex", "FontSize", 22);
legend("Interpreter", "latex","FontSize", 22)
xlim([0 4e9]);
axh = gca;
axh.FontSize=22;
exportgraphics(axh, name2);

figure("Name", "Time", "Position", figurePos, "Resize", "off")
plot((1:length(sig.temporel))/params.fech, sig.temporel, "Color", "#0072BD", "LineWidth", 3, "DisplayName", "Semantic signal");
hold on; grid on;
xlabel("Time, s", "Interpreter", "latex", "FontSize", 22);
ylabel("Amplitude", "Interpreter", "latex", "FontSize", 22);
legend("Interpreter", "latex","FontSize", 22)
xlim([5e-6 5.05e-6]);
axh = gca;
axh.FontSize=22;
exportgraphics(axh, name3);

