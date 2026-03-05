function beam = beam_dynamics(hw, fields, beam_params)
% BEAM_DYNAMICS  Envelope-based beam transport simulation for the
%                Scorpius injector.
%
% Tracks the RMS beam envelope from cathode to the end of the drift pipe
% using the RMS envelope equation:
%
%   R'' + (k_sol^2) R - (emittance^2 / R^3) - (chi / R) = 0
%
% where
%   k_sol   = e*Bz / (2*gamma*m*c*beta)  (solenoid focusing strength)
%   chi     = I / (2*I_A*beta^3*gamma^3) (space-charge term)
%   I_A     = 17045 A  (Alfven current)
%   emittance in [m·rad]
%
% INPUTS
%   hw           - hardware structure from build_hardware()
%   fields       - fields structure from solve_fields()
%   beam_params  - structure with initial beam parameters:
%                    .energy_MeV   - beam kinetic energy [MeV]
%                    .current_A    - peak beam current [A]
%                    .emittance_n  - normalised rms emittance [m·rad]
%                    .r0_m         - initial beam radius [m]
%                    .rp0          - initial beam divergence [rad]
%
% OUTPUTS
%   beam   - structure with:
%     .z          - axial positions [m]
%     .R          - RMS beam radius envelope [m]
%     .Rp         - envelope derivative dR/dz [rad]
%     .beta_rel   - relativistic beta along z
%     .gamma_rel  - relativistic gamma along z
%     .emittance_n - normalised emittance (conserved) [m·rad]
%     .bpm_readings - interpolated beam radius at each BPM location

    fprintf('Running beam dynamics simulation...\n');

    % ------------------------------------------------------------------
    % Physical constants
    % ------------------------------------------------------------------
    c     = 2.99792458e8;   % [m/s]
    m_e   = 9.10938e-31;    % [kg]
    e_ch  = 1.60218e-19;    % [C]
    MeV   = 1e6 * e_ch;     % 1 MeV in Joules
    I_A   = 17045;          % Alfven current [A]
    m_e_MeV = 0.51100;      % electron rest mass [MeV]

    % ------------------------------------------------------------------
    % Initial beam parameters
    % ------------------------------------------------------------------
    KE_MeV   = beam_params.energy_MeV;
    I_beam   = beam_params.current_A;
    eps_n    = beam_params.emittance_n;   % normalised [m·rad]
    R0       = beam_params.r0_m;
    Rp0      = beam_params.rp0;

    gamma0   = 1 + KE_MeV / m_e_MeV;
    beta0    = sqrt(1 - 1/gamma0^2);

    % Geometric (unnormalised) emittance
    eps_g    = eps_n / (gamma0 * beta0);

    % ------------------------------------------------------------------
    % Set up ODE over field grid
    % ------------------------------------------------------------------
    z  = fields.z;
    Bz = fields.Bz_axis;

    % Space charge coefficient
    chi = I_beam / (2 * I_A * beta0^3 * gamma0^3);

    % Solenoid focusing term  k^2(z) = (e*Bz)^2 / (2*p*c)^2
    % p = gamma*m*c*beta
    p_SI     = gamma0 * m_e * c * beta0;
    k2_sol   = (e_ch .* Bz ./ (2 .* p_SI)).^2;

    % Build interpolating functions
    k2_interp  = @(zz) interp1(z, k2_sol, zz, 'pchip', 0);

    % ------------------------------------------------------------------
    % RMS envelope ODE:  d/dz [R; R'] = [R'; F(z,R,R')]
    % ------------------------------------------------------------------
    ode_rhs = @(zz, y) envelope_rhs(zz, y, k2_interp, eps_g, chi);

    z_span = [z(1), z(end)];
    y0     = [R0; Rp0];

    opts = odeset('RelTol', 1e-6, 'AbsTol', 1e-9, ...
                  'Events', @collapse_event);

    [z_out, y_out, ze, ~, ~] = ode45(ode_rhs, z_span, y0, opts);

    if ~isempty(ze)
        warning('beam_dynamics:envelope_collapse', ...
                'Beam envelope collapsed at z = %.3f m.', ze(1));
    end

    % ------------------------------------------------------------------
    % Package results
    % ------------------------------------------------------------------
    beam.z           = z_out;
    beam.R           = y_out(:, 1);
    beam.Rp          = y_out(:, 2);
    beam.emittance_n = eps_n;
    beam.beta_rel    = beta0 * ones(size(z_out));   % constant (no accel in pipe)
    beam.gamma_rel   = gamma0 * ones(size(z_out));

    % Beam size at each BPM
    Nbpm = numel(hw.bpms);
    beam.bpm_readings = struct('name', cell(Nbpm,1), ...
                               'z',    cell(Nbpm,1), ...
                               'R_mm', cell(Nbpm,1));
    for k = 1:Nbpm
        bz = hw.bpms(k).z_position;
        if bz < z_out(1) || bz > z_out(end)
            R_at_bpm = NaN;
        else
            R_at_bpm = interp1(z_out, y_out(:,1), bz, 'pchip');
        end
        beam.bpm_readings(k).name = hw.bpms(k).name;
        beam.bpm_readings(k).z    = bz;
        beam.bpm_readings(k).R_mm = R_at_bpm * 1e3;   % convert to mm
    end

    [R_max, idx_max] = max(beam.R);
    fprintf('Beam dynamics complete. Max radius = %.1f mm at z = %.3f m.\n', ...
            R_max*1e3, beam.z(idx_max));
    fprintf('\n');
end

% ======================================================================
%  Local functions
% ======================================================================

function dydt = envelope_rhs(z, y, k2_interp, eps_g, chi)
    R_MIN = 1e-9;   % minimum radius floor to prevent division by zero [m]
    R  = y(1);
    Rp = y(2);
    if R <= 0
        R = R_MIN;
    end
    k2 = k2_interp(z);
    Rpp = -k2 * R + (eps_g^2) / R^3 + chi / R;
    dydt = [Rp; Rpp];
end

function [val, isterminal, direction] = collapse_event(~, y)
    R_COLLAPSE_THRESHOLD = 1e-6;   % beam collapse if R < 1 micron [m]
    val        = y(1) - R_COLLAPSE_THRESHOLD;
    isterminal = 1;
    direction  = -1;
end
