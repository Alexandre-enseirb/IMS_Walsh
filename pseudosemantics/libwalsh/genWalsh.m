function [W] = genWalsh(ordre)
%GENWALSH genere la matrice de Walsh normalisee a l'ordre donne en argument
%
%  W = genWalsh(ordre) retourne la matrice 2^ordre x 2^ordre normalisee
%  realisant la transformee discrete de Walsh sur 2^ordre points
%
% Base sur le code `Walsh_figure` de Maxandre Fellmann

Had = 1;
N = 2^ordre;

for i=1:ordre
    Had = [Had Had; Had -Had];
end

%Sort Hadamard Matrix by sign change growth to obtain Walsh sequences
index_sorted_Had = zeros(1, 2^ordre);
for j=2:N
    pos                 = Had(j,:)>0;
    changes             = xor(pos(1:end-1),pos(2:end));
    index_sorted_Had(j) = sum(changes);
end
Had = Had/sqrt(N);
[~, Had_to_Walsh] = sort(index_sorted_Had);
W = Had(Had_to_Walsh,:);

end

