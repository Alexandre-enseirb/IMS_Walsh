clear; clc; close all; dbstop if error;

u = udpport("IPV4", "LocalHost", "169.254.158.40", "LocalPort", 8080);

write(u, 1:5, "double", "169.254.103.193", 8080);

% Note : On ne compte pas le "\0" dans la quantite de donnees a lire
% Si la chaine a envoyer fait 5 caracteres, on met `5` dans le champ
% "count".
data = read(u, 5, "string");

fprintf("%s\n", data);