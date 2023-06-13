function [errStats] = simBER(SNRdB, nSNR, params, display)

if ~exist("display", "var")
    display=false;
else
    msgHeader = "|   N   | SNR (dB) | Errors | Paquets |  BER  |  SER  |  FER  | Encoding rate | Decoding rate | Generation time | Non conform |\n";
    msgSep    = "+-------|----------+--------+---------+-------+-------+-------+---------------+---------------+-----------------+-------------+\n";
    msgStats  = "| %5d | %8.2f | %6d | %7d | %5.3f | %5.3f | %5.3f | %9.2f b/s | %9.2f b/s | %13.2f s | %11d |";
    fprintf(msgSep);
    fprintf(msgHeader);
    fprintf(msgSep);
end

simFileName = sprintf("data/simulations/osdm_%d_%d.mat", params.nModulatedCoeffs, params.nWalsh);
carrierFileName  = sprintf("data/carriers/walsh_carrier_%d@%d_Hz.mat", params.BW_middle_freq, params.fech);

% Generation porteuses
if ~isfile(carrierFileName)
    [carriers, ~] = generateWalshCarrier(params, 100, carrierFileName);
else
    tmp      = load(carrierFileName);
    carriers = tmp.carriers;
    
    %clear("tmp");
end



M             = 6; % 64-QAM, 6 bits par symbole
MP = get(0, "MonitorPositions");

if MP(3) == 5120 && MP(4) == 1080 % Config. du labo
    figurePos = [3841 1 5120 1024];
else
    figurePos = get(0, "ScreenSize");
end

t         = length(carriers{1}.temporel);
time_axis = (1:t)/params.fech;

freq_axis = params.freq_axis;

nSymbPerFrame = length(carriers{1}.available);

nErrorsBits     = zeros(1, nSNR);
nErrorsSymb     = zeros(1, nSNR);
nErrorsPaquet   = zeros(1, nSNR);
nNotConform     = zeros(1, nSNR);
nPaquetsEnvoyes = zeros(1, nSNR);

minErrorsSymb = 100;
minPaquets    = 1e5;

nBitsPerSymb = 6; % 64-QAM
encodingRate = 0;
decodingRate = 0;
genRate      = 0;
msgSz        = 0;

carrierSize     = size(carriers{1}.walsh.temporel);
Xw_base         = carriers{1}.coeffs;
availableCoeffs = carriers{1}.available;
nWindows        = size(carriers{1}.walsh.Xw_b, 2);

nullFrequencyIdx = ceil(length(params.freq_axis)/2);

W     = params.W;
Nfft  = params.Nfft;
osr   = params.osr;
dsr   = params.osr;
order = params.order;

ga    = 1/params.osr * ones(1, params.osr);
delay = mean(grpdelay(ga, 1));
delay = 2*delay + 1;% + (delay == ceil(delay));

delay_axis = (delay):dsr:carrierSize(1);

previousBER = 1;

for iSNR = 1:nSNR
%     fprintf("[ITER #%.2d]: %2.2f\n", iSNR, SNRdB(iSNR));
    
    if previousBER < 0.001
        break;
    end

    SNR = 10^(SNRdB(iSNR)/10);

    msgSz        = 0;
    decodingRate = 0;
    encodingRate = 0;

    while any(nErrorsSymb(iSNR) < minErrorsSymb) && nPaquetsEnvoyes(iSNR) < minPaquets
        idxSymb = randi([1,64], 1, nSymbPerFrame);
        
        %% Methode 2 - Somme de signaux
        
        Symb                    = qam64_fast_fast(idxSymb-1, params.maps);
        tic;
        Xw_b                    = Xw_base;
        Xw_b(availableCoeffs,:) = repmat(Symb/nSymbPerFrame, 1, nWindows);
        
        sig = walsh(Xw_b, W, Nfft, osr);
        
        [sigRec, Xw_b] = wse(sig.temporel, params, length(sig.temporel));
        encodingRate   = encodingRate + toc;
        %% Canal
        
        Psig   = 1/length(sigRec) * sum(abs(sigRec).^2);
        Pbruit = Psig/SNR;
        
        b = sqrt(Pbruit/2)*(randn(size(sigRec)) + 1j * randn(size(sigRec)));
        
        y = sigRec + b;

        sigRecFFT = fftshift(fft(sigRec, params.Nfft));
        sigRecPow = abs(sigRecFFT).^2;
        sigRecdB  = 10*log10(sigRecPow/max(sigRecPow));
        
        if ~isConform(sigRecdB(nullFrequencyIdx:end), params.BW_visible)
            nNotConform(iSNR) = nNotConform(iSNR) + 1;
        end
        %% Recepteur

        yFiltered = conv(y, ga);

        dsr = params.osr; % downsampling rate
        
        r = yFiltered(delay_axis);
        
        tic;
        symbols            = dwt(r, W, order, true);
        symbolsNoCarrier   = mean(symbols(availableCoeffs,:), 2)*nSymbPerFrame;
        S                  = qam64demod(symbolsNoCarrier, params.maps) + 1;
        symbBinary         = int2bit(S, M, true);
        symbBinaryEstimate = int2bit(idxSymb, M, true); 
        errorsBin          = sum(symbBinary~=symbBinaryEstimate, "all");
        errors             = sum(S~=idxSymb);
        decodingRate       = decodingRate + toc;

        if display && mod(nPaquetsEnvoyes(iSNR),100) == 0 && nPaquetsEnvoyes(iSNR) > 0
            decodingRate_  = decodingRate/nPaquetsEnvoyes(iSNR);
            encodingRate_  = encodingRate/nPaquetsEnvoyes(iSNR);
            genRate_       = genRate/nPaquetsEnvoyes(iSNR);
            carriageReturn = strjoin(repmat("\b", msgSz, 1), "");
            fprintf(carriageReturn);
            msgSz          = fprintf(msgStats, ...
                params.nWalsh, ...
                SNRdB(iSNR), ...
                nErrorsSymb(iSNR), ...
                nPaquetsEnvoyes(iSNR), ...
                nErrorsBits(iSNR)/(nPaquetsEnvoyes(iSNR)*nSymbPerFrame*M), ...
                nErrorsSymb(iSNR)/(nPaquetsEnvoyes(iSNR)*nSymbPerFrame), ...
                nErrorsPaquet(iSNR)/nPaquetsEnvoyes(iSNR), ...
                nSymbPerFrame*nBitsPerSymb/encodingRate_, ...
                nSymbPerFrame*nBitsPerSymb/decodingRate_, ...
                genRate_, ...
                nNotConform(iSNR));
        end

        nErrorsBits(iSNR)     = nErrorsBits(iSNR) + errorsBin;
        nErrorsSymb(iSNR)     = nErrorsSymb(iSNR) + errors;
        nErrorsPaquet(iSNR)   = nErrorsPaquet(iSNR) + (errors~=0);
        nPaquetsEnvoyes(iSNR) = nPaquetsEnvoyes(iSNR) + 1;
    end

    if display
        carriageReturn = strjoin(repmat("\b", msgSz, 1), "");
        fprintf(carriageReturn);
        decodingRate_  = decodingRate/nPaquetsEnvoyes(iSNR);
        encodingRate_  = encodingRate/nPaquetsEnvoyes(iSNR);
        genRate_       = genRate/nPaquetsEnvoyes(iSNR);
        msgSz          = fprintf(msgStats, ...
            params.nWalsh, ...
            SNRdB(iSNR), ...
            nErrorsSymb(iSNR), ...
            nPaquetsEnvoyes(iSNR), ...
            nErrorsBits(iSNR)/(nPaquetsEnvoyes(iSNR)*nSymbPerFrame*M), ...
            nErrorsSymb(iSNR)/(nPaquetsEnvoyes(iSNR)*nSymbPerFrame), ...
            nErrorsPaquet(iSNR)/nPaquetsEnvoyes(iSNR), ...
            nSymbPerFrame*nBitsPerSymb/encodingRate_, ...
            nSymbPerFrame*nBitsPerSymb/decodingRate_, ...
            genRate_, ...
            nNotConform(iSNR));
        fprintf("\n");
    end
    previousBER = nErrorsBits(iSNR)/(nPaquetsEnvoyes(iSNR)*nSymbPerFrame*M);
end

errStats = struct(...
    "nPaquetsEnvoyes", nPaquetsEnvoyes, ...
    "nErrorsBits", nErrorsBits, ...
    "nErrorsSymb", nErrorsSymb, ...
    "nErrorsPaquets", nErrorsPaquet, ...
    "nNotConform", nNotConform, ...
    "BER", nErrorsBits./(nPaquetsEnvoyes*M*nSymbPerFrame), ...
    "SER", nErrorsBits./(nPaquetsEnvoyes*nSymbPerFrame), ...
    "FER", nErrorsBits./(nPaquetsEnvoyes));
end