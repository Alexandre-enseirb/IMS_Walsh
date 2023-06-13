clear; clc; close all; dbstop if error;

set_path(); plotSetup();

%%

load("sim_qam_5_64_rerolls_test_1_symb.mat");

% Remove NaNs
% nRerolls(isnan(nRerolls)) = -1;
% nNotConform(isnan(nNotConform)) = -1;
% BER(~isnan(BER)) = BER(~isnan(BER)) / 64;
% BER(isnan(BER)) = 1/2;

% Plot for fixed C2 size BER against first coeff and attenuation

titleFormatBER = "visuals/osdm_study/qam_BER_%d.pdf";
titleFormatNC = "visuals/osdm_study/qam_non_conformities_%d.pdf";
titleFormatRerolls = "visuals/osdm_study/qam_rerolls_%d.pdf";

% figurePos(3:4) = repmat(max(figurePos(3:4)), 2, 1);

f1 = figure("Name", strjoin(["Stats ", string(cluster2Sizes(iC2Size))]), "Position", figurePos, "Visible", "on", "Resize", "on");
plot(0);
axh1 = gca;


f2 = figure("Name", strjoin(["Stats ", string(cluster2Sizes(iC2Size))]), "Position", figurePos, "Visible", "on", "Resize", "on" );
plot(0);
axh2 = gca;


f3 = figure("Name", strjoin(["Stats ", string(cluster2Sizes(iC2Size))]), "Position", figurePos, "Visible", "on", "Resize", "on");
plot(0);
axh3 = gca;


for iC2Size=1:nC2Sizes

    titleBER = sprintf(titleFormatBER, cluster2Sizes(iC2Size));
    titleNC = sprintf(titleFormatNC, cluster2Sizes(iC2Size));
    titleReroll = sprintf(titleFormatRerolls, cluster2Sizes(iC2Size));
    
    
    
    surf(axh1, attenuationFactors, 1:cluster2Sizes(iC2Size), squeeze(BER(iC2Size, 1:cluster2Sizes(iC2Size), :)), "displayName", strjoin(["BER for C2 size = ", string(cluster2Sizes(iC2Size))]), ...
        "FaceColor", "interp");
    
    ylabel(axh1, "First coefficient", "Interpreter", "latex", "FontSize", 30);
    xlabel(axh1, "Attenuation factor", "Interpreter", "latex", "FontSize", 30);
    zlabel(axh1, "BER", "Interpreter", "latex", "FontSize", 30);
    % xticklabels(axh1, string(attenuationFactors));
    yticklabels(axh1, string(carrier.Clusters{2}));
    axh1.FontSize = 30;
    view(axh1, [-35 35]);
    
    % pause(.1);
    
    
    surf(axh2, attenuationFactors, 1:cluster2Sizes(iC2Size), squeeze(nNotConform(iC2Size, 1:cluster2Sizes(iC2Size), :)), "displayName", strjoin(["Non-conformities for C2 size = ", string(cluster2Sizes(iC2Size))]), ...
        "FaceColor", "interp");
    ylabel(axh2, "First coefficient", "Interpreter", "latex", "FontSize", 30);
    xlabel(axh2, "Attenuation factor", "Interpreter", "latex", "FontSize", 30);
    zlabel(axh2, "Non-conformities", "Interpreter", "latex", "FontSize", 30);
    % xticklabels(axh2, string(attenuationFactors));
    yticklabels(axh2, string(carrier.Clusters{2}));
    axh2.FontSize = 30;
    view(axh2, [143 35]);
    
    % colorbar;
    % pause(.1);
    
    
    surf(axh3, attenuationFactors, 1:cluster2Sizes(iC2Size), squeeze(nRerolls(iC2Size, 1:cluster2Sizes(iC2Size), :)), "displayName", strjoin(["Rerolls for C2 size = ", string(cluster2Sizes(iC2Size))]), ...
        "FaceColor", "interp");
    ylabel(axh3, "First coefficient", "Interpreter", "latex", "FontSize", 30);
    xlabel(axh3, "Attenuation factor", "Interpreter", "latex", "FontSize", 30);
    zlabel(axh3, "Rerolls", "Interpreter", "latex", "FontSize", 30);
    % xticklabels(axh3, string(attenuationFactors));
    yticklabels(axh3, string(carrier.Clusters{2}));
    axh3.FontSize = 30;
    view(axh3, [143 35]);
    
    
    % colorbar;
    % pause(.1);
    
    
    exportgraphics(axh1, titleBER);
    exportgraphics(axh2, titleNC);
    exportgraphics(axh3, titleReroll);
end