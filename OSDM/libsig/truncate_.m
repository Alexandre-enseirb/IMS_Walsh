function [Xw_b] = truncate_(Xw_b, truncature)
%TRUNCATE_ truncate a vector of coefficients
%
%   [Xw_bt] = TRUNCATE_(Xw_b, truncature) truncate the vector contained in
%   Xw_b of truncature coefficients before and after its middle. If
%   2*truncature is superior than the length of Xw_b, every coefficient is
%   truncated

len = length(Xw_b);

mid = ceil(len/2);

start = max(1, mid-(truncature-1));
stop  = min(len, mid+(truncature));

Xw_b(start:stop) = 0;


end

