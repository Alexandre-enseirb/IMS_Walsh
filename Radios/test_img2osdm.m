clear; clc; close all; dbstop if error;

setPath();

%% Parameters

commParams = getCommParamsForWalsh("tx");
radioParams = getRadioParams("tx");
walshParams = getWalshParams();
colors = plotColors();

scrambler = comm.Scrambler( ...
    "CalculationBase", commParams.scramblerBase, ...
    "Polynomial", commParams.scramblerPolynomial, ...
    "InitialConditions", commParams.scramblerInitState, ...
    "ResetInputPort", commParams.scramblerResetPort);

[sig]=img2osdm(commParams, radioParams, walshParams, scrambler);