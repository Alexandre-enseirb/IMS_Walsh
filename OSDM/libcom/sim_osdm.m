function [error_stats] = sim_osdm(params, SNR_dB)

carrier_name = sprintf("walsh_carrier_%d_Hz.mat", params.BW_middle_freq);
maps = genMapsQam64(params.BW_middle_freq, params);
n_SNR = length(SNR_dB);
ga = 1/params.osr*ones(1,params.osr);
delay = 3;
% Generation porteuses
if ~isfile(carrier_name)
    [carriers, ~] = generateWalshCarrier(params, 100, carrier_name);
else
    tmp = load(carrier_name, "carriers");
    carriers = tmp.carriers;
    clear tmp;
end

% t         = length(carriers{1}.temporel);
% time_axis = (1:t)/params.fech;
% 
% freq_axis = params.freq_axis;

nbSymbPerFrame = length(carriers{1}.available);

nErrorsSymb     = zeros(1, n_SNR);
nErrorsPaquet   = zeros(1, n_SNR);
nPaquetsEnvoyes = zeros(1, n_SNR);

minErrorsSymb = 200;
minPaquets    = 1e3;

for i_SNR = 1:n_SNR
    fprintf("[ITER #%.2d]: %2.2f\n", i_SNR, SNR_dB(i_SNR));
    
    SNR = 10^(SNR_dB(i_SNR)/10);

    while any(nErrorsSymb(:, i_SNR) < minErrorsSymb) && nPaquetsEnvoyes(i_SNR) < minPaquets
        idxSymb  = randi([1,64], 1, nbSymbPerFrame);
        Symb     = qam64_fast_fast(idxSymb-1, maps);
        
        %% Methode 2 - Somme de signaux
        
        sig2 = struct("temporel", zeros(size(carriers{1}.temporel)));
        
        for i=1:nbSymbPerFrame
            Xw_b                             = carriers{1}.coeffs;
            Xw_b(carriers{1}.available(i),:) = Symb(i);
            tmp                              = walsh(Xw_b, params.W, params.Nfft, params.osr);
            sig2.temporel                    = sig2.temporel + tmp.temporel.';
        end
        sig2.temporel = sig2.temporel/nbSymbPerFrame;
        
        [sig_rec2, ~] = wse(sig2.temporel, params, length(sig2.temporel));
        
%         sig_full2     = analyze(sig2, params.Nfft);
%         sig_rec2_full = analyze(struct("temporel", sig_rec2), params.Nfft);
        sig_rec2_full.temporel = sig_rec2;
        %% Canal
        
        %Psig   = 1/length(sig_full.temporel) * sum(abs(sig_full.temporel).^2);
        %Pbruit = Psig/SNR;
        
        Psig2   = 1/length(sig_rec2_full.temporel) * sum(abs(sig_rec2_full.temporel).^2);
        Pbruit2 = Psig2/SNR;
        
        %b  = sqrt(Pbruit/2)*(randn(size(sig_full.temporel)) + 1j * randn(size(sig_full.temporel)));
        b2 = sqrt(Pbruit2/2)*(randn(size(sig_rec2_full.temporel)) + 1j * randn(size(sig_rec2_full.temporel)));
        
        %y  = sig_full.temporel + b;
        y2 = sig_rec2_full.temporel + b2;
        
        %% Recepteur

        %y_filt = conv(y, ga);
        y2_filt = conv(y2, ga);

        dsr = params.osr; % downsampling rate

        %r  = y_filt((delay):dsr:end);
        r2 = y2_filt((delay):dsr:end);
        
%         rr  = reshape(r.', dsr, []);
%         rr2 = reshape(r2.', dsr, []);
%         
%         r  = mean(rr, 1);
%         r2 = mean(rr2, 1);

        %symbols1 = dwt(r,  params.W, params.order, true);
        symbols2 = dwt(r2, params.W, params.order, true);
        
        %symbols1_noCarrier = mean(symbols1(carriers{1}.available,:), 2)*nWin;
        symbols2_noCarrier = mean(symbols2(carriers{1}.available,:), 2)*nbSymbPerFrame;
        
        %S1 = qam64demod(symbols1_noCarrier, maps) + 1;
        S2 = qam64demod(symbols2_noCarrier, maps) + 1;
        
        %errors1 = sum(S1~=idxSymb);
        errors2 = sum(S2~=idxSymb);
        %diffs   = sum(S1~=S2);

        nErrorsSymb(:, i_SNR)   = nErrorsSymb(:, i_SNR) + [errors2];
        nErrorsPaquet(:, i_SNR) = nErrorsPaquet(:, i_SNR) + [errors2~=0];
        nPaquetsEnvoyes(i_SNR)  = nPaquetsEnvoyes(i_SNR) + 1;
    end
end

error_stats = struct( ...
    "nPaquetsEnvoyes", nPaquetsEnvoyes, ...
    "nErrorsSymb", nErrorsSymb, ...
    "nErrorsPaquets", nErrorsPaquet, ...
    "SER", nErrorsSymb./(nPaquetsEnvoyes*nbSymbPerFrame), ...
    "FER", nErrorsPaquet./nPaquetsEnvoyes ...
);