function [sig] = wqammod(value, maps)

    idx = maps.mapping_qam(value+1);

    r = rem(idx - 1, 6) + 1;
    c = (idx - r)/6 + 1;

    coef = 2 * (c-1) - 7 + 1j * (7 - 2*(r-1));

    sig = maps.sinewave * real(coef) + 1j * maps.sinewave * imag(coef);

    
end