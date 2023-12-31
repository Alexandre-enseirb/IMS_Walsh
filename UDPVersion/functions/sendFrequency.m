function sendFrequency(freq)

if ~exist("freq", "var")

    freq = 1e3;

end

radioParams = getRadioParams("tx");
commParams = getCommParams("tx");

radio = comm.SDRuTransmitter("Platform", "B200", ...
    "SerialNum", "327537B", ...
    "CenterFrequency", radioParams.centerFrequency, ...
    "ChannelMapping", radioParams.ChannelMapping, ...
    "ClockSource", radioParams.ClockSource, ...
    "EnableBurstMode", radioParams.enableBurstMode, ...
    "Gain", radioParams.Gain, ... 
    "LocalOscillatorOffset", radioParams.LOOffset, ...
    "MasterClockRate",  radioParams.MasterClockRate, ...
    "PPSSource", radioParams.PPSSource, ...
    "TransportDataType", radioParams.dataType, ...
    "InterpolationFactor",radioParams.InterpolationDecimationFactor);

%% General parameters
tx_sample_rate = radio.MasterClockRate/radio.InterpolationFactor; %% Matlab sample rate = MasterClk/InterpolFactor
num_frames     = 100000;


%% Sinwave
amplitude         = 1;
frequency         = freq;
samples_per_frame = 200;
CW                = dsp.SineWave(amplitude, frequency, 'SampleRate', tx_sample_rate, 'SamplesPerFrame', samples_per_frame, 'ComplexOutput', true);
tx_signal         = CW();
tx_signal_norm    = tx_signal/max(abs(tx_signal));
% tx_signal_norm = [tx_signal_norm tx_signal_norm];

%% Send Signal
frame    = 1;
t_sample = 1/tx_sample_rate;
t_total  = t_sample*samples_per_frame*num_frames;

fprintf('Durée de transmission = %fs \n', t_total)
disp('Début de transmission...')

errored_frames = 0;
!touch flag
while isfile("flag")
    underrun = step(radio,tx_signal_norm);
    if(underrun)
        %fprintf('Underrun in frame %d\n', frame)
        errored_frames = errored_frames + 1;
    end
    % frame = frame +1;
end
disp('Fin de transmission...')
 