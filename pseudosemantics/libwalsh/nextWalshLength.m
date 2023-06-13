function [newLength] = nextWalshLength(value, nbCoeffs)
%NEXTWALSHLENGTH Summary of this function goes here
%   Detailed explanation goes here


newLength = nbCoeffs * floor( (value+nbCoeffs)/nbCoeffs + 1/2 );
end

