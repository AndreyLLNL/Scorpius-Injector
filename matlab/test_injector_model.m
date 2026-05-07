% TEST_INJECTOR_MODEL  Unit tests for the Scorpius injector MATLAB model.
%
% Runs lightweight checks on each model function to verify that outputs
% are physically reasonable.  Uses MATLAB's built-in assert() with a
% tolerance where applicable.
%
% Usage:
%   cd matlab
%   test_injector_model          % interactive
%   matlab -batch "test_injector_model; exit(0)"   % CI / batch mode

clear; clc;
fprintf('=== Running Injector Model Unit Tests ===\n\n');
n_pass = 0;
n_fail = 0;

% ------------------------------------------------------------------ %
%  1. injector_params
% ------------------------------------------------------------------ %
fprintf('-- injector_params --\n');
params = injector_params();

[n_pass, n_fail] = check('params struct has phys field',        isfield(params, 'phys'),      n_pass, n_fail);
[n_pass, n_fail] = check('params struct has gun field',         isfield(params, 'gun'),       n_pass, n_fail);
[n_pass, n_fail] = check('params struct has beam field',        isfield(params, 'beam'),      n_pass, n_fail);
[n_pass, n_fail] = check('params struct has solenoid field',    isfield(params, 'solenoid'),  n_pass, n_fail);
[n_pass, n_fail] = check('params struct has transport field',   isfield(params, 'transport'), n_pass, n_fail);
[n_pass, n_fail] = check('cathode voltage > 0',                 params.gun.voltage > 0,       n_pass, n_fail);
[n_pass, n_fail] = check('gap length > 0',                      params.gun.gap_length > 0,    n_pass, n_fail);
[n_pass, n_fail] = check('total length > 0',                    params.transport.total_length > 0, n_pass, n_fail);
[n_pass, n_fail] = check('n_steps integer > 0',                 params.transport.n_steps > 0, n_pass, n_fail);
[n_pass, n_fail] = check('speed of light ~ 3e8 m/s', ...
    abs(params.phys.c - 2.998e8) < 1e6, n_pass, n_fail);
fprintf('\n');

% ------------------------------------------------------------------ %
%  2. electron_gun
% ------------------------------------------------------------------ %
fprintf('-- electron_gun --\n');
gun_out = electron_gun(params);

[n_pass, n_fail] = check('gamma > 1  (relativistic)',           gun_out.gamma > 1,            n_pass, n_fail);
[n_pass, n_fail] = check('beta in (0,1)',                        gun_out.beta > 0 && gun_out.beta < 1, n_pass, n_fail);
[n_pass, n_fail] = check('KE_MeV ~ gun voltage in MV', ...
    abs(gun_out.KE_MeV - params.gun.voltage/1e6) < 0.1, n_pass, n_fail);
[n_pass, n_fail] = check('beam current > 0',                    gun_out.current > 0,          n_pass, n_fail);
[n_pass, n_fail] = check('perveance > 0',                       gun_out.perveance > 0,        n_pass, n_fail);
[n_pass, n_fail] = check('J_cathode > 0',                       gun_out.J_cathode > 0,        n_pass, n_fail);
[n_pass, n_fail] = check('beam power > 0',                      gun_out.beam_power > 0,       n_pass, n_fail);
[n_pass, n_fail] = check('beam power = V * I', ...
    abs(gun_out.beam_power - params.gun.voltage * gun_out.current) < 1, n_pass, n_fail);
fprintf('\n');

% ------------------------------------------------------------------ %
%  3. solenoid_focusing
% ------------------------------------------------------------------ %
fprintf('-- solenoid_focusing --\n');
z   = linspace(0, params.transport.total_length, params.transport.n_steps);
sol = solenoid_focusing(z, params, gun_out);

[n_pass, n_fail] = check('Bz vector length equals n_steps',     length(sol.Bz) == params.transport.n_steps,   n_pass, n_fail);
[n_pass, n_fail] = check('k_sq vector length equals n_steps',   length(sol.k_sq) == params.transport.n_steps, n_pass, n_fail);
[n_pass, n_fail] = check('Bz is non-negative everywhere',       all(sol.Bz >= 0),             n_pass, n_fail);
[n_pass, n_fail] = check('k_sq is non-negative everywhere',     all(sol.k_sq >= 0),           n_pass, n_fail);
[n_pass, n_fail] = check('focal_len vector has n_solenoids entries', ...
    length(sol.focal_len) == params.solenoid.n_solenoids, n_pass, n_fail);
[n_pass, n_fail] = check('all focal lengths are positive',      all(sol.focal_len > 0),       n_pass, n_fail);
[n_pass, n_fail] = check('entry_pos has n_solenoids entries',   length(sol.entry_pos) == params.solenoid.n_solenoids, n_pass, n_fail);
[n_pass, n_fail] = check('exit_pos > entry_pos for all lenses', all(sol.exit_pos > sol.entry_pos), n_pass, n_fail);
fprintf('\n');

% ------------------------------------------------------------------ %
%  4. beam_transport
% ------------------------------------------------------------------ %
fprintf('-- beam_transport --\n');
[z_out, R, Rp] = beam_transport(params, gun_out, sol);

[n_pass, n_fail] = check('z_out has n_steps points',            length(z_out) == params.transport.n_steps, n_pass, n_fail);
[n_pass, n_fail] = check('R has n_steps points',                length(R) == params.transport.n_steps,     n_pass, n_fail);
[n_pass, n_fail] = check('Rp has n_steps points',               length(Rp) == params.transport.n_steps,    n_pass, n_fail);
[n_pass, n_fail] = check('R is positive everywhere',            all(R > 0),                    n_pass, n_fail);
[n_pass, n_fail] = check('R stays within beam pipe', ...
    all(R <= params.transport.pipe_r), n_pass, n_fail);
[n_pass, n_fail] = check('Initial radius matches beam.r0', ...
    abs(R(1) - params.beam.r0) < 1e-6, n_pass, n_fail);
[n_pass, n_fail] = check('Initial slope matches beam.rp0', ...
    abs(Rp(1) - params.beam.rp0) < 1e-6, n_pass, n_fail);
fprintf('\n');

% ------------------------------------------------------------------ %
%  Summary
% ------------------------------------------------------------------ %
fprintf('=== Test Summary: %d passed, %d failed ===\n', n_pass, n_fail);
if n_fail > 0
    error('test_injector_model: %d test(s) failed.', n_fail);
end

% ======================================================================
%  Local helper – assert a named boolean condition and track counts
% ======================================================================
function [np, nf] = check(name, condition, np, nf)
% CHECK  Print PASS/FAIL and update counters.
%   [np, nf] = check(name, condition, np, nf)
if condition
    fprintf('  PASS  %s\n', name);
    np = np + 1;
else
    fprintf('  FAIL  %s\n', name);
    nf = nf + 1;
end
end
