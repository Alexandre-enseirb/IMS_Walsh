function [out] = compute_power(sigf, type)
%POWER Summary of this function goes here
%   Detailed explanation goes here

if ~exist("type","var")
    type="spectrum";
end

switch type
    case "spectrum"
        out = power_spectrum(sigf);
    case "sum"
        out = cum_power(sigf);
    case "mean"
        out = mpower(sigf);
    otherwise
        error("Type non reconnu.");
end
end

function [spectrum] = power_spectrum(sigf)

spectrum = abs(sigf).^2;

end


function [total_power] = cum_power(sigf)

total_power = sum(abs(sigf).^2);

end

function [mean_power] = mpower(sigf)

sz = length(sig);

mean_power = sum(abs(sigf).^2)/sz;

end