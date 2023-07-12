clear; clc; close all; dbstop if error;

setPath();
%pause(0.5);
[Rx, Data, nOverrun] = recvData();

release(Rx);

counter = 0;
fileformat = "Rx_data_%d.mat";
while isfile(sprintf(fileformat, counter))
    counter = counter +1;
end
filename = sprintf(fileformat, counter);
save(filename, "Data", "nOverrun");
