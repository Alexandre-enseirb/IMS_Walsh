function [sentence] = translateIdx(idx, mapping)
%TRANSLATESENTENCE Summary of this function goes here
%   Detailed explanation goes here

idx = uint64(idx);

if any(~ismember(idx, mapping.keys))
    idxErrors = ~ismember(idx, mapping.keys);
    errorFormat = strjoin(repmat("%d", sum(idxErrors), 1));
    faultedWords = idx(idxErrors);
    errorMsg = strjoin(["Unknown entries: " errorFormat], "");
    error(errorMsg, faultedWords);
end
sentence = strjoin(mapping(idx), " ");
end

