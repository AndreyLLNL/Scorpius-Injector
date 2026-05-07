% INJECTOR_MODEL  Main simulation script for the Scorpius E-Beam Injector
%                 digital twin (MATLAB implementation).
%
% This script performs the following steps:
%   1. Load nominal injector parameters.
%   2. Compute electron-gun performance (Child-Langmuir emission).
%   3. Build solenoid on-axis field profile and compute thin-lens focal
%      lengths.
%   4. Integrate the rms K-V beam-envelope equation along the injector.
%   5. Plot and save results.
%
% Usage:
%   Run this script directly in MATLAB or call it from the command line:
%     matlab -batch "injector_model"
%
% Outputs:
%   Figures saved to:
%     results/envelope.png   – beam envelope R(z)
%     results/Bz_profile.png – solenoid on-axis field Bz(z)
%
% References:
%   See individual function files for detailed physics references.

clear; clc;

% ------------------------------------------------------------------ %
%  1. Load parameters
% ------------------------------------------------------------------ %
fprintf('=== Scorpius E-Beam Injector Digital Twin ===\n\n');
params = injector_params();

% ------------------------------------------------------------------ %
%  2. Electron gun
% ------------------------------------------------------------------ %
gun_out = electron_gun(params);
fprintf('\n');

% ------------------------------------------------------------------ %
%  3. Axial grid (shared by solenoid & transport solvers)
% ------------------------------------------------------------------ %
z = linspace(0, params.transport.total_length, params.transport.n_steps);

% ------------------------------------------------------------------ %
%  4. Solenoid focusing
% ------------------------------------------------------------------ %
sol = solenoid_focusing(z, params, gun_out);
fprintf('\n');

% ------------------------------------------------------------------ %
%  5. Beam-envelope integration
% ------------------------------------------------------------------ %
[z, R, Rp] = beam_transport(params, gun_out, sol);
fprintf('\n');

% ------------------------------------------------------------------ %
%  6. Results directory
% ------------------------------------------------------------------ %
if ~exist('results', 'dir')
    mkdir('results');
end

% ------------------------------------------------------------------ %
%  7. Plot beam envelope
% ------------------------------------------------------------------ %
fig1 = figure('Visible', 'off', 'Position', [100 100 900 450]);
subplot(2, 1, 1);
plot(z*100, R*1e3, 'b-', 'LineWidth', 1.5);
xlabel('z  [cm]');
ylabel('R_{rms}  [mm]');
title('Scorpius Injector – Beam Envelope');
grid on; box on;
ylim([0, max(R)*1e3*1.2]);

% Shade solenoid regions
hold on;
for k = 1:params.solenoid.n_solenoids
    x_in  = sol.entry_pos(k) * 100;
    x_out = sol.exit_pos(k)  * 100;
    ylims = ylim;
    fill([x_in x_out x_out x_in], ...
         [ylims(1) ylims(1) ylims(2) ylims(2)], ...
         [0.8 0.9 1.0], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
end
legend('Beam envelope', 'Solenoid regions', 'Location', 'best');
hold off;

subplot(2, 1, 2);
plot(z*100, Rp*1e3, 'r-', 'LineWidth', 1.5);
xlabel('z  [cm]');
ylabel('R''  [mrad]');
title('Envelope Slope  dR/dz');
grid on; box on;

saveas(fig1, fullfile('results', 'envelope.png'));
fprintf('Saved: results/envelope.png\n');

% ------------------------------------------------------------------ %
%  8. Plot solenoid field profile
% ------------------------------------------------------------------ %
fig2 = figure('Visible', 'off', 'Position', [100 600 900 300]);
plot(z*100, sol.Bz*1e3, 'k-', 'LineWidth', 1.5);
xlabel('z  [cm]');
ylabel('B_z  [mT]');
title('On-Axis Solenoid Field Profile');
grid on; box on;

saveas(fig2, fullfile('results', 'Bz_profile.png'));
fprintf('Saved: results/Bz_profile.png\n');

% ------------------------------------------------------------------ %
%  9. Summary table
% ------------------------------------------------------------------ %
fprintf('\n=== Simulation Summary ===\n');
fprintf('  Beam kinetic energy  : %.3f MeV\n',  gun_out.KE_MeV);
fprintf('  Beam current         : %.1f kA\n',   gun_out.current/1e3);
fprintf('  Beam power (peak)    : %.2f GW\n',   gun_out.beam_power/1e9);
fprintf('  Norm. rms emittance  : %.0f pi·mm·mrad\n', ...
    params.beam.emit_n*1e6);
fprintf('  Injector length      : %.2f m\n',    params.transport.total_length);
fprintf('  Beam pipe radius     : %.0f mm\n',   params.transport.pipe_r*1e3);
fprintf('  Max envelope radius  : %.2f mm\n',   max(R)*1e3);
fprintf('  Final envelope radius: %.2f mm\n',   R(end)*1e3);
fprintf('==========================================\n');
