function [combinations] = improvedCoefficientsSelectionv2(nCoefficientsToSelect, ...
    cluster, ...
    carrier, ...
    nSymbolsCombinationsPerCoefficientsCombinations, ...
    nModSymbPerOSDMSymb, ...
    nSymbOSDMTx, ...
    nCombinationsToGenerate, ...
    symbOSDMDuration, ...
    coeffCarrier, ...
    attenuationFactor, ...
    stopAtMax, ...
    params)
%IMPROVEDCOEFFICIENTSSELECTIONV2 generates combination of modulated Walsh coefficients
%
%   [combinations] = IMPROVEDCOEFFICIENTSSELECTIONV2(nCoefficientsToSelect, cluster, nSymbolsCombinationsPerCoefficientsCombinations,
%   nCombinationsToGenerate, params) generates combinations of modulated Walsh coefficients and tests them with the given modulation.

% dictionnary to store the ouput
combinations = dictionary();

cluster = fliplr(cluster);

depth = nCoefficientsToSelect;
nBestFitsPerDepth = 6;

% fft of every cluster 2 function
fftWalsh = zeros(length(cluster), params.Nfft);

for iFFT = 1:length(cluster)
    fftWalsh(iFFT, :) = abs(fftshift(fft(params.W(cluster(iFFT, :), :), params.Nfft))).^2;
    % fftWalsh(iFFT, :) = 20*log10(fftWalsh(iFFT,:)/max(fftWalsh(iFFT,:)));
end

% avoid infinite values
% fftWalsh(fftWalsh==-Inf) = 0;

coefficients = findBestFits(cluster, fftWalsh, nBestFitsPerDepth, depth, params);
iCoefficients = 1;
validCombinations = 0;
allAttempts = 0;

% Generation of valid combinations
while validCombinations < nCombinationsToGenerate || ~stopAtMax
    % Test a certain amount of combinations per coefficients family
    for iReload=1:nSymbolsCombinationsPerCoefficientsCombinations
        % Since we have no clue for now about which coefficients are best, we randomize it
        [~, sigdB, ~, realVals] = createRealSignal(nModSymbPerOSDMSymb, nSymbOSDMTx, 0, carrier, symbOSDMDuration, coefficients(iCoefficients, :), coeffCarrier, attenuationFactor, params);
        allAttempts = allAttempts + 1;
        % If the generated signal has a conform spectrum
        if isConform(sigdB(params.nullFrequencyIdx:params.maxConformFrequency), params.BW_visible(params.nullFrequencyIdx:params.maxConformFrequency).')
            % Save it to the dictionary.
            [coeffsSorted, idxPerm] = sort(coefficients(iCoefficients, :), "ascend");
            realVals = realVals(idxPerm);
            savedData = [coeffsSorted; realVals.'];
            key = keyHash(savedData);
            % Evite les doublons
            if combinations.numEntries == 0 || ~combinations.isKey(key)
                combinations(key) = {savedData};
                validCombinations = validCombinations + 1;
            end
        end
        
    end
    iCoefficients = iCoefficients+1;
    if iCoefficients > size(coefficients, 1)
        fprintf(2, "Could not generate enough combinations. Exiting early.");
        validCombinations = nCombinationsToGenerate + 1; % exit the while in a clean way
        stopAtMax = true; % ensures we leave even if we wanted combinations for every coefficient families
    end
    fprintf("[%3d]: %4d/%4d found (%8d combinations tested.)\n",iCoefficients, validCombinations, nCombinationsToGenerate, allAttempts);
end
end

function toto = tata(tutu)

foo = bar;

end




% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

function [coefficients] = findBestFitsRecursive(coefficients, cluster2, powerSpectrums, nBestFitsPerDepth, depth, maxDepth, params)

% Determination du nombre de repetitions a cette profondeur
nRepeat = nBestFitsPerDepth^(maxDepth-depth);
nCoeffs = size(coefficients, 1);

% Determination des coefficients de la profondeur donnee
[~, idxIn] = ismember(coefficients(:, 1:depth-1), cluster2);
% Par construction de la recursion, on a une seule valeur dans idxIn, donc
idxIn = unique(idxIn);
[~, idxOut] = setdiff(cluster2, cluster2(idxIn));

% Creation du signal correspondant a nos indices d'entree
sigIn = zeros(size(params.W(1,:)));

% On accumule nos signaux temporels
for i=1:length(idxIn)
    sigIn = sigIn + params.W(idxIn(i), :);
end

% FFT et on duplique autant de fois que l'on veut tester de combinaisons
powerSpectrumsIn = abs(fftshift(fft(sigIn, params.Nfft))).^2;
powerSpectrumsIn = repmat(powerSpectrumsIn, length(idxOut), 1);

% On calcule enfin nos combinaisons et on va trier celles qui ont le meilleur etalement
correlation = correlationNoLag(powerSpectrumsIn, powerSpectrums(idxOut, :));

[~, idx] = sort(correlation, 'ascend');
toAdd = repmat(cluster2(idxOut(idx(1:nBestFitsPerDepth))).', nRepeat, 1);
coefficients(:, depth) = toAdd(:);
if depth < maxDepth
    for i=1:(nCoeffs/nRepeat)
        idxStart = (i-1) * nRepeat + 1;
        idxStop = i*nRepeat;
        coefficients(idxStart:idxStop, :) = findBestFitsRecursive(coefficients(idxStart:idxStop, :), cluster2, powerSpectrums, nBestFitsPerDepth, depth+1, maxDepth, params);
    end
end
end

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

function [coefficients] = findBestFits(cluster2, powerSpectrums, nBestFitsPerDepth, maxDepth, params)

nRepeat = nBestFitsPerDepth^(maxDepth-1);
nRows = nRepeat * length(cluster2);

firstCol = repmat(cluster2.', nRepeat, 1);
firstCol = firstCol(:);

coefficients = zeros(nRows, maxDepth);
coefficients(:, 1) = firstCol;

% Initialisation de la recusion
depth = 1;

% Parcours de tous les elements du cluster pour lancer la recursion
for iCluster = 1:length(cluster2)
    idxStart = (iCluster-1) * nRepeat + 1;
    idxStop  = iCluster * nRepeat;
    coefficients(idxStart:idxStop, :) = findBestFitsRecursive(coefficients(idxStart:idxStop, :), cluster2, powerSpectrums, nBestFitsPerDepth, depth+1, maxDepth, params);
end
end

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

function [correlation] = correlationNoLag(sigToAnalyze, otherSigs)

correlation = sum(sigToAnalyze.*otherSigs, 2);

end
