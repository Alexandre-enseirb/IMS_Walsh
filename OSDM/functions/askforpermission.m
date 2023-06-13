function [retour] = askforpermission(filename)
%ASKFORPERMISSION Summary of this function goes here
%   Detailed explanation goes here

msg = sprintf("Le fichier %s existe déjà. Souhaitez-vous le remplacer ? (y/n) ", filename);

while true
    y = input(msg, "s");
    y = lower(y);
    if strcmp(y,"y") || strcmp(y,"o")
        retour = true;
        return;
    elseif strcmp(y,"n")
        retour = false;
        return;
    end
end

