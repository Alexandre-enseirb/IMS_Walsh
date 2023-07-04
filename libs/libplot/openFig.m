function [fgh, axh] = openFig(name, position)
%LIBPLOT Summary of this function goes here
%   Detailed explanation goes here

if ~exist("name", "var")
    name = "Undefined";
end

if ~exist("position", "var")
    position = getFigPosition();
end

fgh = figure("Name", name, "Position", position);
axh = gca;
hold(axh, "on");
grid(axh, "on");
axh.FontSize=18;
end

