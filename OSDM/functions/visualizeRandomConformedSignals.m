function [] = visualizeRandomConformedSignals(params, amount, pause_time)
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
    amount=50;
end 

if islogical(amount)
    mem = [];
else
    mem = zeros(params.nCoeff, amount);
end

if ~exist("pause_time","var")
    pause_time=1;
end

figure("Name", "Comparaison temps/walsh", ...
    "Position", get(0, "ScreenSize"), ...
    "Visible", "on")
subplot(1,2,1);
plot(0);
axhf = gca;
subplot(2,2,2)
plot(0);
axht = gca;
subplot(2,2,4)
plot(0);
axhc = gca;
summed_coeffs = zeros(params.nCoeff, 1);
mean_coeffs   = zeros(params.nCoeff, 1);
var_coeffs    = zeros(params.nCoeff, 1);
max_coeffs    = zeros(params.nCoeff, 1);
std_c = zeros(params.nCoeff, 1);
i = 1;
if islogical(amount) && ~amount
    while true
        sig = getRandomConformedSignal(params);
        displayRandomConformedSignal(sig, mean_coeffs, std_c, max_coeffs, params, axhf, axht, axhc);
        summed_coeffs = summed_coeffs + sig.sum_Xw_b; 
        mem = [mem sig.sum_Xw_b];
        mean_coeffs = summed_coeffs ./ i;             
        max_coeffs  = max([sig.sum_Xw_b max_coeffs], [], 2);
        var_coeffs  = sum((mem - mean_coeffs).^2, 2)/i;
        std_c = sqrt(var_coeffs);%[max(0, mean_coeffs - sqrt(var_coeffs)) mean_coeffs + sqrt(var_coeffs)];
        i = i+1;
        pause(pause_time);
    end
else
    for i=1:amount
        sig = getRandomConformedSignal(params);
        displayRandomConformedSignal(sig, params, axhf, axht, axhc);
        pause(pause_time);
    end
end
end