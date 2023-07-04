function [figurePos] = getFigPosition()
%GETFIGPOSITION Summary of this function goes here
%   Detailed explanation goes here

MP = get(0, "MonitorPositions");

if MP(3) == 5120 && MP(4) == 1080 % Config. du labo
    figurePos = [3841 10 1920 1080];
elseif size(MP, 1) == 3
    figurePos = MP(3,:);
else
    figurePos = get(0, "ScreenSize");
end

end

