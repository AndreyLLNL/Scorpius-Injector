% INJECTOR_MODEL  Main entry-point script for the Scorpius e-beam injector
%                 digital-twin model.
%
% This script orchestrates:
%   1. Hardware construction  – build_hardware()
%   2. Electromagnetic field solve – solve_fields()
%   3. Beam-dynamics envelope tracking – beam_dynamics()
%   4. Results visualisation – plot_results()
%
% Physical layout
%   z = 0.000 m  :  Photocathode face
%   z = 0.120 m  :  Anode plane (diode gap = 120 mm)
%   z = 0.120 m  :  Start of 8.305 m drift / transport pipe
%   z = 8.425 m  :  End of drift pipe
%
% 49 solenoids / focusing magnets are distributed along the beamline:
%   Solenoids  1-4  : gun solenoids around the diode
%   Solenoids 5-49  : transport lattice along the drift pipe
%
% Beam Parameter Meters (BPMs) are located at key diagnostics stations.
%
% Usage
%   Run this script from the MATLAB command window or add the repository
%   root to the MATLAB path.
%
%       >> injector_model
%
% See also: build_hardware, solve_fields, beam_dynamics, plot_results,
%           define_solenoids, define_bpms

clear; clc;
fprintf('=============================================================\n');
fprintf('  Scorpius Injector Digital-Twin Model\n');
fprintf('  E-Beam Injector to Linear Inductive Accelerator (LIA)\n');
fprintf('=============================================================\n\n');

% -----------------------------------------------------------------------
% Step 1 – Build hardware model
% -----------------------------------------------------------------------
hw = build_hardware();

% Print a summary of the hardware
fprintf('--- Hardware Summary ---\n');
fprintf('  Cathode position   : z = %.3f m\n', hw.cathode.z_position);
fprintf('  Anode   position   : z = %.3f m\n', hw.anode.z_position);
fprintf('  Accel. voltage     : %.2f MV\n',   hw.anode.accel_voltage_V / 1e6);
fprintf('  Drift pipe length  : %.3f m\n',   hw.drift_pipe.length);
fprintf('  Number of solenoids: %d\n',        numel(hw.solenoids));
fprintf('  Number of BPMs     : %d\n',        numel(hw.bpms));
fprintf('\n');

% -----------------------------------------------------------------------
% Step 2 – Solve electromagnetic fields
% -----------------------------------------------------------------------
z_grid = (0 : 0.005 : 8.425)';    % 5 mm axial resolution
r_grid = (0 : 0.002 : 0.080)';    % 2 mm radial resolution

fields = solve_fields(hw, z_grid, r_grid);

fprintf('--- Field Summary ---\n');
[Bz_max, idx_Bz] = max(fields.Bz_axis);
fprintf('  Peak on-axis Bz : %.1f mT at z = %.3f m\n', ...
        Bz_max*1e3, fields.z(idx_Bz));
fprintf('  Diode E-field   : %.2f MV/m\n', ...
        max(abs(fields.Ez_diode)) / 1e6);
fprintf('\n');

% -----------------------------------------------------------------------
% Step 3 – Beam dynamics (envelope tracking)
% -----------------------------------------------------------------------
beam_params.energy_MeV  = 20.0;         % 20 MeV kinetic energy
beam_params.current_A   = 2.0e3;        % 2 kA peak beam current
beam_params.emittance_n = 200e-6;       % 200 pi·mm·mrad normalised
beam_params.r0_m        = 0.020;        % 20 mm initial RMS radius
beam_params.rp0         = 0.0;          % zero initial divergence

beam = beam_dynamics(hw, fields, beam_params);

fprintf('--- Beam Summary ---\n');
fprintf('  Beam energy        : %.1f MeV\n', beam_params.energy_MeV);
fprintf('  Peak current       : %.1f kA\n',  beam_params.current_A / 1e3);
fprintf('  Norm. emittance    : %.0f pi·mm·mrad\n', ...
        beam_params.emittance_n * 1e6);
[R_env_max, idx_R] = max(beam.R);
fprintf('  Max envelope radius: %.1f mm at z = %.3f m\n', ...
        R_env_max*1e3, beam.z(idx_R));
fprintf('\n');

fprintf('--- BPM Readings ---\n');
fprintf('  %-20s  z [m]   R [mm]\n', 'Name');
fprintf('  %s\n', repmat('-', 1, 38));
for k = 1:numel(hw.bpms)
    r_val = beam.bpm_readings(k).R_mm;
    if isnan(r_val)
        fprintf('  %-20s  %5.3f   N/A\n', ...
                hw.bpms(k).name, hw.bpms(k).z_position);
    else
        fprintf('  %-20s  %5.3f   %.2f\n', ...
                hw.bpms(k).name, hw.bpms(k).z_position, r_val);
    end
end
fprintf('\n');

% -----------------------------------------------------------------------
% Step 4 – Visualise results
% -----------------------------------------------------------------------
plot_results(hw, fields, beam);

fprintf('=============================================================\n');
fprintf('  Simulation complete.\n');
fprintf('=============================================================\n');
