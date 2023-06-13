function [sig] = sinusoide(fondamental, amplification, params, decalage, harmoniques, amplitudes)
%SINUSOIDE Summary of this function goes here
%   Detailed explanation goes here

if (nargin <= 4)
    harmoniques=[];
   
    amplitudes=[];
end

if nargin==5
    error("Merci de preciser des amplitudes pour les harmoniques");
end

if ~exist("decalage","var")
    decalage=0;
end

if length(harmoniques) ~= length(amplitudes)
    error("Veuillez specifier une amplitude par frequence harmonique");
end

frequences_harmoniques = (harmoniques+1) * (fondamental+decalage);

frequences = [fondamental frequences_harmoniques];
amplitudes = amplification * [1 amplitudes];

freq_temps_mat = frequences.' * params.time_axis;

sig = amplitudes * sin(2*pi*freq_temps_mat); 


end


