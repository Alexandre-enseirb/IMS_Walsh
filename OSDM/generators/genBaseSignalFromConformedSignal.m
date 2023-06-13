function [sig_sparse, stats] = genBaseSignalFromConformedSignal(params)
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

stats.standard.mem = [];
stats.sparse.mem   = [];

for i=1:100
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
end

end