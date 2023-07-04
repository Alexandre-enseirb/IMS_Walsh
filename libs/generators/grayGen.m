function [code] = grayGen(n)
%GRAYGEN Summary of this function goes here
%   Detailed explanation goes here

if n < 1
    error("n has to be superior or equal to 1");
end

code = [0, 1];

for i=2:n
    mirror = code(end:-1:1);
    mirror = mirror + 2^(i-1);
    code = [code mirror];
end

end

