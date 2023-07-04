function [amplitudes] = update_amp(amplitudes, maxval, step, direction)
%UPDATE_AMP Summary of this function goes here
%   Detailed explanation goes here

if strcmp(direction,"descend")
    step=-1*step;
end


[l,c] = size(amplitudes);

if l>1 && c>1
    error("amplitudes doit etre un vecteur");
end

sz            = max(l,c);
i             = 1;
amplitudes(i) = amplitudes(i) + step;
while abs(amplitudes(i))>=abs(maxval) % gere aussi le cas negatif
    amplitudes(i) = -maxval;
    i             = i+1;
    if i > sz
        break;
    end
    amplitudes(i) = amplitudes(i) + step;
end

end

