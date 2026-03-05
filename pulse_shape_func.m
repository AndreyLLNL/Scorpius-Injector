function factor = pulse_shape_func(t, pulse_start, pulse_rise, pulse_flat, pulse_fall)
    % Single pulse (backward compatible)
    if t < pulse_start
        factor = 0;
    elseif t < pulse_start + pulse_rise
        phase = (t - pulse_start) / pulse_rise;
        factor = 0.5 * (1 + sin(pi * (phase - 0.5)));
    elseif t < pulse_start + pulse_rise + pulse_flat
        factor = 1;
    elseif t < pulse_start + pulse_rise + pulse_flat + pulse_fall
        phase = (t - pulse_start - pulse_rise - pulse_flat) / pulse_fall;
        factor = 0.5 * (1 + sin(pi * (0.5 - phase)));
    else
        factor = 0;
    end
end

