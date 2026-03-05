function params = injector_params()
% INJECTOR_PARAMS  Return a struct of nominal design parameters for the
%                  Scorpius E-Beam Injector digital twin.
%
% Usage:
%   params = injector_params()
%
% The returned struct groups parameters into five sub-structs:
%   params.phys        – fundamental physical constants
%   params.gun         – electron-gun (diode) parameters
%   params.beam        – initial beam-parameter estimates
%   params.solenoid    – solenoid-focusing parameters
%   params.transport   – beam-line / transport parameters
%
% References:
%   [1] R. C. Davidson & H. Qin, "Physics of Intense Charged Particle
%       Beams in High Energy Accelerators", World Scientific, 2001.
%   [2] T. P. Wangler, "RF Linear Accelerators", Wiley-VCH, 2008.

% ------------------------------------------------------------------ %
%  Physical constants (SI)
% ------------------------------------------------------------------ %
phys.c   = 2.997924580e8;   % speed of light          [m/s]
phys.e   = 1.602176634e-19; % elementary charge        [C]
phys.me  = 9.109383702e-31; % electron rest mass       [kg]
phys.eps0 = 8.854187817e-12; % permittivity of vacuum  [F/m]
phys.mec2 = phys.me * phys.c^2 / phys.e; % electron rest energy [eV]

% ------------------------------------------------------------------ %
%  Electron-gun (diode) parameters
% ------------------------------------------------------------------ %
gun.voltage     = 1.0e6;    % cathode-to-anode voltage  [V]  (1 MV)
gun.gap_length  = 0.05;     % anode-cathode gap          [m]
gun.cathode_r   = 0.035;    % cathode radius              [m]
gun.emission_type = 'space_charge_limited'; % Child-Langmuir regime

% ------------------------------------------------------------------ %
%  Initial beam parameters (at gun exit / beam waist)
% ------------------------------------------------------------------ %
beam.energy_MeV  = gun.voltage / 1e6; % kinetic energy            [MeV]
beam.pulse_ns    = 70;                % pulse duration            [ns]
% r0 is set to the smooth-approximation matched envelope radius for
% the solenoid channel below (R_m = sqrt(K / k_s^2)), ensuring stable
% transport through the injector section.
beam.r0          = 0.033;             % initial envelope radius   [m]
beam.rp0         = 0.0;               % initial envelope slope    [rad]
beam.emit_n      = 200e-6;            % norm. rms emittance       [m·rad]

% ------------------------------------------------------------------ %
%  Solenoid-focusing parameters (first section)
% ------------------------------------------------------------------ %
% B0 is chosen so that the smooth-approximation matched radius equals
% beam.r0:  k_s^2 = K / r0^2  →  B0 = sqrt(k_s^2) * 2*p_rel / e.
% This yields B0 ≈ 40 mT for the 1 MV, 3.6 kA beam defined above.
solenoid.B0          = 0.040;   % peak on-axis field     [T]
solenoid.length      = 0.30;    % solenoid physical length [m]
solenoid.entry_pos   = 0.05;    % position along beam line [m]
solenoid.n_solenoids = 4;       % number of solenoid lenses

% ------------------------------------------------------------------ %
%  Transport / beam-line parameters
% ------------------------------------------------------------------ %
transport.total_length = 1.50;  % full injector section length [m]
transport.n_steps      = 1500;  % number of integration steps
transport.pipe_r       = 0.05;  % beam-pipe inner radius       [m]

% ------------------------------------------------------------------ %
%  Assemble output struct
% ------------------------------------------------------------------ %
params.phys      = phys;
params.gun       = gun;
params.beam      = beam;
params.solenoid  = solenoid;
params.transport = transport;

end
