function factor = pulse_shape_multipulse(t, config)
    % Multi-pulse capability
    factor = 0;  % Start with no field
    
    for ip = 1:config.n_pulses
        t_pulse = t - config.pulse_starts(ip);
        
        if t_pulse < 0
            continue;  % Before this pulse starts
        elseif t_pulse < config.rise_time
            % Rising edge
            phase = t_pulse / config.rise_time;
            pulse_factor = 0.5 * (1 + sin(pi * (phase - 0.5)));
        elseif t_pulse < config.rise_time + config.flat_time
            % Flat top
            pulse_factor = 1;
        elseif t_pulse < config.rise_time + config.flat_time + config.fall_time
            % Falling edge
            phase = (t_pulse - config.rise_time - config.flat_time) / config.fall_time;
            pulse_factor = 0.5 * (1 + sin(pi * (0.5 - phase)));
        else
            % After this pulse ends
            pulse_factor = 0;
        end
        
        % Take maximum (allows pulse overlap if needed)
        factor = max(factor, pulse_factor);
    end
end
