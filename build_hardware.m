function hw = build_hardware()
% BUILD_HARDWARE  Assemble the complete hardware model of the Scorpius
%                 electron-beam injector.
%
% Returns a structure 'hw' with sub-structures for each hardware group:
%
%   hw.cathode    - field-emission / photo-emission cathode parameters
%   hw.anode      - anode (accelerating electrode) parameters
%   hw.walls      - grounded vacuum vessel / wall geometry
%   hw.drift_pipe - 8.305 m drift / transport pipe
%   hw.solenoids  - array of 49 solenoid structures (see define_solenoids)
%   hw.bpms       - array of Beam Parameter Meters (see define_bpms)
%
% All lengths in metres, fields in Tesla, voltages in volts.

    fprintf('Building Scorpius injector hardware model...\n');

    % ------------------------------------------------------------------
    % 1. Cathode
    % ------------------------------------------------------------------
    hw.cathode.z_position       = 0.000;       % [m]  reference z = 0
    hw.cathode.radius           = 0.030;       % [m]  emitting-disk radius
    hw.cathode.work_function    = 4.5;         % [eV] typical tungsten-like
    hw.cathode.temperature_K    = 1800;        % [K]  operating temperature
    hw.cathode.emission_current = 2.0e3;       % [A]  peak beam current
    hw.cathode.pulse_length_ns  = 70;          % [ns] beam-pulse duration
    hw.cathode.material         = 'field-emission velvet';

    % ------------------------------------------------------------------
    % 2. Anode
    % ------------------------------------------------------------------
    hw.anode.z_position         = 0.120;       % [m]  diode gap = 0.120 m
    hw.anode.inner_radius       = 0.040;       % [m]  beam aperture radius
    hw.anode.outer_radius       = 0.200;       % [m]  electrode outer radius
    hw.anode.thickness          = 0.010;       % [m]
    hw.anode.voltage_V          = 0.0;         % [V]  grounded anode
    hw.anode.material           = 'stainless_steel';

    % Accelerating voltage applied to the cathode (anode at ground)
    hw.anode.accel_voltage_V    = -3.0e6;      % [V]  -3 MV on cathode

    % ------------------------------------------------------------------
    % 3. Grounded walls (vacuum vessel)
    % ------------------------------------------------------------------
    hw.walls.inner_radius       = 0.100;       % [m]  beam-pipe bore
    hw.walls.outer_radius       = 0.150;       % [m]  vessel outer wall
    hw.walls.z_start            = 0.000;       % [m]
    hw.walls.z_end              = 8.425;       % [m]  = anode + 8.305 m pipe
    hw.walls.potential_V        = 0.0;         % [V]  grounded
    hw.walls.material           = 'stainless_steel';

    % ------------------------------------------------------------------
    % 4. Drift pipe
    % ------------------------------------------------------------------
    hw.drift_pipe.z_start       = 0.120;       % [m]  starts at anode
    hw.drift_pipe.z_end         = 8.425;       % [m]  8.305 m downstream
    hw.drift_pipe.length        = 8.305;       % [m]
    hw.drift_pipe.inner_radius  = 0.080;       % [m]  vacuum aperture
    hw.drift_pipe.outer_radius  = 0.100;       % [m]
    hw.drift_pipe.material      = 'stainless_steel';
    hw.drift_pipe.vacuum_Pa     = 1e-6;        % [Pa]

    % ------------------------------------------------------------------
    % 5. Solenoids / magnets (49 total)
    % ------------------------------------------------------------------
    hw.solenoids = define_solenoids();
    fprintf('  Loaded %d solenoids.\n', numel(hw.solenoids));

    % ------------------------------------------------------------------
    % 6. Beam Parameter Meters (BPMs)
    % ------------------------------------------------------------------
    hw.bpms = define_bpms();
    fprintf('  Loaded %d BPMs.\n', numel(hw.bpms));

    fprintf('Hardware model built successfully.\n\n');
end
