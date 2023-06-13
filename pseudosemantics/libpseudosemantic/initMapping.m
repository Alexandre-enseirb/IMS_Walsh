function [mapping, wordProbabilities] = initMapping(combinations)
%INITMAPPING generates a mapping for pseudo-semantic communications
%
%   [MAPPING] = INITMAPPING() generates a mapping between modulated Walsh coefficients and integer values which
%   represent the semantic symbol.
%
%   This function is to test variations in the mapping of the coefficients. Some questions that should be asked
%   are:
%       - "Should the index of the coefficient matter in the mapping? (i.e. is [3, 5, 7] using coefficients 22, 34 and 47 the same as [3, 5, 7] using 
%       coefficients 8, 13 and 27?)"
%
%       - "Should the order of the coefficients matter? (i.e. is [7, 7, -3] equivalent to [-3, 7, 7] if the three
%       same coefficients are used in a different order)"
%
%       - How to implement a "minimal distance" decoder?
%
%   Multiple iterations of this file shall exist and this function's prototype may evolve to reflect those changes

uniqueWords = fopen("words_list.txt");
nextl = fgetl(uniqueWords);
wordProbabilities = dictionary();
mapping = dictionary();
% randomise les cles pour eviter un "effet voisin" du a la generation des combinaisons
keys = randsample(combinations.keys, combinations.numEntries);
currline = 1;
while nextl ~= -1
    
    mapping(nextl) = keys(currline);
    
    nextl = fgetl(uniqueWords);
    currline = currline + 1;
end

end

