function [n, amps, sig_Walsh_fft, sig_fft, Xw_b] = f2c(params)
%F2C fait la conversion de frequences en coefficients de Walsh.
%
%   F2C(f, params) prend un vecteur de frequences et une structure de
%   parametres. Elle genere toutes les sinusoides associees aux differentes
%   frequences donnees, puis retourne les coefficients associes apres
%   transformee de Walsh et quantification.
%

% Nombre de frequences a generer
f = params.bw_axis;
[l,c] = size(f);
if l == 1
    nbFreq = c;
    f      = f.';
else
    nbFreq = l;
end

% Nombre de points a generer (temporel)
nbPts = length(params.time_axis);

% Pre-allocation
%sig_Walsh = zeros(nbFreq, nbPts);

% Nombre de coeffs a retourner
nbCoeffsRetour = 10;
n              = zeros(nbFreq, nbCoeffsRetour);
amps           = zeros(nbFreq, nbCoeffsRetour);
sig_Walsh_fft  = zeros(nbFreq, params.Nfft);
sig_fft        = zeros(nbFreq, params.Nfft);

size_in_memory = sizeof('double')*nbFreq*nbPts;
maximal_allowed_size = 1023^3; % 1 Go. Ancienne version : nbPts * sizeof("double");

splits = ceil(size_in_memory/maximal_allowed_size);
freq_split = ceil(nbFreq/splits);

if splits>1
    warning("backtrace","off");
    warning("Memory exceeded. Splitting function f2c into %d segments", splits);
    warning("backtrace","on");
end

for j=1:splits
    fprintf("Split no. %d/%d: ",j, splits);
    start = (j-1)*freq_split+1;
    stop  = min(nbFreq, j*freq_split);

    [n(start:stop,:), amps(start:stop, :), sig_Walsh_fft(start:stop,:), sig_fft(start:stop,:)] = f2c_(f(start:stop), params, j==-1);
    fprintf("CHECK!\n");
end


end

function [n, amps, sig_Walsh_fft, sig_fft] = f2c_(f, params, dbg)
%vraie fonction

nbCoeffsRetour = 10;
nbFreq = length(f);

n    = zeros(nbFreq, nbCoeffsRetour);
amps = zeros(nbFreq, nbCoeffsRetour);

% Signaux sinusoidaux
sig = sin(2*pi*f*params.time_axis);
sig(abs(sig)<1e-13) = 0; % evite certains bugs a cause de valeurs tres proches de 0
sig_Walsh_fft = zeros(nbFreq, params.Nfft);
sig_fft       = zeros(nbFreq, params.Nfft);





% Parcours par frequence
for i=1:nbFreq
    N = lcm( ceil(1/f(i) * params.fech), params.TRefresh_e );
 
    [sig_Walsh, Xw_b] = wse(sig(i,:), params, N, params.troncature);

    coeffs_sum      = sum(Xw_b,2);
    coeffs_sum      = coeffs_sum / max(abs(coeffs_sum));
    % Tri des coefficients
    [~, idx_sorted] = sort(abs(coeffs_sum), 'descend');
    n(i,:)          = idx_sorted(1:nbCoeffsRetour);
    amps(i,:)       = Xw_b(idx_sorted(1:nbCoeffsRetour));
    % Correction frequences
    if params.osr ~= 1
        sig_Walsh_osr = oversample_(sig_Walsh, params.osr);
    else
        sig_Walsh_osr = sig_Walsh.';
    end

    % debug
    if i==631 && dbg
        debug_display(params, sig(i,:), sig_Walsh, sig_Walsh_osr);
        disp("foo");
    end
    % Retour fft
    sig_Walsh_fft(i,:) = fft(sig_Walsh_osr, params.Nfft);
    sig_fft(i,:)       = fft(sig(i,:), params.Nfft);
end
end

function [] = debug_display(params, sig, sig_Walsh, sig_Walsh_osr)
figure("Name", "Comparaison temporelle", "Position", get(0, "ScreenSize"))
plot(params.time_axis, sig);
xlim([params.time_axis(1) params.time_axis(41)]);
hold on; grid on;
plot(params.time_axis(1:params.osr:end), sig_Walsh);
plot(params.time_axis, sig_Walsh_osr);
plot(params.time_axis(1:params.osr:end), sig(1:params.osr:end), 'LineStyle','--');
legend(["signal", "Walsh", "Walsh surech.", "sous-ech."],"FontSize",22);
axh = gca;
axh.FontSize=22;
end