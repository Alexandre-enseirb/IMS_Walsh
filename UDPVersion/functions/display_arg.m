function [] = display_arg(s, batch_size,speed)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here

figure();

if ~exist('batch_size','var')
    batch_size=100;
end
if ~exist('speed','var')
    speed=0.1;
end

i=1;
while i+batch_size < length(s)
    plot(real(exp(1j*s(i:i+batch_size-1))),imag(exp(1j*s(i:i+batch_size-1))),'r+ ');
    xlim([-1 1]);
    ylim([-1 1]);
    title(i)
    drawnow limitrate
    pause(speed)
    i=i+batch_size;
end
end

