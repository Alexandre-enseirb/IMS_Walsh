function [Img] = imageReception128x128(filename)

commParams = getCommParams('tx');
commParams.fse = 4; % temp
radioParams = getRadioParams('tx');

descrambler = comm.Descrambler( ...
    "CalculationBase", commParams.scramblerBase, ...
    "Polynomial", commParams.scramblerPolynomial, ...
    "InitialConditions", commParams.scramblerInitState, ...
    "ResetInputPort", commParams.scramblerResetPort);
imgSize = 65536;
load(filename, "buffer1", "buffer2");

[sig, phaseOffsetOrigin] = synchronize(buffer1, buffer2, commParams, radioParams);

if length(sig) > imgSize
    sigRx = sig(1:imgSize);
else
    sigRx = zeros(1, imgSize);
    sigRx(1:length(sig)) = sig;
end

Img = symbols2img(sigRx, descrambler, phaseOffsetOrigin, commParams);