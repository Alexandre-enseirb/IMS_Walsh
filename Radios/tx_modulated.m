close all
clearvars -except tx
reset_sdr = 1;
setPath();
%% Parameters of the USRP B210

carriers = [600e6 1.5e9 2.45e9]; % Hz
gains = 5:5:40;
txMinDuration = 12; % secondes
msgHeader = "| Carrier (MHz) | Gain | Status |\n";
msgSep    = "+---------------+------+--------+\n";
msgFormat = "| %13.3f | %4d | %s |";
status = ["OK", "IP"]; % Ok, In Progress
pauseTime = 2; % secondes
amplitude         = 1;
M = 2;
symbPerFrame = 30;
samples_per_frame = 300;
fse = samples_per_frame/symbPerFrame;

if(reset_sdr == 1)
    disp('Configuration de la radiologicielle Tx')
    tx                       = comm.SDRuTransmitter('Platform','B210','SerialNum','32752A2');
    tx.ChannelMapping        = [1 2];
    tx.CenterFrequency = carriers(1);
    tx.Gain = 40;
    tx.LocalOscillatorOffset = 0;
    tx.PPSSource             = 'Internal';
    tx.ClockSource           = 'Internal';
    tx.MasterClockRate       = 30e6;
    tx.InterpolationFactor   = 10;
    tx.TransportDataType     = 'int16';
    tx.EnableBurstMode       = true;
    if(tx.EnableBurstMode)
        tx.NumFramesInBurst = 100;
    end
else
    reset(tx)
    release(tx)
    disp('Utilisation de la configuration de la radiologicielle')
end

tx_sample_rate = tx.MasterClockRate/tx.InterpolationFactor; %% Matlab sample rate = MasterClk/InterpolFactor
tx_sample_duration = 1/tx_sample_rate; % secondes
tx_frame_duration = tx_sample_duration*samples_per_frame;
num_frames     = ceil(txMinDuration/tx_frame_duration);

% symbPerFrame = samples_per_frame/fse;
Ds = symbPerFrame/tx_frame_duration;

nBits = symbPerFrame*M;

g = 1/fse * ones(1, fse);
%%


%% General parameters



%% Sinwave

% CW                = dsp.SineWave(amplitude, frequency, 'SampleRate', tx_sample_rate, 'SamplesPerFrame', samples_per_frame, 'ComplexOutput', true);


%% Send Signal
frame    = 1;
t_sample = 1/tx_sample_rate;
t_total  = t_sample*samples_per_frame*num_frames;

%fprintf('Durée de transmission = %fs \n', t_total)
msgSz = fprintf(msgFormat, carriers(1), 8, status(2));
fprintf("\n");
errored_frames = 0;
while true
    
    tx_signal_norm = generateNewUSRPFrameQPSK(symbPerFrame, fse, length(tx.ChannelMapping));
    underrun = step(tx,tx_signal_norm);
    if(underrun)
        %fprintf('Underrun in frame %d\n', frame)
        errored_frames = errored_frames + 1;
    end
    frame = frame +1;
end

fprintf(msgFormat, carriers(1), 8, status(1));
fprintf("\n");
%disp('Fin de transmission...')

    