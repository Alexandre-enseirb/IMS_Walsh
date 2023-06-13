function [out, t] = upsample_(x, new_size)
%UPSAMPLE_ Summary of this function goes here
%   Detailed explanation goes here
ratio = floor(new_size/(length(x)));
t = 0:1/new_size:1;
out = [];
for i = 1:length(x)
    out = [out x(i)*ones(1,ratio)];
end

% out = [out x(end)];
end

