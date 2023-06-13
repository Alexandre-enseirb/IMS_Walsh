function [] = displayRandomConformedSignal(sig, mean, std, max_v, params, axhf, axht, axhc)


%% AFFICHAGE FREQUENTIEL
hold(axhf, 'off');
plot(axhf, params.freq_axis, 20*log10(abs(fftshift(sig.frequentiel)).^2/max(abs(fftshift(sig.frequentiel)).^2)));
hold(axhf, 'on'); 
grid(axhf, 'on');
plot(axhf, params.freq_axis, 20*log10(abs(fftshift(sig.walsh_fft)).^2/max(abs(fftshift(sig.walsh_fft)).^2)));
plot(axhf, params.freq_axis, params.BW_visible, 'LineStyle', '--', 'Color', '#77AC30')
xlim(axhf, [0 params.fech/2]);

xlabel(axhf, "Frequency (Hz)");
l = ylabel(axhf, "$ \left \| X(f) \right \|$", "Interpreter", "latex", "Rotation", 0);

l.Position(1) = -32/640*(axhf.XLim(2) - axhf.XLim(1)); % magic constant
l.Position(2) = axhf.YLim(2) - (axhf.YLim(2) - axhf.YLim(1))/2;
legend(axhf, ["Sinusoides", "Walsh"]);

%% AFFICHAGE TEMPOREL
t1 = (1:params.NWalsh)*params.Tech_s;
hold(axht, 'off')
plot(axht, t1, sig.temporel);
hold(axht, 'on');
grid(axht, 'on');
stairs(axht, t1, sig.walsh);
xlabel(axht, "Time (s)");
l = ylabel(axht, "$sin(2\pi f_0t)$","Interpreter","latex", "Rotation", 0);

l.Position(1) = -64/640*(axht.XLim(2) - axht.XLim(1)); % magic constant
l.Position(2) = axht.YLim(2) - (axht.YLim(2) - axht.YLim(1))/2;

%% AFFICHAGE COEFFICIENTS
bup_max = axhc.YLim(2);
hold(axhc, 'off');
stem(axhc, sig.sum_Xw_b, 'DisplayName', 'Xw_b');
grid(axhc, 'on');
hold(axhc, 'on');
plot(axhc, 1:params.nCoeff, mean, 'LineStyle', '--', 'LineWidth', 0.8, 'DisplayName', 'Mean');
plot(axhc, 1:params.nCoeff, max_v, 'LineStyle', 'none', 'Marker', 'v', 'DisplayName', 'Max');
%for i=1:params.nCoeff
    %plot(axhc, [i i], std(i,:), 'LineStyle', ':', 'LineWidth',2, 'Color', '#7E2F8E');
%end
errorbar(axhc, 1:params.nCoeff, mean, std.*ones(size(mean)), 'LineStyle', 'none', 'Marker', 'none', 'DisplayName', 'Std');

xlabel(axhc, "$n$","Interpreter","latex");
l=ylabel(axhc, "$ \left \| c_n \right \| $","Interpreter","latex","Rotation", 0);
%legend(axhc, ["Xw_b", "Mean", "Max"])
legend(axhc, 'show');
axhc.YLim(2) = max(axhc.YLim(2), bup_max);
axhc.XLim(1) = 0;
axhc.XLim(2) = params.nCoeff+1;
l.Position(1) = -64/640*(axhc.XLim(2) - axhc.XLim(1)); % magic constant
l.Position(2) = axhc.YLim(2) - (axhc.YLim(2) - axhc.YLim(1))/2;
