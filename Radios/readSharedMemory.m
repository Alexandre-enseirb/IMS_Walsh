clear; clc; close all; dbstop if error;

setPath();

%% SETUP

filename = strcat(tempdir, "mSharedMemData128128.matdata");

if ~isfile(filename)
    f = fopen(filename, "w+");
    fwrite(f, zeros(128, 128, "uint8"), "uint8");
    fclose(f);
end

fileRead = memmapfile(filename, "Format", "uint8" , "Writable", true);
figure
plot(0);
axh = gca;
previousImage = zeros(16384, 1, "uint8");
newImage = fileRead.Data;
while true
    
    if any(newImage~=previousImage)
        disp("refreshing");
        imagesc(axh, reshape(newImage, 128, 128));
        colormap gray; colorbar;
        drawnow limitrate;
        previousImage(:) = newImage(:);
    end
    pause(.1);
end