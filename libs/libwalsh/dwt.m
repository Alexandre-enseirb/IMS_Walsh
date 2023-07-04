function [X, sig] = dwt(x, W, order, sliding)
%DWT est la transformee discrete de Walsh d'un signal.
% 
%   DWT(x, W) realise la transformee discrete de Walsh de x avec le maximum de
%   coefficients possibles par rapport a la longueur du signal (maximum
%   2^6, evolue en puissances de deux)
%
%   DWT(x, W, order) realise la transformee discrete de Walsh de x avec
%   2^order coefficients
%
%   DWT(x, W, order, sliding) realise la transformee discrete de Walsh de x
%   avec 2^order coefficients et sur toutes les fenetres de longueur
%   2^order composant x si sliding vaut `true`

if ~exist('order','var')
    order = min(floor(log2(length(x))),6);
end

if ~exist('sliding','var')
    sliding=false;
end

if ~exist("Fse","var")
    Fse = 1;
end

[l,~] = size(x);
if l==1
    x = x.';
end

nbCoeffs = 2^order;

if sliding
    nbFen = ceil(length(x)/nbCoeffs);
    x = zero_pad(x, nbFen*nbCoeffs);    
    sig = reshape(x, nbCoeffs, []);
else
    if nbCoeffs > length(x)
        x = zero_pad(x, nbCoeffs);
    end
    sig = x(1:nbCoeffs);  
end
X = W*sig;
end

function [x_pad] = zero_pad(x, l)
   
if l < length(x)
    error("Ne peut pas pad sur une longueur inferieure a celle des donnees.");
end

if l == length(x)
    x_pad = x;
    return;
end

current_length = length(x);
[~,tmp] = size(x);

if tmp==1
    x=x.';
end

x_pad = [x zeros(1, l-current_length)];

x_pad = x_pad.';

end