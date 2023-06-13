classdef walshModulator
    %WALSHMODULATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        carrier % coefficients de base pour la porteuse
        combinations % combinaisons utilisables pour la modulation
        idx % tableau de conversion d'indices entiers en cles pour les combinaisons
        attenuationFactor % attenuation des symboles par rapport a la "porteuse"
        k % nombre de coefficients a moduler
        n % nombre de bits de quantification
    end
    
    methods
        function obj = walshModulator(carrier, combinations, a, k, n)
            %WALSHMODULATOR constructeur de la classe.
            %
            % Args:
            %   - carrier : tableau NxM ou N est le nombre de coefficients de Walsh utilises et M
            %               est le nombre de refresh par paquet
            %   - combinations : Dictionnaire de tableaux kx(L+1) ou k est le nombre de coefficients a
            %                    moduler et L est le nombre de symboles par paquet. La premiere ligne
            %                    doit comporter les indices des coefficients a moduler
            %   - a : Coefficient d'attenuation (defaut : 4)
            %   - k : Nombre de coefficients a moduler (defaut : 3)
            %   - n : Nombre de bits de quantification (defaut : 8)
            %
            % Retourne :
            %   - obj : l'objet cree

            if ~exist("a", "var")
                a = 4;
            end

            if ~exist("k", "var")
                k = 3;
            end

            if ~exist("n", "var")
                n = 8;
            end

            obj.carrier = carrier;
            obj.combinations = combinations;
            obj.idx = combinations.keys;
            obj.attenuationFactor = a;
            obj.k = k;
            obj.n = n;
        end

        
        
        function sig = generate(obj, id, params)
            %METHOD1 genere un signal module a partir de l'id specifiee
            %
            % Args:
            %   - id : indice du symbole de Walsh souhaite
            %   - params : Structure representant les parametres de la simulation

            sig = generateSigFromDictionary(obj.combinations(id), obj.carrier, obj.attenuationFactor, params);
            
        end
    end
end

