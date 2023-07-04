function [F] = genFourier(Nfft, Nwalsh)
%GENFOURIER Summary of this function goes here
%   Detailed explanation goes here

F = zeros(Nfft,Nwalsh);

for j=1:Nfft
    for k=1:Nwalsh
        F(j,k) = 1/sqrt(Nfft) * exp(-1j*2*pi*(j-1)*(k-1)/Nfft);
    end
end
end

