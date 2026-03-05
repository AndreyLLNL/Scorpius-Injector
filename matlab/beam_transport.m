function [z, R, Rp] = beam_transport(params, gun_out, sol)
% BEAM_TRANSPORT  Integrate the rms beam-envelope equation along the
%                 injector beam line.
%
% Usage:
%   [z, R, Rp] = beam_transport(params, gun_out, sol)
%
% Inputs:
%   params   – struct returned by injector_params()
%   gun_out  – struct returned by electron_gun()
%   sol      – struct returned by solenoid_focusing()
%
% Outputs:
%   z   – axial coordinate array          [m]  (1 × Nz)
%   R   – rms beam-envelope radius        [m]  (1 × Nz)
%   Rp  – rms envelope slope dR/dz        [rad](1 × Nz)
%
% Physics – rms K-V envelope equation [1]:
%
%   R'' + k_s²(z)·R  -  K/R  -  εₙ²/(β²γ²R³) = 0            (1)
%
% where:
%   k_s²(z)  = solenoid focusing strength      [m^-2]
%   K        = generalised beam perveance (dimensionless)
%              K = I / (2π ε₀ m_e c³ β³ γ³)                   (2)
%   εₙ       = normalised rms emittance        [m·rad]
%   β, γ     = relativistic parameters
%
% Integration is performed by a 4th-order Runge-Kutta method.
%
% References:
%   [1] M. Reiser, "Theory and Design of Charged Particle Beams",
%       Wiley-VCH, 2nd ed., 2008, Chap. 5.

p  = params.phys;
bp = params.beam;
tp = params.transport;

gamma  = gun_out.gamma;
beta   = gun_out.beta;
I_beam = gun_out.current;
emit_n = bp.emit_n;       % normalised rms emittance [m·rad]

% ------------------------------------------------------------------ %
%  Axial grid
% ------------------------------------------------------------------ %
z  = linspace(0, tp.total_length, tp.n_steps);
dz = z(2) - z(1);

% Minimum radius guard to prevent division by zero on envelope collapse.
MIN_ENVELOPE_RADIUS = 1e-6;  % [m]

% ------------------------------------------------------------------ %
%  Generalised perveance  K  (dimensionless)
% ------------------------------------------------------------------ %
K = I_beam / (2 * pi * p.eps0 * p.me * p.c^3 * beta^3 * gamma^3) * p.e;

% ------------------------------------------------------------------ %
%  Interpolate solenoid focusing strength onto grid
% ------------------------------------------------------------------ %
% sol.k_sq was computed on the same z-grid (same linspace call above
% in solenoid_focusing), so we can use it directly.
k_sq_interp = sol.k_sq;   % Nz×1 → transpose below

% ------------------------------------------------------------------ %
%  4th-order Runge-Kutta integration of envelope equation
%  State vector: y = [R; Rp]
%  dy/dz = f(z, y) = [Rp; -k_sq*R + K/R + emit_n^2/(beta*gamma)^2/R^3]
% ------------------------------------------------------------------ %
R  = zeros(1, tp.n_steps);
Rp = zeros(1, tp.n_steps);

R(1)  = bp.r0;
Rp(1) = bp.rp0;

for i = 1:tp.n_steps-1
    yi  = [R(i); Rp(i)];
    zi  = z(i);
    ksi = k_sq_interp(i);

    k1 = dz * envelope_derivatives(yi,             ksi, K, emit_n, beta, gamma);
    k2 = dz * envelope_derivatives(yi + 0.5*k1,   ksi, K, emit_n, beta, gamma);
    k3 = dz * envelope_derivatives(yi + 0.5*k2,   ksi, K, emit_n, beta, gamma);
    k4 = dz * envelope_derivatives(yi + k3,        ksi, K, emit_n, beta, gamma);

    y_next = yi + (k1 + 2*k2 + 2*k3 + k4) / 6;

    % Guard against unphysical negative radius
    if y_next(1) <= 0
        warning('beam_transport: envelope collapsed at z = %.4f m. ' ...
                'Check focusing strength.', z(i));
        y_next(1) = abs(y_next(1)) + MIN_ENVELOPE_RADIUS;
    end

    R(i+1)  = y_next(1);
    Rp(i+1) = y_next(2);
end

fprintf('--- Beam Transport ---\n');
fprintf('  Generalised perveance K : %.4e\n', K);
fprintf('  Max envelope radius     : %.4f mm\n', max(R)*1e3);
fprintf('  Min envelope radius     : %.4f mm\n', min(R)*1e3);
fprintf('  Final radius            : %.4f mm\n', R(end)*1e3);
fprintf('  Final slope             : %.4f mrad\n', Rp(end)*1e3);

end

% ======================================================================
%  Local helper – return derivatives [dR/dz; d²R/dz²] for the K-V
%  beam-envelope equation.
% ======================================================================
function dydt = envelope_derivatives(y, k_sq, K, emit_n, beta, gamma)
% y = [R; Rp]
R  = y(1);
Rp = y(2);

% Emittance term uses geometric rms emittance:  ε = εₙ / (βγ)
emit_geo = emit_n / (beta * gamma);

dRp = -k_sq * R + K / R + emit_geo^2 / R^3;

dydt = [Rp; dRp];
end
