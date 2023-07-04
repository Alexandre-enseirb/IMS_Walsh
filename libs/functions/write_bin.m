function [] = write_bin(status, value, fID)
%WRITE_COMBINATION Summary of this function goes here
%   Detailed explanation goes here

if ~exist("fID","var")
    fID = 1;
end

if strcmp(status,'ok')
    fwrite(fID, value, 'double');
elseif strcmp(status,'ko')
    return;
else
    error("Statut non reconnu");
end


end

