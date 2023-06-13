clearvars -except rx; clc; close all; dbstop if error;

%% RECEIVER

rx = comm.SDRuReceiver('Platform','B210','SerialNum','32752A2');
rx.ChannelMapping        = 1;
rx.CenterFrequency       = 500e6;
rx.LocalOscillatorOffset = 0;
rx.Gain                  = 1;
rx.PPSSource             = 'Internal';
rx.ClockSource           = 'Internal';
rx.MasterClockRate       = 60e6;
rx.DecimationFactor   = 4;
rx.TransportDataType     = 'int16';
rx.EnableBurstMode       = true;
rx.SamplesPerFrame = 20000;
if(rx.EnableBurstMode)
    rx.NumFramesInBurst = 100;
end

rxSamplingRate = rx.MasterClockRate/rx.DecimationFactor;

timeAxis = (1:rx.SamplesPerFrame)/rxSamplingRate;

%% RECEIVE

[data, dataLen, overrun] = rx();
figure("Name", "Received signal", "Position", get(0, "ScreenSize"))
plot(timeAxis, real(data), "LineWidth", 2, "DisplayName", "$\mathcal{R}$");
hold on; grid on;
plot(timeAxis, imag(data), "LineWidth", 2, "DisplayName", "$\mathcal{I}$");
legend("Interpreter","latex","FontSize",22);
xlabel("Time (s)", "Interpreter", "latex", "FontSize", 22);
ylabel("Amplitude", "Interpreter", "latex", "FontSize", 22);