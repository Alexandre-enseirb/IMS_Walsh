function [colorMap] = plotColors()
%PLOTCOLORS Summary of this function goes here
%   Detailed explanation goes here


keySet = {'blue', 'red', 'orange', 'purple', 'green', 'lightblue', 'bordeaux', 'black'};
values = {"#0072BD", "#D95319","#EDB120","#7E2F8E","#77AC30","#4DBEEE","#A2142F","#000000"};

colorMap = containers.Map(keySet, values);
end

