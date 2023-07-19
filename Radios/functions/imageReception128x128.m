function [Img, sig] = imageReception128x128(buffer1, buffer2, commParams, radioParams)



descrambler = comm.Descrambler( ...
    "CalculationBase", commParams.scramblerBase, ...
    "Polynomial", commParams.scramblerPolynomial, ...
    "InitialConditions", commParams.scramblerInitState, ...
    "ResetInputPort", commParams.scramblerResetPort);
imgSize = 65536;


[sig, phaseOffsetOrigin] = synchronize(buffer1, buffer2, commParams, radioParams);

if length(sig) > imgSize
    sigRx = sig(1:imgSize);
else
    sigRx = zeros(1, imgSize);
    sigRx(1:length(sig)) = sig;
end

Img = symbols2img(sigRx, descrambler, phaseOffsetOrigin, commParams);