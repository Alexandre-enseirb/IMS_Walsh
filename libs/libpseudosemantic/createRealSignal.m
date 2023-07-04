function [sWalsh, sigRecdB, coeffs, Sk ] = createRealSignal(nQPSKSymbPerOSDMSymb, nSymbOSDMTx, ~, carrier, symbOSDMDuration, modulatedCoeffs, coeffCarrier, attenuationFactor, params)

% Generation of random symbols
idxSymb  = randi([1 64], nQPSKSymbPerOSDMSymb, 1);

% Modulation et surechantillonnage
Sk             = qam64_fast_fast(idxSymb, params.maps);
Sk             = reshape(Sk, nQPSKSymbPerOSDMSymb, []);
Sk = real(Sk);

sl_      = zeros(size(carrier.walsh.temporel));

coeffs         = real(carrier.walsh.Xw_b);
upsampledSymbs = zeros(nQPSKSymbPerOSDMSymb, symbOSDMDuration/1 * size(Sk, 2));
for i=1:nQPSKSymbPerOSDMSymb
    upsampled_symb      = upsample_(Sk(i,:), symbOSDMDuration/1 * size(Sk, 2));
    upsampledSymbs(i,:) = upsampled_symb;
end
coeffs(modulatedCoeffs,:) = upsampledSymbs / attenuationFactor;
slStruct                          = walsh(coeffs, params.W, params.Nfft, params.osr, false);
sl = slStruct.temporel;

s = real(sl);

% Extraction des coeffs + simulation DAC
[sWalsh, XWalsh] = wse(s, params, length(s));

% Conformity verification
sigRecFFT = fftshift(fft(sWalsh, params.Nfft));
sigRecPow = abs(sigRecFFT).^2;
sigRecdB  = 20*log10(sigRecPow/max(sigRecPow));
end