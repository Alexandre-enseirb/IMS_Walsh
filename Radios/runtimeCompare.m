clear; 
clc;
close all;
dbstop if error;

setPath();

%%

symbPerFrame = 3;
fse = 3000;
uncompiledTimer = 0;
compiledTimer = 0;
nRuns = 10000;

for i=1:nRuns
    tic;
    generateNewUSRPFrameQPSK(symbPerFrame, fse);
    uncompiledTimer = uncompiledTimer + toc;
    tic;
    generateNewUSRPFrameQPSK_mex(symbPerFrame, fse);
    compiledTimer = compiledTimer + toc;
end

fprintf("Results:\nMean compiled time: %.6f\nMean uncompiled time: %.6f\n", compiledTimer/nRuns, uncompiledTimer/nRuns);