function setPath()
    
    addpath("functions", ...    % vrac de fonctions douteuses
        "Data", ...             % Donnees exploitables (images, fichiers .mat)
        "../libs/libwalsh", ... % Fonctions relatives a la transformee de Walsh
        "../libs/libcom", ...   % Fonctions relatives aux com. num.
        "../libs/libsig", ...   % Fonctions relatives au traitement du signal
        "../libs/libhilbert", ... % Fonctions relatives au filtrage de Hilbert
        "../libs/libpseudosemantic/", ... % fonctions relatives au mapping OSDM/dictionnaire
        "../libs/libplot", ... % fonctions relatives a l'affichage
        "../libs/libsim", ...  % Fonctions pour lancer des simulations
        "../libs/generators"); % Generateurs de structures (~factories)

end