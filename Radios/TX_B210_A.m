close all
clearvars -except tx
reset_sdr = 1;
setPath();
%% Parameters of the USRP B210
if(reset_sdr == 1)
    disp('Configuration de la radiologicielle Tx')
    tx                       = comm.SDRuTransmitter('Platform','B210','SerialNum','32752A2');
    tx.ChannelMapping        = [1 2];
    tx.CenterFrequency       = 600e6;
    tx.LocalOscillatorOffset = 0;
    tx.Gain                  = 30;
    tx.PPSSource             = 'Internal';
    tx.ClockSource           = 'Internal';
    tx.MasterClockRate       = 30e6;
    tx.InterpolationFactor   = 100;
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

%% General parameters
tx_sample_rate = tx.MasterClockRate/tx.InterpolationFactor; %% Matlab sample rate = MasterClk/InterpolFactor
num_frames     = 100000;


%% Sinwave
amplitude         = 1;
frequency         = 100;
samples_per_frame = 200;
CW                = dsp.SineWave(amplitude, frequency, 'SampleRate', tx_sample_rate, 'SamplesPerFrame', samples_per_frame, 'ComplexOutput', true);
tx_signal         = CW();
tx_signal_norm    = tx_signal/max(abs(tx_signal));
tx_signal_norm = [tx_signal_norm tx_signal_norm];

%% Send Signal
frame    = 1;
t_sample = 1/tx_sample_rate;
t_total  = t_sample*samples_per_frame*num_frames;

fprintf('Durée de transmission = %fs \n', t_total)
disp('Début de transmission...')

errored_frames = 0;
while true
    underrun = step(tx,tx_signal_norm);
    if(underrun)
        %fprintf('Underrun in frame %d\n', frame)
        errored_frames = errored_frames + 1;
    end
    % frame = frame +1;
end
disp('Fin de transmission...')
   