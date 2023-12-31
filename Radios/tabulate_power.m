close all
clearvars -except tx
reset_sdr = 1;

setPath();
%% Parameters of the USRP B210

carriers = [833e6 1.5e9 2.45e9]; % Hz
gains = 5:5:40;
txMinDuration = 6; % secondes
msgHeader = "| Carrier (MHz) | Gain | Status |\n";
msgSep    = "+---------------+------+--------+\n";
msgFormat = "| %13.3f | %4d | %s |";
status = ["OK", "IP"]; % Ok, In Progress
pauseTime = 2; % secondes
amplitude         = 1;
frequency         = 2e5;
samples_per_frame = 8000;

for iCarriers = 1:length(carriers)
    for iGains = 1:length(gains)

        if(reset_sdr == 1)
            disp('Configuration de la radiologicielle Tx')
            tx                       = comm.SDRuTransmitter('Platform','B210','SerialNum','327537B');
            tx.ChannelMapping        = 1;
            tx.CenterFrequency       = carriers(iCarriers);
            tx.LocalOscillatorOffset = 0;
            tx.Gain                  = gains(iGains);
            tx.PPSSource             = 'Internal';
            tx.ClockSource           = 'Internal';
            tx.MasterClockRate       = 61.44e6;
            tx.InterpolationFactor   = 25;
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
        tx_sample_duration = 1/tx_sample_rate; % secondes
        num_frames     = ceil(txMinDuration/(tx_sample_duration*samples_per_frame));
        
        
        %% Sinwave
        
        CW                = dsp.SineWave(amplitude, frequency, 'SampleRate', tx_sample_rate, 'SamplesPerFrame', samples_per_frame, 'ComplexOutput', true);
        tx_signal         = CW();
        tx_signal_norm    = tx_signal/max(abs(tx_signal));
        
        %% Send Signal
        frame    = 1;
        t_sample = 1/tx_sample_rate;
        t_total  = t_sample*samples_per_frame*num_frames;
        
        %fprintf('Durée de transmission = %fs \n', t_total)
        msgSz = fprintf(msgFormat, carriers(iCarriers), gains(iGains), status(2));
        fprintf("\n");
        errored_frames = 0;
        while frame<=num_frames
            underrun = step(tx,tx_signal_norm);
            if(underrun)
                %fprintf('Underrun in frame %d\n', frame)
                errored_frames = errored_frames + 1;
            end
            frame = frame +1;
        end
        
        fprintf(msgFormat, carriers(iCarriers), gains(iGains), status(1));
        fprintf("\n");
        %disp('Fin de transmission...')
        pause(pauseTime);
    end
    if iCarriers < length(carriers)
        fprintf("Please set spectrum to %f\n", carriers(iCarriers+1));
        pause(10);
    end
end   