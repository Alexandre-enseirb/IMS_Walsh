function [] = visualizeConformedAndSparsifiedSignals(params, amount, pause_time, export_)
%VISUALIZERANDOMCONFORMEDSIGNALS permet de visualiser des signaux conformes
%
%   VISUALIZERANDOMCONFORMEDSIGNALS(params) utilise des parametres generes
%   par GENPARAMS pour generer et afficher des signaux conformes a la bande
%   de frequences definie dans les parametres, en sommant des sinusoides
%   faisant partie de cette bande et en faisant leur transformee de Walsh.
%   Elle affiche ensuite un comparatif entre le spectre de puissances du
%   signal sinusoidal et de sa transformee de Walsh.
%
%   VISUALIZERANDOMCONFORMEDSIGNALS(params, amount, pause_time) permet de
%   specifier un nombre de signaux a visualiser et le temps entre
%   l'affichage de deux signaux.

if ~exist("amount","var")
    amount = 50;
end 

if ~exist("export_", "var")
    export_=false;
end


stats.standard.mem = [];
stats.sparse.mem   = [];


if ~exist("pause_time","var")
    pause_time = 1;
end

figure("Name", "Comparaison temps/walsh", ...
    "Position", get(0, "ScreenSize"), ...
    "Visible", "on")
subplot(2,2,1);
plot(0);
axhf1 = gca;
subplot(2,2,2)
plot(0);
axhc1 = gca;
subplot(2,2,4)
plot(0);
axhc2 = gca;
subplot(2,2,3)
plot(0);
axhf2 = gca;

stats.standard.summed_coeffs = zeros(params.nCoeff, 1);
stats.standard.mean_coeffs   = zeros(params.nCoeff, 1);
stats.standard.var_coeffs    = zeros(params.nCoeff, 1);
stats.standard.max_coeffs    = zeros(params.nCoeff, 1);
stats.standard.std_c         = zeros(params.nCoeff, 1);

stats.sparse.summed_coeffs = zeros(params.nCoeff, 1);
stats.sparse.mean_coeffs   = zeros(params.nCoeff, 1);
stats.sparse.var_coeffs    = zeros(params.nCoeff, 1);
stats.sparse.max_coeffs    = zeros(params.nCoeff, 1);
stats.sparse.std_c         = zeros(params.nCoeff, 1);

% % Make some stats first
% for i=1:100
%     sig = getRandomConformedSignal(params);
%             
%     stats.standard.summed_coeffs = stats.standard.summed_coeffs + sig.sum_Xw_b; 
%     stats.standard.mem           = [stats.standard.mem sig.sum_Xw_b];
%     stats.standard.mean_coeffs   = stats.standard.summed_coeffs ./ i;             
%     stats.standard.max_coeffs    = max([sig.sum_Xw_b stats.standard.max_coeffs], [], 2);
%     stats.standard.var_coeffs    = sum((stats.standard.mem - stats.standard.mean_coeffs).^2, 2)/i;
%     stats.standard.std_c         = sqrt(stats.standard.var_coeffs);
% end

i = 1;
if islogical(amount) && ~amount
    while true
        sig = getRandomConformedSignal(params);
        
        stats.standard.summed_coeffs = stats.standard.summed_coeffs + sig.sum_Xw_b; 
        stats.standard.mem           = [stats.standard.mem sig.sum_Xw_b];
        stats.standard.mean_coeffs   = stats.standard.summed_coeffs ./ i;             
        stats.standard.max_coeffs    = max([sig.sum_Xw_b stats.standard.max_coeffs], [], 2);
        stats.standard.var_coeffs    = sum((stats.standard.mem - stats.standard.mean_coeffs).^2, 2)/i;
        stats.standard.std_c         = sqrt(stats.standard.var_coeffs);
        
        sig_sparse = sparsifyConformedSignal(sig, params, stats.standard.std_c);

        stats.sparse.summed_coeffs = stats.sparse.summed_coeffs + sig_sparse.sum_Xw_b; 
        stats.sparse.mem           = [stats.sparse.mem sig_sparse.sum_Xw_b];
        stats.sparse.mean_coeffs   = stats.sparse.summed_coeffs ./ i;             
        stats.sparse.max_coeffs    = max([sig_sparse.sum_Xw_b stats.sparse.max_coeffs], [], 2);
        stats.sparse.var_coeffs    = sum((stats.sparse.mem - stats.sparse.mean_coeffs).^2, 2)/i;
        stats.sparse.std_c         = sqrt(stats.sparse.var_coeffs);
        
        displayConformedAndSparsifiedSignal(sig, sig_sparse, stats, params, axhf1, axhc1, axhf2, axhc2);
        if export_
            export_axis(params.sparsify_amnt, i, axhf1, axhc, axhf2, axhc2);
        end
        i = i+1;
        pause(pause_time);
    end
else
    for i=1:amount
        sig = getRandomConformedSignal(params);
        
        stats.standard.summed_coeffs = stats.standard.summed_coeffs + sig.sum_Xw_b; 
        stats.standard.mem           = [stats.standard.mem sig.sum_Xw_b];
        stats.standard.mean_coeffs   = stats.standard.summed_coeffs ./ i;             
        stats.standard.max_coeffs    = max([sig.sum_Xw_b stats.standard.max_coeffs], [], 2);
        stats.standard.var_coeffs    = sum((stats.standard.mem - stats.standard.mean_coeffs).^2, 2)/i;
        stats.standard.std_c         = sqrt(stats.standard.var_coeffs);
        
        sig_sparse = sparsifyConformedSignal(sig, params, stats.standard.std_c);

        stats.sparse.summed_coeffs = stats.sparse.summed_coeffs + sig_sparse.sum_Xw_b; 
        stats.sparse.mem           = [stats.sparse.mem sig_sparse.sum_Xw_b];
        stats.sparse.mean_coeffs   = stats.sparse.summed_coeffs ./ i;             
        stats.sparse.max_coeffs    = max([sig_sparse.sum_Xw_b stats.sparse.max_coeffs], [], 2);
        stats.sparse.var_coeffs    = sum((stats.sparse.mem - stats.sparse.mean_coeffs).^2, 2)/i;
        stats.sparse.std_c         = sqrt(stats.sparse.var_coeffs);
        
        displayConformedAndSparsifiedSignal(sig, sig_sparse, stats, params, axhf1, axhc1, axhf2, axhc2);
        if export_
            export_axis(params.sparsify_amnt, i, axhf1, axhc1, axhf2, axhc2);
        end
        
        pause(pause_time);
    end
end
end

function [] = export_axis(sparsify_amnt, i, axhf1, axhc1, axhf2, axhc2)

folder = sprintf("visuals/conformed_2_4_GHz/%d", sparsify_amnt);
if ~exist(folder, "dir")
    mkdir(folder);
end

freq_1_name = sprintf("%s/fft_no_sparsify_%d.pdf", folder, i);
freq_2_name = sprintf("%s/fft_sparsified_%d.pdf", folder, i);
coef_1_name = sprintf("%s/wal_no_sparsify_%d.pdf", folder, i);
coef_2_name = sprintf("%s/wal_sparsified_%d.pdf", folder, i);

exportgraphics(axhf1, freq_1_name);
exportgraphics(axhf2, freq_2_name);
exportgraphics(axhc1, coef_1_name);
exportgraphics(axhc2, coef_2_name);
end