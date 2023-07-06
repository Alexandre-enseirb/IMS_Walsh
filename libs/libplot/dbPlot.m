function [] = dbPlot(sig, params)

colors = plotColors();

figure("Name", "dBplot", "Position", [1 1 1920 1080], "Resize", "off")
plot(params.freqAxis, sig, "DisplayName", "Signal power", "Color", colors("blue"), LineWidth=4);
hold on; grid on;
axh = gca;
plot(params.freqAxis, params.BW_visible, "DisplayName", "Gabarit", "Color", colors("green"), LineStyle="--", LineWidth=4);
axh.XAxis.LineWidth=3;
axh.YAxis.LineWidth=3;
axh.FontSize=22;
xlabel("Frequency, Hz", Interpreter="latex");
ylabel("Amplitude, dB", Interpreter="latex");
legend(Interpreter="latex");
xlim([0 params.freqAxis(params.maxConformFrequency)])
ylim([-100 0]);