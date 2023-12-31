close all
clearvars -except tx
reset_sdr = 1;

%% Parameters of the USRP B210
if(reset_sdr == 1)
    disp('Configuration de la radiologicielle Tx')
    tx                       = comm.SDRuTransmitter('Platform','B210','SerialNum','32752A2');
    tx.ChannelMapping        = [1 2];
    tx.CenterFrequency       = 500e6;
    tx.LocalOscillatorOffset = 0;
    tx.Gain                  = 25;
    tx.PPSSource             = 'Internal';
    tx.ClockSource           = 'Internal';
    tx.MasterClockRate       = 30e6;
    tx.InterpolationFactor   = 128;
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
t_sample = 1/tx_sample_rate;


%% Sinwave

frequency         = 1e6;
samples_per_frame = 2000;
timeAxis = (1:samples_per_frame)/t_sample;
% CW                = dsp.SineWave(amplitude, frequency, 'SampleRate', tx_sample_rate, 'SamplesPerFrame', samples_per_frame, 'ComplexOutput', true);
% tx_signal         = CW();
% tx_signal_norm    = repmat(tx_signal/max(abs(tx_signal)),1,2);
tx_signal = exp(1j * 2 * pi * frequency * timeAxis).';
tx_signal_norm = tx_signal/max(abs(tx_signal));
tx_signal_norm = repmat(tx_signal_norm, 1, 2);

%% Send Signal
frame    = 1;

% t_total  = t_sample*samples_per_frame*num_frames;

% fprintf('Durée de transmission = %fs \n', t_total)
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