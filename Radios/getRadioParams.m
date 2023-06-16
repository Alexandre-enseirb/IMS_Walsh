function [params] = getRadioParams(radioType)

params = struct();
params.centerFrequency = 500e6;   % Frequence porteuse
params.LOOffset = 0;              % Offset de l'oscillateur local
params.enableBurstMode = false;   % Mode 'rafale'
params.nFramesInBurstMode = 100;  % Nombre de frames par rafale
params.dataType = 'int16';        % Type de donnees
params.PPSSource = 'internal';    % Source de pulsations
params.ClockSource = 'external';  % Source d'horloge
params.MasterClockRate = 30e6;    % Rythme de travail de la radio
params.InterpolationFactor = 30;  % Facteur d'interpolation de l'emetteur
params.DecimationFactor = 30;     % Facteur de decimation du recepteur
params.RxOversampling = params.InterpolationFactor/params.DecimationFactor; % Surechantillonnage du recepteur

if strcmpi(radioType, 'tx')
    % Parametres specifiques a l'emetteur
    params.Gain = 40;
    params.ChannelMapping = [1 2];
    params.InterpolationDecimationFactor = params.InterpolationFactor; % pour la retrocompatibilite du code
elseif strcmpi(radioType, 'rx')
    % Parametres specifiques au recepteur
    params.Gain = 35;
    params.ChannelMapping = 1;
    params.InterpolationDecimationFactor = params.DecimationFactor; % pour la retrocompatibilite du code
end