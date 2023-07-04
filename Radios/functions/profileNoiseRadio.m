function [noiseMean, noiseVariance] = profileNoiseRadio()
%PROFILENOISERADIO etudie les proprietes du bruit associe a la radio

loadedData = load("noiseExtract.mat", "noise");
noise = loadedData.noise;

noiseMean = mean(noise);

noiseVariance = var(noise);

end