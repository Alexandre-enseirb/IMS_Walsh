function [symbol] = wqamdemod(sig, maps)

    sig_r = real(sig);
    sig_i = imag(sig);

    amps = -7:2:7;
    
    sig_r_dist = abs(sig_r - amps);
    sig_i_dist = abs(sig_i - amps);

    [~, val_r] = min(sig_r_dist, [], 1);
    [~, val_i] = min(sig_i_dist, [], 1);
    val_i = 9 - val_i; % compensation d'indice

    symbol = maps.mapping_qam(val_i, val_r);


end