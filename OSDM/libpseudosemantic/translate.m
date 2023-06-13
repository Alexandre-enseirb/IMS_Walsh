function [idx] = translate(word, mapping)
%TRANSLATE Summary of this function goes here
%   Detailed explanation goes here

word = lower(word);

if ismember(word, mapping.keys)
    idx = mapping(word);
else
    error("Unknown word %s. Aborting.", word);
end

end

