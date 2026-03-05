function gun = electron_gun(params)
% ELECTRON_GUN  Model the electron-gun (diode) stage of the injector.
%
% Usage:
%   gun = electron_gun(params)
%
% Input:
%   params  – struct returned by injector_params()
%
% Output:
%   gun  – struct with fields:
%     .gamma        relativistic Lorentz factor         [-]
%     .beta         relativistic speed ratio v/c        [-]
%     .KE_MeV       kinetic energy                      [MeV]
%     .momentum_MeV relativistic momentum               [MeV/c]
%     .current      beam current (Child-Langmuir)       [A]
%     .perveance    generalised perveance                [A/V^(3/2)]
%     .J_cathode    current density at cathode           [A/m^2]
%     .beam_power   peak beam power                     [W]
%
% Physics:
%   Non-relativistic Child-Langmuir space-charge-limited current density:
%       J = (4*eps0/9) * sqrt(2*e/m) * V^(3/2) / d^2          (1)
%
%   Relativistic kinematics:
%       gamma = 1 + eV/(m_e c^2)                               (2)
%       beta  = sqrt(1 - 1/gamma^2)                            (3)
%
% References:
%   [1] C. D. Child, Phys. Rev. 32, 492 (1911).
%   [2] I. Langmuir & K. Blodgett, Phys. Rev. 24, 49 (1924).

p  = params.phys;
g  = params.gun;

% ------------------------------------------------------------------ %
%  Relativistic kinematics
% ------------------------------------------------------------------ %
gamma   = 1 + (p.e * g.voltage) / (p.me * p.c^2);
beta    = sqrt(1 - 1/gamma^2);
KE_MeV  = (gamma - 1) * p.mec2 / 1e6;
p_MeVc  = gamma * beta * p.mec2 / 1e6;

% ------------------------------------------------------------------ %
%  Child-Langmuir space-charge-limited current density
% ------------------------------------------------------------------ %
% Non-relativistic (classical) Child-Langmuir law:
%   J = (4ε₀/9) · sqrt(2e/m) · V^(3/2) / d^2                 (1)
%
% This law is strictly valid when eV << m_e c² (0.511 MeV).
% For higher-voltage guns (eV ≳ m_e c²) it overestimates J by a
% modest factor; it is retained here as the standard engineering
% estimate for injector pre-design.
CL_factor   = (4 * p.eps0 / 9) * sqrt(2 * p.e / p.me);
J_CL        = CL_factor * g.voltage^(3/2) / g.gap_length^2;  % [A/m^2]

cathode_area = pi * g.cathode_r^2;   % [m^2]
I_beam       = J_CL * cathode_area;  % [A]

% ------------------------------------------------------------------ %
%  Beam perveance (generalised)
%    P = I / (beta * gamma)^3 / (p.mec2/1e6)^2
% ------------------------------------------------------------------ %
perveance = I_beam / (g.voltage^(3/2));    % [A/V^(3/2)]

% ------------------------------------------------------------------ %
%  Pack output
% ------------------------------------------------------------------ %
gun.gamma        = gamma;
gun.beta         = beta;
gun.KE_MeV       = KE_MeV;
gun.momentum_MeV = p_MeVc;
gun.current      = I_beam;
gun.perveance    = perveance;
gun.J_cathode    = J_CL;
gun.beam_power   = I_beam * g.voltage;

fprintf('--- Electron Gun ---\n');
fprintf('  Cathode voltage   : %g kV\n',  g.voltage/1e3);
fprintf('  Kinetic energy    : %.4f MeV\n', KE_MeV);
fprintf('  Lorentz gamma     : %.4f\n',   gamma);
fprintf('  beta (v/c)        : %.6f\n',   beta);
fprintf('  Beam current      : %.1f kA\n', I_beam/1e3);
fprintf('  Current density   : %.2f kA/cm^2\n', J_CL/1e7);
fprintf('  Perveance         : %.3e A/V^(3/2)\n', perveance);
fprintf('  Peak beam power   : %.2f GW\n', gun.beam_power/1e9);

end
