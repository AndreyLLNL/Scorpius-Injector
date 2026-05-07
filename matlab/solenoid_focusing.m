function sol = solenoid_focusing(z, params, gun_out)
% SOLENOID_FOCUSING  Compute the thin-lens focal length and phase advance
%                    for each solenoid in the injector beam line.
%
% Usage:
%   sol = solenoid_focusing(z, params, gun_out)
%
% Inputs:
%   z        – array of axial positions along the beam line [m]
%   params   – struct returned by injector_params()
%   gun_out  – struct returned by electron_gun()
%
% Output:
%   sol  – struct with fields:
%     .Bz          on-axis field profile   [T]  (Nz×1 vector)
%     .focal_len   thin-lens focal length  [m]  (1 per solenoid)
%     .entry_pos   solenoid entry positions [m]
%     .exit_pos    solenoid exit positions  [m]
%     .k_sq        solenoid focusing strength k²  [m^-2] (Nz×1)
%
% Physics – thin-lens focal length of a solenoid [1]:
%   1/f = (eB0L)^2 / (8 (p/c)^2)      non-relativistic limit
%   More precisely:
%   1/f = (e/(2*p))^2 * integral(Bz^2, z_in, z_out)           (1)
%
%   where p = gamma*beta*m_e*c is the relativistic momentum.
%
%   Solenoid phase advance per cell k²:
%   k_s^2 = (e*Bz / (2*gamma*beta*m_e*c))^2                   (2)
%
% References:
%   [1] M. Reiser, "Theory and Design of Charged Particle Beams",
%       Wiley-VCH, 2nd ed., 2008, Chap. 3.

p   = params.phys;
sp  = params.solenoid;
tp  = params.transport;

Nz       = length(z);
Bz_total = zeros(Nz, 1);

% ------------------------------------------------------------------ %
%  On-axis field profile: hard-edge solenoids
%  B(z) = B0   for  z_entry <= z <= z_exit,  else 0
% ------------------------------------------------------------------ %
solenoid_spacing = (tp.total_length - sp.entry_pos) / sp.n_solenoids;
entry_pos = zeros(sp.n_solenoids, 1);
exit_pos  = zeros(sp.n_solenoids, 1);

for k = 1:sp.n_solenoids
    z_in  = sp.entry_pos + (k-1) * solenoid_spacing;
    z_out = z_in + sp.length;
    entry_pos(k) = z_in;
    exit_pos(k)  = z_out;
    mask = (z >= z_in) & (z <= z_out);
    Bz_total(mask) = Bz_total(mask) + sp.B0;
end

% ------------------------------------------------------------------ %
%  Solenoid focusing strength k²(z)   [m^-2]
% ------------------------------------------------------------------ %
p_beam = gun_out.gamma * gun_out.beta * p.me * p.c; % relativistic momentum [kg·m/s]
k_sq  = (p.e * Bz_total / (2 * p_beam)).^2;

% ------------------------------------------------------------------ %
%  Thin-lens focal length for each solenoid  (numerical integral)
% ------------------------------------------------------------------ %
dz        = z(2) - z(1);
focal_len = zeros(sp.n_solenoids, 1);

for k = 1:sp.n_solenoids
    mask = (z >= entry_pos(k)) & (z <= exit_pos(k));
    integral_Bz2 = sum(Bz_total(mask).^2) * dz;
    focal_len(k) = 1 / ((p.e / (2 * p_beam))^2 * integral_Bz2);
end

% ------------------------------------------------------------------ %
%  Pack output
% ------------------------------------------------------------------ %
sol.Bz        = Bz_total;
sol.k_sq      = k_sq;
sol.focal_len = focal_len;
sol.entry_pos = entry_pos;
sol.exit_pos  = exit_pos;

fprintf('--- Solenoid Focusing (%d lenses) ---\n', sp.n_solenoids);
for k = 1:sp.n_solenoids
    fprintf('  Solenoid %d: z = [%.3f, %.3f] m,  f = %.4f m\n', ...
        k, entry_pos(k), exit_pos(k), focal_len(k));
end

end
