function [] = disp_mult(s1,s2, batch_size,speed)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here

figure();
grid on;

if ~exist('batch_size','var')
    batch_size=100;
end
if ~exist('speed','var')
    speed=.1;
end

i=1;
while i+batch_size < length(s1)
    plot(real(s1(i:i+batch_size-1)),imag(s1(i:i+batch_size-1)),'r+ ');
    grid on
    hold on
    plot(real(s2(i:i+batch_size-1)),imag(s2(i:i+batch_size-1)),'b+ ');
    hold off
    legend(["signal 1","signal 2"]);
    xlim([-1 1]);
    ylim([-1 1]);
    title(i)
    drawnow limitrate
    pause(speed)
    i=i+batch_size;
end
end

