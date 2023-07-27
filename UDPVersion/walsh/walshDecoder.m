classdef walshDecoder
    %WALSHDECODER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        carrier
        combinations       % Ensemble des combinaisons de Walsh possibles
        referenceCoefficients % Valeurs de reference des coefficients porteurs
        attenuationFactor
        k
        combinations_m    % version "matrice" des combinaisons
    end
    
    methods
        function obj = walshDecoder(carrier, combinations, refs, attenuationFactor, k)
            %WALSHDECODER Construct an instance of this class
            %   Detailed explanation goes here

            if ~exist("attenuationFactor", "var")
                attenuationFactor=4;
            end

            if ~exist("k", "var")
                k=3;
            end

            obj.carrier = carrier;
            obj.combinations = combinations;
            obj.referenceCoefficients = abs(refs * attenuationFactor);
            obj.attenuationFactor = attenuationFactor;
            obj.k = k;
            obj.combinations_m = d2m(obj.combinations, 'keys');
        end
        
        function estimatedIdx = decode(obj, rxCoeffs, cluster2)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            % Args:
            %  rxCoeffs -- coefficients de Walsh recus en sortie d'ADC
            %  cluster2 -- indices des coefficents de Walsh modulables (donc hors cluster1 et coeffs a 0)

            rxCoeffs = rxCoeffs*obj.attenuationFactor;

            interestingCoeffs = rxCoeffs(cluster2, :);

            % Reperage des symboles par moyennage
            means = mean(interestingCoeffs, 2);
            absmeans = abs(means);
            coeffDistance = (obj.referenceCoefficients - absmeans).^2;
            
            round_odd = @(x) 2*floor(x/2) + 1; % source: https://fr.mathworks.com/matlabcentral/answers/45932-round-to-nearest-odd-integer

            [~, idx] = sort(coeffDistance, "descend");

            % Extraction des valeurs d'interet
            
            idx = idx(1:obj.k);

            coeffs = cluster2(idx);
            values = round_odd(means(idx));

            [idxSorted, perms] = sort(coeffs, "ascend");
            sortedValues = values(perms);
        
            % Construction d'une "cle estimee"
            estimatedKey = [idxSorted.'; sortedValues.'];
    
            % Comparaison avec les cles existantes (distance euclidienne)
            % Le vecteur `penaltyVector` existe pour tenter d'equilibrer les erreurs de coefficient et les erreurs
            % de valeur de coefficients.
            % Dans le cas general, la distance entre les coefficients estimes et reels peut rapidement exploser (il
            % suffit de confondre les coefficients 1 et 30 par exemple), tandis que l'erreur sur les valeurs
            % restera globalement faible sauf en presence d'un SNR horriblement bas.
            % Par consequent, ce vecteur vient ponderer la distance des coefficients estimes, selon que l'on
            % souhaite etre plus sensibles a la distance en valeurs, ou en coefficients
            penaltyVector = [0.1 1 0.1 1 0.1 1].';
            distance = sqrt(sum(repmat(penaltyVector, 1, size(obj.combinations_m, 2)).*(repmat(estimatedKey(:), 1, size(obj.combinations_m, 2)) - obj.combinations_m).^2, 1));
            [minDist, minIdx] = min(distance);

            keyout = reshape(obj.combinations_m(:, minIdx), size(estimatedKey));

            try
                estimatedIdx = obj.combinations({keyout});
            catch ME
                estimatedIdx = -1;
            end


            %% TEMPORARY
            % 
            % figure();
            % stem(cluster2, absmeans, "LineWidth", 2);
            % hold on; grid on;
            % stem(cluster2(idx), absmeans(idx),  "LineWidth", 3);
            % axh1 = gca;
            % legend(["Absolute mean"], "Interpreter", "latex", "FontSize", 22);
            % axh1.FontSize = 22;
            % axh1.XAxis.LineWidth = 1.5;
            % axh1.YAxis.LineWidth = 1.5;
            % xlabel("Walsh coefficient index");
            % xlim([0 65]);
            % 
            % figure();
            % stem(cluster2, coeffDistance, "LineWidth", 2);
            % hold on; grid on;
            % stem(cluster2(idx), coeffDistance(idx),  "LineWidth", 3);
            % axh2 = gca;
            % legend(["Distance to ref."], "Interpreter", "latex", "FontSize", 22);
            % axh2.FontSize = 22;
            % axh2.XAxis.LineWidth = 1.5;
            % axh2.YAxis.LineWidth = 1.5;
            % xlabel("Walsh coefficient index");
            % xlim([0 65]);
            % 
            % c = cov(interestingCoeffs.');
            % v = diag(c);
            % 
            % figure();
            % stem(cluster2, v, "LineWidth", 2);
            % hold on; grid on;
            % stem(cluster2(idx), v(idx),  "LineWidth", 3);
            % axh3 = gca;
            % legend(["Variance"], "Interpreter", "latex", "FontSize", 22);
            % axh3.FontSize = 22;
            % axh3.XAxis.LineWidth = 1.5;
            % axh3.YAxis.LineWidth = 1.5;
            % xlabel("Walsh coefficient index");
            % xlim([0 65]);
            % 
            % figure();
            % stem(cluster2, v, "LineWidth", 2);
            % hold on; grid on;
            % stem(cluster2(idx), v(idx),  "LineWidth", 3);
            % axh4 = gca;
            % legend(["Variance"], "Interpreter", "latex", "FontSize", 22);
            % axh4.FontSize = 22;
            % axh4.XAxis.LineWidth = 1.5;
            % axh4.YAxis.LineWidth = 1.5;
            % xlabel("Walsh coefficient index");
            % xlim([0 65]);
            % ylim([0 0.1]);
            % 
            % %%
            % 
            % exportgraphics(axh1, "visuals/noise_absolute_mean.pdf");
            % exportgraphics(axh2, "visuals/noise_distance.pdf");
            % exportgraphics(axh3, "visuals/noise_variance.pdf");
            % exportgraphics(axh4, "visuals/noise_variance_zoom.pdf");
          
        end
    end
end

