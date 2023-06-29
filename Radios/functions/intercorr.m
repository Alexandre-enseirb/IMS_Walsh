function [p] = intercorr(r,s)
%INTERCORR Summary of this function goes here
%   Detailed explanation goes here

T = length(s);

offset=1;
p=[];
while offset+T < length(r)
    E =  sum(r(offset:offset+T-1).*conj(s));
    
    p = [p E];
    
    
    offset = offset+1;
end

end

