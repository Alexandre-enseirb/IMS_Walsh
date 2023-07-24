clear; clc; close all; dbstop if error;

setPath();

%% SETUP

rng('shuffle');

filename = strcat(tempdir, "mSharedMemData128128.matdata");

if ~isfile(filename)
    f = fopen(filename, "w+");
    fwrite(f, zeros(128, 128, "uint8"), "uint8");
    fclose(f);
end

fileWrite = memmapfile(filename, "Format", "uint8" , "Writable", true);
while true
    data = randi([0 255], 128, 128, "uint8");
    % disp(data(1:10));
    fileWrite.Data = data(:);
    pause(.2);
end
disp("written");