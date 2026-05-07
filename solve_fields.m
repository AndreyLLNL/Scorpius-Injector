function fields = solve_fields(hw, z_grid, r_grid)
% SOLVE_FIELDS  Compute the on-axis and 2-D electromagnetic fields for
%               the Scorpius injector hardware model.
%
% INPUTS
%   hw      - hardware structure returned by build_hardware()
%   z_grid  - 1-D column vector of axial positions [m]  (optional)
%   r_grid  - 1-D column vector of radial positions [m] (optional)
%
% OUTPUTS
%   fields  - structure with fields:
%     .z          - axial grid used [m]
%     .r          - radial grid used [m]
%     .Bz_axis    - on-axis axial magnetic field Bz(z) [T]
%     .Br_2d      - radial component Br(r,z) [T]   (Nr x Nz matrix)
%     .Bz_2d      - axial   component Bz(r,z) [T]  (Nr x Nz matrix)
%     .Ez_diode   - on-axis electric field Ez(z) inside the diode [V/m]
%     .phi_diode  - electrostatic potential phi(z) inside the diode [V]
%
% METHOD
%   Magnetic field: superposition of thick solenoid on-axis formulas.
%   Each solenoid is treated as a stack of thin current loops and
%   integrated analytically using the standard Biot-Savart solenoid
%   formula for a finite-length coil.
%
%   Electric field in the diode gap: 1-D uniform-field approximation
%   (parallel-plate) for the cathode-anode region.

    % ------------------------------------------------------------------
    % Default grids
    % ------------------------------------------------------------------
    if nargin < 2 || isempty(z_grid)
        z_grid = (0 : 0.005 : 8.425)';   % 5 mm steps over full length
    end
    if nargin < 3 || isempty(r_grid)
        r_grid = (0 : 0.002 : 0.080)';   % 2 mm steps up to pipe radius
    end

    z_grid = z_grid(:);
    r_grid = r_grid(:);
    Nz     = numel(z_grid);
    Nr     = numel(r_grid);

    fprintf('Solving fields on %d x %d (r x z) grid...\n', Nr, Nz);

    % ------------------------------------------------------------------
    % 1. Magnetic field from solenoids
    % ------------------------------------------------------------------
    Bz_axis = zeros(Nz, 1);
    Bz_2d   = zeros(Nr, Nz);
    Br_2d   = zeros(Nr, Nz);

    mu0 = 4*pi*1e-7;   % [H/m]

    for s = 1:numel(hw.solenoids)
        sol = hw.solenoids(s);
        if isempty(sol.id), continue; end

        % Geometric parameters of this solenoid
        z0  = sol.z_center;
        L   = sol.length;
        Ri  = sol.inner_radius;
        Ro  = sol.outer_radius;
        N   = sol.turns;
        I   = sol.current;

        % Current density [A/m^2]
        A_coil = pi * (Ro^2 - Ri^2);
        J      = N * I / A_coil;

        % --- On-axis Bz contribution (thick solenoid formula) ---
        % Decompose into Nlay radial layers and use thin-solenoid formula
        Nlay = 20;
        r_layers = linspace(Ri, Ro, Nlay);
        dR = (Ro - Ri) / (Nlay - 1);

        for iR = 1:Nlay
            R   = r_layers(iR);
            n_l = J * dR;              % linear turn density
            z1  = z0 - L/2;
            z2  = z0 + L/2;

            for iz = 1:Nz
                zz  = z_grid(iz);
                d1  = zz - z1;
                d2  = zz - z2;
                Bz_axis(iz) = Bz_axis(iz) + ...
                    (mu0 * n_l / 2) * ...
                    (d2 / sqrt(d2^2 + R^2) - d1 / sqrt(d1^2 + R^2));
            end
        end

        % --- Off-axis fields using paraxial approximation ---
        % Bz(r,z) ≈ Bz(0,z) - (r^2/4) * d²Bz/dz²
        % Br(r,z) ≈ -(r/2) * dBz/dz
        % (valid for r << R_coil)
    end

    % Compute 2-D fields from on-axis via paraxial expansion
    dBz_dz  = gradient(Bz_axis, z_grid);
    d2Bz_dz2 = gradient(dBz_dz, z_grid);

    for ir = 1:Nr
        r = r_grid(ir);
        Bz_2d(ir, :) = Bz_axis' - (r^2 / 4) .* d2Bz_dz2';
        Br_2d(ir, :) = -(r / 2) .* dBz_dz';
    end

    % ------------------------------------------------------------------
    % 2. Electric field in the diode gap (cathode–anode)
    % ------------------------------------------------------------------
    z_cath  = hw.cathode.z_position;
    z_an    = hw.anode.z_position;
    V_accel = hw.anode.accel_voltage_V;   % accelerating voltage on cathode (<0)
    V_an    = hw.anode.voltage_V;         % anode at 0 V
    gap     = z_an - z_cath;

    % Only compute for z within the diode gap
    mask_diode = (z_grid >= z_cath) & (z_grid <= z_an);
    phi_diode  = zeros(Nz, 1);
    Ez_diode   = zeros(Nz, 1);

    phi_diode(mask_diode) = V_accel + ...
        (V_an - V_accel) * (z_grid(mask_diode) - z_cath) / gap;
    Ez_diode(mask_diode)  = -(V_an - V_accel) / gap;  % uniform field

    % ------------------------------------------------------------------
    % Package output
    % ------------------------------------------------------------------
    fields.z         = z_grid;
    fields.r         = r_grid;
    fields.Bz_axis   = Bz_axis;
    fields.Bz_2d     = Bz_2d;
    fields.Br_2d     = Br_2d;
    fields.Ez_diode  = Ez_diode;
    fields.phi_diode = phi_diode;

    fprintf('Field solve complete.\n\n');
end
