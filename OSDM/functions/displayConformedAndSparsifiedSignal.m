function [] = displayConformedAndSparsifiedSignal(sig, sig_sparse, stats, params, axhf1, axhc1, axhf2, axhc2)


%% AFFICHAGE FREQUENTIEL
% ======================
% =  VERSION COMPLETE  =
% ======================
hold(axhf1, 'off');
plot(axhf1, params.freq_axis, 20*log10(abs(fftshift(sig.frequentiel)).^2/max(abs(fftshift(sig.frequentiel)).^2)), "DisplayName", "Sinusoides");
hold(axhf1, 'on'); 
grid(axhf1, 'on');
plot(axhf1, params.freq_axis, 20*log10(abs(fftshift(sig.walsh_fft)).^2/max(abs(fftshift(sig.walsh_fft)).^2)), "DisplayName", "Walsh");
plot(axhf1, params.freq_axis, params.BW_visible, 'LineStyle', '--', 'Color', '#77AC30', "DisplayName", "Bandwidth")
xlim(axhf1, [2.45e9 2.55e9]);
ylim(axhf1, [-50 0]);
xlabel(axhf1, "Frequency (Hz)");
l = ylabel(axhf1, "$ \left \| X(f) \right \|$", "Interpreter", "latex", "Rotation", 0);

l.Position(1) = -32/640*(axhf1.XLim(2) - axhf1.XLim(1)); % magic constant
l.Position(2) = axhf1.YLim(2) - (axhf1.YLim(2) - axhf1.YLim(1))/2;
legend(axhf1, ["Sinusoides", "Walsh"]);

% ======================
% = VERSION SPARSIFIEE =
% ======================

hold(axhf2, 'off');
plot(axhf2, params.freq_axis, 20*log10(abs(fftshift(sig.frequentiel)).^2/max(abs(fftshift(sig.frequentiel)).^2)), "DisplayName", "Sinusoides");
hold(axhf2, 'on'); 
grid(axhf2, 'on');
plot(axhf2, params.freq_axis, sig_sparse.dB, "DisplayName", "Walsh sparse");
plot(axhf2, params.freq_axis, params.BW_visible, 'LineStyle', '--', 'Color', '#77AC30', "DisplayName", "Bandwidth")
xlim(axhf2, [2e9 3e9]);
ylim(axhf2, [-100 0]);
xlabel(axhf2, "Frequency (Hz)");
l = ylabel(axhf2, "$ \left \| X(f) \right \|$", "Interpreter", "latex", "Rotation", 0);
% axhf2.YLim = axhf1.YLim;
% axhf2.XLim = axhf1.XLim;
% ylim(axhf2, [-300 0]);
l.Position(1) = -32/640*(axhf2.XLim(2) - axhf2.XLim(1)); % magic constant
l.Position(2) = axhf2.YLim(2) - (axhf2.YLim(2) - axhf2.YLim(1))/2;
legend(axhf2, "show");

%% AFFICHAGE COEFFICIENTS
% ======================
% =  VERSION COMPLETE  =
% ======================

bup_max = axhc1.YLim(2);
hold(axhc1, 'off');
stem(axhc1, sig.sum_Xw_b, 'DisplayName', 'Xw_b');
grid(axhc1, 'on');
hold(axhc1, 'on');
plot(axhc1, 1:params.nCoeff, stats.standard.mean_coeffs, 'LineStyle', '--', 'LineWidth', 0.8, 'DisplayName', 'Mean');
plot(axhc1, 1:params.nCoeff, stats.standard.max_coeffs, 'LineStyle', 'none', 'Marker', 'v', 'DisplayName', 'Max');
%for i=1:params.nCoeff
    %plot(axhc1, [i i], std(i,:), 'LineStyle', ':', 'LineWidth',2, 'Color', '#7E2F8E');
%end
errorbar(axhc1, 1:params.nCoeff, stats.standard.mean_coeffs, stats.standard.std_c.*ones(size(stats.standard.mean_coeffs)), 'LineStyle', 'none', 'Marker', 'none', 'DisplayName', 'Std');

xlabel(axhc1, "$n$","Interpreter","latex");
l=ylabel(axhc1, "$ \left \| c_n \right \| $","Interpreter","latex","Rotation", 0);
%legend(axhc1, ["Xw_b", "Mean", "Max"])
legend(axhc1, 'show');
axhc1.YLim(2) = max(axhc1.YLim(2), bup_max);
axhc1.XLim(1) = 0;
axhc1.XLim(2) = params.nCoeff+1;
l.Position(1) = -64/640*(axhc1.XLim(2) - axhc1.XLim(1)); % magic constant
l.Position(2) = axhc1.YLim(2) - (axhc1.YLim(2) - axhc1.YLim(1))/2;


% ======================
% = VERSION SPARSIFIEE =
% ======================

bup_max = axhc2.YLim(2);
hold(axhc2, 'off');
stem(axhc2, sig_sparse.sum_Xw_b, 'DisplayName', 'Xw_b');
grid(axhc2, 'on');
hold(axhc2, 'on');
plot(axhc2, 1:params.nCoeff, stats.sparse.mean_coeffs, 'LineStyle', '--', 'LineWidth', 0.8, 'DisplayName', 'Mean');
plot(axhc2, 1:params.nCoeff, stats.sparse.max_coeffs, 'LineStyle', 'none', 'Marker', 'v', 'DisplayName', 'Max');
%for i=1:params.nCoeff
    %plot(axhc2, [i i], std(i,:), 'LineStyle', ':', 'LineWidth',2, 'Color', '#7E2F8E');
%end
errorbar(axhc2, 1:params.nCoeff, stats.sparse.mean_coeffs, stats.sparse.std_c.*ones(size(stats.standard.mean_coeffs)), 'LineStyle', 'none', 'Marker', 'none', 'DisplayName', 'Std');

xlabel(axhc2, "$n$","Interpreter","latex");
l=ylabel(axhc2, "$ \left \| c_n \right \| $","Interpreter","latex","Rotation", 0);
%legend(axhc2, ["Xw_b", "Mean", "Max"])
legend(axhc2, 'show');
axhc2.YLim = axhc1.YLim;
axhc2.XLim = axhc1.XLim;
l.Position(1) = -64/640*(axhc2.XLim(2) - axhc2.XLim(1)); % magic constant
l.Position(2) = axhc2.YLim(2) - (axhc2.YLim(2) - axhc2.YLim(1))/2;
