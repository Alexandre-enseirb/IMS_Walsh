function [Xw_Q] = hilbertWalsh(Xw_I, W)
%HILBERTWALSH Summary of this function goes here
%   Detailed explanation goes here

N = size(W, 1);

% Source : Walsh_FR1_RF_IQ_Hilbert.m (Maxandre Fellmann)
signFrequency = linspace(-N/2, N/2, N);
Hf            = diag(-1j*sign(signFrequency));

a                   = 0 : N-1;
b                   = transpose(a);                                 
F                   = 1 / sqrt(N) * exp(-2 * pi  *1i / N).^(b * a); % Matrice de Fourrier
A                   = F \ Hf * F;                                   
Hw                  = real(W \ A * W); % Elimination de la partie imaginaire (de module quasi-nul)

Xw_Q             =  Hw*Xw_I;

end

