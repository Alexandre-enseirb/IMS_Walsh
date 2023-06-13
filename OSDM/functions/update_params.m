function [params] = update_params(params, order, N)
%UPDATE_PARAMS est un utilitaire pour mettre a jour tous les parametres qui
%sont lies a l'ordre de la transformee de Walsh

if ~exist("order", "var")
    order = params.order;
end

if ~exist("N", "var")
    N = params.nBitsAmp;
end


%% Parametres Walsh
params.order = order;
params.nCoeff = 2^params.order;
params.nBitsAmp = N;    % type amplitudes : int8
params.nAmp     = 2^params.nBitsAmp;

%% Parametres frequentiels
params.fRefresh = params.fWalsh/params.nCoeff;


%% Parametres temporels
params.duration = params.NWalsh * params.TWalsh * params.nCoeff;
params.Nech = params.duration/params.Tech;

params.time_axis = 0:params.Tech:params.duration-params.Tech;
params.walsh_time_axis = 0:params.TWalsh:params.duration - params.TWalsh;

end

