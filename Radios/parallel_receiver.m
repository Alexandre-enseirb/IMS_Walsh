clear; clc; close all; dbstop if error;

setPath();

%% PARALLEL POOL CREATION

flag    = fullfile(tempdir, "radioRxflag");


f = fopen(flag, "w+");
fwrite(f, int8(0), "int8");
fclose(f);

mflag    = memmapfile(flag, "Format", "int8" , "Writable", true);
imgRx(mflag);