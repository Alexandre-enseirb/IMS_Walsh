function [sigComplexI, sigComplexQ, walshCarrier] = hilbertTransformNoDistortion(sigReel, carrier)
%HILBERTTRANSFORM Summary of this function goes here
%   Detailed explanation goes here


% Extraction du signal analytique et de la TH de s
sigAnalytic = 1/2 * hilbert(sigReel);
sigHilbert  = 1j * ( sigReel - 2 * sigAnalytic );


    
cosine = real(carrier);
sine = imag(carrier);

sigComplexI = real(sigReel .* cosine + ...
    sigHilbert .* sine );
sigComplexQ = real(sigHilbert .* cosine - ...
    sigReel .* sine);

end

