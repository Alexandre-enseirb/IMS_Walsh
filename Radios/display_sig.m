function [] = display_sig(s, batch_size,speed)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here

if ~exist('batch_size','var')
    batch_size=100;
end
if ~exist('speed','var')
    speed=.1;
end
figure()
i=1;
while i+batch_size < length(s)
    plot(real(s(i:i+batch_size-1)),imag(s(i:i+batch_size-1)),'r+ ');
    xlim([-4000 4000]);
    ylim([-4000 4000]);
    title(i)
    drawnow limitrate
    pause(speed)
    i=i+batch_size;
end
end

