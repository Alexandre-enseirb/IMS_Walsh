function [sig, startIdx, endIdx, flag] = detectSignalStartEnd(buffer)
%DETECTSIGNALSTARTEND detecte le debut et la fin du signal dans un buffer de radio

buffer = buffer(:);
figure("Name", "Display", "Position", [1 1 1920 1080], "Resize", "off")
plot(real(buffer)   );
hold on; grid on;
[~, noiseVariance] = profileNoiseRadio();

threshold = 20*sqrt(noiseVariance);
yline(threshold);
yline(-threshold);
% On regarde toutes les fois ou on depasse le seuil : potentiel signal
allSuspectedSigIdx = find(real(buffer) > threshold | abs(buffer) > threshold);
axis = 1:length(buffer);
plot(axis(allSuspectedSigIdx), real(buffer(allSuspectedSigIdx)), " x");
% On regarde la distance entre chaque depassement de seuil.
% Une distance trop longue peut indiquer ou bien un bruit trop important sur
% un seul echantillon, ou une scission du signal etudie en deux parties
% (comme un overlap du buffer par exemple).
distBetweenAllIdx = allSuspectedSigIdx(2:end) - allSuspectedSigIdx(1:end-1);

% On considere que si on depasse 100x la longueur mediane alors il y a 
% eu scission du signal etudie
longBreaks = find(distBetweenAllIdx > 100*median(distBetweenAllIdx));
% figure("Name", "Breaks", "Position", [1 1 1920 1080], "Resize", "off")
% plot(distBetweenAllIdx);
% hold on; grid on;
% plot(longBreaks, distBetweenAllIdx(longBreaks));
% On va alors etudier la taille de chaque "bloc" et garder le plus large

if ~isempty(longBreaks)
    jumpingPoints = [max(longBreaks(1)-1, 1); longBreaks(1:end-1)];
    distBetweenLongBreaks = longBreaks - jumpingPoints;
    
    m = mean(distBetweenLongBreaks);
    v = var(distBetweenLongBreaks);
    
    if any(distBetweenLongBreaks > m+4*v)
        sig = [];
        startIdx = -1;
        endIdx = -1;
        return;
    end
    if any(distBetweenLongBreaks > 0.45 * length(buffer))
        flag=false;
    else
        flag=true;
    end
    startIdx = jumpingPoints(1);
    endIdx = jumpingPoints(end);
else
    startIdx = allSuspectedSigIdx(1);
    endIdx = allSuspectedSigIdx(end);
    flag=false;
end



sig = buffer(startIdx:endIdx);
% figure(1)
% plot(startIdx:endIdx, sig);


end