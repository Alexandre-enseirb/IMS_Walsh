function [status] = asynchronousRxHelper(mbuffer1, mflag)

membuffer = [];
saveNext = false;
counter = 0;
fileformat = "Rx_data_%d.mat";

while isfile("/tmp/continue")
    while (mflag.Data == 0)
        pause(0.25);
    end

    if saveNext
        % Get next matlab file available
        while isfile(sprintf(fileformat, counter))
            counter = counter +1;
        end
        filename = sprintf(fileformat, counter);
        if mflag.Data == 1
            save(filename, "membuffer", "mbuffer1.Data");
        else
            save(filename, "membuffer", "mbuffer2.Data");
        end
    else

        if mflag.Data == 1 && detectSignal(mbuffer1.Data)
            membuffer = mbuffer1.Data;
            saveNext = true;
        elseif mflag.Data == 2 && detectSignal(mbuffer2.Data)
            membuffer = mbuffer2.Data;
            saveNext = true;
        end
    end
end


end

function [out] = detectSignal(buffer, threshold)

if ~exist("threshold", "var")
    threshold = 250;
end

out = sum(buffer > threshold, "all") ~= 0;

end