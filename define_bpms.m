function bpms = define_bpms()
% DEFINE_BPMS  Return parameters for all Beam Parameter Meters (BPMs)
%              along the Scorpius injector beamline.
%
% Each BPM structure contains:
%   id          - sequential index
%   name        - human-readable label
%   z_position  - longitudinal position along beamline [m]
%   type        - 'stripline' | 'button' | 'Faraday_cup' | 'ICT'
%   resolution  - position resolution [mm]
%   bandwidth   - signal bandwidth [MHz]
%
% BPM placement strategy
%   - 1 Faraday cup at the gun exit (beam current measurement)
%   - 1 ICT (Integrating Current Transformer) after the diode gap
%   - Stripline / button BPMs every ~0.8 m along the drift pipe
%   - Additional BPMs bracketing key focusing elements

    bpm_data = {
        %  z [m]    type            resolution_mm  bandwidth_MHz  name
        0.130,   'Faraday_cup',   0.50,          500,   'BPM_gun_exit'
        0.200,   'ICT',           0.30,          200,   'BPM_ICT_01'
        0.500,   'stripline',     0.10,          500,   'BPM_strip_01'
        1.000,   'stripline',     0.10,          500,   'BPM_strip_02'
        1.500,   'stripline',     0.10,          500,   'BPM_strip_03'
        2.000,   'stripline',     0.10,          500,   'BPM_strip_04'
        2.500,   'stripline',     0.10,          500,   'BPM_strip_05'
        3.000,   'button',        0.15,          300,   'BPM_butt_01'
        3.500,   'stripline',     0.10,          500,   'BPM_strip_06'
        4.000,   'stripline',     0.10,          500,   'BPM_strip_07'
        4.500,   'stripline',     0.10,          500,   'BPM_strip_08'
        5.000,   'button',        0.15,          300,   'BPM_butt_02'
        5.500,   'stripline',     0.10,          500,   'BPM_strip_09'
        6.000,   'stripline',     0.10,          500,   'BPM_strip_10'
        6.500,   'stripline',     0.10,          500,   'BPM_strip_11'
        7.000,   'button',        0.15,          300,   'BPM_butt_03'
        7.500,   'stripline',     0.10,          500,   'BPM_strip_12'
        8.000,   'stripline',     0.10,          500,   'BPM_strip_13'
        8.350,   'ICT',           0.30,          200,   'BPM_ICT_02'
    };

    N = size(bpm_data, 1);
    bpms(N) = struct('id', [], 'name', '', 'z_position', [], ...
                     'type', '', 'resolution', [], 'bandwidth', []);

    for k = 1:N
        bpms(k).id         = k;
        bpms(k).z_position = bpm_data{k, 1};
        bpms(k).type       = bpm_data{k, 2};
        bpms(k).resolution = bpm_data{k, 3};
        bpms(k).bandwidth  = bpm_data{k, 4};
        bpms(k).name       = bpm_data{k, 5};
    end
end
