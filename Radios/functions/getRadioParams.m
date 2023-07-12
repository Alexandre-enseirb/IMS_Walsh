function [params] = getRadioParams(radioType)

params = struct();
params.centerFrequency = 500e6;   % Frequence porteuse
params.LOOffset = 0;              % Offset de l'oscillateur local
params.enableBurstMode = false;   % Mode 'rafale'
params.nFramesInBurstMode = 100;  % Nombre de frames par rafale
params.dataType = 'int16';        % Type de donnees
params.PPSSource = 'external';    % Source de pulsations
params.ClockSource = 'external';  % Source d'horloge
params.MasterClockRate = 10e6;    % Rythme de travail de la radio
params.InterpolationFactor = 4;  % Facteur d'interpolation de l'emetteur
params.DecimationFactor = 4;     % Facteur de decimation du recepteur
params.RxOversampling = params.InterpolationFactor/params.DecimationFactor; % Surechantillonnage du recepteur

if strcmpi(radioType, 'tx')
    % Parametres specifiques a l'emetteur
    % params.enableBurstMode = true;
    % params.nFramesInBurstMode = 200;
    params.Gain = 35;
    params.ChannelMapping = 1;
    params.InterpolationDecimationFactor = params.InterpolationFactor; % pour la retrocompatibilite du code
elseif strcmpi(radioType, 'rx')
    % Parametres specifiques au recepteur
    params.Gain = 37;
    params.ChannelMapping = 1;
    params.InterpolationDecimationFactor = params.DecimationFactor; % pour la retrocompatibilite du code
elseif strcmpi(radioType, 'obs')
    params.Gain = 35;
    params.ChannelMapping = [1 2];
    params.InterpolationDecimationFactor = params.InterpolationFactor;
    params.PPSSource = 'external';    % Source de pulsations
    params.ClockSource = 'external';  % Source d'horloge
end
