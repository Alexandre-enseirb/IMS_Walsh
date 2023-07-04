function [vecteur_out] = vect2time(vecteur_in, OSR)

%Initialisation

porte            = ones(1, OSR);
[ligne, colonne] = size(vecteur_in);
vecteur_out      = zeros(ligne,(OSR+1)*colonne-1);
vecteur2         = [];

%Signal Processing

vecteur_out(:,1:OSR:OSR*colonne) = vecteur_in(:,1:1:colonne);
for i=1:1:ligne
    vecteur2 = [vecteur2; conv(porte, vecteur_out(i,1:OSR*colonne))];
end
vecteur_out = vecteur2(:,1:OSR*colonne);
end