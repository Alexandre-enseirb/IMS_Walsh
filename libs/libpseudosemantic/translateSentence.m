function [idx] = translateSentence(sentence, mapping)
%TRANSLATESENTENCE Summary of this function goes here
%   Detailed explanation goes here

sentenceList = strsplit(lower(erasePunctuation(sentence)), " ");
if sentenceList(end) == ""
    sentenceList = sentenceList(1:end-1);
end

if any(~ismember(sentenceList, mapping.keys))
    idxErrors = ~ismember(sentenceList, mapping.keys);
    errorFormat = strjoin(repmat("%s", sum(idxErrors), 1));
    faultedWords = sentenceList(~ismember(sentenceList, mapping.keys));
    errorMsg = strjoin(["The following words are unknown: " errorFormat], "");
    error(errorMsg, faultedWords{:});
end
idx = mapping(sentenceList);
end

