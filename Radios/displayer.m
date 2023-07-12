clear; clc; close all; dbstop if error;
radioParams = getRadioParams('rx');
commParams  = getCommParams('tx');

status = 0;

filenames = ["img_rx_no_clock_no_pps_rectwin.mat", ...
             "img_rx_clock_no_pps_rectwin.mat", ...
             "img_rx_clock_pps_rectwin.mat"];

% Instantiation de la radio
radio = comm.SDRuReceiver("Platform", "B210", ...         % Type de radio
    "SerialNum", "3218C8E", ...                           % Numero de serie
    "CenterFrequency", radioParams.centerFrequency, ...   % Frequence porteuse
    "ChannelMapping", 1, ...                              % Combien d'entrees/sorties
    "ClockSource", radioParams.ClockSource, ...           % Source de 10 MHz
    "EnableBurstMode", radioParams.enableBurstMode, ...   % Mode rafale
    "Gain", radioParams.Gain, ...                         % Gain a l'entree
    "LocalOscillatorOffset", radioParams.LOOffset, ...    % ?
    "MasterClockRate",  radioParams.MasterClockRate, ...  % Vitesse de l'horloge de la radio
    "PPSSource", radioParams.PPSSource, ...               % Source de pulsations (1 Hz)
    "TransportDataType", radioParams.dataType, ...        % Type des donnees en entree
    "DecimationFactor",radioParams.InterpolationDecimationFactor, ...
                                                          % Facteur de sous-echantillonnage en entree
    "OutputDataType", "double", ...                       % Type des donnees recues dans MATLAB
    "SamplesPerFrame", commParams.samplesPerFrame);       % Nombre d'echantillons recus par appel de la radio



% Choix du nom de fichier en fonction des synchronisations externes
if strcmpi(radioParams.ClockSource, 'external')
    if strcmpi(radioParams.PPSSource, 'external')
        filename = filenames(3); % Clock && PPS
    else
        filename = filenames(2); % Clock only
    end
else
    filename = filenames(1); % Nothing
end

Nfft = 4096;  % Nombre de points de la transformee de Fourier
nOverrun = 0; % Compte les overrun

data_ = radio(); % Initialisation de la radio (charge l'image FPGA en avance)

% Verouillage sur la source de 10 MHz si utilisee
if strcmpi(radioParams.ClockSource, "external")
    lockedStatus = referenceLockedStatus(radio);
    disp(lockedStatus);
end


i = 1;
datalength = length(data_); % Longueur d'une frame lue
nBuffers = 2;               % Nombre de buffers utilises pour la reception
nBufferWindows = nBuffers*radioParams.RxOversampling*commParams.nFramesTx;
                            % Taille de buffers necessaire pour garantir d'avoir le signal entier
buffer1 = zeros(datalength, nBufferWindows);
                            % Allocation du buffer 1
buffer2 = zeros(datalength, nBufferWindows);
                            % Allocation du buffer 2

timeout = -1;               % Nombre de frames a lire avant de sauvegarder
                            % une fois notifie que le signal est envoye

halfBufferWindows = nBufferWindows/2; % Taille d'un demi-buffer

while true

    [buffer1(:, i), ~, overrun] = radio(); % Reception
    
    % Ecriture en memoire (choix de ii sensiblement equivalent a un modulo halfBufferWindows)
    % Pour ma defense, il me semble que cette approche est legerement plus rapide
    if i <= halfBufferWindows
        ii = i+halfBufferWindows;
    elseif i <= nBufferWindows
        ii = i-halfBufferWindows;
    end
    buffer2(:, ii) = buffer1(:, i);

    i = i+1;
    % Si on a rempli le buffer
    if i==nBufferWindows+1
        
        % Affichage
        plot(real(buffer1(:)));
        drawnow limitrate;
        i=1; % et ca repart
    end

end



