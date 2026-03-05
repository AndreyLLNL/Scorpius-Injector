%%MATLAB model Pierce_Gun_PIC_v8_Integrated_SC_F6_2_V3_12.m
%%Tis particular folder dedicated to tests with longer and softer AK pulse modulation
%% Pierce_Gun_PIC_v8_Integrated_SC.m - Complete with Space Charge
% Performance-optimized PIC simulator for extended domain (0-2760mm)
% Includes space charge, magnetic fields, ion accumulation and full diagnostics
%Focus on pulse to pulse lensing in  multi-pulse mode, four pulses
% Date: 2025-11-06
%pulse_config.n_pulses=4; % Line 229
z_active
n_active
active_idx
clear all; close all; clc;

fprintf('\n=== Pirce_Gun_PIC_v8_Integrated_SC_Extended_V1.m ===\n');

%% ==================== CONFIGURATION ====================
simulation_mode = 'PRODUCTION';  % 'QUICK_TEST', 'OPTIMIZATION', 'PRODUCTION'
%simulation_mode = 'QUICK_TEST';  % 'QUICK_TEST', 'OPTIMIZATION', 'PRODUCTION'
%ENABLE_SPACE_CHARGE = false;      % Toggle for A/B testing false or true
ENABLE_SPACE_CHARGE = true;      % Toggle for A/B testing false or true
%%%%%%%%%%%%%%%%%%%%% Complete Solenoids Listing 02.12.2026 %%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== SOLENOID FIELD STRENGTHS (ALL 49) ====================
% Original solenoids 1-19 (EXISTING - no changes needed)
solenoid1_field = -0.0450;  % Cathode solenoid at z = -279 mm
solenoid2_field = 0.0135;   % Anode Solenoid at z = 372 mm
solenoid3_field = 0.0075;   % Drift solenoid 1 at 1144.61mm
solenoid4_field = 0.0075;   % Drift solenoid 2 at 1267.57mm
solenoid5_field = 0.0050;   % Drift solenoid 3 at 1369.27mm
% solenoid6 = Steering magnet (OFF)
solenoid7_field = 0.0025;   % Drift solenoid 4 at 1492.23mm
solenoid8_field = 0.0025;   % Drift solenoid 5 at 1593.93mm
solenoid9_field = 0.0025;   % Drift solenoid 6 at 1716.89mm
solenoid10_field = 0.0025;  % Drift solenoid 7 at 1818.60mm
solenoid11_field = 0.0020;  % Drift solenoid 8 at 1941.56mm
solenoid12_field = 0.0020;  % Drift solenoid 9 at 2043.26mm
% solenoid13 = Steering magnet (OFF)
solenoid14_field = 0.0020;  % Drift solenoid 10 at 2166.22mm
solenoid15_field = 0.0020;  % Drift solenoid 11 at 2267.93mm
solenoid16_field = 0.0015;  % Drift solenoid 12 at 2390.89mm
solenoid17_field = 0.0015;  % Drift solenoid 13 at 2492.59mm
solenoid18_field = 0.0015;  % Drift solenoid 14 at 2615.55mm
solenoid19_field = 0.0015;  % Drift solenoid 15 at 2717.26mm
% ==================== EXTENDED SOLENOIDS 20-49 (NEW) ====================
solenoid20_field = 0.0015;  % Drift solenoid 16 at 2840.22mm
solenoid21_field = 0.0015;  % Drift solenoid 17 at 2941.92mm
solenoid22_field = 0.0015;  % Drift solenoid 18 at 3064.88mm
solenoid23_field = 0.0015;  % Drift solenoid 19 at 3166.58mm
solenoid24_field = 0.0015;  % Drift solenoid 20 at 3289.54mm
solenoid25_field = 0.0015;  % Drift solenoid 21 at 3391.25mm
solenoid26_field = 0.0015;  % Drift solenoid 22 at 3514.21mm
solenoid27_field = 0.0015;  % Drift solenoid 23 at 3615.91mm
solenoid28_field = 0.0015;  % Drift solenoid 24 at 3738.87mm
solenoid29_field = 0.0015;  % Drift solenoid 25 at 3840.58mm
solenoid30_field = 0.0015;  % Drift solenoid 26 at 3963.54mm
solenoid31_field = 0.0015;  % Drift solenoid 27 at 4065.24mm
solenoid32_field = 0.0015;  % Drift solenoid 28 at 4188.20mm
solenoid33_field = 0.0015;  % Drift solenoid 29 at 4289.93mm
solenoid34_field = 0.0015;  % Drift solenoid 30 at 4412.89mm
solenoid35_field = 0.0015;  % Drift solenoid 31 at 4514.59mm
solenoid36_field = 0.0015;  % Drift solenoid 32 at 4637.55mm
% solenoid37 = Steering magnet 3 at 4677.00mm (OFF)
solenoid38_field = 0.0015;  % Drift solenoid 33 at 4739.25mm
solenoid39_field = 0.0015;  % Drift solenoid 34 at 4862.21mm
solenoid40_field = 0.0015;  % Drift solenoid 35 at 4963.92mm
solenoid41_field = 0.0015;  % Drift solenoid 36 at 5086.88mm
solenoid42_field = 0.0015;  % Drift solenoid 37 at 5188.58mm
solenoid43_field = 0.0015;  % Drift solenoid 38 at 5311.54mm
% solenoid44 = Steering magnet 4 at 5377.00mm (OFF)
solenoid45_field = 0.0015;  % Drift solenoid 39 at 5413.24mm
solenoid46_field = 0.0015;  % Drift solenoid 40 at 5536.20mm
solenoid47_field = 0.0015;  % Drift solenoid 41 at 5637.91mm
solenoid48_field = 0.0015;  % Drift solenoid 42 at 5760.87mm
solenoid49_field = 0.0015;  % Drift solenoid 43 at 7448.00mm (LAST SOLENOID)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== SNAPSHOT TIMING CONFIGURATION ====================
% TWISS ANALYSIS TIMING CONFIGURATION
TWISS_PULSE1_TIME = 205e-9;      % Middle of Pulse 1 flat-top
TWISS_PULSE2_TIME = 405e-9;      % Middle of Pulse 2 flat-top
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Corrected BETATRON AVERAGING Setup %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 01.26.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== STEP 1: SNAPSHOT TIMING CONFIGURATION ====================
% Place this at the top of your code (around line 50)

% Multi-snapshot configuration for betatron averaging
ENABLE_BETATRON_AVERAGING = true;  % Master toggle
%ENABLE_BETATRON_AVERAGING = false;  % Master toggle 2

%%%%%%%%%%%%%%%%%%%%%%%%%%%% new dual pulse configuration %%%%%%%%%%%%%%%%%%%%%%%%%
% REGULAR MULTIPULSE OPTION IN UNTITLED25
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% QUICK_TEST_OPTION %%%%%%%%%%%%%%%%%%%%%%
%% ==================== MULTI-PULSE CONFIGURATION ====================
%ENABLE_MULTIPULSE = true;  % Keep enabled
ENABLE_MULTIPULSE = false;  % Single pulse operation

if ENABLE_BETATRON_AVERAGING == true
    if ENABLE_MULTIPULSE == true
        % Multi-pulse mode: P1 and P2 snapshots
        SNAPSHOT_P1_TIMES = [195e-9, 200e-9, 205e-9, 210e-9, 215e-9, 220e-9, 225e-9];
        SNAPSHOT_P2_TIMES = [395e-9, 400e-9, 405e-9, 410e-9, 415e-9, 420e-9, 425e-9];
        % Pulse 3 snapshots (NEW - add after P2)
        SNAPSHOT_P3_TIMES = [570e-9, 575e-9, 580e-9, 585e-9, 590e-9, 595e-9, 600e-9];
        %ADD THIS LINE after SNAPSHOT_P3_TIMES:
        SNAPSHOT_P4_TIMES = [770e-9, 775e-9, 780e-9, 785e-9, 790e-9, 795e-9, 800e-9];
        N_SNAPSHOTS = 7;
        % ===== ADD THIS SAFETY CHECK =====
        N_SNAPSHOTS_EARLY = N_SNAPSHOTS;  % For consistency
        N_SNAPSHOTS_LATE = N_SNAPSHOTS;
        SNAPSHOT_EARLY_TIMES = [165e-9, 168e-9, 171e-9, 174e-9, 177e-9, 180e-9, 183e-9];
        %SNAPSHOT_LATE_TIMES  = [210e-9, 213e-9, 216e-9, 219e-9, 222e-9, 225e-9, 228e-9];
        SNAPSHOT_LATE_TIMES  = [227e-9, 230e-9, 233e-9, 236e-9, 239e-9, 242e-9, 245e-9];
        
        fprintf('\n=== BETATRON AVERAGING MODE (MULTI-PULSE) ===\n');
        fprintf('Snapshots per pulse: %d\n', N_SNAPSHOTS);
        fprintf('Temporal spacing: %.1f ns\n', (SNAPSHOT_P1_TIMES(2)-SNAPSHOT_P1_TIMES(1))*1e9);
        fprintf('Total window: %.1f ns (~1 betatron period)\n', ...
                (SNAPSHOT_P1_TIMES(end)-SNAPSHOT_P1_TIMES(1))*1e9);
    else
        % Single-pulse mode: EARLY vs LATE for intra-pulse ion focusing study
        % Early beam: 165-180ns (ions just starting to accumulate)
        % Late beam: 210-225ns (ions have accumulated, ~300M ions present)
 %%%%%%%%%%%%%%%%%%%%%%%%%%% Updated 01.29.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %SNAPSHOT_EARLY_TIMES = [165e-9, 170e-9, 175e-9, 180e-9];
        %SNAPSHOT_LATE_TIMES  = [210e-9, 215e-9, 220e-9, 225e-9];
        % Change from 4 to 7 snapshots per window
        SNAPSHOT_EARLY_TIMES = [165e-9, 168e-9, 171e-9, 174e-9, 177e-9, 180e-9, 183e-9];
        SNAPSHOT_LATE_TIMES  = [210e-9, 213e-9, 216e-9, 219e-9, 222e-9, 225e-9, 228e-9];

        N_SNAPSHOTS_EARLY = length(SNAPSHOT_EARLY_TIMES);
        N_SNAPSHOTS_LATE = length(SNAPSHOT_LATE_TIMES);
 %%%%%%%%%%%%%%%%%%%%%%%%%% updated 02.25.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % ADD after the existing early/late initialization:
 % Also initialize P1 mid-pulse snapshots for betatron averaging
%       snapshot_p1 = cell(N_SNAPSHOTS, 1);
%       snapshot_p1_count = 0;
      
        % Single pulse regime with ENABLE_BETATRON_AVERAGING == true
        SNAPSHOT_P1_TIMES = [195e-9, 200e-9, 205e-9, 210e-9, 215e-9, 220e-9, 225e-9];
        N_SNAPSHOTS = 7;
        
        fprintf('\n=== INTRA-PULSE ION FOCUSING MODE ===\n');
        fprintf('Early beam snapshots: %d (t=%.0f-%.0f ns, minimal ions)\n', ...
                N_SNAPSHOTS_EARLY, SNAPSHOT_EARLY_TIMES(1)*1e9, SNAPSHOT_EARLY_TIMES(end)*1e9);
        fprintf('Late beam snapshots: %d (t=%.0f-%.0f ns, with ion focusing)\n', ...
                N_SNAPSHOTS_LATE, SNAPSHOT_LATE_TIMES(1)*1e9, SNAPSHOT_LATE_TIMES(end)*1e9);
        fprintf('Snapshot Pi times: %d (t=%.0f-%.0f ns, with ion focusing)\n', ...
                N_SNAPSHOTS, SNAPSHOT_P1_TIMES(1)*1e9, SNAPSHOT_P1_TIMES(end)*1e9);
        
        % Estimate ion difference
        fprintf('Expected ion increase: ~50M → ~300M (6x growth)\n');
    end
else
    % Legacy single snapshot mode
    SNAPSHOT_P1_TIMES = 205e-9;
    N_SNAPSHOTS = 1;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% ==================== LOAD RESOURCES ====================
fprintf('================================================================\n');
fprintf('  PIERCE GUN PIC v8 - WITH SPACE CHARGE                        \n');
fprintf('================================================================\n\n');

% Check required files
%if ~exist('pierce_gun_geometry_extended_scale_1.mat', 'file')
if ~exist('pierce_gun_lego_theta80_gap10_recess20.mat', 'file')    
    error('Geometry file not found. Run geometry builder first.');
end
if ~exist('pierce_gun_field_solution_ready.mat', 'file')
    error('Field solution not found. Run field solver first.');
end

% Load geometry and fields
fprintf('Loading resources...\n');
%load('pierce_gun_geometry_extended_scale_1.mat');
%load('pierce_gun_lego_theta80_gap10_recess20.mat');
load('pierce_gun_lego_theta68_gap0_recess0.mat');

%load('pierce_gun_field_solution_capped.mat');
load('pierce_gun_field_solution_ready.mat');

fprintf('  ✓ Geometry loaded (mesh: %dx%d)\n', nz, nr);
fprintf('  ✓ Fields loaded (max E: %.1f MV/m)\n', max(abs(Ez_capped(:)))/1e6);
%%%%%%%%%%%%%%%%%%%%%%%%% added 02.25.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================================================================================
%% FIX 1b: ALSO ADD THIS AT PIC INITIALIZATION (after loading fields)
%% Place around line 175, after "load('pierce_gun_field_solution_capped.mat')"
%% This provides an early diagnostic before the main loop starts
%% ==================================================================================

%% ==================== CATHODE FIELD DIAGNOSTIC (AT STARTUP) ====================
fprintf('\n=== Cathode Surface Field Analysis ===\n');

% Extract field at cathode surface
z_cath_search = find(z >= 0 & z <= 0.010);  % 0 to 10mm
if ~isempty(z_cath_search)
    Ez_cath_profile = abs(Ez_capped(1, z_cath_search));
    [E_peak, peak_idx] = max(Ez_cath_profile);
    z_peak = z(z_cath_search(peak_idx));
    
    fprintf('  Peak cathode field: %.2f MV/m at z=%.1f mm\n', E_peak/1e6, z_peak*1000);
    fprintf('  (This value will be used for Schottky emission calculation)\n');
    
    % Compare with expected analytical value
    E_analytical = abs(V_anode - V_cathode) / gap_distance;
    fprintf('  Analytical gap field: %.2f MV/m (V/d)\n', E_analytical/1e6);
    fprintf('  Enhancement factor: %.2f\n', E_peak / E_analytical);
    
    % Store for later use
    E_CATHODE_BASE_DETECTED = E_peak;
else
    fprintf('  WARNING: Cannot find cathode region in z array\n');
    E_CATHODE_BASE_DETECTED = 5.37e6;  % Legacy fallback
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%% added 02.25.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================================================================================
%% FIX 4: STARTUP GEOMETRY-FIELD CONSISTENCY CHECK
%% ==================================================================================
%% Add this after loading both geometry and field files in the PIC code
%% (around line 180, after both load() calls)
%% Verifies that the field solution matches the current geometry
%% ==================================================================================

%% ==================== GEOMETRY-FIELD CONSISTENCY CHECK ====================
fprintf('\n=== Geometry-Field Consistency Check ===\n');

% Check 1: Domain boundaries match
fprintf('  Domain check:\n');
fprintf('    Geometry z-range: [%.1f, %.1f] mm\n', z(1)*1000, z(end)*1000);
fprintf('    Expected: [-400, 8305] mm\n');

if abs(z(1)*1000 - (-400)) > 1 || abs(z(end)*1000 - 8305) > 1
    fprintf('    WARNING: Domain mismatch! Re-run field solver with current geometry.\n');
else
    fprintf('    OK: Domain boundaries match\n');
end

% Check 2: Mesh dimensions match
fprintf('  Mesh check: %d x %d\n', nz, nr);

% Check 3: Cathode field available
if exist('cathode_field_info', 'var') && isfield(cathode_field_info, 'E_peak_on_axis')
    fprintf('  Cathode field (from solver): %.2f MV/m\n', ...
            cathode_field_info.E_peak_on_axis/1e6);
    
    % Cross-check with direct extraction
    z_cath_idx = find(z >= 0 & z <= 0.010);
    if ~isempty(z_cath_idx)
        E_direct = max(abs(Ez_capped(1, z_cath_idx)));
        fprintf('  Cathode field (direct check): %.2f MV/m\n', E_direct/1e6);
        
        if abs(E_direct - cathode_field_info.E_peak_on_axis) / E_direct > 0.01
            fprintf('  WARNING: Cathode field mismatch (>1%%)!\n');
            fprintf('  The field solution may not match the loaded geometry.\n');
            fprintf('  Re-run the field solver.\n');
        else
            fprintf('  OK: Cathode field consistent\n');
        end
    end
else
    fprintf('  NOTE: cathode_field_info not in field file (legacy format)\n');
    fprintf('  Using direct extraction from Ez_capped\n');
end

% Check 4: Electrode count sanity
n_cathode = sum(electrode_map(:) == 1);
n_anode = sum(electrode_map(:) == 2);
n_ground = sum(electrode_map(:) == 3);
fprintf('  Electrodes: Cathode=%d, Anode=%d, Ground=%d\n', ...
        n_cathode, n_anode, n_ground);

if n_cathode < 50000
    fprintf('  WARNING: Unusually low cathode point count!\n');
end

fprintf('  Consistency check complete.\n');

%% ==================================================================================
%% SUMMARY OF EXPECTED CATHODE FIELDS BY PIERCE ANGLE
%% (For reference - actual values should come from dynamic extraction)
%% ==================================================================================
%
% These are APPROXIMATE values based on field solver results:
%
%   Pierce Angle | E_cathode_base | Gap Field | Notes
%   -------------|----------------|-----------|------------------
%   68°          | ~5.37 MV/m     | ~6.7 MV/m | Original design
%   80°          | ~6.0  MV/m     | ~6.7 MV/m | Moderate angle
%   89° (flat)   | ~6.5  MV/m     | ~6.7 MV/m | Nearly flat cathode
%
% The gap center field (V/d = 1.7MV/254mm = 6.69 MV/m) is relatively
% independent of Pierce angle because it depends mainly on the gap
% voltage and distance. However, the cathode SURFACE field varies
% because the electrode geometry near z=0 changes the local field
% enhancement/suppression.
%
% With dynamic extraction (FIX 1), you never need to update this
% manually - just re-run geometry builder + field solver + PIC.
%
%% ==================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check field array continuity
fprintf('\n=== Field Array Diagnostics ===\n');
fprintf('  z array: %.1f to %.1f mm (%d points)\n', z(1)*1000, z(end)*1000, length(z));
fprintf('  r array: %.1f to %.1f mm (%d points)\n', r(1)*1000, r(end)*1000, length(r));
fprintf('  Ez_capped size: %dx%d\n', size(Ez_capped));
fprintf('  Er_capped size: %dx%d\n', size(Er_capped));

% Check for discontinuities in Ez along axis
Ez_axis = Ez_capped(1,:);
z_checks = [250, 350, 600, 1000, 1400, 1800, 2200, 2600]; %added 1800, 2200, 2600
for zc = z_checks
    [~, iz] = min(abs(z*1000 - zc));
    fprintf('  Ez at z=%d mm: %.2e V/m\n', zc, Ez_axis(iz));
end

% Look for sharp drops
Ez_diff = diff(Ez_axis);
large_drops = find(abs(Ez_diff) > 0.5*max(abs(Ez_axis)));
if ~isempty(large_drops)
    fprintf('  WARNING: Sharp field drops at z indices: ');
    fprintf('%d ', large_drops);
    fprintf('\n');
    for ld = large_drops
        fprintf('    z=%.1f mm: Ez drops from %.2e to %.2e V/m\n', ...
                z(ld)*1000, Ez_axis(ld), Ez_axis(ld+1));
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% ==================== PHYSICAL CONSTANTS ====================
c = 299792458;
e_charge = 1.602176634e-19;
m_e = 9.10938356e-31;
eps0 = 8.854187817e-12;
k_B = 1.380649e-23;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%nr = 500;  % Radial points (unchanged)
%nz = 11000; % Axial points for -400 to 8305mm (dz ≈ 0.79mm)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== MODE CONFIGURATION ====================
switch simulation_mode
    case 'QUICK_TEST'
        dt = 10e-12;
        base_particles = 20;
        base_weight = 5e9;
        sc_interval = 50;
        diag_interval = 500;
        
    case 'OPTIMIZATION'
        dt = 10e-12;
        base_particles = 50;
        base_weight = 7e8;
        sc_interval = 25;
        diag_interval = 100;
        
    case 'PRODUCTION'
        dt = 10e-12;
        base_particles = 100; % Changed down from 200
        base_weight = 1e9;   % Changed up from 5e8
        sc_interval = 50;    % Changed up from 25
        diag_interval = 100; %Changed up from 50
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== SPACE CHARGE ARRAY INITIALIZATION ====================
% Initialize to prevent "variable doesn't exist" errors
%if ENABLE_SPACE_CHARGE
%   Ez_sc = zeros(sc_nr, sc_nz);
%   Er_sc = zeros(sc_nr, sc_nz);
%   phi_grid = zeros(sc_nr, sc_nz);
%   rho_grid = zeros(sc_nr, sc_nz);
%   fprintf('Space charge arrays initialized\n');
%end
%UNrecognized function or variable sc_nr (sc_nz)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Don't define t_start/t_end here - let multi-pulse section handle it
fprintf('\nConfiguration: %s mode\n', simulation_mode);
fprintf('  Timestep: %.2f ps\n', dt*1e12);
fprintf('  Particles/step: %d (weight: %.2e)\n', base_particles, base_weight);

%%%%%%%%%%%%%%%%%%%%%%%%%%%% new dual pulse configuration %%%%%%%%%%%%%%%%%%%%%%%%%
% REGULAR MULTIPULSE OPTION IN UNTITLED25
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% QUICK_TEST_OPTION %%%%%%%%%%%%%%%%%%%%%%
%% ==================== MULTI-PULSE CONFIGURATION ====================
%ENABLE_MULTIPULSE = true;  % Keep enabled - second time call!!!!
%ENABLE_MULTIPULSE = false;  % Single pulse operation

if ENABLE_MULTIPULSE == true
    pulse_config = struct();
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% added 02.06.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    pulse_config.n_pulses = 4;  % Changed from 3 to 4
    pulse_config.pulse_starts = [150e-9, 350e-9, 550e-9, 750e-9];  % Added 750ns for P4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %pulse_config.n_pulses = 3; %Changed from 2 to 3
    %pulse_config.pulse_starts = [150e-9, 350e-9, 550e-9];  % Closer spacing for quick test
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %pulse_config.n_pulses = 2; % Two pulse regime
    %pulse_config.pulse_starts = [150e-9, 350e-9];  % Closer spacing for quick test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Updated 02.06.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% At top of code (around line 230), define capture times:
% Inter-pulse electron cloud capture configuration
ENABLE_INTERPULSE_SNAPSHOT = true;
INTERPULSE_SNAPSHOT_TIMES = [349e-9, 549e-9, 749e-9];  % Before P2, P3, P4
n_interpulse_snapshots = pulse_config.n_pulses - 1;  % One less than total pulses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    pulse_config.rise_time = 15e-9;    % Shorter rise (was 15ns)
    pulse_config.flat_time = 80e-9;   % Shorter flat (was 80ns)
    pulse_config.fall_time = 25e-9;    % Shorter fall (was 25ns)
    
    % Calculate total simulation window
    last_pulse_end = pulse_config.pulse_starts(end) + ...
                     pulse_config.rise_time + ...
                     pulse_config.flat_time + ...
                     pulse_config.fall_time;
    
    t_start = pulse_config.pulse_starts(1) - 1e-9; % t_start 1ns before first pulse start
    %t_end = last_pulse_end + 35e-9;  % See line 390
    
    %fprintf('\n=== MULTI-PULSE MODE (QUICK TEST) ===\n');
    fprintf('\n=== MULTI-PULSE MODE (PRODUCTION) ===\n');
    % ... rest of output ...
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf('Number of pulses: %d\n', pulse_config.n_pulses);
    fprintf('Pulse spacing: %.1f ns\n', ...
            (pulse_config.pulse_starts(2) - pulse_config.pulse_starts(1))*1e9);
    %fprintf('Total simulation time: %.1f ns\n', (t_end - t_start)*1e9);
    
    % ===== ADD THIS LINE HERE (inside if block) =====
    pulse_shape = @(t_curr) pulse_shape_multipulse(t_curr, pulse_config);
    
%%%%%%%%%%%%%%%%%%%%%%%%  Corrected 01.26.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    % Single pulse mode - CORRECTED to match multi-pulse structure
    pulse_config = struct();
    pulse_config.n_pulses = 1;
    pulse_config.pulse_starts = 150e-9;
    pulse_config.rise_time = 15e-9;   % ← ADD THESE TO STRUCT
    pulse_config.flat_time = 80e-9;   % ← ADD THESE TO STRUCT
    pulse_config.fall_time = 25e-9;   % ← ADD THESE TO STRUCT
    
    %t_start = 149e-9;
    %t_end = 305e-9;   % Takes more time of flight for 8.3m tube
    t_start = pulse_config.pulse_starts(1) - 1e-9;
    
    fprintf('\n=== SINGLE PULSE MODE ===\n');
    fprintf('Pulse duration: %.1f ns\n', ...
            (pulse_config.rise_time + pulse_config.flat_time + pulse_config.fall_time)*1e9);
    %fprintf('Simulation time: %.1f-%.1f ns\n', t_start*1e9, t_end*1e9);
    
    pulse_shape = @(t_curr) pulse_shape_func(t_curr, pulse_config.pulse_starts, ...
                    pulse_config.rise_time, pulse_config.flat_time, pulse_config.fall_time);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== SIMULATION TIME WINDOW (PHYSICS-BASED) ====================
% Calculate proper simulation end time based on beam time-of-flight

% Beam parameters at full energy
E_beam = 1.70e6;  % eV (from 1.7 MV gap voltage)
gamma_beam = 1 + E_beam / (m_e * c^2 / e_charge);  % γ ≈ 4.33
beta_beam = sqrt(1 - 1/gamma_beam^2);  % β ≈ 0.974
v_beam = beta_beam * c;  % m/s

% Time of flight from cathode to final exit
beamline_length = 8.305;  % meters
t_flight = beamline_length / v_beam;  % seconds

fprintf('\n=== Beam Time-of-Flight Calculation ===\n');
fprintf('  Beam energy: %.2f MeV\n', E_beam/1e6);
fprintf('  Lorentz factor: γ = %.3f\n', gamma_beam);
fprintf('  Velocity: β = %.4f (v = %.3e m/s)\n', beta_beam, v_beam);
fprintf('  Flight time to z=%.2fm: %.1f ns\n', beamline_length, t_flight*1e9);

if ENABLE_MULTIPULSE == true
    % Multi-pulse mode
    last_pulse_end = pulse_config.pulse_starts(end) + ...
                     pulse_config.rise_time + ...
                     pulse_config.flat_time + ...
                     pulse_config.fall_time;
    
    % Add flight time PLUS margin for diagnostics
    margin_time = 40e-9;  % 40ns margin for clear tail observation
    t_end = last_pulse_end + t_flight + margin_time;
    
    fprintf('\n=== Multi-Pulse Timing (n=%d) ===\n', pulse_config.n_pulses);
    fprintf('  Last pulse ends: %.1f ns\n', last_pulse_end*1e9);
    fprintf('  Latest exit arrival: %.1f ns\n', (last_pulse_end + t_flight)*1e9);
    fprintf('  Simulation end: %.1f ns (includes %.0f ns margin)\n', ...
            t_end*1e9, margin_time*1e9);
    
    total_sim_time = t_end - t_start;
    fprintf('  Total simulation window: %.1f ns\n', total_sim_time*1e9);
    
else
    % Single pulse mode  
    pulse_end = pulse_config.pulse_starts + pulse_config.rise_time + ...
                pulse_config.flat_time + pulse_config.fall_time;
    
    margin_time = 40e-9;  % 40ns margin
    t_end = pulse_end + t_flight + margin_time;
    
    fprintf('\n=== Single Pulse Timing ===\n');
    fprintf('  Pulse ends: %.1f ns\n', pulse_end*1e9);
    fprintf('  Latest exit arrival: %.1f ns\n', (pulse_end + t_flight)*1e9);
    fprintf('  Simulation end: %.1f ns\n', t_end*1e9);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== PLOTTING HELPER FUNCTIONS ====================
% Calculate appropriate time axis limits based on simulation mode
if ENABLE_MULTIPULSE == true
    t_plot_min = 145;  % ns - just before first pulse
    t_plot_max = t_end * 1e9;  % ns - full simulation window
else
    t_plot_min = 149;
    t_plot_max = t_end * 1e9;  % Typically (295+28+40)ns for single pulse
end

fprintf('\n=== Plot Time Axis Configuration ===\n');
fprintf('  Time range for plots: %.0f to %.0f ns\n', t_plot_min, t_plot_max);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Time array (common to both single and mulxtipulse modes)
t = t_start:dt:t_end;
nt = length(t);
fprintf('Time steps: %d (dt=%.2f ps)\n', nt, dt*1e12);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% Updated Space Charge Domain 02.12.2026 %%%%%%%%%%%%%%%%%%%%%
%% ==================== SPACE CHARGE SETUP (EXTENDED DOMAIN) ====================
if ENABLE_SPACE_CHARGE == true
    fprintf('\nSpace charge configuration:\n');
    
    % Fine mesh for accuracy
    sc_nz = 500;  % Axial cells (maintained for performance)
    sc_nr = 100;  % Radial cells (unchanged)
    sc_z_min = -0.05;
    sc_z_max = 8.31;  % ← CHANGED from 8.31 to 8.31 for extended domain
    sc_r_max = 0.15;
    
    sc_z = linspace(sc_z_min, sc_z_max, sc_nz);
    sc_r = linspace(0, sc_r_max, sc_nr);
    sc_dz = sc_z(2) - sc_z(1);  % Now ≈ 16.7mm (was 5.6mm)
    sc_dr = sc_r(2) - sc_r(1);  % Unchanged ≈ 1.5mm
    
    % Pre-allocate arrays
    rho_grid = zeros(sc_nr, sc_nz);
    phi_grid = zeros(sc_nr, sc_nz);
    Ez_sc = zeros(sc_nr, sc_nz);
    Er_sc = zeros(sc_nr, sc_nz);
    
    % Solver parameters (unchanged)
    sc_omega = 1.4;
    sc_iterations = 100;
    
    fprintf('  Grid: %dx%d (dz=%.1fmm, dr=%.2fmm)\n', ...
            sc_nz, sc_nr, sc_dz*1000, sc_dr*1000);
    fprintf('  Solver: %d iterations, ω=%.2f\n', sc_iterations, sc_omega);
    fprintf('  Domain extended: -50mm to +8310mm\n');
else
    fprintf('\n  Space charge DISABLED\n');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== GAS SCATTERING MODULE INITIALIZATION ====================
ENABLE_GAS_SCATTERING = true;   % Master toggle
SCATTERING_METHOD = 'HYBRID';    % Options: 'MONTE_CARLO', 'CONTINUOUS', 'HYBRID'

if ENABLE_GAS_SCATTERING == true
    fprintf('\n=== GAS SCATTERING MODULE ===\n');
    fprintf('Method: %s\n', SCATTERING_METHOD);
    
    % Gas properties (air at room temperature)
    gas_params = struct();
    gas_params.P = 1e-7 * 133.322;      % 1e-9 mbar → Pa increased to 1e-8, 1e-7 mbar
    gas_params.T = 300;                  % Temperature in K 
    gas_params.composition = struct('N2', 0.78, 'O2', 0.21, 'Ar', 0.01);
    
    % Calculate gas density (ideal gas law)
    gas_params.n_gas = gas_params.P / (k_B * gas_params.T);
    
    % Scattering cross-sections (literature values for 1.7 MeV e⁻)
    sigma_N2 = 2.0e-20;  % m² (total elastic)
    sigma_O2 = 2.2e-20;  % m²
    gas_params.sigma_elastic = gas_params.composition.N2 * sigma_N2 + ...
                               gas_params.composition.O2 * sigma_O2;
    
    % Mean free path
    gas_params.lambda_mfp = 1 / (gas_params.n_gas * gas_params.sigma_elastic);
    
    % Radiation length for multiple scattering (at STP)
    X0_air_STP = 300;  % m (standard tables)
    gas_params.X0_effective = X0_air_STP / (gas_params.P / 1.013e5);
    
    % Calibration parameters (tune these to match experiment)
    scatter_cal = struct();
    scatter_cal.strength_factor = 1.0;      % Multiply cross-section
    scatter_cal.rare_fraction = 0.01;       % For hybrid mode: fraction of large-angle events
    scatter_cal.theta_rare_max = 10e-3;     % Maximum rare scatter angle (rad)
    scatter_cal.check_interval = 10;        % Check every N timesteps
    
    % Diagnostics
    scatter_diag = struct();
    scatter_diag.event_count = 0;
    scatter_diag.rare_count = 0;
    scatter_diag.theta_history = [];
    scatter_diag.z_scatter_positions = [];
    
    % Print configuration
    fprintf('  Pressure: %.2e mbar\n', gas_params.P/133.322);
    fprintf('  Gas density: %.2e molecules/m³\n', gas_params.n_gas);
    fprintf('  Elastic σ: %.2e m²\n', gas_params.sigma_elastic);
    fprintf('  Mean free path: %.1f km\n', gas_params.lambda_mfp/1000);
    fprintf('  Effective X₀: %.2e m\n', gas_params.X0_effective);
    fprintf('  Check interval: %d timesteps (%.1f ps)\n', ...
            scatter_cal.check_interval, scatter_cal.check_interval*dt*1e12);
    fprintf('  Method: %s\n', SCATTERING_METHOD);
    
else
    fprintf('\n  Gas scattering DISABLED\n');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== ION ACCUMULATION MODULE ====================
ENABLE_ION_ACCUMULATION = true;  % Turn on for testing
%ENABLE_ION_ACCUMULATION = false;  % Turn off for testing

if ENABLE_ION_ACCUMULATION == true
    fprintf('\n=== ION ACCUMULATION MODULE ===\n');
    
    % Use the ion_physics struct from your module
    ion_physics = struct();
    ion_physics.sigma_ionization = 3.5e-21;  % Weighted for air
    ion_physics.mass_ion_avg = 29 * 1.66054e-27;
    ion_physics.charge_ion = e_charge;
    ion_physics.mobility = 2.5e-4;  % m²/(V·s)
    ion_physics.t_recomb_effective = 10e-6;  % 10 µs
 %%%%%%%%%%%%%%%%%%%%%%%%%% added 11.25.2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % ===== ADD THIS NEW PARAMETER =====
    ion_physics.superparticle_weight = 1000;  % Each ion super-particle represents 1000 or set 500 real ions for 1e-9 mbar
    % Typical values: 100-10000 depending on performance needs
    % Start with 1000, increase if still too slow
    
    fprintf('  Ion super-particle weight: %.0f ions/super-particle\n', ...
            ion_physics.superparticle_weight);
 %%%%%%%%%%%%%%%%%%%%%%%%%% added 11.25.2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if ENABLE_SPACE_CHARGE == true 
    % Ion grids (same as SC)
    ion_density_grid = zeros(sc_nr, sc_nz);
    ion_density_by_pulse = zeros(sc_nr, sc_nz, pulse_config.n_pulses);
    ion_vz_grid = zeros(sc_nr, sc_nz);
    
    % Diagnostics
    ion_diag = struct();
    ion_diag.creation_history = zeros(nt, 1);
    ion_diag.total_ions_vs_time = zeros(nt, 1);
    ion_diag.peak_density_vs_time = zeros(nt, 1);
    ion_diag.ions_per_pulse = zeros(pulse_config.n_pulses, 1);
    
    fprintf('  Ionization σ: %.2e m²\n', ion_physics.sigma_ionization);
    fprintf('  Recombination time: %.1f µs\n', ion_physics.t_recomb_effective*1e6);
   end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== PARTICLE POOL INITIALIZATION ====================
%%%%%%%%%%%%%% Updated Particle Pool Initialization 02.13.2026 %%%%%%%%%%%%%%%%%%%
%% ==================== PARTICLE POOL INITIALIZATION (ADAPTIVE) ====================
% Adaptive sizing based on beamline length and pulse count
% Empirical scaling: 1.002M particles for 2.76m single pulse

% Base scaling for length (linear with beamline)
length_factor = 8.305 / 2.760;  % 3.01× scaling

% Calculate expected particles in flight
if strcmp(simulation_mode, 'PRODUCTION')
    base_single_pulse = 1.05e6;  % Slightly above your observed 1.002M
    
    if ENABLE_MULTIPULSE == true
        % Multi-pulse: particles from all pulses can overlap in beamline
        expected_particles = base_single_pulse * length_factor * pulse_config.n_pulses;
        safety_factor = 1.25;  % 25% margin for pulse overlap
        max_particles = ceil(expected_particles * safety_factor);
    else
        % Single pulse
        expected_particles = base_single_pulse * length_factor;
        safety_factor = 1.15;  % 15% margin
        max_particles = ceil(expected_particles * safety_factor);
    end
    
    %max_particles = ceil(expected_particles * safety_factor);
    
    %else  % QUICK_TEST mode
    %   max_particles = 3.1e6;  % Fixed for testing
end

fprintf('\nInitializing particle pool...\n');
fprintf('  Beamline length: %.2f m (%.2fx scaling)\n', 8.305, length_factor);
fprintf('  Number of pulses: %d\n', pulse_config.n_pulses);
fprintf('  Expected particles: %.2e\n', expected_particles);
fprintf('  Max particles allocated: %.2e (safety factor: %.2f)\n', ...
        max_particles, safety_factor);
fprintf('  Memory allocated: %.1f MB\n', max_particles*8*10/1024^2);

% Verify memory is reasonable (<2 GB)
if max_particles > 20e6
    fprintf('  WARNING: Very large particle pool! Consider reducing base_particles\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%% Added 02.06.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize storage (around line 220):
interpulse_clouds = cell(n_interpulse_snapshots, 1);  % Array of structures
interpulse_capture_count = 0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Pre-allocate arrays
z_particles = ones(max_particles, 1) * NaN;
r_particles = ones(max_particles, 1) * NaN;
pz_particles = zeros(max_particles, 1);
pr_particles = zeros(max_particles, 1);
ptheta_particles = zeros(max_particles, 1);
weight_particles = zeros(max_particles, 1);
gamma_particles = ones(max_particles, 1);
active_particles = false(max_particles, 1);

% Counters
n_active = 0;
n_created = 0;
particles_at_anode = 0;
particles_transmitted = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%  SNAPSHOT STORAGE INITIATION %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 01.26.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== SNAPSHOT STORAGE INITIALIZATION ====================
if ENABLE_MULTIPULSE == true
    % Multi-pulse: P1 and P2 snapshots
    snapshot_p1 = cell(N_SNAPSHOTS, 1);
    snapshot_p2 = cell(N_SNAPSHOTS, 1);
    % Pulse 3 diagnostics (NEW - add after P2)
    snapshot_p3 = cell(N_SNAPSHOTS, 1);
    %ADD THESE LINES after snapshot_p3 initialization:
    snapshot_p4 = cell(N_SNAPSHOTS, 1);
    snapshot_p1_count = 0;
    snapshot_p2_count = 0;
    snapshot_p3_count = 0;
    snapshot_p4_count = 0;
    fprintf('Snapshot storage initialized: %d per pulse\n', N_SNAPSHOTS);
else
    % Single-pulse: early vs late
    snapshot_early = cell(N_SNAPSHOTS_EARLY, 1);
    snapshot_late = cell(N_SNAPSHOTS_LATE, 1);
    snapshot_p1 = cell(N_SNAPSHOTS, 1);

    snapshot_early_count = 0;
    snapshot_late_count = 0;
    snapshot_p1_count = 0;
    fprintf('Snapshot storage initialized: %d early, %d late, %d per pulse\n', ...
            N_SNAPSHOTS_EARLY, N_SNAPSHOTS_LATE, N_SNAPSHOTS);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% added 11.11.2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% ==================== MULTI-PULSE DIAGNOSTICS INITIALIZATION ====================
if ENABLE_MULTIPULSE == true
    % Track which pulse created each particle
    particle_source_pulse = zeros(max_particles, 1);
    
    % Per-pulse statistics
    pulse_diagnostics = struct();
    for ip = 1:pulse_config.n_pulses
        pulse_diagnostics(ip).particles_emitted = 0;
        pulse_diagnostics(ip).particles_at_anode = 0;
        pulse_diagnostics(ip).particles_transmitted = 0;
        pulse_diagnostics(ip).charge_emitted = 0;
        pulse_diagnostics(ip).charge_transmitted = 0;
        pulse_diagnostics(ip).I_peak = 0;
    end
    
    fprintf('Multi-pulse diagnostics initialized\n');
end
% ===== END OF ADDITION =====
%%%%%%%%%%%%%%%%%%%%%%%%%%%% added 10.08.2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Add tracking arrays that are missing
%particle_crossed_anode = false(max_particles, 1); % Exist at 379
particle_r_at_anode = ones(max_particles, 1) * NaN;
particle_E_at_anode = zeros(max_particles, 1);
%particle_t_at_anode = ones(max_particles, 1) * NaN;% Exist at 376
% Tracking flags to prevent double-counting
particle_counted_as_return = false(max_particles, 1);
particle_counted_as_violation = false(max_particles, 1);

%%%%%%%%%%%%%%%%%%%%%% Monitors Positions Updated 02.12.2026 %%%%%%%%%%%%%%%%%%%
%% ==================== MONITOR POSITIONS (WITH EXPERIMENTAL BPMs) ====================
% Includes all legacy diagnostics PLUS 5 real BPM locations
monitor_positions = [0.001;    % Cathode (legacy diagnostic)
                     0.254;    % Anode entrance
                     0.600;    % Transition 1 (legacy)
                     1.000;    % Transition 2 (legacy)
                     1.700;    % Transition 3 (legacy)
                     2.760;    % BPM1 (first experimental monitor) ← FIXED from 8.310
                     3.964;    % BPM2 (experimental)
                     6.4018;   % BPM3 (experimental)
                     6.8276;   % BPM4 (experimental)
                     8.305];   % BPM5 (final exit, experimental)

monitor_names = ["Cathode", "Anode", "Trans1", "Trans2", "Trans3", ...
                 "BPM1", "BPM2", "BPM3", "BPM4", "BPM5"];

n_monitors = length(monitor_positions);
I_monitor = zeros(nt, n_monitors);
particles_through = zeros(n_monitors, 1);
%particle_counted_at_monitor = false(max_particles, n_monitors); See line 693

fprintf('\n=== Monitor Configuration (Extended) ===\n');
fprintf('Total monitors: %d\n', n_monitors);
fprintf('  Legacy diagnostics: 5 (0-1700mm)\n');
fprintf('  Experimental BPMs: 5 (2760-8305mm)\n');
for i = 1:n_monitors
    fprintf('  %s at z=%.1f mm\n', monitor_names(i), monitor_positions(i)*1000);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%% added 02.25.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================================================================================
%% FIX 1: UNIFIED 15-PLANE ANALYSIS LOCATIONS (SINGLE SOURCE OF TRUTH)
%% ==================================================================================
%% Place this ONCE before any analysis sections (after main loop, before post-processing)
%% Remove all duplicate definitions of twiss_locations/analysis_locations elsewhere
%% ==================================================================================

%% ==================== STANDARD ANALYSIS LOCATIONS (15 PLANES) ====================
% This is the SINGLE definition used by ALL analysis modules
% Do NOT redefine these variables elsewhere in the code

ANALYSIS_LOCATIONS = [254;    % Anode (after gap acceleration)
                      600;    % Early drift (near Sol 3-4)
                      1000;   % Mid drift region 1 (near Sol 7-8)
                      1500;   % Between Sol 9-10
                      1700;   % Legacy diagnostic
                      2200;   % Near Sol 14-15
                      2700;   % BPM1 region (near Sol 19-20)
                      3400;   % Mid-extension (near Sol 25)
                      3964;   % BPM2 (experimental)
                      4600;   % Mid-extension 2 (near Sol 35)
                      5400;   % Near Sol 45
                      6402;   % BPM3 (experimental)
                      6828;   % BPM4 (experimental)
                      7450;   % Near final solenoid (Sol 49)
                      8305];  % BPM5 / Final exit

ANALYSIS_LOCATION_NAMES = {'Anode', 'Early_Drift', 'Mid_Drift1', 'Trans1', 'Trans2', ...
                           'Mid_Drift2', 'BPM1', 'Extension1', 'BPM2', 'Extension2', ...
                           'Late_Drift', 'BPM3', 'BPM4', 'Sol49', 'Exit'};

N_ANALYSIS_PLANES = length(ANALYSIS_LOCATIONS);

% Backward compatibility aliases (used by betatron averaging, Twiss modules, etc.)
twiss_locations = ANALYSIS_LOCATIONS;
analysis_locations = ANALYSIS_LOCATIONS;
location_names = ANALYSIS_LOCATION_NAMES;
n_locations = N_ANALYSIS_PLANES;
n_twiss_planes = N_ANALYSIS_PLANES;

fprintf('\n=== Standard Analysis Configuration ===\n');
fprintf('  Analysis planes: %d (full 8.3m beamline)\n', N_ANALYSIS_PLANES);
fprintf('  Coverage: %d mm to %d mm\n', ANALYSIS_LOCATIONS(1), ANALYSIS_LOCATIONS(end));
fprintf('  BPM locations included: BPM1(2700), BPM2(3964), BPM3(6402), BPM4(6828), BPM5(8305)\n');
%%%%%%%%%%%%%%%%%%%%%%%%%%%% added 10.07.2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add with other counter initializations
particles_lost_to_cathode = 0;
particles_lost_to_walls = 0; 
particles_out_of_bounds = 0;
max_sc_field_recorded = 0;  % Track peak space charge field
%%%%%%%%%%%%%%%%%%%%%%% added 10.08.2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add to initialization (around line 150):
particle_counted_at_monitor = false(max_particles, n_monitors);
%%%%%%%%%%%%%%%%%%%%%%% added 10.15.2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== PARTICLE TRACKING ARRAYS ====================
% Add these right after your existing initialization
particle_crossed_anode = false(max_particles, 1);
particle_crossed_exit = false(max_particles, 1);
particle_t_at_anode = ones(max_particles, 1) * NaN;
particle_t_at_exit = ones(max_particles, 1) * NaN;

% Current accumulator arrays
I_anode_accumulator = 0;
I_exit_accumulator = 0;
% Add a counter for actual contributions
I_anode_count = 0;  % Add with other initializations
I_exit_count = 0;

%% ==================== EMISSION DIAGNOSTICS INITIALIZATION ====================
% Time-resolved current diagnostics
I_cathode = zeros(nt, 1);  % Emission current at cathode
I_drift_exit = zeros(nt, 1);  % Current at drift exit (1700mm)
collection_efficiency = zeros(nt, 1);  % I_anode/I_cathode ratio

% Current density components for emission
J_thermionic = zeros(nt, 1);  % Pure Richardson-Dushman current
J_space_charge = zeros(nt, 1);  % Space-charge limited current  
J_actual = zeros(nt, 1);  % Actual emission (minimum of above)

% Space charge field diagnostics
sc_field_cathode = zeros(nt, 1);  % SC field at cathode surface
sc_field_max = zeros(nt, 1);  % Maximum SC field in domain
sc_field_distribution = zeros(nt, 1);  % RMS of SC field

% Particle weight tracking
particle_weight_history = zeros(nt, 1);  % Track adaptive weighting

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% Magnetic Fields Setup  02.12.2026 %%%%%%%%%%%%%%%%%%%%%%%
% ==================== EXTENDED SOLENOID STRUCTURES 1-19_20-49 ====================
%% ==================== MAGNETIC FIELD SETUP ====================
fprintf('\nMagnetic field configuration:\n');
%NOTE Solenoids #6 and #13 are steering dipole magnets, not used currently
solenoid1 = struct('B', solenoid1_field, 'z_c', -0.279, 'L', 0.106, 'R', 0.451);
solenoid2 = struct('B', solenoid2_field, 'z_c', 0.372, 'L', 0.195, 'R', 0.245);
solenoid3 = struct('B', solenoid3_field, 'z_c', 1.14461, 'L', 0.120, 'R', 0.245);
solenoid4 = struct('B', solenoid4_field, 'z_c', 1.26757, 'L', 0.120, 'R', 0.245);
solenoid5 = struct('B', solenoid5_field, 'z_c', 1.36927, 'L', 0.120, 'R', 0.245);
solenoid7 = struct('B', solenoid7_field, 'z_c', 1.49223, 'L', 0.100, 'R', 0.245);
solenoid8 = struct('B', solenoid8_field, 'z_c', 1.59393, 'L', 0.100, 'R', 0.245);
solenoid9 = struct('B', solenoid9_field, 'z_c', 1.71689, 'L', 0.100, 'R', 0.245);
solenoid10 = struct('B', solenoid10_field, 'z_c', 1.81860, 'L', 0.090, 'R', 0.245);
solenoid11 = struct('B', solenoid11_field, 'z_c', 1.94156, 'L', 0.110, 'R', 0.245);
solenoid12 = struct('B', solenoid12_field, 'z_c', 2.04326, 'L', 0.110, 'R', 0.245);
solenoid14 = struct('B', solenoid14_field, 'z_c', 2.16622, 'L', 0.090, 'R', 0.245);
solenoid15 = struct('B', solenoid15_field, 'z_c', 2.26793, 'L', 0.100, 'R', 0.245);
solenoid16 = struct('B', solenoid16_field, 'z_c', 2.39089, 'L', 0.110, 'R', 0.245);
solenoid17 = struct('B', solenoid17_field, 'z_c', 2.49259, 'L', 0.110, 'R', 0.245);
solenoid18 = struct('B', solenoid18_field, 'z_c', 2.61555, 'L', 0.090, 'R', 0.245);
solenoid19 = struct('B', solenoid19_field, 'z_c', 2.71726, 'L', 0.090, 'R', 0.245);
solenoid20 = struct('B', solenoid20_field, 'z_c', 2.84022, 'L', 0.100, 'R', 0.245);
solenoid21 = struct('B', solenoid21_field, 'z_c', 2.94192, 'L', 0.100, 'R', 0.245);
solenoid22 = struct('B', solenoid22_field, 'z_c', 3.06488, 'L', 0.100, 'R', 0.245);
solenoid23 = struct('B', solenoid23_field, 'z_c', 3.16658, 'L', 0.100, 'R', 0.245);
solenoid24 = struct('B', solenoid24_field, 'z_c', 3.28954, 'L', 0.100, 'R', 0.245);
solenoid25 = struct('B', solenoid25_field, 'z_c', 3.39125, 'L', 0.100, 'R', 0.245);
solenoid26 = struct('B', solenoid26_field, 'z_c', 3.51421, 'L', 0.100, 'R', 0.245);
solenoid27 = struct('B', solenoid27_field, 'z_c', 3.61591, 'L', 0.100, 'R', 0.245);
solenoid28 = struct('B', solenoid28_field, 'z_c', 3.73887, 'L', 0.100, 'R', 0.245);
solenoid29 = struct('B', solenoid29_field, 'z_c', 3.84058, 'L', 0.100, 'R', 0.245);
solenoid30 = struct('B', solenoid30_field, 'z_c', 3.96354, 'L', 0.100, 'R', 0.245);
solenoid31 = struct('B', solenoid31_field, 'z_c', 4.06524, 'L', 0.100, 'R', 0.245);
solenoid32 = struct('B', solenoid32_field, 'z_c', 4.18820, 'L', 0.100, 'R', 0.245);
solenoid33 = struct('B', solenoid33_field, 'z_c', 4.28993, 'L', 0.100, 'R', 0.245);
solenoid34 = struct('B', solenoid34_field, 'z_c', 4.41289, 'L', 0.100, 'R', 0.245);
solenoid35 = struct('B', solenoid35_field, 'z_c', 4.51459, 'L', 0.100, 'R', 0.245);
solenoid36 = struct('B', solenoid36_field, 'z_c', 4.63755, 'L', 0.100, 'R', 0.245);
% solenoid37 = Steering magnet 3 (NOT USED)
solenoid38 = struct('B', solenoid38_field, 'z_c', 4.73925, 'L', 0.100, 'R', 0.245);
solenoid39 = struct('B', solenoid39_field, 'z_c', 4.86221, 'L', 0.100, 'R', 0.245);
solenoid40 = struct('B', solenoid40_field, 'z_c', 4.96392, 'L', 0.100, 'R', 0.245);
solenoid41 = struct('B', solenoid41_field, 'z_c', 5.08688, 'L', 0.100, 'R', 0.245);
solenoid42 = struct('B', solenoid42_field, 'z_c', 5.18858, 'L', 0.100, 'R', 0.245);
solenoid43 = struct('B', solenoid43_field, 'z_c', 5.31154, 'L', 0.100, 'R', 0.245);
% solenoid44 = Steering magnet 4 (NOT USED)
solenoid45 = struct('B', solenoid45_field, 'z_c', 5.41324, 'L', 0.100, 'R', 0.245);
solenoid46 = struct('B', solenoid46_field, 'z_c', 5.53620, 'L', 0.100, 'R', 0.245);
solenoid47 = struct('B', solenoid47_field, 'z_c', 5.63791, 'L', 0.100, 'R', 0.245);
solenoid48 = struct('B', solenoid48_field, 'z_c', 5.76087, 'L', 0.100, 'R', 0.245);
solenoid49 = struct('B', solenoid49_field, 'z_c', 7.44800, 'L', 0.100, 'R', 0.245);

% Print extended configuration
fprintf('  Solenoid 1: %.0f G at z=%.0f mm\n', solenoid1.B*1e4, solenoid1.z_c*1000);
fprintf('  Solenoid 2: %.0f G at z=%.0f mm\n', solenoid2.B*1e4, solenoid2.z_c*1000);
fprintf('  Solenoid 3: %.0f G at z=%.0f mm\n', solenoid3.B*1e4, solenoid3.z_c*1000);
fprintf('  Solenoid 4: %.0f G at z=%.0f mm\n', solenoid4.B*1e4, solenoid4.z_c*1000);
fprintf('  Solenoid 5: %.0f G at z=%.0f mm\n', solenoid5.B*1e4, solenoid5.z_c*1000);
fprintf('NOTE:  Solenoid 6 is a steering dipole magnet not in use currently ');
fprintf('  Solenoid 7: %.0f G at z=%.0f mm\n', solenoid7.B*1e4, solenoid7.z_c*1000);
fprintf('  Solenoid 8: %.0f G at z=%.0f mm\n', solenoid8.B*1e4, solenoid8.z_c*1000);
fprintf('  Solenoid 9: %.0f G at z=%.0f mm\n', solenoid9.B*1e4, solenoid9.z_c*1000);
fprintf('  Solenoid 10: %.0f G at z=%.0f mm\n', solenoid10.B*1e4, solenoid10.z_c*1000);
fprintf('  Solenoid 11: %.0f G at z=%.0f mm\n', solenoid11.B*1e4, solenoid11.z_c*1000);
fprintf('  Solenoid 12: %.0f G at z=%.0f mm\n', solenoid12.B*1e4, solenoid12.z_c*1000);
fprintf('NOTE:  Solenoid 13 is a steering dipole magnet not in use currently ');
fprintf('  Solenoid 14: %.0f G at z=%.0f mm\n', solenoid14.B*1e4, solenoid14.z_c*1000);
fprintf('  Solenoid 15: %.0f G at z=%.0f mm\n', solenoid15.B*1e4, solenoid15.z_c*1000);
fprintf('  Solenoid 16: %.0f G at z=%.0f mm\n', solenoid16.B*1e4, solenoid16.z_c*1000);
fprintf('  Solenoid 17: %.0f G at z=%.0f mm\n', solenoid17.B*1e4, solenoid17.z_c*1000);
fprintf('  Solenoid 18: %.0f G at z=%.0f mm\n', solenoid18.B*1e4, solenoid18.z_c*1000);
fprintf('  Solenoid 19: %.0f G at z=%.0f mm\n', solenoid19.B*1e4, solenoid19.z_c*1000);
fprintf('  Solenoid 20: %.0f G at z=%.0f mm\n', solenoid20.B*1e4, solenoid20.z_c*1000);
fprintf('  Solenoid 21: %.0f G at z=%.0f mm\n', solenoid21.B*1e4, solenoid21.z_c*1000);
fprintf('  Solenoid 22: %.0f G at z=%.0f mm\n', solenoid22.B*1e4, solenoid22.z_c*1000);
fprintf('  Solenoid 23: %.0f G at z=%.0f mm\n', solenoid23.B*1e4, solenoid23.z_c*1000);
fprintf('  Solenoid 24: %.0f G at z=%.0f mm\n', solenoid24.B*1e4, solenoid24.z_c*1000);
fprintf('  Solenoid 25: %.0f G at z=%.0f mm\n', solenoid25.B*1e4, solenoid25.z_c*1000);
fprintf('  Solenoid 26: %.0f G at z=%.0f mm\n', solenoid26.B*1e4, solenoid26.z_c*1000);
fprintf('  Solenoid 27: %.0f G at z=%.0f mm\n', solenoid27.B*1e4, solenoid27.z_c*1000);
fprintf('  Solenoid 28: %.0f G at z=%.0f mm\n', solenoid28.B*1e4, solenoid28.z_c*1000);
fprintf('  Solenoid 29: %.0f G at z=%.0f mm\n', solenoid29.B*1e4, solenoid29.z_c*1000);
fprintf('  Solenoid 30: %.0f G at z=%.0f mm\n', solenoid30.B*1e4, solenoid30.z_c*1000);
fprintf('  Solenoid 31: %.0f G at z=%.0f mm\n', solenoid31.B*1e4, solenoid31.z_c*1000);
fprintf('  Solenoid 32: %.0f G at z=%.0f mm\n', solenoid32.B*1e4, solenoid32.z_c*1000);
fprintf('  Solenoid 33: %.0f G at z=%.0f mm\n', solenoid33.B*1e4, solenoid33.z_c*1000);
fprintf('  Solenoid 34: %.0f G at z=%.0f mm\n', solenoid34.B*1e4, solenoid34.z_c*1000);
fprintf('  Solenoid 35: %.0f G at z=%.0f mm\n', solenoid35.B*1e4, solenoid35.z_c*1000);
fprintf('  Solenoid 36: %.0f G at z=%.0f mm\n', solenoid36.B*1e4, solenoid36.z_c*1000);
fprintf('NOTE:  Solenoid 37 is a steering dipole magnet not in use currently ');
fprintf('  Solenoid 38: %.0f G at z=%.0f mm\n', solenoid38.B*1e4, solenoid38.z_c*1000);
fprintf('  Solenoid 39: %.0f G at z=%.0f mm\n', solenoid39.B*1e4, solenoid39.z_c*1000);
fprintf('  Solenoid 40: %.0f G at z=%.0f mm\n', solenoid40.B*1e4, solenoid40.z_c*1000);
fprintf('  Solenoid 41: %.0f G at z=%.0f mm\n', solenoid41.B*1e4, solenoid41.z_c*1000);
fprintf('  Solenoid 42: %.0f G at z=%.0f mm\n', solenoid42.B*1e4, solenoid42.z_c*1000);
fprintf('  Solenoid 43: %.0f G at z=%.0f mm\n', solenoid43.B*1e4, solenoid43.z_c*1000);
fprintf('NOTE:  Solenoid 44 is a steering dipole magnet not in use currently ');
fprintf('  Solenoid 45: %.0f G at z=%.0f mm\n', solenoid45.B*1e4, solenoid45.z_c*1000);
fprintf('  Solenoid 46: %.0f G at z=%.0f mm\n', solenoid46.B*1e4, solenoid46.z_c*1000);
fprintf('  Solenoid 47: %.0f G at z=%.0f mm\n', solenoid47.B*1e4, solenoid47.z_c*1000);
fprintf('  Solenoid 48: %.0f G at z=%.0f mm\n', solenoid48.B*1e4, solenoid48.z_c*1000);
fprintf('  Solenoid 49: %.0f G at z=%.0f mm\n', solenoid49.B*1e4, solenoid49.z_c*1000);

%%%%%%%%%%%%%%%%%%%%%%% Extended Bz_func, Br_func 02.12.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== MAGNETIC FIELD FUNCTIONS (EXTENDED TO 49 SOLENOIDS) ====================
Bz_func = @(z_pos, r_pos, t_curr) calculate_Bz(z_pos, r_pos, t_curr, ...
    solenoid1, solenoid2, solenoid3, solenoid4, solenoid5, ...
    solenoid7, solenoid8, solenoid9, solenoid10, solenoid11, solenoid12, ...
    solenoid14, solenoid15, solenoid16, solenoid17, solenoid18, solenoid19, ...
    solenoid20, solenoid21, solenoid22, solenoid23, solenoid24, solenoid25, ...
    solenoid26, solenoid27, solenoid28, solenoid29, solenoid30, solenoid31, ...
    solenoid32, solenoid33, solenoid34, solenoid35, solenoid36, ...
    solenoid38, solenoid39, solenoid40, solenoid41, solenoid42, solenoid43, ...
    solenoid45, solenoid46, solenoid47, solenoid48, solenoid49, ...
    pulse_shape);

Br_func = @(z_pos, r_pos, t_curr) calculate_Br(z_pos, r_pos, t_curr, ...
    solenoid1, solenoid2, solenoid3, solenoid4, solenoid5, ...
    solenoid7, solenoid8, solenoid9, solenoid10, solenoid11, solenoid12, ...
    solenoid14, solenoid15, solenoid16, solenoid17, solenoid18, solenoid19, ...
    solenoid20, solenoid21, solenoid22, solenoid23, solenoid24, solenoid25, ...
    solenoid26, solenoid27, solenoid28, solenoid29, solenoid30, solenoid31, ...
    solenoid32, solenoid33, solenoid34, solenoid35, solenoid36, ...
    solenoid38, solenoid39, solenoid40, solenoid41, solenoid42, solenoid43, ...
    solenoid45, solenoid46, solenoid47, solenoid48, solenoid49, ...
    pulse_shape);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% ==================== DIAGNOSTIC ARRAYS ====================
I_emit = zeros(nt, 1);
I_anode = zeros(nt, 1);
n_active_history = zeros(nt, 1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%% added 10.08.2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ADD THESE LINES:
% Monitor positions - track through entire beamline
%monitor_positions = [0.001, 0.254, 0.350, 0.450, 0.500, 0.600];
%monitor_names = ["Cathode", "Anode entrance", "Mid-drift", "Pre-exit", "Exit", "Extended"];
%n_monitors = length(monitor_positions);
%I_monitor = zeros(nt, n_monitors);
%particles_through = zeros(n_monitors, 1);
%particle_counted_at_monitor = false(max_particles, n_monitors);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Snapshot configuration
ENABLE_SNAPSHOTS = true;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ENABLE_MULTIPULSE == true
    snapshot_times = [165e-9, TWISS_PULSE1_TIME, 365e-9, TWISS_PULSE2_TIME];  
    % Early P1, mid-P1, early P2, mid-P2
else
    snapshot_times = [165e-9, 185e-9, 205e-9, 225e-9];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
snapshot_data = struct();
snapshot_count = 0;

%%%%%%%%%%%%%%%%%% Updated Diagnostic Arrays 02.12.2026 %%%%%%%%%%%%%%%%%%%%%%%
%% ==================== DIAGNOSTIC ARRAYS (EXTENDED DOMAIN) ====================
% Beam envelope tracking over full 8.3m length
n_z_diagnostic = 480;  % 3× more positions for 3× longer beamline
z_diagnostic = linspace(0, 8.31, n_z_diagnostic);  % Now covers -400 to +8305mm region
r_rms_history = zeros(nt, n_z_diagnostic);  % RMS radius vs z and time
n_particles_vs_z = zeros(nt, n_z_diagnostic);  % Particle count vs z

% Wall radius reference (drift tube)
r_wall = 0.075;  % 75mm drift tube radius (unchanged)

fprintf('Diagnostic grid: %d positions over %.1f m (dz=%.1f mm)\n', ...
        n_z_diagnostic, max(z_diagnostic), ...
        (z_diagnostic(2)-z_diagnostic(1))*1000);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== MAIN TIME LOOP ====================
fprintf('\nStarting simulation...\n');
tic_start = tic;
fprintf('Progress: ');

for it = 1:nt
    current_t = t(it);
%%%%%%%%%%%%%%%%%%%%%% added 10.15.2025  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
    % Reset accumulators if starting fresh (ADD THIS BLOCK)
    if it == 1
        I_anode_accumulator = 0;
        I_exit_accumulator = 0;
        I_anode_count = 0;
        I_exit_count = 0;
    end
    
    % Progress reporting (your existing code continues...)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Progress reporting
    if mod(it, 1000) == 0
        elapsed = toc(tic_start);
        rate = it / elapsed;
        eta = (nt - it) / rate;
        fprintf('\n  Step %d/%d (%.1f%%) | %.1f steps/s | ETA: %.1f min', ...
                it, nt, 100*it/nt, rate, eta/60);
        fprintf('\n  Active: %d | Created: %d | At anode: %d', ...
                n_active, n_created, particles_at_anode);
        fprintf('\n  ');
    elseif mod(it, round(nt/20)) == 0
        fprintf('.');
    end
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% added 10.17.2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SCHOTTKY-ENHANCED THERMIONIC EMISSION MODEL FOR PIC v8
% Replace the existing emission section in your main loop with this enhanced version
% This properly accounts for field-enhanced emission at the cathode surface

%% ==================== ENHANCED EMISSION WITH SCHOTTKY EFFECT ====================
% Place this inside your main time loop where emission occurs
% Around line 430 in your current code, replace:
% pulse_factor = pulse_shape(current_t);
% With:
%if ENABLE_MULTIPULSE == true
%   pulse_factor = pulse_shape_multipulse(current_t, pulse_config);
%%%%%%%%%%%%%%%%%%%%%%%%% corrected section 11.25.2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ENABLE_MULTIPULSE == true
    pulse_factor = pulse_shape_multipulse(current_t, pulse_config);
    
    % Determine which pulse we're currently in
    current_pulse = 0;
    for ip = 1:pulse_config.n_pulses
        t_pulse = current_t - pulse_config.pulse_starts(ip);
        pulse_duration = pulse_config.rise_time + pulse_config.flat_time + pulse_config.fall_time;
        
        if t_pulse >= 0 && t_pulse <= pulse_duration
            current_pulse = ip;
            break;
        end
    end  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else  % NOW the else can follow
    % Single pulse mode
    pulse_starts = 150e-9;
    pulse_rise = 15e-9;
    pulse_flat = 80e-9;
    pulse_fall = 25e-9; % Pulse endded at 270ns 
    
    %t_start = 149e-9;   Both t_start and t_end were defined earlier at line 345 
    %t_end = 305e-9;      % Simulation end 25ns after pulse end

    pulse_factor = pulse_shape_func(current_t, pulse_starts, pulse_rise, pulse_flat, pulse_fall);
    current_pulse = 1;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if pulse_factor > 0.01
    % Physical constants
    J_SPECIFICATION = 11e4;  % 11 A/cm² - operational limit
    A_emit = pi * 0.065^2;   % Cathode area (m²)
    
    % Richardson-Dushman constants
    A_RD = 1.20173e6;  % A/m²/K²
    phi_0 = 1.8;       % Base work function in eV (scandium-doped cathode)
    
    % CRITICAL: Extract local electric field at cathode surface
    % This is the field that causes Schottky barrier reduction
   % if exist('Ez_sc', 'var') && ENABLE_SPACE_CHARGE
        % Total field = applied + space charge
        %E_cathode = abs(Ez_capped(1,1)) * pulse_factor + abs(Ez_sc(1,1));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Better field extraction at z=0, r=0:
%[~, iz_cath] = min(abs(z - 0.001));  % Find z index closest to cathode
%[~, ir_cath] = min(abs(r));          % Find r=0 index
%E_cathode = abs(Ez_capped(ir_cath, iz_cath)) * pulse_factor;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Option 2: Search for the maximum field magnitude near cathode
%field_search_range = 1:20;  % Check first 20 z-indices
%Ez_near_cathode = Ez_capped(1, field_search_range);
%E_cathode = max(abs(Ez_near_cathode)) * pulse_factor;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Option 1: Use the known field value from your geometry
%E_cathode_base = 5.37e6;  % V/m - from your field diagnostic
%E_cathode = E_cathode_base * pulse_factor;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CORRECTED CATHODE FIELD EXTRACTION
% Replace the existing E_cathode calculation in your emission section with:
% Option 1: Use the known field value from your geometry
%E_cathode_base = 5.37e6;  % V/m - from your field diagnostic output
%E_cathode = E_cathode_base * pulse_factor;
%%%%%%%%%%%%%%%%%%%%%%%%%%%% added 02.25.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== DYNAMIC CATHODE FIELD EXTRACTION ====================
% Automatically extracts cathode surface field from loaded field solution
% Adapts to ANY Pierce angle geometry (68°, 80°, 89°, etc.)
% No manual calibration needed when changing cathode geometry

% METHOD: Sample Ez along axis near cathode surface (z = 0 to ~5mm)
% The field peaks just ahead of the cathode and represents the
% accelerating field that drives Schottky-enhanced emission

% Search region: z = 0 to 10mm, r = 0 (on-axis)
z_search_min = 0.000;    % Cathode surface
z_search_max = 0.010;    % 10mm ahead of cathode
iz_search = find(z >= z_search_min & z <= z_search_max);

if ~isempty(iz_search)
    % Sample on-axis field (first few radial indices for robustness)
    Ez_near_cathode = abs(Ez_capped(1:3, iz_search));
    
    % Take the maximum field in this region (peak accelerating field)
    E_cathode_base = max(Ez_near_cathode(:));
    
    % Sanity check: field should be between 3 and 8 MV/m for our geometry
    if E_cathode_base < 3e6 || E_cathode_base > 8e6
        fprintf('  WARNING: Unusual cathode field %.2f MV/m (expected 3-8 MV/m)\n', ...
                E_cathode_base/1e6);
        fprintf('  Check geometry/field solution consistency\n');
    end
else
    % Fallback: use the field at the first vacuum point ahead of cathode
    [~, iz_fallback] = min(abs(z - 0.005));
    E_cathode_base = abs(Ez_capped(1, iz_fallback));
    fprintf('  WARNING: Using fallback cathode field extraction\n');
end

% Apply pulse modulation (existing logic unchanged)
E_cathode = E_cathode_base * pulse_factor;

% Report (first timestep only)
if it == 1 || (exist('cathode_field_reported', 'var') == 0)
    fprintf('\n=== Dynamic Cathode Field Extraction ===\n');
    fprintf('  E_cathode_base = %.2f MV/m (auto-detected from field solution)\n', ...
            E_cathode_base/1e6);
    fprintf('  Search region: z = %.0f to %.0f mm\n', z_search_min*1000, z_search_max*1000);
    
    % Report field profile near cathode for verification
    fprintf('  Field profile near cathode (on-axis):\n');
    z_profile_idx = find(z >= -0.005 & z <= 0.020);
    for k = 1:min(8, length(z_profile_idx))
        jj = z_profile_idx(k);
        fprintf('    z=%6.1f mm: Ez = %.2f MV/m\n', z(jj)*1000, abs(Ez_capped(1,jj))/1e6);
    end
    cathode_field_reported = true;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add space charge contribution if enabled
if ENABLE_SPACE_CHARGE == true && exist('Ez_sc', 'var') && any(Ez_sc(:) ~= 0)
    % Find the closest sc_z index to cathode
    [~, iz_sc] = min(abs(sc_z - 0.001));
    % Average the radial field at cathode position
    sc_contribution = abs(mean(Ez_sc(:, iz_sc)));
    E_cathode = E_cathode + sc_contribution;
end

% Now calculate Schottky reduction with the correct field
schottky_constant = sqrt(e_charge^3 / (4*pi*eps0));
delta_phi = schottky_constant * sqrt(E_cathode)/e_charge; % In units of eV
phi_eff = phi_0 - delta_phi;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add space charge if present
%if ENABLE_SPACE_CHARGE && exist('Ez_sc', 'var')
    % Sample space charge field near cathode
%    [~, iz_sc] = min(abs(sc_z - 0.001));
%    E_cathode = E_cathode + abs(mean(Ez_sc(:, iz_sc)));
%end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
    % Temperature options for exploration
    % Option 1: Fixed temperature (current approach)
    % T_cathode = 1280;  % K - your current setting
    
    % Option 2: Temperature control for current limiting
    % This finds the temperature that gives J_SPECIFICATION
    J_target = J_SPECIFICATION * pulse_factor;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Replace the Newton-Raphson section with this approach:

% Option 1: Fixed temperature exploration
T_cathode = 1200;  % K - Set this to explore different temperatures 1150K for 5A/cm2
% This temperature will naturally limit emission

% Calculate emission at this temperature same as on line 663
%J_thermionic_current = A_RD * T_cathode^2 * exp(-phi_eff * e_charge / (k_B* T_cathode)); 

% The actual emission is the minimum of thermionic and space-charge limits
% Don't include J_SPECIFICATION as a limit when exploring temperature effects
%J_emit = min(J_thermionic_current, J_CL);

% For diagnostic purposes, still track what spec would be
J_SPECIFICATION_display = 11e4;  % 2 A/cm² for comparison

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Calculate thermionic emission with Schottky-reduced barrier
    J_thermionic_current = A_RD * T_cathode^2 * exp(-phi_eff * e_charge / (k_B * T_cathode));
    
    % Calculate space-charge limited emission (Child-Langmuir)
    V_gap = 1.70e6 * pulse_factor;  % Gap voltage 1.7MV
    d_gap = 0.254;  % Gap distance
    
    % Modified Child-Langmuir with relativistic correction
    % For 1.7 MV, particles become relativistic
    gamma_exit = 1 + V_gap * e_charge / (m_e * c^2);
    beta_exit = sqrt(1 - 1/gamma_exit^2);
    relativistic_factor = gamma_exit^(3/2) * (1 + 2*log(gamma_exit));
    
    % Empirical enhancement factor (accounts for geometry, non-uniformity)
    emp_factor = 1.75;
    
    J_CL = emp_factor * (4/9) * eps0 * sqrt(2*e_charge/m_e) * ...
           V_gap^(3/2) / d_gap^2 * sqrt(relativistic_factor);
    
    % THREE-WAY MINIMUM: Take lowest of all three
    J_emit = min([J_SPECIFICATION, J_thermionic_current, J_CL]);
    
    % Calculate currents
    I_emit_current = J_emit * A_emit;
    I_emit(it) = I_emit_current;
    I_cathode(it) = I_emit_current;
    
    % Store enhanced diagnostics
    J_thermionic(it) = J_thermionic_current;
    J_space_charge(it) = J_CL;
    J_actual(it) = J_emit;
    
    % NEW: Store Schottky diagnostics
    if ~exist('schottky_diagnostics', 'var')
        schottky_diagnostics = struct();
        schottky_diagnostics.E_cathode = zeros(nt, 1);
        schottky_diagnostics.delta_phi = zeros(nt, 1);
        schottky_diagnostics.phi_eff = zeros(nt, 1);
        schottky_diagnostics.T_cathode = zeros(nt, 1);
        schottky_diagnostics.T_required = zeros(nt, 1);
    end
    
    schottky_diagnostics.E_cathode(it) = E_cathode;
    schottky_diagnostics.delta_phi(it) = delta_phi;
    schottky_diagnostics.phi_eff(it) = phi_eff;
    schottky_diagnostics.T_cathode(it) = T_cathode;
    
    % Calculate what temperature would be needed WITHOUT Schottky effect
    T_no_schottky = T_cathode * phi_0 / phi_eff;  % Approximate
    schottky_diagnostics.T_required(it) = T_no_schottky;
    
    % Adaptive particle count (your existing code)
    if pulse_factor < 0.95
        n_emit = ceil(base_particles * pulse_factor);
    else
        n_emit = base_particles;
    end
    
    % Calculate particle weight
    charge_to_emit = I_emit_current * dt;
    particle_weight = charge_to_emit / (n_emit * e_charge);
    
    % Track weight for diagnostics
    if n_emit > 0
        particle_weight_history(it) = particle_weight;
    end
    
    % Emit particles (your existing particle creation code)
    for ip = 1:n_emit
        if n_created < max_particles
            n_created = n_created + 1;
            idx = n_created;
            
            % Random cathode position
            r_emit = sqrt(rand()) * 0.065;
            
            % Initialize particle
            z_particles(idx) = 0.001;
            r_particles(idx) = r_emit;
            weight_particles(idx) = particle_weight;
            active_particles(idx) = true;
            
            % Thermal velocity based on actual cathode temperature
            v_thermal = sqrt(2 * k_B * T_cathode / m_e);
            pz_particles(idx) = m_e * abs(randn()) * v_thermal * 0.1;
            pr_particles(idx) = m_e * randn() * v_thermal * 0.01;
            ptheta_particles(idx) = m_e * randn() * v_thermal * 0.01;
            
            n_active = n_active + 1;
        % ===== ADD THIS LINE HERE =====
        if ENABLE_MULTIPULSE == true
            particle_source_pulse(idx) = current_pulse;
        end
        % ===== END OF ADDITION =====
        end
    end
    
    % Enhanced emission verification
    if mod(it, 100) == 0
        fprintf('\n  [SCHOTTKY EMISSION] t=%.1fns:', current_t*1e9);
        fprintf('\n    E_cathode=%.2f MV/m, Δφ=%.3f eV', E_cathode/1e6, delta_phi);
        fprintf('\n    φ_eff=%.3f eV (%.1f%% reduction)', phi_eff, 100*delta_phi/phi_0);
        fprintf('\n    T_cathode=%.0f K (saves %.0f K vs no Schottky)', ...
                T_cathode, T_no_schottky - T_cathode);
        fprintf('\n    J=%.1f A/cm² @ I=%.1f A', J_emit/1e4, I_emit_current);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Monitor cathode field if space charge is enabled
if ENABLE_SPACE_CHARGE == true && mod(it, sc_interval) == 0 && exist('Ez_sc', 'var')
    % Sample SC field near cathode (z ≈ 0)
    [~, iz_cath] = min(abs(sc_z - 0.001));
    sc_field_cathode(it) = mean(abs(Ez_sc(:, iz_cath)));
    
    % Maximum field in domain
    sc_field_max(it) = max(abs(Ez_sc(:)));
    
    % RMS field distribution
    sc_field_distribution(it) = sqrt(mean(Ez_sc(:).^2));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  Update 01.23.2026  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% ==================== ION DRIFT AND RECOMBINATION ====================
%% ==================== ION DIAGNOSTICS UPDATE (EVERY TIMESTEP) ====================
% Update ion diagnostics EVERY timestep for smooth plotting (moved to 1935)
%if ENABLE_ION_ACCUMULATION
 %   total_ions_on_grid = sum(ion_density_grid(:));
%   ion_diag.total_ions_vs_time(it) = total_ions_on_grid * ion_physics.superparticle_weight;
%    ion_diag.peak_density_vs_time(it) = max(ion_density_grid(:)) * ion_physics.superparticle_weight;
%end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ion drift and recombination still only every sc_interval
if ENABLE_ION_ACCUMULATION == true && mod(it, sc_interval) == 0
    % ===== ONLY DO DRIFT/RECOMBINATION IF IONS EXIST =====
    if total_ions_on_grid > 0.1
        % Ion drift in electric fields
        for i = 2:sc_nr-1
            for j = 2:sc_nz-1
                if ion_density_grid(i,j) > 0.01
                    E_z_local = interp2(z, r, Ez_capped, sc_z(j), sc_r(i), 'linear', 0);
                    E_r_local = interp2(z, r, Er_capped, sc_z(j), sc_r(i), 'linear', 0);
                    
                    if exist('Ez_sc', 'var')
                        E_z_local = E_z_local + Ez_sc(i,j);
                        E_r_local = E_r_local + Er_sc(i,j);
                    end
                    
                    ion_vz_grid(i,j) = ion_physics.mobility * E_z_local;
                end
            end
        end
        
        % Recombination every 1ns (every 100 timesteps at dt=10ps)
        if mod(it, 100) == 0
            decay_factor = exp(-dt * 100 / ion_physics.t_recomb_effective);
            ion_density_grid = ion_density_grid * decay_factor;
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%% TEMPORARY DIAGNOSTIC REMOVED FROM HERE %%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 01.26.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% ---------------------- SPACE CHARGE CALCULATION -----------------------_-------%%
    if ENABLE_SPACE_CHARGE && mod(it, sc_interval) == 0 && n_active > 100
        active_idx = find(active_particles);
        z_active = z_particles(active_idx);
        r_active = r_particles(active_idx);
        
        % Reset charge density
        rho_grid(:) = 0;

%% PERFORMANCE NOTE: This particle-by-particle charge deposition loop
%% is the main bottleneck. Consider vectorizing with:
%%   iz_all = interp1(sc_z, 1:sc_nz, z_active, 'nearest');
%%   ir_all = interp1(sc_r, 1:sc_nr, r_active, 'nearest');
%% and accumulating with accumarray() instead of the inner for loop.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In space charge calculation section, replace current logic with:
% Accumulate charge
for i = 1:length(active_idx)
    [~, iz] = min(abs(sc_z - z_active(i)));
    [~, ir] = min(abs(sc_r - r_active(i)));
    
    if iz >= 1 && iz <= sc_nz && ir >= 1 && ir <= sc_nr
        % Cylindrical cell volume
        if ir == 1
            cell_volume = pi * (sc_dr/2)^2 * sc_dz;
        else
            r_inner = sc_r(ir) - sc_dr/2;
            r_outer = sc_r(ir) + sc_dr/2;
            cell_volume = pi * (r_outer^2 - r_inner^2) * sc_dz;
        end
        
        % Apply region-dependent enhancement
        if z_active(i) < 0.254  % Gap region
            enhancement = 1.050*0.25;  % Full enhancement 1.0 or less
            enhancement1 = enhancement;
        else  % Drift region
            enhancement = 0.950*0.25;  % Half of 1.010
            enhancement2 = enhancement;
        end
        
        rho_grid(ir, iz) = rho_grid(ir, iz) - ...
            enhancement * e_charge * weight_particles(active_idx(i)) / cell_volume;
    end
end
% Don't apply enhancement again after this

%%%%%%%%%%%%%%%%%%%%%%%%%%%% 11.25.2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ION CONTRIBUTION TO SPACE CHARGE (positive charge)
if ENABLE_ION_ACCUMULATION == true && sum(ion_density_grid(:)) > 0
    for i = 1:sc_nr
        for j = 1:sc_nz
            if ion_density_grid(i,j) > 0.01  % At least 0.01 super-ions
                if i == 1
                    cell_volume = pi * (sc_dr/2)^2 * sc_dz;
                else
                    r_inner = sc_r(i) - sc_dr/2;
                    r_outer = sc_r(i) + sc_dr/2;
                    cell_volume = pi * (r_outer^2 - r_inner^2) * sc_dz;
                end
                
                % ===== CRITICAL: Account for super-particle weight =====
                % ion_density_grid stores NUMBER OF SUPER-IONS
                % Each super-ion represents ion_physics.superparticle_weight real ions
                real_ions_in_cell = ion_density_grid(i,j) * ion_physics.superparticle_weight;
                ion_charge_density = e_charge * real_ions_in_cell / cell_volume;
                
                rho_grid(i, j) = rho_grid(i, j) + ion_charge_density;  % POSITIVE charge
            end
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                
        % Solve Poisson equation
        phi_grid(:) = 0;
        for iter = 1:sc_iterations
            for i = 2:sc_nr-1
                for j = 2:sc_nz-1
                    r_local = sc_r(i);
                    
                    if r_local > 1e-6
                        phi_new = (sc_dz^2*(phi_grid(i+1,j) + phi_grid(i-1,j)) + ...
                                  sc_dr^2*(phi_grid(i,j+1) + phi_grid(i,j-1))) / ...
                                 (2*(sc_dr^2 + sc_dz^2));
                        
                        phi_new = phi_new - rho_grid(i,j)*sc_dr^2*sc_dz^2 / ...
                                 (2*eps0*(sc_dr^2 + sc_dz^2));
                    else
                        phi_new = (4*phi_grid(2,j) + phi_grid(1,j+1) + phi_grid(1,j-1)) / 6;
                        phi_new = phi_new - rho_grid(1,j)*sc_dr^2*sc_dz^2 / (6*eps0);
                    end
                    
                    phi_grid(i,j) = (1-sc_omega)*phi_grid(i,j) + sc_omega*phi_new;
                end
            end
        end
        
        % Calculate fields
        for i = 2:sc_nr-1
            for j = 2:sc_nz-1
                Ez_sc(i,j) = -(phi_grid(i,j+1) - phi_grid(i,j-1))/(2*sc_dz);
                Er_sc(i,j) = -(phi_grid(i+1,j) - phi_grid(i-1,j))/(2*sc_dr);
            end
        end
        
        % Limit space charge (30%, 50%, 70% or 100% of max applied field)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        sc_strength_factor = 3.0;  % Changed from 2.0 / 10.08.2025
        max_sc = sc_strength_factor * 7.5e6;
        Ez_mag = max(abs(Ez_sc(:)));   
        if Ez_mag > max_sc
           scale_factor = max_sc / Ez_mag;
           Ez_sc = Ez_sc * scale_factor;
            Er_sc = Er_sc * scale_factor;
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    %Add this after the space charge calculation to monitor actual field strength:
    % After line ~280
 %   if ENABLE_SPACE_CHARGE && mod(it, sc_interval) == 0
 %      max_Ez_sc = max(abs(Ez_sc(:)));
 %      if mod(it, 1000) == 0  % Report occasionally
 %       fprintf('  [SC Field: %.2f MV/m]\n', max_Ez_sc/1e6);
 %       end
 %  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Add this after the space charge calculation to monitor actual field strength:
% After line ~280
if ENABLE_SPACE_CHARGE == true && mod(it, sc_interval) == 0
    % GUARD: Only check if Ez_sc exists
    if exist('Ez_sc', 'var') && ~isempty(Ez_sc)
        max_Ez_sc = max(abs(Ez_sc(:)));
        if mod(it, 1000) == 0  % Report occasionally
            fprintf('  [SC Field: %.2f MV/m]\n', max_Ez_sc/1e6);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%% added 10.07.2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ENABLE_SPACE_CHARGE == true && mod(it, sc_interval) == 0
    max_sc_field_recorded = max(max_sc_field_recorded, max(abs(Ez_sc(:))));
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% --- PARTICLE PUSH ---
    %%%%%%%%%%%%%%%%%%%%%%%% added 10.07.2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% --- PARTICLE PUSH AND LOSS ACCOUNTING ---
   if n_active > 0
    active_idx = find(active_particles);
    
    z_active = z_particles(active_idx);
    r_active = r_particles(active_idx);
    
    % Define actual geometry limits
    r_cathode_gap = 0.075;  % 75mm radius in cathode-anode gap
    r_drift_tube = 0.075;    % 75mm drift tube radius
    r_max_computational = 0.450;  % Maximum computational boundary
    
    % Categorize particle losses by region and mechanism
    % 1. Particles returning to cathode (backstreaming)
    back_to_cathode = z_active < 0;
    
    % 2. Wall losses in different regions
    % Gap region (0 < z < 254mm)
    in_gap = z_active >= 0 & z_active < 0.254;
    gap_wall_loss = in_gap & r_active > r_cathode_gap;
    
    % Drift tube region (z > 500mm)
    in_drift = z_active >= 0.500;
    drift_wall_loss = in_drift & r_active > r_drift_tube;
    
    % Transition region (254mm < z < 500mm) - gradual expansion
    in_transition = z_active >= 0.254 & z_active < 0.500;
    r_transition = r_cathode_gap + (r_drift_tube - r_cathode_gap) * ...
                   (z_active - 0.254) / (0.500 - 0.254);
    transition_wall_loss = in_transition & r_active > r_transition;
    
    % 3. Computational boundary violations
    out_of_domain = z_active > 8.350 | r_active > r_max_computational | z_active < -0.5;
    
    % Combine all loss mechanisms
    lost_particles = back_to_cathode | gap_wall_loss | drift_wall_loss | ...
                    transition_wall_loss | out_of_domain;
    
    % Count losses by type before removing particles
    if any(lost_particles)
        % Detailed accounting
        n_back_to_cathode = sum(back_to_cathode);
        n_gap_wall = sum(gap_wall_loss);
        n_drift_wall = sum(drift_wall_loss);
        n_transition_wall = sum(transition_wall_loss);
        n_out_of_bounds = sum(out_of_domain & ~back_to_cathode & ...
                             ~gap_wall_loss & ~drift_wall_loss & ~transition_wall_loss);
        
        % Update global counters (weighted by particle weight)
        lost_idx = active_idx(lost_particles);
        weight_lost = sum(weight_particles(lost_idx));
        
        particles_lost_to_cathode = particles_lost_to_cathode + n_back_to_cathode;
        particles_lost_to_walls = particles_lost_to_walls + ...
                                 n_gap_wall + n_drift_wall + n_transition_wall;
        particles_out_of_bounds = particles_out_of_bounds + n_out_of_bounds;
        
        % Remove lost particles
        active_particles(lost_idx) = false;
        n_active = n_active - sum(lost_particles);
        
        % Debug output every 1000 steps
        if mod(it, 1000) == 0 && sum(lost_particles) > 0
            fprintf('\n  [LOSSES] Cathode:%d, Walls:%d, Bounds:%d\n', ...
                    n_back_to_cathode, n_gap_wall+n_drift_wall+n_transition_wall, ...
                    n_out_of_bounds);
        end
    end
    
    % Continue with valid particles only
    valid = ~lost_particles;
    active_idx = active_idx(valid);
    z_active = z_active(valid);
    r_active = r_active(valid);
    
        if ~isempty(active_idx)
        % ... rest of particle push code continues here ...
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Clamp positions to valid field region
            z_clamped = max(z(1), min(z(end)-1e-6, z_active)); %Added 01.29.2026
            r_clamped = max(r(1), min(r(end)-1e-6, r_active));
            % Field interpolation
            %Ez_local = interp2(z, r, Ez_capped, z_active, r_active, 'linear', 0);
            %Er_local = interp2(z, r, Er_capped, z_active, r_active, 'linear', 0);

            Ez_local = interp2(z, r, Ez_capped, z_clamped, r_clamped, 'linear', 0);
            Er_local = interp2(z, r, Er_capped, z_clamped, r_clamped, 'linear', 0);
            
            Ez_local = Ez_local * pulse_factor;
            Er_local = Er_local * pulse_factor;
            
            % Add space charge
            if ENABLE_SPACE_CHARGE && exist('Ez_sc', 'var') && any(Ez_sc(:) ~= 0)
                Ez_sc_local = interp2(sc_z, sc_r, Ez_sc, z_active, r_active, 'linear', 0);
                Er_sc_local = interp2(sc_z, sc_r, Er_sc, z_active, r_active, 'linear', 0);
                
                Ez_local = Ez_local + Ez_sc_local;
                Er_local = Er_local + Er_sc_local;
            end
            
            % Boris push
            pz_minus = pz_particles(active_idx) - 0.5*e_charge*Ez_local*dt;
            pr_minus = pr_particles(active_idx) - 0.5*e_charge*Er_local*dt;
            ptheta_minus = ptheta_particles(active_idx);
            
            % Magnetic field
            Bz_local = Bz_func(z_active, r_active, current_t);
            Br_local = Br_func(z_active, r_active, current_t);
            
            p_mag = sqrt(pz_minus.^2 + pr_minus.^2 + ptheta_minus.^2);
            gamma_minus = sqrt(1 + (p_mag/(m_e*c)).^2);
            
            t_factor = -e_charge*dt./(2*gamma_minus*m_e);
            tz = t_factor .* Bz_local;
            tr = t_factor .* Br_local;
            
            s_factor = 2./(1 + tz.^2 + tr.^2);
            pz_plus = pz_minus + s_factor.*(pr_minus.*tr);
            pr_plus = pr_minus + s_factor.*(ptheta_minus.*tz);
            ptheta_plus = ptheta_minus + s_factor.*(pz_minus.*tr - pr_minus.*tz);
            
            % Second half push
            pz_particles(active_idx) = pz_plus - 0.5*e_charge*Ez_local*dt;
            pr_particles(active_idx) = pr_plus - 0.5*e_charge*Er_local*dt;
            ptheta_particles(active_idx) = ptheta_plus;
       
       
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% ==================== GAS SCATTERING MODULE (CORRECTED) ====================
% Apply after Boris pusher, before position update

if ENABLE_GAS_SCATTERING == true  && mod(it, scatter_cal.check_interval) == 0
    % Work with already-found active_idx
    n_scatter_check = length(active_idx);

    if n_scatter_check > 0
        % Calculate velocities and momenta
        p_total_sc = sqrt(pz_particles(active_idx).^2 + ...
                         pr_particles(active_idx).^2 + ...
                         ptheta_particles(active_idx).^2);
        gamma_sc = gamma_particles(active_idx);
        beta_sc = sqrt(1 - 1./gamma_sc.^2);
        v_electron = c * beta_sc;
        
        % Path length over this interval
        ds = v_electron * dt * scatter_cal.check_interval;
        
        % Scattering probability (apply calibration factor)
        sigma_tuned = gas_params.sigma_elastic * scatter_cal.strength_factor;
        p_scatter = 1 - exp(-sigma_tuned * gas_params.n_gas .* ds);
        
        % Monte Carlo: which particles scatter?
        scatter_mask = rand(n_scatter_check, 1) < p_scatter;
        
        if any(scatter_mask)
            scatter_idx = active_idx(scatter_mask);
            n_scattered = length(scatter_idx);
            
            % Extract scattered particle properties
            p_sc = p_total_sc(scatter_mask);
            beta_sc_scattered = beta_sc(scatter_mask);
            ds_sc = ds(scatter_mask);
            
            % ===== METHOD SELECTION =====
            switch SCATTERING_METHOD
 
%% ==================== CORRECTED SCATTERING ANGLES FOR THIN TARGET ====================
case 'MONTE_CARLO'
    % For thin targets, use Rutherford scattering directly
    % Not Highland formula (which assumes thick targets)
    
    % Physical parameters
    Z_eff = 7.4;  % Weighted average for air
    b_min = 1e-10;  % Minimum impact parameter (atomic radius)
    
    % Calculate characteristic scattering angle
    % θ_typ = Z×e²/(4πε₀×p×c×b)
    theta_char = Z_eff * e_charge^2 ./ (4*pi*eps0 * p_sc * c * b_min);
    
    % RMS angle for multiple scatters over path ds
    % Number of scatters = n_gas × σ × ds
    n_scatters_avg = gas_params.n_gas * sigma_tuned * mean(ds_sc);
    
    % Multiple scattering: θ_rms = √N × θ_single
    theta_0 = theta_char * sqrt(n_scatters_avg);
    
    % Generate deflections
    theta_deflect = randn(n_scattered, 1) * mean(theta_0);
    phi_deflect = 2*pi*rand(n_scattered, 1);
    
    % Apply kicks
    delta_pr = p_sc .* theta_deflect .* cos(phi_deflect);
    delta_ptheta = p_sc .* theta_deflect .* sin(phi_deflect);
    
    pr_particles(scatter_idx) = pr_particles(scatter_idx) + delta_pr;
    ptheta_particles(scatter_idx) = ptheta_particles(scatter_idx) + delta_ptheta;
    
    scatter_diag.theta_history = [scatter_diag.theta_history; theta_deflect];

case 'CONTINUOUS'
    % Same thin-target approach for continuous
    Z_eff = 7.4;
    b_min = 1e-10;
    
    p_mean = mean(p_total_sc);
    theta_char = Z_eff * e_charge^2 / (4*pi*eps0 * p_mean * c * b_min);
    
    n_scatters_avg = gas_params.n_gas * sigma_tuned * mean(ds);
    theta_rms = theta_char * sqrt(n_scatters_avg);
    
    theta_all = randn(n_scatter_check, 1) * theta_rms;
    phi_all = 2*pi*rand(n_scatter_check, 1);
    
    delta_pr = p_total_sc .* theta_all .* cos(phi_all);
    delta_ptheta = p_total_sc .* theta_all .* sin(phi_all);
    
    pr_particles(active_idx) = pr_particles(active_idx) + delta_pr;
    ptheta_particles(active_idx) = ptheta_particles(active_idx) + delta_ptheta;
    
    if n_scatter_check > 100
        sample_idx = randperm(n_scatter_check, 100);
        scatter_diag.theta_history = [scatter_diag.theta_history; theta_all(sample_idx)];
    else
        scatter_diag.theta_history = [scatter_diag.theta_history; theta_all];
    end

    %case 'HYBRID'
    % === TYPICAL EVENTS: Use Rutherford ===
    %typical_idx = scatter_idx(~is_rare);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
    case 'HYBRID'
    % Separate into typical vs rare events
    is_rare = rand(n_scattered, 1) < scatter_cal.rare_fraction;
    
    % === TYPICAL SMALL-ANGLE SCATTERS (99%) ===
    typical_idx = scatter_idx(~is_rare);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~isempty(typical_idx)
        p_typ = p_sc(~is_rare);
        ds_typ = ds_sc(~is_rare);
        
        Z_eff = 7.4;
        b_min = 1e-10;
        
        theta_char = Z_eff * e_charge^2 ./ (4*pi*eps0 * p_typ * c * b_min);
        n_scatters = gas_params.n_gas * sigma_tuned * ds_typ;
        theta_0_typ = theta_char .* sqrt(n_scatters);
        
        theta_typ = randn(length(typical_idx), 1) .* theta_0_typ;
        phi_typ = 2*pi*rand(length(typical_idx), 1);
        
        delta_pr_typ = p_typ .* theta_typ .* cos(phi_typ);
        delta_ptheta_typ = p_typ .* theta_typ .* sin(phi_typ);
        
        pr_particles(typical_idx) = pr_particles(typical_idx) + delta_pr_typ;
        ptheta_particles(typical_idx) = ptheta_particles(typical_idx) + delta_ptheta_typ;
        
        scatter_diag.theta_history = [scatter_diag.theta_history; theta_typ];
    end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % === RARE LARGE-ANGLE SCATTERS (1%) ===
                    rare_idx = scatter_idx(is_rare);
                    if ~isempty(rare_idx)
                        n_rare = length(rare_idx);
                        
                        % Power-law distribution for large angles
                        theta_min = 0.1e-3;  % 0.1 mrad
                        theta_max = scatter_cal.theta_rare_max;  % 10 mrad
                        
                        u = rand(n_rare, 1);
                        theta_rare = theta_min * (theta_max/theta_min).^u;
                        phi_rare = 2*pi*rand(n_rare, 1);
                        
                        p_rare = p_sc(is_rare);
                        
                        delta_pr_rare = p_rare .* theta_rare .* cos(phi_rare);
                        delta_ptheta_rare = p_rare .* theta_rare .* sin(phi_rare);
                        
                        pr_particles(rare_idx) = pr_particles(rare_idx) + delta_pr_rare;
                        ptheta_particles(rare_idx) = ptheta_particles(rare_idx) + delta_ptheta_rare;
                        
                        % Store rare angles separately
                        scatter_diag.theta_history = [scatter_diag.theta_history; theta_rare];
                        scatter_diag.rare_count = scatter_diag.rare_count + n_rare;
                    end
            end
            
            % Update diagnostics
            scatter_diag.event_count = scatter_diag.event_count + n_scattered;
            scatter_diag.z_scatter_positions = [scatter_diag.z_scatter_positions; ...
                                               z_particles(scatter_idx)];
            
            % Periodic reporting (CORRECTED units)
            if mod(it, 5000) == 0
                fprintf('\n  [SCATTER] %d events', n_scattered);
                if strcmp(SCATTERING_METHOD, 'HYBRID')
                    fprintf(' (%d rare)', sum(is_rare));
                end
                % Show mean angle in µrad (correct units)
                if ~isempty(scatter_diag.theta_history)
                    fprintf(', <θ>=%.3f µrad', mean(abs(scatter_diag.theta_history(end-n_scattered+1:end)))*1e6);
                end
            end
        end
    end
end
   
  %% ==================== end of updated scattering module ========================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% corrected ions creation 11.25.2025 %%%%%%%%%%%%%%%%%%%
%% ==================== CORRECTED ION CREATION WITH SUPER-PARTICLES ====================
% This replaces lines ~755-832 in your current code
% COMPLETE with all necessary closing end statements

if ENABLE_ION_ACCUMULATION == true && mod(it, scatter_cal.check_interval) == 0
    active_idx = find(active_particles);
    n_check = length(active_idx);
    
    if n_check > 0
        % Calculate path length and ionization probability
        p_total = sqrt(pz_particles(active_idx).^2 + ...
                      pr_particles(active_idx).^2 + ...
                      ptheta_particles(active_idx).^2);
        gamma_local = gamma_particles(active_idx);
        beta_local = sqrt(1 - 1./gamma_local.^2);
        v_electron = c * beta_local;
        ds = v_electron * dt * scatter_cal.check_interval;
        
        p_ionize = 1 - exp(-ion_physics.sigma_ionization * gas_params.n_gas .* ds);
        
        % ===== Create super-ions instead of individual ions =====
        real_ions_per_particle = weight_particles(active_idx) .* p_ionize;
        superions_per_particle = real_ions_per_particle / ion_physics.superparticle_weight;
        total_superions_this_step = sum(superions_per_particle);
        
        if total_superions_this_step > 0.01  % Threshold for numerical noise
            
            % Deposit super-ions on grid
            for i = 1:n_check
                idx = active_idx(i);
                superions_from_this = superions_per_particle(i);
                
                if superions_from_this > 0.01
                    z_ion = z_particles(idx);
                    r_ion = r_particles(idx);
                    
                    [~, iz] = min(abs(sc_z - z_ion));
                    [~, ir] = min(abs(sc_r - r_ion));
                    
                    if iz >= 1 && iz <= sc_nz && ir >= 1 && ir <= sc_nr
                        % Store super-ions on grid
                        ion_density_grid(ir, iz) = ion_density_grid(ir, iz) + superions_from_this;
                        
                        if current_pulse > 0
                            ion_density_by_pulse(ir, iz, current_pulse) = ...
                                ion_density_by_pulse(ir, iz, current_pulse) + superions_from_this;
                        end  % Closes: if current_pulse > 0
                    end  % Closes: if iz >= 1 && iz <= sc_nz...
                end  % Closes: if superions_from_this > 0.01
            end  % Closes: for i = 1:n_check
            
            % ===== Define real_ions_created for diagnostics =====
            real_ions_created = total_superions_this_step * ion_physics.superparticle_weight;
            
            % Update diagnostics (using REAL ion count)
            ion_diag.creation_history(it) = real_ions_created;
            
            if current_pulse > 0
                ion_diag.ions_per_pulse(current_pulse) = ...
                    ion_diag.ions_per_pulse(current_pulse) + real_ions_created;
            end  % Closes: if current_pulse > 0 (diagnostics)

            % ===== First-time diagnostic =====
            if ~exist('first_ion_report', 'var') && real_ions_created > 10
                fprintf('\n*** FIRST ION CREATION at t=%.1f ns ***\n', current_t*1e9);
                fprintf('  Particles checked: %d\n', n_check);
                fprintf('  Average electron weight: %.2e\n', mean(weight_particles(active_idx)));
                fprintf('  Average p_ionize: %.2e\n', mean(p_ionize));
                fprintf('  Total REAL ions created: %.0f\n', real_ions_created);
                fprintf('  Super-ions created: %.1f\n', total_superions_this_step);
                fprintf('  Super-ion weight: %.0f ions/super-ion\n', ion_physics.superparticle_weight);
                first_ion_report = true;
            end  % Closes: if ~exist('first_ion_report'...)
            
            % ===== Progress reporting =====
            if mod(it, 5000) == 0 && real_ions_created > 0
                fprintf(' | [ION] %.0f real ions (%.1f super-ions)', ...
                        real_ions_created, total_superions_this_step);
            end  % Closes: if mod(it, 5000)
            
        end  % Closes: if total_superions_this_step > 0.01
    end  % Closes: if n_check > 0
end  % Closes: if ENABLE_ION_ACCUMULATION && mod(it, scatter_cal.check_interval)
%% ==================== END OF CORRECTED ION CREATION ====================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %% ==================== UPDATE POSITIONS ====================
     % Re-establish active particles list (some may have been lost)
    if n_active > 0
            active_idx = find(active_particles);
            z_active = z_particles(active_idx);
            r_active = r_particles(active_idx);

            % Update positions
            p_total = sqrt(pz_particles(active_idx).^2 + pr_particles(active_idx).^2 + ...
                          ptheta_particles(active_idx).^2);
            gamma_particles(active_idx) = sqrt(1 + (p_total/(m_e*c)).^2);
            
            vz = pz_particles(active_idx) ./ (gamma_particles(active_idx) * m_e);
            vr = pr_particles(active_idx) ./ (gamma_particles(active_idx) * m_e);
            
            z_new = z_active + vz * dt;
            r_new = r_active + vr * dt;
            
            z_particles(active_idx) = z_new;
            r_particles(active_idx) = r_new;
            
            % Radial reflection
            at_axis = r_new < 0;
            r_particles(active_idx(at_axis)) = -r_particles(active_idx(at_axis));
            pr_particles(active_idx(at_axis)) = -pr_particles(active_idx(at_axis));
    end
    %%%%%%%%%%%%%%%%%%%%%%%% added 10.08.2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Monitor crossings with double-counting prevention
for mon = 1:n_monitors
    z_mon = monitor_positions(mon);
    % Check which particles cross this monitor plane
    crossing = z_active < z_mon & z_new >= z_mon;
    
    if any(crossing)
        % Find indices of crossing particles
        crossing_idx = find(crossing);
        
        for ci = 1:length(crossing_idx)
            idx_local = crossing_idx(ci);
            idx_global = active_idx(idx_local);
            
            % Only count if not already counted at this monitor
            if ~particle_counted_at_monitor(idx_global, mon)
                I_monitor(it, mon) = I_monitor(it, mon) + ...
                    weight_particles(idx_global) * e_charge / dt;
                particles_through(mon) = particles_through(mon) + 1;
                particle_counted_at_monitor(idx_global, mon) = true;
            end
         end
    end
end
 

%%%%%%%%%%%%%%%%%%%%%%%% added 10.08.2025 - FIXED v3 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Monitor crossings with proper double-counting prevention and accurate counting
% Anode crossing detection (z = 254mm)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 11.19.2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% CORRECTED ANODE & EXIT TRACKING %%%%%%%%%%%%%%%%%%%%
%% ==================== ANODE CROSSING DETECTION ====================
at_anode = z_active < 0.254 & z_new >= 0.254;

if any(at_anode)
    crossing_local_idx = find(at_anode);
    
    for i = 1:length(crossing_local_idx)
        local_idx = crossing_local_idx(i);
        global_idx = active_idx(local_idx);
        
        if ~particle_crossed_anode(global_idx)
            particle_crossed_anode(global_idx) = true;
            particle_t_at_anode(global_idx) = current_t;
            particles_at_anode = particles_at_anode + 1;
            
            % Accumulate charge
            charge_contrib = weight_particles(global_idx) * e_charge;
            I_anode_accumulator = I_anode_accumulator + charge_contrib;
        end
    end
end

% Convert to Anode current ONLY at regular intervals
if mod(it, 10) == 0
    I_anode(it) = I_anode_accumulator / (10 * dt);
    I_anode_accumulator = 0;  % Reset
else
    if it > 1
        I_anode(it) = I_anode(it-1);  % Carry forward
    end
end

%% ==================== DRIFT EXIT CROSSING DETECTION ====================
drift_exit_crossings = z_active < 8.305 & z_new >= 8.305;

if any(drift_exit_crossings)
    crossing_local_idx = find(drift_exit_crossings);
    
    for i = 1:length(crossing_local_idx)
        local_idx = crossing_local_idx(i);
        global_idx = active_idx(local_idx);
        
        if ~particle_crossed_exit(global_idx)
            particle_crossed_exit(global_idx) = true;
            particle_t_at_exit(global_idx) = current_t;
            particles_transmitted = particles_transmitted + 1;
            
            % Accumulate charge
            I_exit_accumulator = I_exit_accumulator + ...
                weight_particles(global_idx) * e_charge;
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert to current at regular intervals
%if mod(it, 10) == 0
%    I_drift_exit(it) = I_exit_accumulator / (10 * dt);
%    I_exit_accumulator = 0;  % Reset
%else
%    if it > 1
%        I_drift_exit(it) = I_drift_exit(it-1);  % Carry forward
%    end
%end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Drift Current %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert accumulated charge to current over the averaging interval
if mod(it, 10) == 0
    if I_exit_accumulator > 0
        % Divide by the time interval, not particle count
        I_drift_exit(it) = I_exit_accumulator / (10 * dt);
        I_exit_accumulator = 0;  % Reset accumulator
    elseif it > 1
        I_drift_exit(it) = I_drift_exit(it-1);  %// Carry forward
    end
elseif it > 1
    I_drift_exit(it) = I_drift_exit(it-1);  %// Carry forward between updates
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            % Calculate collection efficiency
            if I_cathode(it) > 0
            collection_efficiency(it) = 100 * I_anode(it) / I_cathode(it);

            end
            

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Remove out-of-bounds
            out_bounds = z_new > 8.31 | r_new > 0.5 | z_new < -0.5;
            active_particles(active_idx(out_bounds)) = false;
            n_active = n_active - sum(out_bounds);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SNAPSHOT P1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== ENHANCED SNAPSHOT ANALYSIS AT MID-PULSE ====================
% Add this inside the main loop, around timestep 5000 (mid-pulse)
if it == 5500  % Mid-pulse, steady state, 15ns + 40ns from the start
    fprintf('\n=== Capturing Full Beam Snapshot at t=%.1f ns ===\n', current_t*1e9);
    
    % Save complete beam state
    active_idx = find(active_particles);
    beam_snapshot = struct();
    beam_snapshot.z = z_particles(active_idx);
    beam_snapshot.r = r_particles(active_idx);
    beam_snapshot.pr = pr_particles(active_idx);
    beam_snapshot.pz = pz_particles(active_idx);
    beam_snapshot.ptheta = ptheta_particles(active_idx);
    beam_snapshot.gamma = gamma_particles(active_idx);
    beam_snapshot.weight = weight_particles(active_idx);
    beam_snapshot.n_total = length(active_idx);
    beam_snapshot.time = current_t;
    
    % Calculate velocities for dt-based selection
    vz = pz_particles(active_idx) ./ (gamma_particles(active_idx) * m_e);
    beam_snapshot.vz = vz;
    
    fprintf('  Total active particles: %d\n', beam_snapshot.n_total);
    fprintf('  Z range: %.1f to %.1f mm\n', min(beam_snapshot.z)*1000, max(beam_snapshot.z)*1000);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%% Updated 02.06.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%REPLACE current inter-pulse capture block (around line 1013) with:
%% ==================== INTER-PULSE ELECTRON CLOUD SNAPSHOTS (MULTI-CAPTURE) ====================
if ENABLE_INTERPULSE_SNAPSHOT == true && ENABLE_MULTIPULSE == true
    
    % Check each inter-pulse time
     for ipc = 1:n_interpulse_snapshots
        if abs(current_t - INTERPULSE_SNAPSHOT_TIMES(ipc)) < dt/2
            
            % Only capture if not already done
            if isempty(interpulse_clouds{ipc})
                
                fprintf('\n=== CAPTURING INTER-PULSE CLOUD %d/%d at t=%.1f ns ===\n', ...
                        ipc, n_interpulse_snapshots, current_t*1e9);
                fprintf('(Before Pulse %d starts)\n', ipc+1);
                
                active_idx = find(active_particles);
                
                if n_active > 0
                    cloud = struct();
                    cloud.z = z_particles(active_idx);
                    cloud.r = r_particles(active_idx);
                    cloud.pr = pr_particles(active_idx);
                    cloud.pz = pz_particles(active_idx);
                    cloud.ptheta = ptheta_particles(active_idx);
                    cloud.gamma = gamma_particles(active_idx);
                    cloud.weight = weight_particles(active_idx);
                    cloud.n_total = length(active_idx);
                    cloud.time = current_t;
                    cloud.before_pulse = ipc + 1;  % This cloud is BEFORE pulse N
                    
                    % Calculate velocities and energies
                    cloud.vz = pz_particles(active_idx) ./ (gamma_particles(active_idx) * m_e);
                    cloud.vr = pr_particles(active_idx) ./ (gamma_particles(active_idx) * m_e);
                    cloud.energy_MeV = (gamma_particles(active_idx) - 1) * m_e * c^2 / e_charge / 1e6;
                    
                    % Identify source pulses
                    if exist('particle_source_pulse', 'var')
                        cloud.source_pulse = particle_source_pulse(active_idx);
                        n_from_previous = sum(particle_source_pulse(active_idx) <= ipc);
                    else
                        n_from_previous = n_active;
                    end
                    
                    % Calculate slow electron centroid (most important for lensing)
                    slow_electrons = cloud.energy_MeV < 1.0;
                    n_slow = sum(slow_electrons);
                    
                    if n_slow > 0
                        z_slow = cloud.z(slow_electrons);
                        r_slow = cloud.r(slow_electrons);
                        cloud.z_centroid = mean(z_slow);
                        cloud.r_centroid = sqrt(mean(r_slow.^2));
                        cloud.n_slow = n_slow;
                    else
                        cloud.z_centroid = NaN;
                        cloud.r_centroid = NaN;
                        cloud.n_slow = 0;
                    end
                    
                    % Store in array
                    interpulse_clouds{ipc} = cloud;
                    interpulse_capture_count = interpulse_capture_count + 1;
                    
                    % Get ion count at this moment
                    current_ions = sum(ion_density_grid(:)) * ion_physics.superparticle_weight;
                    
                    fprintf('  Total residual electrons: %d\n', cloud.n_total);
                    fprintf('  From pulses 1-%d: %d (%.1f%%)\n', ...
                            ipc, n_from_previous, 100*n_from_previous/n_active);
                    fprintf('  Slow electrons (<1 MeV): %d\n', n_slow);
                    if ~isnan(cloud.z_centroid)
                        fprintf('  Slow electron centroid: z=%.0f mm, r=%.1f mm\n', ...
                                cloud.z_centroid*1000, cloud.r_centroid*1000);
                    end
                    fprintf('  Energy range: %.3f to %.3f MeV\n', ...
                            min(cloud.energy_MeV), max(cloud.energy_MeV));
                    fprintf('  Accumulated ions: %.2e (Ion lens for P%d)\n', ...
                            current_ions, ipc+1);
                    
                else
                    fprintf('  WARNING: No active particles between pulses!\n');
                end
            end  % End isempty check
        end  % End time check
    end  % End loop over inter-pulse times
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In your main loop, around line 650, ADD THIS SECTION:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== CAPTURE PULSE 2 STEADY STATE ====================
% Use snapshot timing for consistency
if ENABLE_SNAPSHOTS == true && abs(current_t - 405e-9) < dt/2
    if ~exist('steady_state_beam_pulse2', 'var')  % Only capture once
        fprintf('\n=== Capturing Pulse 2 Steady-State Beam at t=%.1f ns ===\n', current_t*1e9);
        
        active_idx = find(active_particles);
        steady_state_beam_pulse2 = struct();
        steady_state_beam_pulse2.z = z_particles(active_idx);
        steady_state_beam_pulse2.r = r_particles(active_idx);
        steady_state_beam_pulse2.pr = pr_particles(active_idx);
        steady_state_beam_pulse2.pz = pz_particles(active_idx);
        steady_state_beam_pulse2.ptheta = ptheta_particles(active_idx);
        steady_state_beam_pulse2.gamma = gamma_particles(active_idx);
        steady_state_beam_pulse2.weight = weight_particles(active_idx);
        steady_state_beam_pulse2.n_total = length(active_idx);
        steady_state_beam_pulse2.time = current_t;
        steady_state_beam_pulse2.vz = pz_particles(active_idx) ./ (gamma_particles(active_idx) * m_e);
        
        fprintf('  Total active particles captured: %d\n', steady_state_beam_pulse2.n_total);
        fprintf('  Z range: %.1f to %.1f mm\n', min(steady_state_beam_pulse2.z)*1000, max(steady_state_beam_pulse2.z)*1000);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Added 02.03.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== CAPTURE PULSE 3 STEADY STATE ====================
if ENABLE_SNAPSHOTS == true && abs(current_t - 605e-9) < dt/2  % Mid-P3 flat-top
    if ~exist('steady_state_beam_pulse3', 'var')  % Only capture once
        fprintf('\n=== Capturing Pulse 3 Steady-State Beam at t=%.1f ns ===\n', current_t*1e9);
        
        active_idx = find(active_particles);
        steady_state_beam_pulse3 = struct();
        steady_state_beam_pulse3.z = z_particles(active_idx);
        steady_state_beam_pulse3.r = r_particles(active_idx);
        steady_state_beam_pulse3.pr = pr_particles(active_idx);
        steady_state_beam_pulse3.pz = pz_particles(active_idx);
        steady_state_beam_pulse3.ptheta = ptheta_particles(active_idx);
        steady_state_beam_pulse3.gamma = gamma_particles(active_idx);
        steady_state_beam_pulse3.weight = weight_particles(active_idx);
        steady_state_beam_pulse3.n_total = length(active_idx);
        steady_state_beam_pulse3.time = current_t;
        steady_state_beam_pulse3.vz = pz_particles(active_idx) ./ (gamma_particles(active_idx) * m_e);
        
        fprintf('  Total active particles captured: %d\n', steady_state_beam_pulse3.n_total);
        fprintf('  Z range: %.1f to %.1f mm\n', ...
                min(steady_state_beam_pulse3.z)*1000, max(steady_state_beam_pulse3.z)*1000);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Added 02.06.2026  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%STEP 6: P4 Steady-State Beam Capture
%Location: Line ~1100 (after P3 steady-state block)
%Action: Add P4 mid-pulse snapshot at t=805ns
%% ==================== CAPTURE PULSE 4 STEADY STATE ====================
if ENABLE_SNAPSHOTS == true && abs(current_t - 805e-9) < dt/2  % Mid-P4 flat-top
    if ~exist('steady_state_beam_pulse4', 'var')  % Only capture once
        fprintf('\n=== Capturing Pulse 4 Steady-State Beam at t=%.1f ns ===\n', current_t*1e9);
        
        active_idx = find(active_particles);
        steady_state_beam_pulse4 = struct();
        steady_state_beam_pulse4.z = z_particles(active_idx);
        steady_state_beam_pulse4.r = r_particles(active_idx);
        steady_state_beam_pulse4.pr = pr_particles(active_idx);
        steady_state_beam_pulse4.pz = pz_particles(active_idx);
        steady_state_beam_pulse4.ptheta = ptheta_particles(active_idx);
        steady_state_beam_pulse4.gamma = gamma_particles(active_idx);
        steady_state_beam_pulse4.weight = weight_particles(active_idx);
        steady_state_beam_pulse4.n_total = length(active_idx);
        steady_state_beam_pulse4.time = current_t;
        steady_state_beam_pulse4.vz = pz_particles(active_idx) ./ (gamma_particles(active_idx) * m_e);
        
        fprintf('  Total active particles captured: %d\n', steady_state_beam_pulse4.n_total);
        fprintf('  Z range: %.1f to %.1f mm\n', ...
                min(steady_state_beam_pulse4.z)*1000, max(steady_state_beam_pulse4.z)*1000);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Added 01.13.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== TWISS ANALYSIS MODULE - PULSE 2 ====================
% Insert this section in your main loop right after Pulse 2 snapshot capture
% Currently around line 648 in your code, after the steady_state_beam_pulse2 capture

if ENABLE_SNAPSHOTS == true && abs(current_t - 405e-9) < dt/2  % Adjusted to true pulse midpoint
    if exist('steady_state_beam_pulse2', 'var') && steady_state_beam_pulse2.n_total > 1000
        fprintf('\n=== TWISS PARAMETER ANALYSIS - PULSE 2 (t=%.1f ns) ===\n', current_t*1e9);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        % Use same analysis planes as Pulse 1 for direct comparison
        %twiss_locations = [254, 600, 1000, 1700, 2700];  % mm
        %location_names = {'Anode', 'Transition', 'Transition', 'Transition', 'Drift Exit'};
%%%%%%%%%%%%%%%%%%  Updated Twiss Locations 02.13.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% ==================== ENHANCED TWISS ANALYSIS LOCATIONS (15 PLANES) ====================
% Add this in Twiss analysis sections (multiple locations in code)
% Replaces current: twiss_locations = [254, 600, 1000, 1700, 2700];

% Extended to cover key solenoid centers and BPMs
twiss_locations = [254;    % Anode (after gap acceleration)
                   600;    % Early drift (near Sol 3-4)
                   1000;   % Mid drift region 1 (near Sol 7-8)
                   1500;   % Between Sol 9-10
                   1700;   % Legacy diagnostic
                   2200;   % Near Sol 14-15
                   2700;   % BPM1 region (near Sol 19-20)
                   3400;   % Mid-extension (near Sol 25)
                   3964;   % BPM2 (experimental)
                   4600;   % Mid-extension 2 (near Sol 35)
                   5400;   % Near Sol 45
                   6402;   % BPM3 (experimental)
                   6828;   % BPM4 (experimental)
                   7450;   % Near final solenoid (Sol 49)
                   8305];  % BPM5 / Final exit

location_names = {'Anode', 'Early_Drift', 'Mid_Drift1', 'Trans1', 'Trans2', ...
                  'Mid_Drift2', 'BPM1', 'Extension1', 'BPM2', 'Extension2', ...
                  'Late_Drift', 'BPM3', 'BPM4', 'Sol49', 'Exit'};

n_twiss_planes = length(twiss_locations);

fprintf('=== Twiss Analysis Configuration ===\n');
fprintf('  Number of analysis planes: %d (expanded from 5)\n', n_twiss_planes);
fprintf('  Axial coverage: %.0f mm to %.0f mm\n', ...
        twiss_locations(1), twiss_locations(end));
fprintf('  Average spacing: %.0f mm\n', mean(diff(twiss_locations)));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Initialize storage for Pulse 2 Twiss results
        twiss_results_pulse2 = struct();
        
        % Extract snapshot data
        z_beam = steady_state_beam_pulse2.z;
        r_beam = steady_state_beam_pulse2.r;
        pr_beam = steady_state_beam_pulse2.pr;
        pz_beam = steady_state_beam_pulse2.pz;
        gamma_beam = steady_state_beam_pulse2.gamma;
        
        for ip = 1:length(twiss_locations)
            z_target = twiss_locations(ip) / 1000;  % Convert to meters
            plane_name = location_names{ip};
            
            % Select particles using spatial window (±15mm)
            selection_window = 0.015;  % 15mm
            in_plane = abs(z_beam - z_target) < selection_window;
            
            n_selected = sum(in_plane);
            
            if n_selected >= 50  % Minimum for statistics
                % Extract local particle data
                r_sel = r_beam(in_plane);
                pr_sel = pr_beam(in_plane);
                pz_sel = pz_beam(in_plane);
                gamma_sel = gamma_beam(in_plane);
                
                % Calculate normalized transverse momentum
                pr_norm = pr_sel ./ (gamma_sel * m_e * c);
                
                % Center distributions
                r_mean = mean(r_sel);
                pr_mean = mean(pr_norm);
                r_centered = r_sel - r_mean;
                pr_centered = pr_norm - pr_mean;
                
                % Second moments
                r2_avg = mean(r_centered.^2);
                pr2_avg = mean(pr_centered.^2);
                r_pr_avg = mean(r_centered .* pr_centered);
                
                % RMS emittance
                emit_rms = sqrt(r2_avg * pr2_avg - r_pr_avg^2);
                
                % Twiss parameters
                if emit_rms > 1e-10
                    beta_twiss = r2_avg / emit_rms;
                    gamma_twiss = pr2_avg / emit_rms;
                    alpha_twiss = -r_pr_avg / emit_rms;
                    
                    % Consistency check
                    twiss_consistency = beta_twiss * gamma_twiss - alpha_twiss^2;
                    
                    % Normalized emittance
                    gamma_avg = mean(gamma_sel);
                    beta_rel = sqrt(1 - 1/gamma_avg^2);
                    emit_norm = emit_rms * gamma_avg * beta_rel;
                    
                    % RMS quantities for reporting
                    r_rms = sqrt(r2_avg);
                    pr_rms = sqrt(pr2_avg);
                    
                    % Determine beam condition
                    if alpha_twiss > 0.1
                        beam_condition = 'Converging';
                    elseif alpha_twiss < -0.1
                        beam_condition = 'Diverging';
                    else
                        beam_condition = 'Nearly collimated';
                    end
                    
                    % Store results
                    twiss_results_pulse2(ip).location = plane_name;
                    twiss_results_pulse2(ip).z_mm = twiss_locations(ip);
                    twiss_results_pulse2(ip).n_particles = n_selected;
                    twiss_results_pulse2(ip).r_rms = r_rms * 1000;  % mm
                    twiss_results_pulse2(ip).rp_rms = pr_rms * 1000;  % mrad
                    twiss_results_pulse2(ip).beta = beta_twiss;  % m
                    twiss_results_pulse2(ip).alpha = alpha_twiss;
                    twiss_results_pulse2(ip).gamma = gamma_twiss;  % 1/m
                    twiss_results_pulse2(ip).emit_geo = emit_rms * 1e6;  % mm-mrad
                    twiss_results_pulse2(ip).emit_norm = emit_norm * 1e6;  % mm-mrad
                    twiss_results_pulse2(ip).consistency = twiss_consistency;
                    twiss_results_pulse2(ip).condition = beam_condition;
                    
                    % Print results
                    fprintf('\n%s (%dmm):\n', plane_name, twiss_locations(ip));
                    fprintf('  Particles analyzed: %d\n', n_selected);
                    fprintf('  RMS radius: %.2f mm\n', r_rms*1000);
                    fprintf('  RMS divergence: %.2f mrad\n', pr_rms*1000);
                    fprintf('  Geometric emittance: %.2f mm-mrad\n', emit_rms*1e6);
                    fprintf('  Normalized emittance: %.2f mm-mrad\n', emit_norm*1e6);
                    fprintf('  Twiss parameters:\n');
                    fprintf('    β = %.3f m\n', beta_twiss);
                    fprintf('    α = %.3f (%s)\n', alpha_twiss, beam_condition);
                    fprintf('    γ = %.3f 1/m\n', gamma_twiss);
                    fprintf('  Consistency check (βγ-α²): %.4f\n', twiss_consistency);
                    
                else
                    fprintf('\n%s: Emittance too small for Twiss analysis\n', plane_name);
                end
            else
                fprintf('\n%s: Only %d particles - insufficient for analysis\n', ...
                        plane_name, n_selected);
            end
        end
        
        % Save Pulse 2 Twiss results
        if exist('twiss_results_pulse2', 'var')
            save('twiss_analysis_pulse2_results.mat', 'twiss_results_pulse2');
            fprintf('\nTwiss analysis (Pulse 2) saved to twiss_analysis_pulse2_results.mat\n');
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%% Added 02.04.2026 Twiss snapshot P3 %%%%%%%%%%%%%%%%%%%%%% 
%% ==================== TWISS ANALYSIS MODULE - PULSE 3 ====================
if ENABLE_SNAPSHOTS == true && abs(current_t - 605e-9) < dt/2
    if exist('steady_state_beam_pulse3', 'var') && steady_state_beam_pulse3.n_total > 1000
        fprintf('\n=== TWISS PARAMETER ANALYSIS - PULSE 3 (t=%.1f ns) ===\n', current_t*1e9);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        % Use same analysis planes as Pulse 1 and 2 for direct comparison
        %twiss_locations = [254, 600, 1000, 1700, 2700];  % mm
        %location_names_p3 = {'Anode', 'Transition1', 'Transition2', 'Transition3', 'Drift Exit'};
%%%%%%%%%%%%%%%%%%%%%%%%% Updated Twiss Locations 02.13.2026 %%%%%%%%%%%%%%%%%%%%%%%
        %% ==================== ENHANCED TWISS ANALYSIS LOCATIONS (15 PLANES) ====================
% Add this in Twiss analysis sections (multiple locations in code)
% Replaces current: twiss_locations = [254, 600, 1000, 1700, 2700];

% Extended to cover key solenoid centers and BPMs
twiss_locations = [254;    % Anode (after gap acceleration)
                   600;    % Early drift (near Sol 3-4)
                   1000;   % Mid drift region 1 (near Sol 7-8)
                   1500;   % Between Sol 9-10
                   1700;   % Legacy diagnostic
                   2200;   % Near Sol 14-15
                   2700;   % BPM1 region (near Sol 19-20)
                   3400;   % Mid-extension (near Sol 25)
                   3964;   % BPM2 (experimental)
                   4600;   % Mid-extension 2 (near Sol 35)
                   5400;   % Near Sol 45
                   6402;   % BPM3 (experimental)
                   6828;   % BPM4 (experimental)
                   7450;   % Near final solenoid (Sol 49)
                   8305];  % BPM5 / Final exit

location_names = {'Anode', 'Early_Drift', 'Mid_Drift1', 'Trans1', 'Trans2', ...
                  'Mid_Drift2', 'BPM1', 'Extension1', 'BPM2', 'Extension2', ...
                  'Late_Drift', 'BPM3', 'BPM4', 'Sol49', 'Exit'};

n_twiss_planes = length(twiss_locations);

fprintf('=== Twiss Analysis Configuration ===\n');
fprintf('  Number of analysis planes: %d (expanded from 5)\n', n_twiss_planes);
fprintf('  Axial coverage: %.0f mm to %.0f mm\n', ...
        twiss_locations(1), twiss_locations(end));
fprintf('  Average spacing: %.0f mm\n', mean(diff(twiss_locations)));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Initialize storage for Pulse 3 Twiss results
        twiss_results_pulse3 = struct();
        
        % Extract snapshot data
        z_beam = steady_state_beam_pulse3.z;
        r_beam = steady_state_beam_pulse3.r;
        pr_beam = steady_state_beam_pulse3.pr;
        pz_beam = steady_state_beam_pulse3.pz;
        gamma_beam = steady_state_beam_pulse3.gamma;
        
        for ip = 1:length(twiss_locations)
            z_target = twiss_locations(ip) / 1000;  % Convert to meters
            plane_name = location_names{ip};
            
            % Select particles using spatial window (±15mm)
            selection_window = 0.015;  % 15mm
            in_plane = abs(z_beam - z_target) < selection_window;
            
            n_selected = sum(in_plane);
            
            if n_selected >= 50  % Minimum for statistics
                % Extract local particle data
                r_sel = r_beam(in_plane);
                pr_sel = pr_beam(in_plane);
                pz_sel = pz_beam(in_plane);
                gamma_sel = gamma_beam(in_plane);
                
                % Calculate normalized transverse momentum
                pr_norm = pr_sel ./ (gamma_sel * m_e * c);
                
                % Center distributions
                r_mean = mean(r_sel);
                pr_mean = mean(pr_norm);
                r_centered = r_sel - r_mean;
                pr_centered = pr_norm - pr_mean;
                
                % Second moments
                r2_avg = mean(r_centered.^2);
                pr2_avg = mean(pr_centered.^2);
                r_pr_avg = mean(r_centered .* pr_centered);
                
                % RMS emittance
                emit_rms = sqrt(r2_avg * pr2_avg - r_pr_avg^2);
                
                % Twiss parameters
                if emit_rms > 1e-10
                    beta_twiss = r2_avg / emit_rms;
                    gamma_twiss = pr2_avg / emit_rms;
                    alpha_twiss = -r_pr_avg / emit_rms;
                    
                    % Consistency check
                    twiss_consistency = beta_twiss * gamma_twiss - alpha_twiss^2;
                    
                    % Normalized emittance
                    gamma_avg = mean(gamma_sel);
                    beta_rel = sqrt(1 - 1/gamma_avg^2);
                    emit_norm = emit_rms * gamma_avg * beta_rel;
                    
                    % RMS quantities
                    r_rms = sqrt(r2_avg);
                    pr_rms = sqrt(pr2_avg);
                    
                    % Beam condition
                    if alpha_twiss > 0.1
                        beam_condition = 'Converging';
                    elseif alpha_twiss < -0.1
                        beam_condition = 'Diverging';
                    else
                        beam_condition = 'Nearly collimated';
                    end
                    
                    % Store results
                    twiss_results_pulse3(ip).location = plane_name;
                    twiss_results_pulse3(ip).z_mm = twiss_locations(ip);
                    twiss_results_pulse3(ip).n_particles = n_selected;
                    twiss_results_pulse3(ip).r_rms = r_rms * 1000;  % mm
                    twiss_results_pulse3(ip).rp_rms = pr_rms * 1000;  % mrad
                    twiss_results_pulse3(ip).beta = beta_twiss;  % m
                    twiss_results_pulse3(ip).alpha = alpha_twiss;
                    twiss_results_pulse3(ip).gamma = gamma_twiss;  % 1/m
                    twiss_results_pulse3(ip).emit_geo = emit_rms * 1e6;  % mm-mrad
                    twiss_results_pulse3(ip).emit_norm = emit_norm * 1e6;  % mm-mrad
                    twiss_results_pulse3(ip).consistency = twiss_consistency;
                    twiss_results_pulse3(ip).condition = beam_condition;
                    
                    % Print results
                    fprintf('\n%s (%dmm):\n', plane_name, twiss_locations(ip));
                    fprintf('  Particles analyzed: %d\n', n_selected);
                    fprintf('  RMS radius: %.2f mm\n', r_rms*1000);
                    fprintf('  RMS divergence: %.2f mrad\n', pr_rms*1000);
                    fprintf('  Geometric emittance: %.2f mm-mrad\n', emit_rms*1e6);
                    fprintf('  Normalized emittance: %.2f mm-mrad\n', emit_norm*1e6);
                    fprintf('  Twiss parameters:\n');
                    fprintf('    β = %.3f m\n', beta_twiss);
                    fprintf('    α = %.3f (%s)\n', alpha_twiss, beam_condition);
                    fprintf('    γ = %.3f 1/m\n', gamma_twiss);
                    fprintf('  Consistency check (βγ-α²): %.4f\n', twiss_consistency);
                    
                else
                    fprintf('\n%s: Emittance too small for Twiss analysis\n', plane_name);
                end
            else
                fprintf('\n%s: Only %d particles - insufficient for analysis\n', ...
                        plane_name, n_selected);
            end
        end
        
        % Save Pulse 3 Twiss results
        if exist('twiss_results_pulse3', 'var')
            save('twiss_analysis_pulse3_results.mat', 'twiss_results_pulse3');
            fprintf('\nTwiss analysis (Pulse 3) saved to twiss_analysis_pulse3_results.mat\n');
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  Added 02.06.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%STEP 7: P4 Twiss Analysis Module
%Location: Line ~1360 (after P3 Twiss block)
%Action: Add single-snapshot Twiss analysis for P4
%% ==================== TWISS ANALYSIS MODULE - PULSE 4 ====================
if ENABLE_SNAPSHOTS == true && abs(current_t - 805e-9) < dt/2
    if exist('steady_state_beam_pulse4', 'var') && steady_state_beam_pulse4.n_total > 1000
        fprintf('\n=== TWISS PARAMETER ANALYSIS - PULSE 4 (t=%.1f ns) ===\n', current_t*1e9);
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
        % Use same analysis planes as P1, P2, P3 for direct comparison
        %twiss_locations = [254, 600, 1000, 1700, 2700];  % mm
        %location_names_p4 = {'Anode', 'Transition1', 'Transition2', 'Transition3', 'Drift Exit'};
 %%%%%%%%%%%%%%%%%%% Updated Twiss Locations 02.13.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% ==================== ENHANCED TWISS ANALYSIS LOCATIONS (15 PLANES) ====================
% Add this in Twiss analysis sections (multiple locations in code)
% Replaces current: twiss_locations = [254, 600, 1000, 1700, 2700];

% Extended to cover key solenoid centers and BPMs
twiss_locations = [254;    % Anode (after gap acceleration)
                   600;    % Early drift (near Sol 3-4)
                   1000;   % Mid drift region 1 (near Sol 7-8)
                   1500;   % Between Sol 9-10
                   1700;   % Legacy diagnostic
                   2200;   % Near Sol 14-15
                   2700;   % BPM1 region (near Sol 19-20)
                   3400;   % Mid-extension (near Sol 25)
                   3964;   % BPM2 (experimental)
                   4600;   % Mid-extension 2 (near Sol 35)
                   5400;   % Near Sol 45
                   6402;   % BPM3 (experimental)
                   6828;   % BPM4 (experimental)
                   7450;   % Near final solenoid (Sol 49)
                   8305];  % BPM5 / Final exit

location_names = {'Anode', 'Early_Drift', 'Mid_Drift1', 'Trans1', 'Trans2', ...
                  'Mid_Drift2', 'BPM1', 'Extension1', 'BPM2', 'Extension2', ...
                  'Late_Drift', 'BPM3', 'BPM4', 'Sol49', 'Exit'};

n_twiss_planes = length(twiss_locations);

fprintf('=== Twiss Analysis Configuration ===\n');
fprintf('  Number of analysis planes: %d (expanded from 5)\n', n_twiss_planes);
fprintf('  Axial coverage: %.0f mm to %.0f mm\n', ...
        twiss_locations(1), twiss_locations(end));
fprintf('  Average spacing: %.0f mm\n', mean(diff(twiss_locations)));
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Initialize storage for Pulse 4 Twiss results
        twiss_results_pulse4 = struct();
        
        % Extract snapshot data
        z_beam = steady_state_beam_pulse4.z;
        r_beam = steady_state_beam_pulse4.r;
        pr_beam = steady_state_beam_pulse4.pr;
        pz_beam = steady_state_beam_pulse4.pz;
        gamma_beam = steady_state_beam_pulse4.gamma;
        
        for ip = 1:length(twiss_locations)
            z_target = twiss_locations(ip) / 1000;  % Convert to meters
            plane_name = location_names{ip};
            
            % Select particles using spatial window (±15mm)
            selection_window = 0.015;  % 15mm
            in_plane = abs(z_beam - z_target) < selection_window;
            
            n_selected = sum(in_plane);
            
            if n_selected >= 50  % Minimum for statistics
                % Extract local particle data
                r_sel = r_beam(in_plane);
                pr_sel = pr_beam(in_plane);
                pz_sel = pz_beam(in_plane);
                gamma_sel = gamma_beam(in_plane);
                
                % Calculate normalized transverse momentum
                pr_norm = pr_sel ./ (gamma_sel * m_e * c);
                
                % Center distributions
                r_mean = mean(r_sel);
                pr_mean = mean(pr_norm);
                r_centered = r_sel - r_mean;
                pr_centered = pr_norm - pr_mean;
                
                % Second moments
                r2_avg = mean(r_centered.^2);
                pr2_avg = mean(pr_centered.^2);
                r_pr_avg = mean(r_centered .* pr_centered);
                
                % RMS emittance
                emit_rms = sqrt(r2_avg * pr2_avg - r_pr_avg^2);
                
                % Twiss parameters
                if emit_rms > 1e-10
                    beta_twiss = r2_avg / emit_rms;
                    gamma_twiss = pr2_avg / emit_rms;
                    alpha_twiss = -r_pr_avg / emit_rms;
                    
                    % Consistency check
                    twiss_consistency = beta_twiss * gamma_twiss - alpha_twiss^2;
                    
                    % Normalized emittance
                    gamma_avg = mean(gamma_sel);
                    beta_rel = sqrt(1 - 1/gamma_avg^2);
                    emit_norm = emit_rms * gamma_avg * beta_rel;
                    
                    % RMS quantities
                    r_rms = sqrt(r2_avg);
                    pr_rms = sqrt(pr2_avg);
                    
                    % Beam condition
                    if alpha_twiss > 0.1
                        beam_condition = 'Converging';
                    elseif alpha_twiss < -0.1
                        beam_condition = 'Diverging';
                    else
                        beam_condition = 'Nearly collimated';
                    end
                    
                    % Store results
                    twiss_results_pulse4(ip).location = plane_name;
                    twiss_results_pulse4(ip).z_mm = twiss_locations(ip);
                    twiss_results_pulse4(ip).n_particles = n_selected;
                    twiss_results_pulse4(ip).r_rms = r_rms * 1000;  % mm
                    twiss_results_pulse4(ip).rp_rms = pr_rms * 1000;  % mrad
                    twiss_results_pulse4(ip).beta = beta_twiss;  % m
                    twiss_results_pulse4(ip).alpha = alpha_twiss;
                    twiss_results_pulse4(ip).gamma = gamma_twiss;  % 1/m
                    twiss_results_pulse4(ip).emit_geo = emit_rms * 1e6;  % mm-mrad
                    twiss_results_pulse4(ip).emit_norm = emit_norm * 1e6;  % mm-mrad
                    twiss_results_pulse4(ip).consistency = twiss_consistency;
                    twiss_results_pulse4(ip).condition = beam_condition;
                    
                    % Print results
                    fprintf('\n%s (%dmm):\n', plane_name, twiss_locations(ip));
                    fprintf('  Particles analyzed: %d\n', n_selected);
                    fprintf('  RMS radius: %.2f mm\n', r_rms*1000);
                    fprintf('  RMS divergence: %.2f mrad\n', pr_rms*1000);
                    fprintf('  Geometric emittance: %.2f mm-mrad\n', emit_rms*1e6);
                    fprintf('  Normalized emittance: %.2f mm-mrad\n', emit_norm*1e6);
                    fprintf('  Twiss parameters:\n');
                    fprintf('    β = %.3f m\n', beta_twiss);
                    fprintf('    α = %.3f (%s)\n', alpha_twiss, beam_condition);
                    fprintf('    γ = %.3f 1/m\n', gamma_twiss);
                    fprintf('  Consistency check (βγ-α²): %.4f\n', twiss_consistency);
                    
                else
                    fprintf('\n%s: Emittance too small for Twiss analysis\n', plane_name);
                end
            else
                fprintf('\n%s: Only %d particles - insufficient for analysis\n', ...
                        plane_name, n_selected);
            end
        end
        
        % Save Pulse 4 Twiss results
        if exist('twiss_results_pulse4', 'var')
            save('twiss_analysis_pulse4_results.mat', 'twiss_results_pulse4');
            fprintf('\nTwiss analysis (Pulse 4) saved to twiss_analysis_pulse4_results.mat\n');
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%  11.20.2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Capture ion snapshots (add after line ~710 where particle snapshots are taken)
if ENABLE_SNAPSHOTS == true && ENABLE_ION_ACCUMULATION == true && ...
   any(abs(current_t - snapshot_times) < dt/2)
    
    % Only proceed if a particle snapshot was just taken (snapshot_count > 0)
    if snapshot_count > 0
        
        if ~exist('ion_snapshot_data', 'var')
            ion_snapshot_data = struct();
        end
        
        % Use the current snapshot_count value
        ion_snapshot_data(snapshot_count).time = current_t;
        ion_snapshot_data(snapshot_count).density_grid = ion_density_grid;
        ion_snapshot_data(snapshot_count).total_ions = sum(ion_density_grid(:));
        
        % Calculate spatial moments
        ion_z_moment = 0;
        ion_count = sum(ion_density_grid(:));
        if ion_count > 0
            for j = 1:sc_nz
                ion_z_moment = ion_z_moment + sc_z(j) * sum(ion_density_grid(:, j));
            end
            ion_centroid = ion_z_moment / ion_count;
        else
            ion_centroid = NaN;
        end
        ion_snapshot_data(snapshot_count).centroid_z = ion_centroid;
        
        fprintf('  [Ion snapshot %d: %d ions, centroid at z=%.1f mm]\n', ...
                snapshot_count, round(ion_count), ion_centroid*1000);
    end
end
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Debug: Check for particles disappearing
if mod(it, 100) == 0 && n_active > 0
    z_check = z_particles(active_idx);
    lost_zone = z_check > 0.6 & z_check < 0.7;
    if any(lost_zone)
        fprintf('  DEBUG: %d particles in danger zone 600-700mm\n', sum(lost_zone));
        % Check fields at these positions
        Ez_check = interp2(z, r, Ez_capped, z_check(lost_zone), r_active(lost_zone), 'linear', 0);
        if any(isnan(Ez_check)) || all(Ez_check == 0)
            fprintf('  WARNING: Bad field interpolation at z=600-700mm!\n');
        end
    end
end
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
    
    % Store diagnostics
    n_active_history(it) = n_active;
%%%%%%%%%%%%%%%%%%%%%%%% Update 01.23.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== ION DIAGNOSTICS UPDATE (EVERY TIMESTEP) ====================
% Update ion diagnostics at EVERY timestep for smooth plotting
% This is computationally cheap (just sum operations) and eliminates plotting issues
if ENABLE_ION_ACCUMULATION == true
    total_ions_on_grid = sum(ion_density_grid(:));
    ion_diag.total_ions_vs_time(it) = total_ions_on_grid * ion_physics.superparticle_weight;
    ion_diag.peak_density_vs_time(it) = max(ion_density_grid(:)) * ion_physics.superparticle_weight;
end
%% ==================== END ION DIAGNOSTICS UPDATE ====================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ===== ADD THIS ENTIRE BLOCK HERE =====
% RMS radius calculation with debug
if mod(it, diag_interval) == 0 && n_active > 0
    active_idx = find(active_particles);
    z_active = z_particles(active_idx);
    r_active = r_particles(active_idx);
    
    % Debug first slice only
    if it == diag_interval  % First collection
        fprintf('  First diagnostic collection:\n');
        fprintf('  Active particles: %d\n', length(active_idx));
        fprintf('  Z range: %.1f-%.1f mm\n', min(z_active)*1000, max(z_active)*1000);
    end
    
    for iz = 1:n_z_diagnostic
        z_slice = z_diagnostic(iz);
        in_slice = abs(z_active - z_slice) < 0.005;
        if sum(in_slice) > 10
            r_slice = r_active(in_slice);
            r_rms_history(it, iz) = sqrt(mean(r_slice.^2));
            n_particles_vs_z(it, iz) = sum(in_slice);
            
            % Debug first successful collection
            if it == diag_interval && sum(in_slice) > 10
                fprintf('    Slice at z=%.1fmm: %d particles, RMS=%.1fmm\n', ...
                        z_slice*1000, sum(in_slice), sqrt(mean(r_slice.^2))*1000);
                break;  % Just show first successful slice
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BUT ALSO ADD BACK the RMS collection code (uncomment and modify):
% RMS radius calculation - ADD THIS BACK
if mod(it, diag_interval) == 0 && n_active > 0
    % Need to re-find active_idx if not already found
    if ~exist('active_idx', 'var') || isempty(active_idx)
        active_idx = find(active_particles);
    end
    z_active = z_particles(active_idx);
    r_active = r_particles(active_idx);
    
    for iz = 1:n_z_diagnostic
        z_slice = z_diagnostic(iz);
        % Find particles within ±5mm of this z position
        in_slice = abs(z_active - z_slice) < 0.005;
        if sum(in_slice) > 10  % Need minimum particles for statistics
            r_slice = r_active(in_slice);
            r_rms_history(it, iz) = sqrt(mean(r_slice.^2));
            n_particles_vs_z(it, iz) = sum(in_slice);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Replace your current debug section (around line 432) with this expanded version:
% Debug: Check for particles disappearing and field continuity
if mod(it, 100) == 0 && n_active > 0
    z_check = z_particles(active_idx);
    r_check = r_particles(active_idx);
    
    % Check multiple danger zones
    danger_zones = [
        struct('min', 0.3, 'max', 0.4, 'name', 'Gap exit'),...
        struct('min', 0.6, 'max', 0.7, 'name', 'Injector end'),...
        struct('min', 1.0, 'max', 1.1, 'name', 'Near Sol3')...
         ];
    
    for dz = 1:length(danger_zones)
        in_zone = z_check > danger_zones(dz).min & z_check < danger_zones(dz).max;
        if any(in_zone)
            fprintf('  DEBUG: %d particles in %s (%.0f-%.0f mm)\n', ...
                    sum(in_zone), danger_zones(dz).name, ...
                    danger_zones(dz).min*1000, danger_zones(dz).max*1000);
            
            % Check field values
            Ez_test = interp2(z, r, Ez_capped, z_check(in_zone), r_check(in_zone), 'linear', 0);
            Er_test = interp2(z, r, Er_capped, z_check(in_zone), r_check(in_zone), 'linear', 0);
            
            if any(isnan(Ez_test)) || any(isnan(Er_test))
                fprintf('    WARNING: NaN fields detected!\n');
            elseif all(abs(Ez_test) < 1e4) && all(abs(Er_test) < 1e4) % Changed up from 1e3
                fprintf('    WARNING: Very weak fields (<%d V/m)!\n', 10000); % Changed up from 1000
            end
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Capture snapshots
    if ENABLE_SNAPSHOTS == true && any(abs(current_t - snapshot_times) < dt/2)
        snapshot_count = snapshot_count + 1;
        active_idx = find(active_particles);
        drift_idx = active_idx(z_particles(active_idx) > 0.254);
        
        snapshot_data(snapshot_count).time = current_t;
        snapshot_data(snapshot_count).z = z_particles(drift_idx);
        snapshot_data(snapshot_count).r = r_particles(drift_idx);
        snapshot_data(snapshot_count).pz = pz_particles(drift_idx);
        snapshot_data(snapshot_count).pr = pr_particles(drift_idx);
        snapshot_data(snapshot_count).gamma = gamma_particles(drift_idx);
        snapshot_data(snapshot_count).n_particles = length(drift_idx);
        
        fprintf('  [Snapshot %d at %.1f ns: %d particles]\n', ...
                snapshot_count, current_t*1e9, length(drift_idx));
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Inside main loop, around where snapshots are taken
if it == 5500  % Save data for Twiss analysis
    saved_particles = struct();
    saved_particles.z = z_particles;
    saved_particles.r = r_particles;
    saved_particles.pr = pr_particles;
    saved_particles.pz = pz_particles;
    saved_particles.gamma = gamma_particles;
    saved_particles.active = active_particles;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%% Updated STEP 3 MULTI_SNAPSHOT %%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== MULTI-SNAPSHOT CAPTURE IN MAIN LOOP ====================
 if ENABLE_BETATRON_AVERAGING == true

        if ENABLE_MULTIPULSE == true
        %% ===== MULTI-PULSE MODE: Capture P1 and P2 snapshots =====
    
        % Capture Pulse 1 snapshots
        for is = 1:N_SNAPSHOTS
                 if abs(current_t - SNAPSHOT_P1_TIMES(is)) < dt/2
                    if isempty(snapshot_p1{is})
                    fprintf('\n=== Capturing Pulse 1 Snapshot %d/%d at t=%.1f ns ===\n', ...
                            is, N_SNAPSHOTS, current_t*1e9);
                    
                    active_idx = find(active_particles);
                    snapshot_p1{is} = struct();
                    snapshot_p1{is}.z = z_particles(active_idx);
                    snapshot_p1{is}.r = r_particles(active_idx);
                    snapshot_p1{is}.pr = pr_particles(active_idx);
                    snapshot_p1{is}.pz = pz_particles(active_idx);
                    snapshot_p1{is}.ptheta = ptheta_particles(active_idx);
                    snapshot_p1{is}.gamma = gamma_particles(active_idx);
                    snapshot_p1{is}.weight = weight_particles(active_idx);
                    snapshot_p1{is}.time = current_t;
                    snapshot_p1{is}.n_total = length(active_idx);
                    
                    snapshot_p1_count = snapshot_p1_count + 1;
                    fprintf('  Particles: %d | Progress: %d/%d snapshots\n', ...
                            length(active_idx), snapshot_p1_count, N_SNAPSHOTS);
                    end
                 end
        end


        
        % Capture Pulse 2 snapshots  
        for is = 1:N_SNAPSHOTS
            if abs(current_t - SNAPSHOT_P2_TIMES(is)) < dt/2
                if isempty(snapshot_p2{is})
                    fprintf('\n=== Capturing Pulse 2 Snapshot %d/%d at t=%.1f ns ===\n', ...
                            is, N_SNAPSHOTS, current_t*1e9);
                    
                    active_idx = find(active_particles);
                    snapshot_p2{is} = struct();
                    snapshot_p2{is}.z = z_particles(active_idx);
                    snapshot_p2{is}.r = r_particles(active_idx);
                    snapshot_p2{is}.pr = pr_particles(active_idx);
                    snapshot_p2{is}.pz = pz_particles(active_idx);
                    snapshot_p2{is}.ptheta = ptheta_particles(active_idx);
                    snapshot_p2{is}.gamma = gamma_particles(active_idx);
                    snapshot_p2{is}.weight = weight_particles(active_idx);
                    snapshot_p2{is}.time = current_t;
                    snapshot_p2{is}.n_total = length(active_idx);
                    
                    snapshot_p2_count = snapshot_p2_count + 1;
                    fprintf('  Particles: %d | Progress: %d/%d snapshots\n', ...
                            length(active_idx), snapshot_p2_count, N_SNAPSHOTS);
                end
            end
        end
%%%%%%%%%%%%%%%%%%%%%%%%  added Pulse 3 shnapshots %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Capture Pulse 3 snapshots (NEW - add after P2 block)
        for is = 1:N_SNAPSHOTS
           if abs(current_t - SNAPSHOT_P3_TIMES(is)) < dt/2
              if isempty(snapshot_p3{is})
            fprintf('\n=== Capturing Pulse 3 Snapshot %d/%d at t=%.1f ns ===\n', ...
                    is, N_SNAPSHOTS, current_t*1e9);
            
            active_idx = find(active_particles);
            snapshot_p3{is} = struct();
            snapshot_p3{is}.z = z_particles(active_idx);
            snapshot_p3{is}.r = r_particles(active_idx);
            snapshot_p3{is}.pr = pr_particles(active_idx);
            snapshot_p3{is}.pz = pz_particles(active_idx);
            snapshot_p3{is}.ptheta = ptheta_particles(active_idx);
            snapshot_p3{is}.gamma = gamma_particles(active_idx);
            snapshot_p3{is}.weight = weight_particles(active_idx);
            snapshot_p3{is}.time = current_t;
            snapshot_p3{is}.n_total = length(active_idx);
            
            snapshot_p3_count = snapshot_p3_count + 1;
            fprintf('  Particles: %d | Progress: %d/%d snapshots\n', ...
                    length(active_idx), snapshot_p3_count, N_SNAPSHOTS);
              end
           end
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%% Added 02.06.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %STEP 5: P4 Snapshot Collection in Main Loop
        %Location: Line ~1135 (after P3 snapshot block)
        %Action: Add Pulse 4 snapshot capture
        % Capture Pulse 4 snapshots (NEW - add after P3 block)
        for is = 1:N_SNAPSHOTS
            if abs(current_t - SNAPSHOT_P4_TIMES(is)) < dt/2
            if isempty(snapshot_p4{is})
                fprintf('\n=== Capturing Pulse 4 Snapshot %d/%d at t=%.1f ns ===\n', ...
                     is, N_SNAPSHOTS, current_t*1e9);
            
            active_idx = find(active_particles);
            snapshot_p4{is} = struct();
            snapshot_p4{is}.z = z_particles(active_idx);
            snapshot_p4{is}.r = r_particles(active_idx);
            snapshot_p4{is}.pr = pr_particles(active_idx);
            snapshot_p4{is}.pz = pz_particles(active_idx);
            snapshot_p4{is}.ptheta = ptheta_particles(active_idx);
            snapshot_p4{is}.gamma = gamma_particles(active_idx);
            snapshot_p4{is}.weight = weight_particles(active_idx);
            snapshot_p4{is}.time = current_t;
            snapshot_p4{is}.n_total = length(active_idx);
            
            snapshot_p4_count = snapshot_p4_count + 1;
            fprintf('  Particles: %d | Progress: %d/%d snapshots\n', ...
                    length(active_idx), snapshot_p4_count, N_SNAPSHOTS);
                end
             end
         end   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end   
  end
if ENABLE_BETATRON_AVERAGING == true
       if ENABLE_MULTIPULSE == false
        %% ===== SINGLE-PULSE MODE: Capture EARLY and LATE beam snapshots =====
        
        % Capture EARLY beam snapshots (minimal ion accumulation)
        for is = 1:N_SNAPSHOTS_EARLY
            if abs(current_t - SNAPSHOT_EARLY_TIMES(is)) < dt/2
                if isempty(snapshot_early{is})
                    active_idx = find(active_particles);
                    snapshot_early{is} = struct();
                    snapshot_early{is}.z = z_particles(active_idx);
                    snapshot_early{is}.r = r_particles(active_idx);
                    snapshot_early{is}.pr = pr_particles(active_idx);
                    snapshot_early{is}.pz = pz_particles(active_idx);
                    snapshot_early{is}.ptheta = ptheta_particles(active_idx);
                    snapshot_early{is}.gamma = gamma_particles(active_idx);
                    snapshot_early{is}.weight = weight_particles(active_idx);
                    snapshot_early{is}.time = current_t;
                    snapshot_early{is}.n_total = length(active_idx);
                    
                    snapshot_early_count = snapshot_early_count + 1;
                    
                    % Get current ion count
                    current_ions = sum(ion_density_grid(:)) * ion_physics.superparticle_weight;
                    
                    fprintf('\n=== Capturing EARLY Beam Snapshot %d/%d at t=%.1f ns ===\n', ...
                            is, N_SNAPSHOTS_EARLY, current_t*1e9);
                    fprintf('  Particles: %d | Ions: %.1e | Progress: %d/%d\n', ...
                            length(active_idx), current_ions, snapshot_early_count, N_SNAPSHOTS_EARLY);
                end
            end
        end
        
        % Capture LATE beam snapshots (with ion focusing effect)
        for is = 1:N_SNAPSHOTS_LATE
            if abs(current_t - SNAPSHOT_LATE_TIMES(is)) < dt/2
                if isempty(snapshot_late{is})
                    active_idx = find(active_particles);
                    snapshot_late{is} = struct();
                    snapshot_late{is}.z = z_particles(active_idx);
                    snapshot_late{is}.r = r_particles(active_idx);
                    snapshot_late{is}.pr = pr_particles(active_idx);
                    snapshot_late{is}.pz = pz_particles(active_idx);
                    snapshot_late{is}.ptheta = ptheta_particles(active_idx);
                    snapshot_late{is}.gamma = gamma_particles(active_idx);
                    snapshot_late{is}.weight = weight_particles(active_idx);
                    snapshot_late{is}.time = current_t;
                    snapshot_late{is}.n_total = length(active_idx);
                    
                    snapshot_late_count = snapshot_late_count + 1;
                    
                    current_ions = sum(ion_density_grid(:)) * ion_physics.superparticle_weight;
                    
                    fprintf('\n=== Capturing LATE Beam Snapshot %d/%d at t=%.1f ns ===\n', ...
                            is, N_SNAPSHOTS_LATE, current_t*1e9);
                    fprintf('  Particles: %d | Ions: %.1e (ION FOCUSING!) | Progress: %d/%d\n', ...
                            length(active_idx), current_ions, snapshot_late_count, N_SNAPSHOTS_LATE);
                end
               end
        end

%%%%%%%%%%%%%%%%%%%%%%%%% Added Pulse 1 SNAPSHOTS for Betatron Averaging %%%%%%%%%%%%%%% 
%% ===== SINGLE-PULSE MODE: Also capture P1 mid-pulse snapshots =====
if ENABLE_BETATRON_AVERAGING == true && ENABLE_MULTIPULSE == false
    % Capture P1 snapshots at mid-pulse times (for betatron averaging)
    % These use SNAPSHOT_P1_TIMES which is already defined in single-pulse mode
    for is = 1:N_SNAPSHOTS
        if abs(current_t - SNAPSHOT_P1_TIMES(is)) < dt/2
            if isempty(snapshot_p1{is})
                fprintf('\n=== Capturing P1 Snapshot %d/%d at t=%.1f ns (single-pulse) ===\n', ...
                        is, N_SNAPSHOTS, current_t*1e9);
                
                active_idx = find(active_particles);
                snapshot_p1{is} = struct();
                snapshot_p1{is}.z = z_particles(active_idx);
                snapshot_p1{is}.r = r_particles(active_idx);
                snapshot_p1{is}.pr = pr_particles(active_idx);
                snapshot_p1{is}.pz = pz_particles(active_idx);
                snapshot_p1{is}.ptheta = ptheta_particles(active_idx);
                snapshot_p1{is}.gamma = gamma_particles(active_idx);
                snapshot_p1{is}.weight = weight_particles(active_idx);
                snapshot_p1{is}.time = current_t;
                snapshot_p1{is}.n_total = length(active_idx);
                
                snapshot_p1_count = snapshot_p1_count + 1;
                
                % Get ion count at this moment
                current_ions = sum(ion_density_grid(:)) * ion_physics.superparticle_weight;
                
                fprintf('  Particles: %d | Ions: %.1e | Progress: %d/%d\n', ...
                        length(active_idx), current_ions, snapshot_p1_count, N_SNAPSHOTS);
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          end  % End ENABLE_MULTIPULSE check
end  % End ENABLE_BETATRON_AVERAGING check
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% added 10.16.2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CORRECTED SLICE ANALYSIS AT STEADY STATE Pulse 1
% Replace the existing slice analysis section with this version
% This captures beam data during the pulse flat-top, not after it ends

%% ==================== CAPTURE BEAM STATE AT STEADY STATE Pulse 1 ====================
% Add this inside the main loop at timestep 4000 (mid-pulse, t=189ns)
if it == 5500  % Mid-pulse steady state 15ns + 40ns
    fprintf('\n=== Capturing Steady-State Beam for Slice Analysis at t=%.1f ns ===\n', current_t*1e9);
    
    % Save complete beam state for slice analysis
    active_idx = find(active_particles);
    steady_state_beam = struct();
    steady_state_beam.z = z_particles(active_idx);
    steady_state_beam.r = r_particles(active_idx);
    steady_state_beam.pr = pr_particles(active_idx);
    steady_state_beam.pz = pz_particles(active_idx);
    steady_state_beam.ptheta = ptheta_particles(active_idx);
    steady_state_beam.gamma = gamma_particles(active_idx);
    steady_state_beam.weight = weight_particles(active_idx);
    steady_state_beam.n_total = length(active_idx);
    steady_state_beam.time = current_t;
    
    % Calculate velocities for current calculations
    steady_state_beam.vz = pz_particles(active_idx) ./ (gamma_particles(active_idx) * m_e);
    
    fprintf('  Total active particles captured: %d\n', steady_state_beam.n_total);
    fprintf('  Z range: %.1f to %.1f mm\n', min(steady_state_beam.z)*1000, max(steady_state_beam.z)*1000);
end

%%%%%%%%%%%%%%%%%%%%%% added 10.08.2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Complete current conservation check
if mod(it, 1000) == 0 && it > 1000
    % Total charge in system
    active_idx = active_particles;
    charge_in_flight = sum(weight_particles(active_idx)) * e_charge;
    
    % Calculate cumulative charge emitted (simple integration)
    if it > 1
        total_emitted = trapz(t(1:it), I_emit(1:it));
    else
        total_emitted = 0;
    end
    
    % Calculate cumulative charge collected
    charge_collected_total = particles_transmitted * mean(weight_particles(weight_particles>0)) * e_charge;
    
    % Conservation check
    fprintf('\n  [CHARGE AUDIT] at %.1f ns:', current_t*1e9);
    fprintf('\n    Emitted: %.3f µC', total_emitted*1e6);
    fprintf('\n    In flight: %.3f µC', charge_in_flight*1e6);
    fprintf('\n    Collected: %.3f µC', charge_collected_total*1e6);
    
    % Check for leaks
    charge_lost = total_emitted - charge_in_flight - charge_collected_total;
    if abs(charge_lost) > 0.01 * total_emitted
        fprintf('\n    WARNING: %.3f µC unaccounted!', charge_lost*1e6);
    end
end
end  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%  END OF THE MAIN LOOP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% ==================== SAVE WORKSPACE & RUN DIAGNOSTICS ====================
% Save the complete workspace for diagnostics
save('simulation_workspace.mat', '-v7.3');
fprintf('\nWorkspace saved to simulation_workspace.mat\n');

% Run post-processing diagnostics
% (Uncomment the line below to run diagnostics automatically,
%  or run Injector_Model_Diagnostics.m separately)
% run('Injector_Model_Diagnostics.m');
