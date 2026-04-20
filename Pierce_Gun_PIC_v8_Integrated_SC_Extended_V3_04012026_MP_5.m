%% Pierce_Gun_PIC_V3_MP_5.m
%% Multi-Pulse extension of V3 — created 2026-04-06
%% Based on Pierce_Gun_PIC_v8_Integrated_SC_Extended_V3_04012026.m
%% Adds support for 1, 2, 3, or 4 pulse operation modes
%% All V3 fixes retained:
%%   [FIX-11] Single position update, all crossing detection inside push block
%%   [FIX-10] particle_KE recorded at crossing, exited particles removed immediately
%%   gamma_particles updated inside push block
twiss_p1_averaged
clear all; close all; clc;

wall_clock_start = tic;   %% start wall timer — used by save block

fprintf('\n=== Pierce_Gun_PIC_v8_Integrated_SC_Extended_V3_04012026_MP_5.m ===\n');
%fprintf('Multi-pulse mode, PRODUCTION, SC enabled\n\n');

%% ==================== MASTER SWITCHES ====================
simulation_mode      = 'PRODUCTION';
ENABLE_SPACE_CHARGE  = true;
ENABLE_SC            = ENABLE_SPACE_CHARGE;   %% ← ADD THIS LINE — alias for save block
ENABLE_MULTIPULSE           = true;   % Master: true = multi-pulse, false = single-pulse
%ENABLE_INTERPULSE_SNAPSHOT  = true;   % Inter-pulse electron cloud capture
ENABLE_BETATRON_AVERAGING   = true;
ENABLE_GAS_SCATTERING       = true;
ENABLE_ION_ACCUMULATION     = true;
ENABLE_SNAPSHOTS            = true;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% User Control Save Mode %%%%%%%%%%%%%%%%%%%
%% ==================== TEST IDENTIFICATION AND SAVE CONFIGURATION ====================
%% USER EDITABLE — update before each run

%% --- Machine identity ---
%TEST_MACHINE = 'LAPTOP';        %% 'LAPTOP' or 'HPC'

%% --- Independent test counters per machine ---
%TEST_NUMBER_LAPTOP = 22;        %% ← increment each new laptop run
%TEST_NUMBER_HPC    = 7;         %% ← increment each new HPC run
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TEST ID  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ================================================================
%% TEST IDENTIFICATION — set once at top of script
%% ================================================================
%TEST_NUMBER         = 27;
TEST_NUMBER_LAPTOP  = 30;
TEST_NUMBER_HPC     = 50;
%TEST_ID             = sprintf('L%03d', TEST_NUMBER);   %% 'L024'
TEST_MACHINE        = 'LAPTOP';  % Was before 'missionpeak'
SAVE_MODE           = 'DIAGNOSTICS';
CSV_MODE            = 'PARENT';
%% --- Save mode ---
%% 'HANDOFF'     : all particle arrays all pulses + CSV + figures
%% 'FULL'        : key variables + diagnostics + CSV + figures
%% 'DIAGNOSTICS' : metrics .mat + CSV + interactive figure save  ← default
%% 'MINIMAL'     : CSV + metrics .mat only, no figures
%% 'NONE'        : nothing saved, workspace open, path printed
%% --- Master CSV location ---
%% 'LOCAL'  : CSV written inside each test folder only
%% 'PARENT' : one master CSV in parent directory, one row per run appended


%% ---- DO NOT EDIT BELOW THIS LINE IN THIS SECTION ----
switch upper(TEST_MACHINE)
    case 'LAPTOP'
        TEST_NUMBER = TEST_NUMBER_LAPTOP;
        TEST_PREFIX = 'L';
    case 'HPC'
        TEST_NUMBER = TEST_NUMBER_HPC;
        TEST_PREFIX = 'H';
    otherwise
        warning('Unknown TEST_MACHINE "%s" — defaulting to LAPTOP', ...
                TEST_MACHINE);
        TEST_NUMBER = TEST_NUMBER_LAPTOP;
        TEST_PREFIX = 'L';
end
TEST_ID = sprintf('%s%03d', TEST_PREFIX, TEST_NUMBER);

fprintf('=== TEST IDENTIFICATION ===\n');
fprintf('  Machine:   %s\n',  TEST_MACHINE);
fprintf('  Test ID:   %s\n',  TEST_ID);
fprintf('  Save mode: %s\n',  SAVE_MODE);
fprintf('  CSV mode:  %s\n',  CSV_MODE);
fprintf('===========================\n\n');
%% ==================== END TEST IDENTIFICATION ====================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== MULTI-PULSE COUNT CONTROL ====================
%% Set n_pulses_config to 1, 2, 3, or 4 to select operating mode
n_pulses_config = 2;   % OPTIONS: 1 | 2 | 3 | 4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ENABLE_MULTIPULSE == true
    fprintf('  PIERCE GUN PIC V3  MULTI-PULSE (n=%d), SC ENABLED\n', n_pulses_config);
    ENABLE_INTERPULSE_SNAPSHOT  = true;   % Inter-pulse electron cloud capture
else
    fprintf('  PIERCE GUN PIC V3  SINGLE PULSE, SC ENABLED\n');
    ENABLE_INTERPULSE_SNAPSHOT  = false;   % Inter-pulse electron cloud capture
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== DIAGNOSTIC TRACKING VARIABLES ====================
step_history      = [];
wall_loss_history = [];
fprintf('Diagnostic tracking initialized.\n');

%% ==================== SOLENOID FIELD STRENGTHS ====================
solenoid1_field  = -0.0450;
solenoid2_field  =  0.0185;
solenoid3_field  =  0.0070;
solenoid4_field  =  0.0050;
solenoid5_field  =  0.0020;
solenoid7_field  =  0.0015;
solenoid8_field  =  0.0013;
solenoid9_field  =  0.0012;
solenoid10_field =  0.0012;
solenoid11_field =  0.0012;
solenoid12_field =  0.0012;
solenoid14_field =  0.0012;
solenoid15_field =  0.0012;
solenoid16_field =  0.0012;
solenoid17_field =  0.0012;
solenoid18_field =  0.0012;
solenoid19_field =  0.0012;
solenoid20_field =  0.0012;
solenoid21_field =  0.0012;
solenoid22_field =  0.0012;
solenoid23_field =  0.0012;
solenoid24_field =  0.0012;
solenoid25_field =  0.0012;
solenoid26_field =  0.0012;
solenoid27_field =  0.0012;
solenoid28_field =  0.0012;
solenoid29_field =  0.0012;
solenoid30_field =  0.0012;
solenoid31_field =  0.0012;
solenoid32_field =  0.0012;
solenoid33_field =  0.0012;
solenoid34_field =  0.0012;
solenoid35_field =  0.0012;
solenoid36_field =  0.0012;
solenoid38_field =  0.0012;
solenoid39_field =  0.0012;
solenoid40_field =  0.0012;
solenoid41_field =  0.0015;
solenoid42_field =  0.0015;
solenoid43_field =  0.0015;
solenoid45_field =  0.0015;
solenoid46_field =  0.0015;
solenoid47_field =  0.0020;
solenoid48_field =  0.0035;
solenoid49_field =  0.0075;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Better version 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== SNAPSHOT TIMING ====================
%% Pulse timing reference:
%%   P1: start=150ns  flat-top=165-245ns  injector_full=195-245ns
%%   P2: start=350ns  flat-top=365-445ns  injector_full=395-445ns
%%   P3: start=550ns  flat-top=565-645ns  injector_full=595-645ns
%%   P4: start=750ns  flat-top=765-845ns  injector_full=795-845ns
%%   Flight time cathode→exit ≈ 30ns
%%   Capture window = 50ns per pulse, 11 snapshots at 5ns spacing

%% Mid-window steady-state capture times — one per pulse
TWISS_PULSE_TIMES = [220e-9, 420e-9, 620e-9, 820e-9];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% And initialize in pre-loop setup:
%ion_diag.snapshot_grids = cell(1, 4); %defined at line 488
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Convenience aliases — backward compatibility
TWISS_PULSE1_TIME = TWISS_PULSE_TIMES(1);   % 220ns — P1 mid capture window
TWISS_PULSE2_TIME = TWISS_PULSE_TIMES(2);   % 420ns — P2 mid capture window
TWISS_PULSE3_TIME = TWISS_PULSE_TIMES(3);   % 620ns — P3 mid capture window
TWISS_PULSE4_TIME = TWISS_PULSE_TIMES(4);   % 820ns — P4 mid capture window

if ENABLE_MULTIPULSE == true
    %% 11 snapshots per pulse — 5ns spacing — full 50ns capture window
    SNAPSHOT_P1_TIMES = (195:5:245) * 1e-9;   % 195,200,...,245 ns
    SNAPSHOT_P2_TIMES = (395:5:445) * 1e-9;   % 395,400,...,445 ns
    SNAPSHOT_P3_TIMES = (595:5:645) * 1e-9;   % 595,600,...,645 ns
    SNAPSHOT_P4_TIMES = (795:5:845) * 1e-9;   % 795,800,...,845 ns
    N_SNAPSHOTS       = 11;

    %% Adaptive cell array — only active pulses included
    PULSE_SNAP_ARRAY   = {SNAPSHOT_P1_TIMES, SNAPSHOT_P2_TIMES, ...
                          SNAPSHOT_P3_TIMES, SNAPSHOT_P4_TIMES};
%%%%%%%%%%%%%%%%%%%%%%% Those lines plaved later 294-300 %%%%%%%%%%%%%%%%%%%%%%% 
    %ALL_SNAPSHOT_TIMES = cell(1, pulse_config.n_pulses);
    %for ip = 1:pulse_config.n_pulses
    %   ALL_SNAPSHOT_TIMES{ip} = PULSE_SNAP_ARRAY{ip};
    %end

    %% Generic drift snapshot — one per pulse at mid-window
    %snapshot_times = TWISS_PULSE_TIMES(1:pulse_config.n_pulses);

    %% EARLY/LATE not used in multi-pulse mode
    N_SNAPSHOTS_EARLY    = 0;
    N_SNAPSHOTS_LATE     = 0;
    SNAPSHOT_EARLY_TIMES = [];
    SNAPSHOT_LATE_TIMES  = [];
%%%%%%%%%%%%%%%%%%%%%%% Those lines placed later 301-309 %%%%%%%%%%%%%%%%%%
    %fprintf('=== MULTI-PULSE BETATRON AVERAGING MODE ===\n');
    %fprintf('Pulses: %d  |  Snapshots/pulse: %d  |  Spacing: 5 ns\n', ...
    %        pulse_config.n_pulses, N_SNAPSHOTS);
    %for ip = 1:pulse_config.n_pulses
    %    fprintf('  P%d: capture window %.0f-%.0f ns  |  Twiss at %.0f ns\n', ...
    %            ip, ...
    %            ALL_SNAPSHOT_TIMES{ip}(1)*1e9, ...
    %            ALL_SNAPSHOT_TIMES{ip}(end)*1e9, ...
    %            TWISS_PULSE_TIMES(ip)*1e9);
    %end

else
    %% Single-pulse: 11 snapshots, 3ns spacing
    %% EARLY = low ion load (190-220ns)
    %% LATE  = high ion load (220-250ns)
    %% P1    = mid-pulse betatron (205-235ns)
    SNAPSHOT_EARLY_TIMES = [190e-9,193e-9,196e-9,199e-9,202e-9, ...
                            205e-9,208e-9,211e-9,214e-9,217e-9,220e-9];
    SNAPSHOT_LATE_TIMES  = [220e-9,223e-9,226e-9,229e-9,232e-9, ...
                            235e-9,238e-9,241e-9,244e-9,247e-9,250e-9];
    SNAPSHOT_P1_TIMES    = [205e-9,208e-9,211e-9,214e-9,217e-9, ...
                            220e-9,223e-9,226e-9,229e-9,232e-9,235e-9];
    N_SNAPSHOTS          = 11;
    N_SNAPSHOTS_EARLY    = length(SNAPSHOT_EARLY_TIMES);
    N_SNAPSHOTS_LATE     = length(SNAPSHOT_LATE_TIMES);

    %% Generic drift snapshot — 4 times across P1 capture window
    snapshot_times = [195e-9, 215e-9, 235e-9, 255e-9];

    %% Single entry for loop compatibility
    ALL_SNAPSHOT_TIMES   = {SNAPSHOT_P1_TIMES};

    fprintf('=== SINGLE-PULSE INTRA-PULSE ION FOCUSING MODE ===\n');
    fprintf('Early snapshots: %d  (t=%.0f-%.0f ns)\n', ...
            N_SNAPSHOTS_EARLY, ...
            SNAPSHOT_EARLY_TIMES(1)*1e9, SNAPSHOT_EARLY_TIMES(end)*1e9);
    fprintf('Late  snapshots: %d  (t=%.0f-%.0f ns)\n', ...
            N_SNAPSHOTS_LATE, ...
            SNAPSHOT_LATE_TIMES(1)*1e9, SNAPSHOT_LATE_TIMES(end)*1e9);
    fprintf('P1   snapshots: %d  (t=%.0f-%.0f ns)\n', ...
            N_SNAPSHOTS, ...
            SNAPSHOT_P1_TIMES(1)*1e9, SNAPSHOT_P1_TIMES(end)*1e9);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== LOAD RESOURCES ====================
fprintf('\n================================================================\n');
fprintf('  PIERCE GUN PIC V3 — SINGLE PULSE, SC ENABLED\n');
fprintf('================================================================\n\n');

if ~exist('pierce_gun_lego_theta68_gap0_recess0.mat','file')
    error('Geometry file not found.');
end
if ~exist('pierce_gun_field_solution_ready.mat','file')
    error('Field solution not found.');
end

fprintf('Loading resources...\n');
load('pierce_gun_lego_theta68_gap0_recess0.mat');
load('pierce_gun_field_solution_ready.mat');
fprintf('  Geometry loaded (mesh: %dx%d)\n', nz, nr);
fprintf('  Fields loaded   (max E: %.1f MV/m)\n', max(abs(Ez_capped(:)))/1e6);

%% ==================== VOLTAGE BOUNDARY CHECK ====================
fprintf('\n=== Voltage boundary conditions ===\n');
fprintf('  V_cathode    = %.0f V  (%.0f kV)\n', V_cathode, V_cathode/1e3);
fprintf('  V_anode      = %.0f V  (%.0f kV)\n', V_anode,   V_anode/1e3);
fprintf('  V_total      = %.0f V  (%.0f kV)\n', ...
        V_anode-V_cathode, (V_anode-V_cathode)/1e3);
fprintf('  gap_distance = %.1f mm\n', gap_distance*1000);
fprintf('  E_analytical = %.3f MV/m\n', ...
        abs(V_anode-V_cathode)/gap_distance/1e6);
fprintf('  Expected: V_cathode=-850000, V_anode=+850000, V_total=1700000\n');

%% ==================== CATHODE FIELD DIAGNOSTIC ====================
fprintf('\n=== Cathode Field Analysis ===\n');
iz_cath_search = find(z >= 0 & z <= 0.010);
if ~isempty(iz_cath_search)
    Ez_cath_profile = abs(Ez_capped(1, iz_cath_search));
    [E_peak_cath, peak_idx] = max(Ez_cath_profile);
    z_peak_cath = z(iz_cath_search(peak_idx));
    fprintf('  Peak cathode field : %.2f MV/m at z=%.1f mm\n', ...
            E_peak_cath/1e6, z_peak_cath*1000);
    fprintf('  Analytical gap field: %.2f MV/m\n', ...
            abs(V_anode-V_cathode)/gap_distance/1e6);
    E_CATHODE_BASE_DETECTED = E_peak_cath;
else
    E_CATHODE_BASE_DETECTED = 5.37e6;
    fprintf('  WARNING: cathode region not found — using fallback %.2f MV/m\n', ...
            E_CATHODE_BASE_DETECTED/1e6);
end

%% ==================== FIELD ARRAY DIAGNOSTICS ====================
fprintf('\n=== Field Array Diagnostics ===\n');
fprintf('  z: %.1f to %.1f mm  (%d pts)\n', z(1)*1000, z(end)*1000, length(z));
fprintf('  r: %.1f to %.1f mm  (%d pts)\n', r(1)*1000, r(end)*1000, length(r));
fprintf('  Ez_capped: %dx%d\n', size(Ez_capped,1), size(Ez_capped,2));
fprintf('  Er_capped: %dx%d\n', size(Er_capped,1), size(Er_capped,2));

Ez_axis = Ez_capped(1,:);
for zc = [250,350,500,1000,2000,4000,8000]
    [~,iz] = min(abs(z*1000 - zc));
    fprintf('  Ez at z=%4d mm: %+.3e V/m\n', zc, Ez_axis(iz));
end

%% On-axis potential integral (field normalization check)
iz0 = find(z >= 0.0,   1,'first');
izD = find(z >= 0.500, 1,'first');
V_integral = -trapz(z(iz0:izD), Ez_capped(1,iz0:izD));
fprintf('  Potential rise z=0→500mm: %+.4f MV  (expected +1.694 MV)\n', ...
        V_integral/1e6);

%% ==================== PHYSICAL CONSTANTS ====================
c        = 299792458;
e_charge = 1.602176634e-19;
m_e      = 9.10938356e-31;
eps0     = 8.854187817e-12;
k_B      = 1.380649e-23;

%% ==================== MODE CONFIGURATION ====================
switch simulation_mode
    case 'QUICK_TEST'
        dt             = 10e-12;
        base_particles = 20;
        base_weight    = 5e9;
        sc_interval    = 50;
        diag_interval  = 500;
    case 'OPTIMIZATION'
        dt             = 10e-12;
        base_particles = 50;
        base_weight    = 7e8;
        sc_interval    = 25;
        diag_interval  = 100;
    case 'PRODUCTION'
        dt             = 10e-12;
        base_particles = 100;
        base_weight    = 1e9;
        sc_interval    = 50;
        diag_interval  = 100;
end
fprintf('\nMode: %s  |  dt=%.0f ps  |  %d particles/step  |  weight=%.1e\n', ...
        simulation_mode, dt*1e12, base_particles, base_weight);

%% ==================== SIMULATION TIME REFERENCE (t_flight pre-computation) ====================
E_beam_ref    = 1.70e6;
gamma_ref     = 1 + E_beam_ref / (m_e*c^2/e_charge);
beta_ref      = sqrt(1 - 1/gamma_ref^2);
v_ref         = beta_ref * c;
t_flight      = 8.305 / v_ref;

%% ==================== PULSE CONFIGURATION ====================
if ENABLE_MULTIPULSE == true

    pulse_config             = struct();
    pulse_config.n_pulses    = n_pulses_config;

    ALL_SNAPSHOT_TIMES = cell(1, pulse_config.n_pulses);
    for ip = 1:pulse_config.n_pulses
        ALL_SNAPSHOT_TIMES{ip} = PULSE_SNAP_ARRAY{ip};
    end

    %% Generic drift snapshot — one per pulse at mid-window
    %snapshot_times = TWISS_PULSE_TIMES(1:pulse_config.n_pulses); %Redefined at the llne 596

    fprintf('=== MULTI-PULSE BETATRON AVERAGING MODE ===\n');
    fprintf('Pulses: %d  |  Snapshots/pulse: %d  |  Spacing: 5 ns\n', ...
            pulse_config.n_pulses, N_SNAPSHOTS);
    for ip = 1:pulse_config.n_pulses
        fprintf('  P%d: capture window %.0f-%.0f ns  |  Twiss at %.0f ns\n', ...
                ip, ...
                ALL_SNAPSHOT_TIMES{ip}(1)*1e9, ...
                ALL_SNAPSHOT_TIMES{ip}(end)*1e9, ...
                TWISS_PULSE_TIMES(ip)*1e9);
    end

    %% Pulse start times — automatically sized to n_pulses_config
    all_pulse_starts = [150e-9, 350e-9, 550e-9, 750e-9];
    pulse_config.pulse_starts = all_pulse_starts(1:pulse_config.n_pulses);

    pulse_config.rise_time   = 15e-9;
    pulse_config.flat_time   = 80e-9;
    pulse_config.fall_time   = 25e-9;

    %% Inter-pulse snapshot configuration
    %ENABLE_INTERPULSE_SNAPSHOT  = true; % already exis at the line 31
    all_interpulse_times = [349e-9, 549e-9, 749e-9];
    n_interpulse_snapshots      = pulse_config.n_pulses - 1;
    INTERPULSE_SNAPSHOT_TIMES   = all_interpulse_times(1:n_interpulse_snapshots);
    interpulse_clouds           = cell(n_interpulse_snapshots, 1);
    interpulse_capture_count    = 0;

    %% Timing window
    last_pulse_end = pulse_config.pulse_starts(end) + ...
                     pulse_config.rise_time + pulse_config.flat_time + pulse_config.fall_time;
    t_start        = pulse_config.pulse_starts(1) - 1e-9;
    margin_time    = 40e-9;
    t_end          = last_pulse_end + t_flight + margin_time;
    t_plot_min     = 145;
    t_plot_max     = t_end * 1e9;

    pulse_shape = @(t_curr) pulse_shape_multipulse(t_curr, pulse_config);

    fprintf('\n=== MULTI-PULSE MODE (n=%d) ===\n', pulse_config.n_pulses);
    fprintf('  Pulse starts: ');
    fprintf('%.0f ns  ', pulse_config.pulse_starts*1e9);
    fprintf('\n');
    fprintf('  Last pulse ends:   %.1f ns\n', last_pulse_end*1e9);
    fprintf('  Flight time:       %.1f ns  (beta=%.4f)\n', t_flight*1e9, beta_ref);
    fprintf('  Simulation end:    %.1f ns\n', t_end*1e9);

else

    pulse_config              = struct();
    pulse_config.n_pulses     = 1;
    pulse_config.pulse_starts = 150e-9;
    pulse_config.rise_time    = 15e-9;
    pulse_config.flat_time    = 80e-9;
    pulse_config.fall_time    = 25e-9;

    n_interpulse_snapshots    = 0;
    interpulse_clouds         = cell(0,1);
    interpulse_capture_count  = 0;

    pulse_end  = pulse_config.pulse_starts + pulse_config.rise_time + ...
                 pulse_config.flat_time    + pulse_config.fall_time;
    t_start    = pulse_config.pulse_starts - 1e-9;
    margin_time = 40e-9;
    t_end       = pulse_end + t_flight + margin_time;
    t_plot_min  = 149;
    t_plot_max  = t_end * 1e9;

    pulse_shape = @(t_curr) pulse_shape_func(t_curr, ...
                      pulse_config.pulse_starts, ...
                      pulse_config.rise_time, ...
                      pulse_config.flat_time, ...
                      pulse_config.fall_time);

    fprintf('\n=== SINGLE PULSE MODE ===\n');
    fprintf('  Pulse ends:      %.1f ns\n', pulse_end*1e9);
    fprintf('  Simulation end:  %.1f ns\n', t_end*1e9);

end

fprintf('\n=== Timing Summary ===\n');
fprintf('  t_start: %.1f ns\n', t_start*1e9);
fprintf('  t_end:   %.1f ns\n', t_end*1e9);

t  = t_start : dt : t_end;
nt = length(t);
t_ns=t.*1e9;
fprintf('  Time steps: %d  (dt=%.0f ps)\n', nt, dt*1e12);

%t_plot_min = t_plot_min;  %% already set above
%t_plot_max = t_plot_max;  %% already set above

%% ==================== SPACE CHARGE SETUP ====================
if ENABLE_SPACE_CHARGE
    sc_nz    = 1500;
    sc_nr    = 100;
    sc_z_min = -0.05;
    sc_z_max =  8.31;
    sc_r_max =  0.080;

    sc_z  = linspace(sc_z_min, sc_z_max, sc_nz);
    sc_r  = linspace(0,        sc_r_max, sc_nr);
    sc_dz = sc_z(2) - sc_z(1);
    sc_dr = sc_r(2) - sc_r(1);

    rho_grid = zeros(sc_nr, sc_nz);
    phi_grid = zeros(sc_nr, sc_nz);
    Ez_sc    = zeros(sc_nr, sc_nz);
    Er_sc    = zeros(sc_nr, sc_nz);

    sc_omega      = 1.85; % was 1.2 used before
    sc_iterations = 100; % was 100 applied before

    fprintf('\nSC grid: %dx%d  dz=%.1f mm  dr=%.2f mm\n', ...
            sc_nz, sc_nr, sc_dz*1000, sc_dr*1000);

    %% Meshgrids for applied-field interpolation
    [Z_grid, R_grid] = meshgrid(z, r);
    fprintf('Applied-field meshgrid: %dx%d\n', size(Z_grid,1), size(Z_grid,2));
else
    fprintf('\nSpace charge DISABLED\n');
    %% Still need Z_grid / R_grid for applied-field interpolation
    [Z_grid, R_grid] = meshgrid(z, r);
end
%%%%%%%%%%%%%%%%%%%%%%%% Added 03.30.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== FIELD INTERPOLATION PRE-COMPUTATION ====================
%% Step 1 — Add to Block 1 (once, after [Z_grid, R_grid] = meshgrid(z, r))
%% Replaces interp2 with direct index arithmetic — computed once at startup
app_nz = length(z);
app_nr = length(r);
app_dz = z(2) - z(1);
app_dr = r(2) - r(1);
app_z0 = z(1);
app_r0 = r(1);
fprintf('Field interp pre-computed: nz=%d  nr=%d  dz=%.4f mm  dr=%.4f mm\n', ...
        app_nz, app_nr, app_dz*1000, app_dr*1000);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== GAS SCATTERING ====================
if ENABLE_GAS_SCATTERING
    gas_params = struct();
    gas_params.P          = 1e-9 * 133.322;
    gas_params.T          = 300;
    gas_params.n_gas      = gas_params.P / (k_B * gas_params.T);
    sigma_N2              = 2.0e-20;
    sigma_O2              = 2.2e-20;
    gas_params.sigma_elastic = 0.78*sigma_N2 + 0.21*sigma_O2;
    gas_params.lambda_mfp = 1 / (gas_params.n_gas * gas_params.sigma_elastic);

    scatter_cal = struct();
    scatter_cal.strength_factor = 1.0;
    scatter_cal.rare_fraction   = 0.01;
    scatter_cal.theta_rare_max  = 10e-3;
    scatter_cal.check_interval  = 10;

    scatter_diag = struct();
    scatter_diag.event_count = 0;
    scatter_diag.rare_count  = 0;
    scatter_diag.theta_history        = [];
    scatter_diag.z_scatter_positions  = [];

    SCATTERING_METHOD = 'HYBRID';
    fprintf('\nGas scattering: %s  P=%.1e mbar  λ=%.1f km\n', ...
            SCATTERING_METHOD, gas_params.P/133.322, gas_params.lambda_mfp/1000);
end

%% ==================== ION ACCUMULATION ====================
if ENABLE_ION_ACCUMULATION && ENABLE_SPACE_CHARGE
    ion_physics = struct();
    ion_physics.sigma_ionization    = 3.5e-21;
    ion_physics.mass_ion_avg        = 29 * 1.66054e-27;
    ion_physics.charge_ion          = e_charge;
    ion_physics.mobility            = 2.5e-4;
    ion_physics.t_recomb_effective  = 10e-6;
    %ion_physics.superparticle_weight = 1000; % Changed to 100 from 1000 for P - 1e-9mbar
    ion_physics.superparticle_weight = 100;

    ion_density_grid     = zeros(sc_nr, sc_nz);
    ion_density_by_pulse = zeros(sc_nr, sc_nz, pulse_config.n_pulses);
    ion_vz_grid          = zeros(sc_nr, sc_nz);

    ion_diag = struct();
    ion_diag.creation_history      = zeros(nt, 1);
    ion_diag.total_ions_vs_time    = zeros(nt, 1);
    ion_diag.peak_density_vs_time  = zeros(nt, 1);
    ion_diag.ions_per_pulse        = zeros(pulse_config.n_pulses, 1);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% And initialize in pre-loop setup:
    %ion_diag.snapshot_grids = cell(1, 4);
    ion_diag.snapshot_grids = cell(1, pulse_config.n_pulses);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    fprintf('Ion accumulation enabled  (weight=%d ions/super-particle)\n', ...
            ion_physics.superparticle_weight);
end

%% ==================== PARTICLE POOL ====================
length_factor = 8.305 / 2.760;
base_single   = 1.05e6;

if ENABLE_MULTIPULSE == true
    expected_parts = base_single * length_factor * pulse_config.n_pulses;
    safety_factor  = 1.25;
else
    expected_parts = base_single * length_factor;
    safety_factor  = 1.15;
end

max_particles = ceil(expected_parts * safety_factor);

fprintf('\nParticle pool: %.2e  (safety=%.2f  pulses=%d  %.1f MB)\n', ...
        max_particles, safety_factor, pulse_config.n_pulses, ...
        max_particles*8*10/1024^2);

if max_particles > 20e6
    fprintf('  WARNING: Very large particle pool (>20M). Consider reducing base_particles.\n');
end

z_particles       = NaN(max_particles, 1);
r_particles       = NaN(max_particles, 1);
pz_particles      = zeros(max_particles, 1);
pr_particles      = zeros(max_particles, 1);
ptheta_particles  = zeros(max_particles, 1);
weight_particles  = zeros(max_particles, 1);
gamma_particles   = ones(max_particles,  1);
active_particles  = false(max_particles, 1);

%% ==================== COUNTERS ====================
n_active                  = 0;
n_created                 = 0;
particles_at_anode        = 0;
particles_transmitted     = 0;
particles_lost_to_cathode = 0;
particles_lost_to_walls   = 0;
particles_out_of_bounds   = 0;

%% ==================== PARTICLE TRACKING ARRAYS ====================
%%% Those 6 parametersinitialization repeated below
%particle_crossed_anode   = false(max_particles, 1);
%particle_crossed_exit    = false(max_particles, 1);
%particle_t_at_anode      = NaN(max_particles, 1);
%particle_t_at_exit       = NaN(max_particles, 1);
%particle_KE_at_anode     = zeros(max_particles, 1);   % eV
%particle_KE_at_exit      = zeros(max_particles, 1);   % eV
particle_r_at_anode      = NaN(max_particles, 1);
particle_counted_as_return     = false(max_particles, 1); % seems not used
particle_counted_as_violation  = false(max_particles, 1); %seems not used
%% ==================== CURRENT ACCUMULATORS ====================
I_anode_accumulator = 0;
I_exit_accumulator  = 0;
I_anode_count       = 0;
I_exit_count        = 0;

%% ==================== MONITOR POSITIONS ====================
monitor_positions = [0.001; 0.254; 0.600; 1.000; 1.700; ...
                     2.760; 3.964; 6.4018; 6.8276; 8.305];
monitor_names     = ["Cathode","Anode","Trans1","Trans2","Trans3", ...
                     "BPM1","BPM2","BPM3","BPM4","BPM5"];
n_monitors        = length(monitor_positions);
I_monitor         = zeros(nt, n_monitors);
particles_through = zeros(n_monitors, 1);
particle_counted_at_monitor = false(max_particles, n_monitors);

fprintf('\nMonitors: %d positions (%.0f mm to %.0f mm)\n', ...
        n_monitors, monitor_positions(1)*1000, monitor_positions(end)*1000);

%% ==================== ANALYSIS PLANES ====================
ANALYSIS_LOCATIONS = [254;600;1000;1500;1700;2200;2700; ...
                      3400;3964;4600;5400;6402;6828;7450;8305];
ANALYSIS_LOCATION_NAMES = {'Anode','Early Drift','Mid Drift1','Trans1','Trans2', ...
    'Mid Drift2','BPM1','Extension1','BPM2','Extension2', ...
    'Late Drift','BPM3','BPM4','Sol49','Exit'};
N_ANALYSIS_PLANES = length(ANALYSIS_LOCATIONS);
twiss_locations   = ANALYSIS_LOCATIONS;
location_names    = ANALYSIS_LOCATION_NAMES;
n_locations       = N_ANALYSIS_PLANES;
n_twiss_planes    = N_ANALYSIS_PLANES;

%% ==================== DIAGNOSTIC ARRAYS ====================
I_emit                = zeros(nt, 1);
I_anode               = zeros(nt, 1);
I_exit                = zeros(nt, 1);
I_cathode             = zeros(nt, 1);
I_drift_exit          = zeros(nt, 1);
collection_efficiency = zeros(nt, 1);
n_active_history      = zeros(nt, 1);

J_thermionic  = zeros(nt, 1);
J_space_charge = zeros(nt, 1);
J_actual      = zeros(nt, 1);

sc_field_cathode      = zeros(nt, 1);
sc_field_max          = zeros(nt, 1);
sc_field_distribution = zeros(nt, 1);
particle_weight_history = zeros(nt, 1);
max_sc_field_recorded = 0;

n_z_diagnostic   = 480;
z_diagnostic     = linspace(0, 8.31, n_z_diagnostic);
r_rms_history    = zeros(nt, n_z_diagnostic);
n_particles_vs_z = zeros(nt, n_z_diagnostic);
r_wall           = 0.075;

snapshot_times = [195e-9, 200e-9, 205e-9, 210e-9, 215e-9, 220e-9, ...
    225e-9, 230e-9, 235e-9, 240e-9, 245e-9]; % was four Pi snapshots, now 11

snapshot_data  = struct();
snapshot_count = 0;

%% ==================== SNAPSHOT STORAGE ====================
if ENABLE_MULTIPULSE == true
    snapshot_p1 = cell(N_SNAPSHOTS, 1);
    snapshot_p2 = cell(N_SNAPSHOTS, 1);
    snapshot_p3 = cell(N_SNAPSHOTS, 1);
    snapshot_p4 = cell(N_SNAPSHOTS, 1);
    snapshot_p1_count = 0;
    snapshot_p2_count = 0;
    snapshot_p3_count = 0;
    snapshot_p4_count = 0;
    fprintf('Snapshot storage: %d per pulse (P1-P4)\n', N_SNAPSHOTS);
else
    snapshot_early = cell(N_SNAPSHOTS_EARLY, 1);
    snapshot_late  = cell(N_SNAPSHOTS_LATE,  1);
    snapshot_p1    = cell(N_SNAPSHOTS, 1);
    snapshot_early_count = 0;
    snapshot_late_count  = 0;
    snapshot_p1_count    = 0;
    fprintf('Snapshot storage: %d early, %d late, %d P1\n', ...
            N_SNAPSHOTS_EARLY, N_SNAPSHOTS_LATE, N_SNAPSHOTS);
end

%% ==================== MULTI-PULSE DIAGNOSTICS ====================
if ENABLE_MULTIPULSE == true
    particle_source_pulse = zeros(max_particles, 1);

    pulse_diagnostics = struct();
    for ip = 1:pulse_config.n_pulses
        pulse_diagnostics(ip).particles_emitted     = 0;
        pulse_diagnostics(ip).particles_at_anode    = 0;
        pulse_diagnostics(ip).particles_transmitted = 0;
        pulse_diagnostics(ip).charge_emitted        = 0;
        pulse_diagnostics(ip).charge_transmitted    = 0;
        pulse_diagnostics(ip).I_peak                = 0;
    end
    fprintf('Multi-pulse diagnostics initialized (%d pulses)\n', pulse_config.n_pulses);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% HANDOFF ARRAYS %%%%%%%%%%%%%%%%%%%%%%%%%%
%% If the debug line prints length = 1 for particle_t_at_exit then the 
% Block 1 initialization needs:
    %% In Block 1 — ensure full pre-allocation (R2025b compatible)
     particle_t_at_exit  = zeros(max_particles, 1, 'double');   %% explicit type
     particle_KE_at_exit = zeros(max_particles, 1, 'double');
     particle_t_at_anode  = zeros(max_particles, 1, 'double');
     particle_KE_at_anode = zeros(max_particles, 1, 'double');
     particle_crossed_exit  = false(max_particles, 1);
     particle_crossed_anode = false(max_particles, 1);
     n_max = max_particles; %just to make clear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End of first section %%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== SOLENOID STRUCTURES ====================
solenoid1  = struct('B', solenoid1_field,  'z_c', -0.279,  'L', 0.106, 'R', 0.451);
solenoid2  = struct('B', solenoid2_field,  'z_c',  0.372,  'L', 0.195, 'R', 0.245);
solenoid3  = struct('B', solenoid3_field,  'z_c',  1.14461,'L', 0.120, 'R', 0.245);
solenoid4  = struct('B', solenoid4_field,  'z_c',  1.26757,'L', 0.120, 'R', 0.245);
solenoid5  = struct('B', solenoid5_field,  'z_c',  1.36927,'L', 0.120, 'R', 0.245);
solenoid7  = struct('B', solenoid7_field,  'z_c',  1.49223,'L', 0.100, 'R', 0.245);
solenoid8  = struct('B', solenoid8_field,  'z_c',  1.59393,'L', 0.100, 'R', 0.245);
solenoid9  = struct('B', solenoid9_field,  'z_c',  1.71689,'L', 0.100, 'R', 0.245);
solenoid10 = struct('B', solenoid10_field, 'z_c',  1.81860,'L', 0.090, 'R', 0.245);
solenoid11 = struct('B', solenoid11_field, 'z_c',  1.94156,'L', 0.110, 'R', 0.245);
solenoid12 = struct('B', solenoid12_field, 'z_c',  2.04326,'L', 0.110, 'R', 0.245);
solenoid14 = struct('B', solenoid14_field, 'z_c',  2.16622,'L', 0.090, 'R', 0.245);
solenoid15 = struct('B', solenoid15_field, 'z_c',  2.26793,'L', 0.100, 'R', 0.245);
solenoid16 = struct('B', solenoid16_field, 'z_c',  2.39089,'L', 0.110, 'R', 0.245);
solenoid17 = struct('B', solenoid17_field, 'z_c',  2.49259,'L', 0.110, 'R', 0.245);
solenoid18 = struct('B', solenoid18_field, 'z_c',  2.61555,'L', 0.090, 'R', 0.245);
solenoid19 = struct('B', solenoid19_field, 'z_c',  2.71726,'L', 0.090, 'R', 0.245);
solenoid20 = struct('B', solenoid20_field, 'z_c',  2.84022,'L', 0.100, 'R', 0.245);
solenoid21 = struct('B', solenoid21_field, 'z_c',  2.94192,'L', 0.100, 'R', 0.245);
solenoid22 = struct('B', solenoid22_field, 'z_c',  3.06488,'L', 0.100, 'R', 0.245);
solenoid23 = struct('B', solenoid23_field, 'z_c',  3.16658,'L', 0.100, 'R', 0.245);
solenoid24 = struct('B', solenoid24_field, 'z_c',  3.28954,'L', 0.100, 'R', 0.245);
solenoid25 = struct('B', solenoid25_field, 'z_c',  3.39125,'L', 0.100, 'R', 0.245);
solenoid26 = struct('B', solenoid26_field, 'z_c',  3.51421,'L', 0.100, 'R', 0.245);
solenoid27 = struct('B', solenoid27_field, 'z_c',  3.61591,'L', 0.100, 'R', 0.245);
solenoid28 = struct('B', solenoid28_field, 'z_c',  3.73887,'L', 0.100, 'R', 0.245);
solenoid29 = struct('B', solenoid29_field, 'z_c',  3.84058,'L', 0.100, 'R', 0.245);
solenoid30 = struct('B', solenoid30_field, 'z_c',  3.96354,'L', 0.100, 'R', 0.245);
solenoid31 = struct('B', solenoid31_field, 'z_c',  4.06524,'L', 0.100, 'R', 0.245);
solenoid32 = struct('B', solenoid32_field, 'z_c',  4.18820,'L', 0.100, 'R', 0.245);
solenoid33 = struct('B', solenoid33_field, 'z_c',  4.28993,'L', 0.100, 'R', 0.245);
solenoid34 = struct('B', solenoid34_field, 'z_c',  4.41289,'L', 0.100, 'R', 0.245);
solenoid35 = struct('B', solenoid35_field, 'z_c',  4.51459,'L', 0.100, 'R', 0.245);
solenoid36 = struct('B', solenoid36_field, 'z_c',  4.63755,'L', 0.100, 'R', 0.245);
solenoid38 = struct('B', solenoid38_field, 'z_c',  4.73925,'L', 0.100, 'R', 0.245);
solenoid39 = struct('B', solenoid39_field, 'z_c',  4.86221,'L', 0.100, 'R', 0.245);
solenoid40 = struct('B', solenoid40_field, 'z_c',  4.96392,'L', 0.100, 'R', 0.245);
solenoid41 = struct('B', solenoid41_field, 'z_c',  5.08688,'L', 0.100, 'R', 0.245);
solenoid42 = struct('B', solenoid42_field, 'z_c',  5.18858,'L', 0.100, 'R', 0.245);
solenoid43 = struct('B', solenoid43_field, 'z_c',  5.31154,'L', 0.100, 'R', 0.245);
solenoid45 = struct('B', solenoid45_field, 'z_c',  5.41324,'L', 0.100, 'R', 0.245);
solenoid46 = struct('B', solenoid46_field, 'z_c',  5.53620,'L', 0.100, 'R', 0.245);
solenoid47 = struct('B', solenoid47_field, 'z_c',  5.63791,'L', 0.100, 'R', 0.245);
solenoid48 = struct('B', solenoid48_field, 'z_c',  5.76087,'L', 0.100, 'R', 0.245);
solenoid49 = struct('B', solenoid49_field, 'z_c',  7.44800,'L', 0.100, 'R', 0.245);

fprintf('\nSolenoid configuration: 43 active solenoids (6,13,37,44 are steering — OFF)\n');
fprintf('  Sol1:  %+.0f G at z=%.0f mm  (cathode)\n', solenoid1.B*1e4,  solenoid1.z_c*1000);
fprintf('  Sol2:  %+.0f G at z=%.0f mm  (anode)\n',   solenoid2.B*1e4,  solenoid2.z_c*1000);
fprintf('  Sol49: %+.0f G at z=%.0f mm  (last)\n',    solenoid49.B*1e4, solenoid49.z_c*1000);

%% ==================== MAGNETIC FIELD FUNCTIONS ====================
SOLENOID_ARGS = {solenoid1,solenoid2,solenoid3,solenoid4,solenoid5, ...
    solenoid7,solenoid8,solenoid9,solenoid10,solenoid11,solenoid12, ...
    solenoid14,solenoid15,solenoid16,solenoid17,solenoid18,solenoid19, ...
    solenoid20,solenoid21,solenoid22,solenoid23,solenoid24,solenoid25, ...
    solenoid26,solenoid27,solenoid28,solenoid29,solenoid30,solenoid31, ...
    solenoid32,solenoid33,solenoid34,solenoid35,solenoid36, ...
    solenoid38,solenoid39,solenoid40,solenoid41,solenoid42,solenoid43, ...
    solenoid45,solenoid46,solenoid47,solenoid48,solenoid49};

Bz_func = @(z_pos, r_pos, t_curr) ...
    calculate_Bz_solenoid(z_pos, r_pos, t_curr, SOLENOID_ARGS{:});

Br_func = @(z_pos, r_pos, t_curr) ...
    calculate_Br_solenoid(z_pos, r_pos, t_curr, SOLENOID_ARGS{:});

%% Quick solenoid function test
fprintf('\n=== Solenoid Function Test (t=200ns) ===\n');
for z_test = [0.5, 1.0, 2.0, 4.0, 6.0]
    Bz_t = Bz_func(z_test, 0.04, 200e-9);
    fprintf('  z=%.1f m:  Bz=%.2e T  (%.1f G)\n', z_test, Bz_t, Bz_t*1e4);
end

%% ==================== SCHOTTKY DIAGNOSTICS STRUCT ====================
schottky_diagnostics = struct();
schottky_diagnostics.E_cathode  = zeros(nt, 1);
schottky_diagnostics.delta_phi  = zeros(nt, 1);
schottky_diagnostics.phi_eff    = zeros(nt, 1);
schottky_diagnostics.T_cathode  = zeros(nt, 1);
schottky_diagnostics.T_required = zeros(nt, 1);

%% ==================== MAIN TIME LOOP ====================
fprintf('\nStarting simulation...\n');
fprintf('  nt=%d steps  |  dt=%.0f ps  |  t=%.1f→%.1f ns\n', ...
        nt, dt*1e12, t_start*1e9, t_end*1e9);
tic_start = tic;
fprintf('Progress: ');

for it = 1:nt
    current_t = t(it);

    %% Reset accumulators on first step
    if it == 1
        I_anode_accumulator = 0;
        I_exit_accumulator  = 0;
        I_anode_count       = 0;
        I_exit_count        = 0;
    end

    %% Progress reporting
    if mod(it, 1000) == 0
        elapsed = toc(tic_start);
        rate    = it / elapsed;
        eta     = (nt - it) / rate;
        fprintf('\n  Step %d/%d (%.1f%%) | %.0f steps/s | ETA %.1f min', ...
                it, nt, 100*it/nt, rate, eta/60);
        fprintf('\n  Active:%d  Created:%d  At_anode:%d  Transmitted:%d', ...
                n_active, n_created, particles_at_anode, particles_transmitted);
        fprintf('\n  ');
    elseif mod(it, round(nt/20)) == 0
        fprintf('.');
    end

    %% Refresh active index once per timestep
    active_idx = find(active_particles); 
    active_idx = active_idx(:);  %% added 04.07.2026
    n_active   = length(active_idx);

    %% ==================== PULSE FACTOR ====================
    pulse_factor  = pulse_shape(current_t);
    %% ==================== CURRENT PULSE DETECTION ====================
    if ENABLE_MULTIPULSE == true
        current_pulse = pulse_config.n_pulses;  % default to last pulse (inter-pulse coast)
        for ip = 1:pulse_config.n_pulses
            p_start = pulse_config.pulse_starts(ip);
            p_end   = p_start + pulse_config.rise_time + ...
                      pulse_config.flat_time + pulse_config.fall_time;
            if current_t >= p_start && current_t <= p_end
                current_pulse = ip;
                break;
            end
        end
    else
        current_pulse = 1;
    end

    %% ==================== EMISSION ====================
    if pulse_factor > 0.01

        %% --- Dynamic cathode field extraction ---
        iz_search = find(z >= 0.000 & z <= 0.010);
        if ~isempty(iz_search)
            E_cathode_base = max(abs(Ez_capped(1:3, iz_search(:)')), [], 'all');
        else
            E_cathode_base = E_CATHODE_BASE_DETECTED;
        end
        E_cathode = E_cathode_base * pulse_factor;

        %% Add space-charge contribution at cathode
        if ENABLE_SPACE_CHARGE && exist('Ez_sc','var') && any(Ez_sc(:) ~= 0)
            [~, iz_sc_cath] = min(abs(sc_z - 0.001));
            E_cathode = E_cathode + abs(mean(Ez_sc(:, iz_sc_cath)));
        end

        %% Schottky barrier reduction
        schottky_constant = sqrt(e_charge^3 / (4*pi*eps0));
        delta_phi = schottky_constant * sqrt(E_cathode) / e_charge;  % eV
        phi_0     = 1.8;    % base work function (eV)
        phi_eff   = phi_0 - delta_phi;
        
        %% Thermionic emission (Richardson-Dushman)
        A_RD       = 1.20173e6;   % A/m²/K²
        T_cathode  = 1200;        % K
        J_thermionic_current = A_RD * T_cathode^2 * ...
                               exp(-phi_eff * e_charge / (k_B * T_cathode));
        %%%%%%%%% Add In Block 1 Schottky setup %%%%%%%%%%%% 
        %% T_required: temperature needed WITHOUT Schottky enhancement
        %% to achieve the same emission current density J_emit
        %% Uses approximation T_req ≈ T_actual × (phi_0 / phi_eff)
        %% Valid for delta_phi << phi_0 (here delta_phi/phi_0 ≈ 5%)
        if phi_eff > 0.01   % guard against divide-by-zero at pulse edges
            schottky_diagnostics.T_required(it) = T_cathode * (phi_0 / phi_eff);
        else
            schottky_diagnostics.T_required(it) = T_cathode;
        end
        schottky_diagnostics.T_cathode(it) = T_cathode;
        schottky_diagnostics.delta_phi(it) = delta_phi;
        schottky_diagnostics.phi_eff(it)   = phi_eff;
        schottky_diagnostics.E_cathode(it) = E_cathode;

        %% Child-Langmuir space-charge limit (relativistic)
        V_gap    = 1.70e6 * pulse_factor;
        d_gap    = 0.254;
        gamma_exit = 1 + V_gap * e_charge / (m_e * c^2);
        beta_exit  = sqrt(1 - 1/gamma_exit^2);
        rel_factor = gamma_exit^(3/2) * (1 + 2*log(gamma_exit));
        emp_factor = 1.75;
        J_CL = emp_factor * (4/9) * eps0 * sqrt(2*e_charge/m_e) * ...
               V_gap^(3/2) / d_gap^2 * sqrt(rel_factor);

        %% Operational limit
        J_SPECIFICATION = 11e4;   % A/m²
        A_emit          = pi * 0.065^2;

        %% Three-way minimum
        J_emit         = min([J_SPECIFICATION, J_thermionic_current, J_CL]);
        I_emit_current = J_emit * A_emit;

        I_emit(it)    = I_emit_current;
        I_cathode(it) = I_emit_current;

        J_thermionic(it)   = J_thermionic_current;
        J_space_charge(it) = J_CL;
        J_actual(it)       = J_emit;

        schottky_diagnostics.E_cathode(it) = E_cathode;
        schottky_diagnostics.delta_phi(it) = delta_phi;
        schottky_diagnostics.phi_eff(it)   = phi_eff;
        schottky_diagnostics.T_cathode(it) = T_cathode;

        %% Adaptive particle count
        if pulse_factor < 0.95
            n_emit = ceil(base_particles * pulse_factor);
        else
            n_emit = base_particles;
        end

        charge_to_emit  = I_emit_current * dt;
        particle_weight = charge_to_emit / (n_emit * e_charge);

        if n_emit > 0
            particle_weight_history(it) = particle_weight;
        end

        %% Emit particles
        v_thermal = sqrt(2 * k_B * T_cathode / m_e);

        for ip = 1:n_emit
            if n_created < max_particles
                n_created = n_created + 1;
                idx       = n_created;

                r_emit = sqrt(rand()) * 0.065;

                z_particles(idx)      = 0.001;
                r_particles(idx)      = r_emit;
                weight_particles(idx) = particle_weight;
                active_particles(idx) = true;
                if ENABLE_MULTIPULSE == true
                    particle_source_pulse(idx) = current_pulse;
                end

                pz_particles(idx)     = m_e * abs(randn()) * v_thermal * 0.1;
                pr_particles(idx)     = m_e * randn()      * v_thermal * 0.01;
                ptheta_particles(idx) = m_e * randn()      * v_thermal * 0.01;

                n_active = n_active + 1;
            end
        end

        %% Emission diagnostic (every 1000 steps)
        if mod(it, 1000) == 0
            fprintf('\n  [EMISSION] t=%.1f ns  E_cath=%.2f MV/m  phi_eff=%.3f eV', ...
                    current_t*1e9, E_cathode/1e6, phi_eff);
            fprintf('\n             J=%.1f A/cm²  I=%.1f A  n_emit=%d', ...
                    J_emit/1e4, I_emit_current, n_emit);
        end

    end  %% pulse_factor > 0.01
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End of the section 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Start of new third section %%%%%%%%%%%%%%%%%%%%%%%%%
    %% ==================== SC FIELD MONITOR ====================
    %% [CHANGED] — correctly zeros between solves and after beam off
    if ENABLE_SPACE_CHARGE && exist('Ez_sc','var')
        if mod(it, sc_interval) == 0 && n_active > 100
            %% SC solve just ran — record fresh values
            [~, iz_cath_sc] = min(abs(sc_z - 0.001));
            sc_field_cathode(it)      = mean(abs(Ez_sc(:, iz_cath_sc)));
            sc_field_max(it)          = max(abs(Ez_sc(:)));
            sc_field_distribution(it) = sqrt(mean(Ez_sc(:).^2));
        elseif n_active > 100 && it > 1
            %% Between SC solves — carry forward previous value
            sc_field_cathode(it)      = sc_field_cathode(it-1);
            sc_field_max(it)          = sc_field_max(it-1);
            sc_field_distribution(it) = sc_field_distribution(it-1);
        else
            %% Beam off (n_active <= 100) — zero the monitor
            sc_field_cathode(it)      = 0;
            sc_field_max(it)          = 0;
            sc_field_distribution(it) = 0;
        end
    end
    %% ==================== END SC FIELD MONITOR ====================

    %% ==================== ION DRIFT AND RECOMBINATION ====================
    total_ions_on_grid = 0;

    if ENABLE_ION_ACCUMULATION == true && ENABLE_SPACE_CHARGE == true
        total_ions_on_grid = sum(ion_density_grid(:));
    end
 %%%%%%%%%%%%%%%%%%%%%%%%% Replaced section    %%%%%%%%%%%%%%%%%%%%%%%%%%%
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       if ENABLE_ION_ACCUMULATION == true && ENABLE_SPACE_CHARGE == true && ...
       mod(it, sc_interval) == 0 && total_ions_on_grid > 0.1

        [ir_ion, jz_ion] = find(ion_density_grid > 0.01);
        valid_ion = ir_ion > 1 & ir_ion < sc_nr & ...
                    jz_ion > 1 & jz_ion < sc_nz;
        ir_ion = ir_ion(valid_ion);
        jz_ion = jz_ion(valid_ion);

        if ~isempty(ir_ion)
            z_pts = sc_z(jz_ion(:));   % column vector
            r_pts = sc_r(ir_ion(:));   % column vector

            E_z_local = interp2(z, r, Ez_capped, ...
                                z_pts, r_pts, 'linear', 0);
            E_z_local = E_z_local(:);  % ← force column vector

            if exist('Ez_sc','var')
                lin_idx   = sub2ind(size(Ez_sc), ir_ion, jz_ion);
                E_z_local = E_z_local + Ez_sc(lin_idx(:));
            end

            lin_idx_vz = sub2ind(size(ion_vz_grid), ir_ion, jz_ion);
            ion_vz_grid(lin_idx_vz) = ion_physics.mobility * E_z_local;
        end

           if mod(it, 100) == 0
            decay_factor     = exp(-dt * 100 / ion_physics.t_recomb_effective);
            ion_density_grid = ion_density_grid * decay_factor;
           end
        end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% ==================== SPACE CHARGE SOLVER ====================
    if ENABLE_SPACE_CHARGE == true  && mod(it, sc_interval) == 0 && n_active > 100

        %% Reset SC arrays
        rho_grid(:) = 0;
        phi_grid(:) = 0;
        Ez_sc(:)    = 0;
        Er_sc(:)    = 0;

        active_idx = find(active_particles);
        n_dep      = length(active_idx);

        z_dep = z_particles(active_idx);
        r_dep = r_particles(active_idx);

        sc_enhancement_scale = 0.25;
        enhancement_gap      = 1.050 * sc_enhancement_scale;
        enhancement_drift    = 0.950 * sc_enhancement_scale;

%%%%%%%%%%%%%%%%%%%%%% Corrected Charge Deposition block %%%%%%%%%%%%%%%%%%%
%% ==================== SC CHARGE DEPOSITION — BILINEAR ====================
rho_grid(:) = 0;

if n_dep > 0
    z_dep = z_dep(:);
    r_dep = r_dep(:);
    w_col = weight_particles(active_idx(:));
    w_col = w_col(:);

    %% Enhancement vector
    in_gap  = (z_dep < 0.254);
    enh_vec = enhancement_drift * ones(n_dep, 1);
    enh_vec(in_gap) = enhancement_gap;

    %% Charge per super-particle
    q_vec = -enh_vec .* e_charge .* w_col;   %% (n_dep×1)

    %% Lower-left cell indices
    iz0 = max(1, min(sc_nz-1, floor((z_dep - sc_z(1)) / sc_dz) + 1));
    ir0 = max(1, min(sc_nr-1, floor((r_dep - sc_r(1)) / sc_dr) + 1));
    iz1 = iz0 + 1;
    ir1 = ir0 + 1;

    %% Force all index arrays to column vectors
    iz0 = iz0(:);  iz1 = iz1(:);
    ir0 = ir0(:);  ir1 = ir1(:);

    %% Bilinear weights — all column vectors
    %% Bilinear weights — sc_z and sc_r must be indexed as column vectors
    sc_z_col = sc_z(:);   %% force sc_z to column vector once
    sc_r_col = sc_r(:);   %% force sc_r to column vector once

    dz_frac = (z_dep - (sc_z(1) + (iz0-1).*sc_dz)) ./ sc_dz;
    dr_frac = (r_dep - (sc_r(1) + (ir0-1).*sc_dr)) ./ sc_dr;
    dz_frac = max(0, min(1, dz_frac(:)));
    dr_frac = max(0, min(1, dr_frac(:)));

    w00 = (1 - dz_frac) .* (1 - dr_frac);
    w01 = (1 - dz_frac) .*      dr_frac;
    w10 =      dz_frac  .* (1 - dr_frac);
    w11 =      dz_frac  .*      dr_frac;

    %% Cell volumes — annular rings, all column vectors
    vol_ir0 = pi .* ((ir0.*sc_dr).^2 - ((ir0-1).*sc_dr).^2) .* sc_dz;
    vol_ir1 = pi .* ((ir1.*sc_dr).^2 - ((ir1-1).*sc_dr).^2) .* sc_dz;
    vol_ir0(ir0 == 1) = pi * sc_dr^2 * sc_dz;
    vol_ir1(ir1 == 1) = pi * sc_dr^2 * sc_dz;

    %% Charge density contributions — all column vectors
    c00 = q_vec .* w00 ./ vol_ir0;  c00 = c00(:);
    c01 = q_vec .* w01 ./ vol_ir1;  c01 = c01(:);
    c10 = q_vec .* w10 ./ vol_ir0;  c10 = c10(:);
    c11 = q_vec .* w11 ./ vol_ir1;  c11 = c11(:);

    %% Linear indices — all column vectors
    idx00 = sub2ind([sc_nr, sc_nz], ir0, iz0);
    idx01 = sub2ind([sc_nr, sc_nz], ir1, iz0);
    idx10 = sub2ind([sc_nr, sc_nz], ir0, iz1);
    idx11 = sub2ind([sc_nr, sc_nz], ir1, iz1);

    %% Accumulate — guaranteed column vectors, same length
    all_idx = [idx00; idx01; idx10; idx11];
    all_c   = [c00;   c01;   c10;   c11];

    %% Safety check
    assert(numel(all_idx) == numel(all_c), ...
           'Size mismatch: idx=%d  c=%d', numel(all_idx), numel(all_c));

    rho_grid = reshape( ...
        accumarray(all_idx, all_c, [sc_nr*sc_nz, 1], @sum, 0), ...
        sc_nr, sc_nz);
end
%% ======================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% Verification script 
%% Add immediately after rho_grid = reshape(accumarray(...))
if it <= sc_interval * 2
    fprintf('  [SC verify] n_dep=%d  rho_max=%.3e  rho_nnz=%d\n', ...
            n_dep, max(abs(rho_grid(:))), sum(rho_grid(:)~=0));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Ion contribution
        if ENABLE_ION_ACCUMULATION == true && total_ions_on_grid > 0
            ion_cell_vol       = zeros(sc_nr, sc_nz);
            ion_cell_vol(1, :) = pi * (sc_dr/2)^2 * sc_dz;
            r_i = sc_r(2:end)';
            ion_cell_vol(2:end, :) = repmat( ...
                pi * ((r_i + sc_dr/2).^2 - (r_i - sc_dr/2).^2) * sc_dz, 1, sc_nz);

            in_gap_cells = repmat((sc_z(:)' < 0.254), sc_nr, 1);
            enh_ion                = zeros(sc_nr, sc_nz);
            enh_ion( in_gap_cells) = enhancement_gap;
            enh_ion(~in_gap_cells) = enhancement_drift;

            real_ion_density = ion_density_grid * ion_physics.superparticle_weight;
            sig_ions         = (ion_density_grid > 0.01);
            ion_rho          = enh_ion .* e_charge .* real_ion_density ./ ion_cell_vol;
            rho_grid         = rho_grid + ion_rho .* sig_ions;
        end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Clamp rho before Poisson solve
        rho_cap  = 3.0 * eps0 * 7.5e6 / sc_dz;
        rho_grid = max(-rho_cap, min(rho_cap, rho_grid));

        %% SOR Poisson solver
        dz2    = sc_dz^2;
        dr2    = sc_dr^2;
        denom  = 2.0 * (dr2 + dz2);
        rhs_fac = dr2 * dz2 / (denom * eps0);

        ir_int = 2:(sc_nr - 1);
        jz_int = 2:(sc_nz - 1);

        for iter = 1:sc_iterations

            phi_new = (dr2 * (phi_grid(ir_int+1, jz_int) + ...
                               phi_grid(ir_int-1, jz_int)) + ...
                       dz2 * (phi_grid(ir_int, jz_int+1) + ...
                               phi_grid(ir_int, jz_int-1))) / denom ...
                      - rho_grid(ir_int, jz_int) * rhs_fac;

            phi_grid(ir_int, jz_int) = (1 - sc_omega) * phi_grid(ir_int, jz_int) + ...
                                        sc_omega * phi_new;

            axis_denom   = 4*dz2 + 2*dr2;
            phi_axis_new = ((4*dz2) * phi_grid(2, jz_int) + ...
                             dr2    * (phi_grid(1, jz_int+1) + ...
                                       phi_grid(1, jz_int-1))) / axis_denom ...
                           - rho_grid(1, jz_int) * (dr2*dz2) / (axis_denom * eps0);

            phi_grid(1, jz_int) = (1 - sc_omega) * phi_grid(1, jz_int) + ...
                                   sc_omega * phi_axis_new;

            phi_grid(sc_nr, :) = phi_grid(sc_nr-1, :);
            phi_grid(:,    1)  = 0;
            phi_grid(:, sc_nz) = 0;
        end

        %% Electric field from potential
        Ez_sc(ir_int, jz_int) = -(phi_grid(ir_int, jz_int+1) - ...
                                   phi_grid(ir_int, jz_int-1)) / (2*sc_dz);
        Er_sc(ir_int, jz_int) = -(phi_grid(ir_int+1, jz_int) - ...
                                   phi_grid(ir_int-1, jz_int)) / (2*sc_dr);

        Ez_sc(1, jz_int) = -(phi_grid(1, jz_int+1) - ...
                              phi_grid(1, jz_int-1)) / (2*sc_dz);
        Er_sc(1, :)      = 0;

        %% Inf/NaN guard
        if any(~isfinite(Ez_sc(:))) || any(~isfinite(Er_sc(:)))
            Ez_sc(~isfinite(Ez_sc)) = 0;
            Er_sc(~isfinite(Er_sc)) = 0;
        end

        %% SC field cap
        max_sc   = 3.0 * 7.5e6;
        E_sc_mag = max(max(abs(Ez_sc(:))), max(abs(Er_sc(:))));
        if E_sc_mag > max_sc
            scale = max_sc / E_sc_mag;
            Ez_sc = Ez_sc * scale;
            Er_sc = Er_sc * scale;
        end

        max_sc_field_recorded = max(max_sc_field_recorded, max(abs(Ez_sc(:))));

        if mod(it, 1000) == 0
            fprintf('\n  [SC] rho_max=%.2e C/m³ | Ez_max=%.3f MV/m | Er_max=%.3f MV/m', ...
                    max(abs(rho_grid(:))), max(abs(Ez_sc(:)))/1e6, max(abs(Er_sc(:)))/1e6);
        end

    end  %% SC solver

    %% ==================== ION CREATION ====================
    if ENABLE_ION_ACCUMULATION == true && ENABLE_SPACE_CHARGE == true  && ...
       mod(it, scatter_cal.check_interval) == 0

        active_idx = find(active_particles);
        n_check    = length(active_idx);

        if n_check > 0
            p_total_ion  = sqrt(pz_particles(active_idx).^2 + ...
                                pr_particles(active_idx).^2 + ...
                                ptheta_particles(active_idx).^2);
            gamma_ion    = gamma_particles(active_idx);
            beta_ion     = sqrt(1 - 1./gamma_ion.^2);
            ds_ion       = c * beta_ion * dt * scatter_cal.check_interval;

            p_ionize     = 1 - exp(-ion_physics.sigma_ionization * ...
                                    gas_params.n_gas .* ds_ion);

            real_ions_pp   = weight_particles(active_idx) .* p_ionize;
            superions_pp   = real_ions_pp / ion_physics.superparticle_weight;
            total_superions = sum(superions_pp);

            if total_superions > 0.01
                for i = 1:n_check
                    if superions_pp(i) > 0.01
                        idx_g = active_idx(i);
                        [~, iz_ion] = min(abs(sc_z - z_particles(idx_g)));
                        [~, ir_ion] = min(abs(sc_r - r_particles(idx_g)));
                        if iz_ion >= 1 && iz_ion <= sc_nz && ...
                           ir_ion >= 1 && ir_ion <= sc_nr
                            ion_density_grid(ir_ion, iz_ion) = ...
                                ion_density_grid(ir_ion, iz_ion) + superions_pp(i);
                            ion_density_by_pulse(ir_ion, iz_ion, current_pulse) = ...
                                ion_density_by_pulse(ir_ion, iz_ion, current_pulse) + ...
                                superions_pp(i);
                        end
                    end
                end

                real_ions_created = total_superions * ion_physics.superparticle_weight;
                ion_diag.creation_history(it)       = real_ions_created;
                ion_diag.ions_per_pulse(current_pulse) = ...
                    ion_diag.ions_per_pulse(current_pulse) + real_ions_created;
            end
        end
    end

    %% ==================== ION DIAGNOSTICS ====================
    if ENABLE_ION_ACCUMULATION == true && ENABLE_SPACE_CHARGE == true 
        ion_diag.total_ions_vs_time(it)   = total_ions_on_grid * ...
                                             ion_physics.superparticle_weight;
        ion_diag.peak_density_vs_time(it) = max(ion_density_grid(:)) * ...
                                             ion_physics.superparticle_weight;
    end

    %% ==================== GAS SCATTERING ====================
    if ENABLE_GAS_SCATTERING && mod(it, scatter_cal.check_interval) == 0

        active_idx      = find(active_particles);
        n_scatter_check = length(active_idx);

        if n_scatter_check > 0
            p_total_sc = sqrt(pz_particles(active_idx).^2 + ...
                              pr_particles(active_idx).^2 + ...
                              ptheta_particles(active_idx).^2);
            gamma_sc   = gamma_particles(active_idx);
            beta_sc    = sqrt(1 - 1./gamma_sc.^2);
            ds_sc      = c * beta_sc * dt * scatter_cal.check_interval;

            sigma_tuned = gas_params.sigma_elastic * scatter_cal.strength_factor;
            p_scatter   = 1 - exp(-sigma_tuned * gas_params.n_gas .* ds_sc);
            p_scatter = p_scatter(:); % added 04.07.2026
            scatter_mask = rand(n_scatter_check, 1) < p_scatter;

            if any(scatter_mask)
                scatter_idx = active_idx(scatter_mask);
                n_scattered = length(scatter_idx);
                p_sc        = p_total_sc(scatter_mask);
                ds_s        = ds_sc(scatter_mask);

                Z_eff = 7.4;
                b_min = 1e-10;
                is_rare = rand(n_scattered, 1) < scatter_cal.rare_fraction;

                %% Typical small-angle scatters
                typical_idx = scatter_idx(~is_rare);
                if ~isempty(typical_idx)
                    p_typ  = p_sc(~is_rare);
                    ds_typ = ds_s(~is_rare);
                    theta_char = Z_eff * e_charge^2 ./ ...
                                 (4*pi*eps0 * p_typ * c * b_min);
                    n_scat_avg = gas_params.n_gas * sigma_tuned * ds_typ;
                    theta_0    = theta_char .* sqrt(n_scat_avg);
                    theta_typ  = randn(length(typical_idx), 1) .* theta_0;
                    phi_typ    = 2*pi * rand(length(typical_idx), 1);
                    pr_particles(typical_idx) = pr_particles(typical_idx) + ...
                                                p_typ .* theta_typ .* cos(phi_typ);
                    ptheta_particles(typical_idx) = ptheta_particles(typical_idx) + ...
                                                    p_typ .* theta_typ .* sin(phi_typ);
                end

                %% Rare large-angle scatters
                rare_idx = scatter_idx(is_rare);
                if ~isempty(rare_idx)
                    n_rare     = length(rare_idx);
                    p_rare     = p_sc(is_rare);
                    theta_min  = 0.1e-3;
                    theta_max  = scatter_cal.theta_rare_max;
                    u          = rand(n_rare, 1);
                    theta_rare = theta_min * (theta_max/theta_min).^u;
                    phi_rare   = 2*pi * rand(n_rare, 1);
                    pr_particles(rare_idx) = pr_particles(rare_idx) + ...
                                             p_rare .* theta_rare .* cos(phi_rare);
                    ptheta_particles(rare_idx) = ptheta_particles(rare_idx) + ...
                                                 p_rare .* theta_rare .* sin(phi_rare);

                    %% Store rare angles for diagnostics
                    scatter_diag.theta_history = [scatter_diag.theta_history; ...
                                                  theta_rare];
                    scatter_diag.rare_count = scatter_diag.rare_count + n_rare;
                end

                %% Store typical angles for diagnostics
                if ~isempty(typical_idx)
                    scatter_diag.theta_history = [scatter_diag.theta_history; ...
                                                  theta_typ];
                end

                %% Store scatter positions (z coordinates of scattered particles)
                scatter_diag.z_scatter_positions = [ ...
                    scatter_diag.z_scatter_positions; ...
                    z_particles(scatter_idx)]; %replaced %z_active(scatter_mask)];

                scatter_diag.event_count = scatter_diag.event_count + n_scattered;
                end
        end
    end  %% gas scattering

    %% ==================== PARTICLE PUSH ====================
    %%  Single position update — no second update anywhere in the loop.
    %%  All crossing detection runs here, immediately after z_particles
    %%  is written, using z_active (pre-step) and z_new (post-step).

    if n_active > 0

        active_idx = find(active_particles);
        z_active   = z_particles(active_idx);
        r_active   = r_particles(active_idx);

        %% --- Geometry loss classification ---
        r_cathode_gap       = 0.075;
        r_drift_tube        = 0.075;
        r_max_computational = 0.450;

        back_to_cathode      = (z_active < 0);
        in_gap               = (z_active >= 0)     & (z_active < 0.254);
        gap_wall_loss        = in_gap  & (r_active > r_cathode_gap);
        in_drift             = (z_active >= 0.500);
        drift_wall_loss      = in_drift & (r_active > r_drift_tube);
        in_transition        = (z_active >= 0.254) & (z_active < 0.500);
        r_transition         = r_cathode_gap + ...
                               (r_drift_tube - r_cathode_gap) .* ...
                               (z_active - 0.254) / (0.500 - 0.254);
        transition_wall_loss = in_transition & (r_active > r_transition);
        out_of_domain        = (z_active > 8.350) | ...
                               (r_active > r_max_computational) | ...
                               (z_active < -0.5);

        lost_mask = back_to_cathode | gap_wall_loss | drift_wall_loss | ...
                    transition_wall_loss | out_of_domain;

        %% --- Loss accounting ---
        if any(lost_mask)
            n_back   = sum(back_to_cathode);
            n_gwall  = sum(gap_wall_loss);
            n_dwall  = sum(drift_wall_loss);
            n_twall  = sum(transition_wall_loss);
            n_oob    = sum(out_of_domain & ~back_to_cathode & ...
                           ~gap_wall_loss & ~drift_wall_loss & ...
                           ~transition_wall_loss);

            lost_idx = active_idx(lost_mask);
            particles_lost_to_cathode = particles_lost_to_cathode + n_back;
            particles_lost_to_walls   = particles_lost_to_walls   + ...
                                        n_gwall + n_dwall + n_twall;
            particles_out_of_bounds   = particles_out_of_bounds   + n_oob;

            active_particles(lost_idx) = false;
            n_active = n_active - sum(lost_mask);

            if mod(it, 1000) == 0 && sum(lost_mask) > 0
                fprintf('\n  [LOSS] Cathode:%d  Walls:%d  OOB:%d', ...
                        n_back, n_gwall+n_dwall+n_twall, n_oob);
            end
        end

        %% --- Surviving particles ---
        valid      = ~lost_mask;
        active_idx = active_idx(valid);
        z_active   = z_active(valid);
        r_active   = r_active(valid);

        if ~isempty(active_idx)

            %% --- Grid clamps ---
            z_clamp_app = max(z(1),    min(z(end)    - 1e-6, z_active));
            r_clamp_app = max(r(1),    min(r(end)    - 1e-6, r_active));
            z_clamp_sc  = max(sc_z(1), min(sc_z(end) - 1e-6, z_active));
            r_clamp_sc  = max(sc_r(1), min(sc_r(end) - 1e-6, r_active));

            %% --- Applied field ---
            %Ez_local = interp2(Z_grid, R_grid, Ez_capped, ...
            %                    z_clamp_app, r_clamp_app, 'linear', 0) * pulse_factor;
            % Er_local = interp2(Z_grid, R_grid, Er_capped, ...
            %                   z_clamp_app, r_clamp_app, 'linear', 0) * pulse_factor;
%%%%%%%%%%%%%%%%%%%%%%%%%% Replacement for Ez Er interp2() %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% --- Applied field --- FAST BILINEAR (replaces interp2)
%% Step 2 — Replace in Main Loop (find the interp2 block and swap it out)
%% z_clamp_app and r_clamp_app already clamped — use directly

%% Cell indices (1-based)
iz_a = floor((z_clamp_app - app_z0) / app_dz) + 1;
ir_a = floor((r_clamp_app - app_r0) / app_dr) + 1;

%% Clamp to valid range
iz_a = max(1, min(app_nz-1, iz_a));
ir_a = max(1, min(app_nr-1, ir_a));

%% Fractional weights
wz_a = (z_clamp_app - (app_z0 + (iz_a-1)*app_dz)) / app_dz;
wr_a = (r_clamp_app - (app_r0 + (ir_a-1)*app_dr)) / app_dr;

%% Linear indices — Ez_capped is 500 rows (r) × 11000 cols (z)
idx_a   = ir_a   + (iz_a-1) * app_nr;
idx_az  = ir_a   + (iz_a  ) * app_nr;
idx_ar  = ir_a+1 + (iz_a-1) * app_nr;
idx_azr = ir_a+1 + (iz_a  ) * app_nr;

%% Bilinear interpolation — Ez
Ez_local = ( (1-wz_a).*(1-wr_a) .* Ez_capped(idx_a  ) + ...
                wz_a .*(1-wr_a) .* Ez_capped(idx_az ) + ...
             (1-wz_a).*   wr_a  .* Ez_capped(idx_ar  ) + ...
                wz_a .*   wr_a  .* Ez_capped(idx_azr ) ) * pulse_factor;

%% Bilinear interpolation — Er
Er_local = ( (1-wz_a).*(1-wr_a) .* Er_capped(idx_a  ) + ...
                wz_a .*(1-wr_a) .* Er_capped(idx_az ) + ...
             (1-wz_a).*   wr_a  .* Er_capped(idx_ar  ) + ...
                wz_a .*   wr_a  .* Er_capped(idx_azr ) ) * pulse_factor;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Add this one-time check immediately after the replacement block, 
% inside the loop but only at step == 1:
%% ONE-TIME VERIFICATION — remove after Test 30 confirms correctness
if it == 1
    Ez_ref = interp2(Z_grid, R_grid, Ez_capped, ...
                     z_clamp_app, r_clamp_app, 'linear', 0) * pulse_factor;
    Er_ref = interp2(Z_grid, R_grid, Er_capped, ...
                     z_clamp_app, r_clamp_app, 'linear', 0) * pulse_factor;
    ez_err = max(abs(Ez_local - Ez_ref));
    er_err = max(abs(Er_local - Er_ref));
    fprintf('INTERP CHECK step 1: Ez_max_err=%.2e  Er_max_err=%.2e\n', ...
            ez_err, er_err);
    %% Both should be < 1e-6 V/m — essentially machine precision
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% --- Space charge field ---
            if ENABLE_SPACE_CHARGE == true && exist('Ez_sc','var') && any(Ez_sc(:) ~= 0)
                Ez_sc_local = interp2(sc_z, sc_r, Ez_sc, ...
                                      z_clamp_sc, r_clamp_sc, 'linear', 0);
                Er_sc_local = interp2(sc_z, sc_r, Er_sc, ...
                                      z_clamp_sc, r_clamp_sc, 'linear', 0);
                Ez_local = Ez_local + Ez_sc_local;
                Er_local = Er_local + Er_sc_local;
            end

            %% --- Boris push: first half electric kick ---
            pz_minus     = pz_particles(active_idx)    - 0.5*e_charge*Ez_local*dt;
            pr_minus     = pr_particles(active_idx)    - 0.5*e_charge*Er_local*dt;
            ptheta_minus = ptheta_particles(active_idx);

            %% --- Magnetic field ---
            Bz_local = calculate_Bz_solenoid(z_active, r_active, current_t, ...
                SOLENOID_ARGS{:});
            Br_local = calculate_Br_solenoid(z_active, r_active, current_t, ...
                SOLENOID_ARGS{:});

            %% --- Boris magnetic rotation ---
            p_mag_minus = sqrt(pz_minus.^2 + pr_minus.^2 + ptheta_minus.^2);
            gamma_minus = sqrt(1 + (p_mag_minus / (m_e*c)).^2);

            t_factor = -e_charge * dt ./ (2 * gamma_minus * m_e);
            tz = t_factor .* Bz_local;
            tr = t_factor .* Br_local;

            pr_prime     = pr_minus     + ptheta_minus .* tz;
            ptheta_prime = ptheta_minus + (pz_minus .* tr - pr_minus .* tz);
            pz_prime     = pz_minus     - ptheta_minus .* tr;

            s_denom = 1 + tz.^2 + tr.^2;
            sz = 2*tz ./ s_denom;
            sr = 2*tr ./ s_denom;

            pz_plus     = pz_minus     - ptheta_prime .* sr;
            pr_plus     = pr_minus     + ptheta_prime .* sz;
            ptheta_plus = ptheta_minus + pz_prime .* sr - pr_prime .* sz;

            %% --- Second half electric kick ---
            pz_particles(active_idx)     = pz_plus     - 0.5*e_charge*Ez_local*dt;
            pr_particles(active_idx)     = pr_plus     - 0.5*e_charge*Er_local*dt;
            ptheta_particles(active_idx) = ptheta_plus;

            %% --- Position update (THE ONLY position update in the loop) ---
            p_mag_new = sqrt(pz_particles(active_idx).^2 + ...
                             pr_particles(active_idx).^2 + ...
                             ptheta_particles(active_idx).^2);
            gamma_new = sqrt(1 + (p_mag_new / (m_e*c)).^2);

            %% Update gamma_particles here — used by ion creation & scattering
            gamma_particles(active_idx) = gamma_new;

            vz_new = pz_particles(active_idx) ./ (gamma_new * m_e);
            vr_new = pr_particles(active_idx) ./ (gamma_new * m_e);

            z_particles(active_idx) = z_active + vz_new * dt;
            r_particles(active_idx) = r_active + vr_new * dt;

            %% Enforce r >= 0
            neg_r = r_particles(active_idx) < 0;
            if any(neg_r)
                neg_g = active_idx(neg_r);
                r_particles(neg_g)      = abs(r_particles(neg_g));
                pr_particles(neg_g)     = -pr_particles(neg_g);
                ptheta_particles(neg_g) = -ptheta_particles(neg_g);
            end

            %% ============================================================
            %% [FIX-11] CROSSING DETECTION
            %%   z_active = pre-push positions  (assigned above, before losses)
            %%   z_new    = post-push positions  (just written to z_particles)
            %%   This block is the ONLY place crossings are detected.
            %% ============================================================
            z_new = z_particles(active_idx);

            %% --- Monitor crossings ---
            for mon = 1:n_monitors
                z_mon    = monitor_positions(mon);
                crossing = (z_active < z_mon) & (z_new >= z_mon);
                if any(crossing)
                    for ci = find(crossing)'
                        idx_g = active_idx(ci);
                        if ~particle_counted_at_monitor(idx_g, mon)
                            I_monitor(it, mon) = I_monitor(it, mon) + ...
                                weight_particles(idx_g) * e_charge / dt;
                            particles_through(mon) = particles_through(mon) + 1;
                            particle_counted_at_monitor(idx_g, mon) = true;
                        end
                    end
                end
            end

            %% --- Anode crossing (z = 0.254 m) ---
            at_anode = (z_active < 0.254) & (z_new >= 0.254);
            if any(at_anode)
                for ii = find(at_anode)'
                    g = active_idx(ii);
                    if ~particle_crossed_anode(g)
                        particle_crossed_anode(g) = true;
                        particle_t_at_anode(g)    = current_t;
                        particle_r_at_anode(g)    = r_particles(g);
                        particles_at_anode        = particles_at_anode + 1;
                        I_anode_accumulator       = I_anode_accumulator + ...
                                                    weight_particles(g) * e_charge;
                        pm_c  = sqrt(pz_particles(g)^2 + ...
                                     pr_particles(g)^2 + ...
                                     ptheta_particles(g)^2);
                        gam_c = sqrt(1 + (pm_c/(m_e*c))^2);
                        particle_KE_at_anode(g) = (gam_c - 1) * m_e * c^2 / e_charge;
                    end
                end
            end

            %% --- Exit crossing (z = 8.305 m) ---
            at_exit = (z_active < 8.305) & (z_new >= 8.305);
            if any(at_exit)
                for ii = find(at_exit)'
                    g = active_idx(ii);
                    if ~particle_crossed_exit(g)
                        particle_crossed_exit(g) = true;
                        particle_t_at_exit(g)    = current_t;
                        particles_transmitted    = particles_transmitted + 1;
                        I_exit_accumulator       = I_exit_accumulator + ...
                                                   weight_particles(g) * e_charge;
                        pm_e  = sqrt(pz_particles(g)^2 + ...
                                     pr_particles(g)^2 + ...
                                     ptheta_particles(g)^2);
                        gam_e = sqrt(1 + (pm_e/(m_e*c))^2);
                        particle_KE_at_exit(g) = (gam_e - 1) * m_e * c^2 / e_charge;
                        %% Remove immediately — prevents out-of-domain trap
                        active_particles(g) = false;
                        n_active = n_active - 1;
                    end
                end
            end
            %% ============================================================
            %% END [FIX-11] CROSSING DETECTION
            %% ============================================================

        end  %% ~isempty(active_idx)
    end  %% n_active > 0
    %% ==================== END PARTICLE PUSH ====================

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End of new third section %%%%%%%%%%%%%%%%%%%%%
    %% ==================== CURRENT CONVERSION ====================
    %%  Runs every timestep. Accumulator → current array every 10 steps.

    if mod(it, 10) == 0
        I_anode(it)         = I_anode_accumulator / (10 * dt);
        I_anode_accumulator = 0;
    else
        if it > 1, I_anode(it) = I_anode(it-1); end
    end

    if mod(it, 10) == 0
        I_exit(it)         = I_exit_accumulator / (10 * dt);
        I_exit_accumulator = 0;
    else
        if it > 1, I_exit(it) = I_exit(it-1); end
    end

    %% Collection efficiency
    if I_cathode(it) > 0
        collection_efficiency(it) = 100 * I_anode(it) / I_cathode(it);
    end

    %% ==================== OUT-OF-BOUNDS SAFETY NET ====================
    %%  Catches any particle that slipped past the exit trap
    %%  (e.g. emitted at z>8.305 in a single step at very high energy).
    %%  Does NOT count as transmitted — these are numerical artefacts.

    if n_active > 0
        active_idx_chk = find(active_particles);
        z_chk = z_particles(active_idx_chk);
        r_chk = r_particles(active_idx_chk);
        oob   = (z_chk > 8.31) | (r_chk > 0.5) | (z_chk < -0.5);
        if any(oob)
            active_particles(active_idx_chk(oob)) = false;
            n_active = n_active - sum(oob);
            particles_out_of_bounds = particles_out_of_bounds + sum(oob);
        end
    end

    %% ==================== STORE ACTIVE COUNT ====================
    n_active_history(it) = n_active;

    %% ==================== RMS RADIUS VS Z ====================
    if mod(it, diag_interval) == 0 && n_active > 0
        active_idx = find(active_particles);
        z_diag     = z_particles(active_idx);
        r_diag     = r_particles(active_idx);
        for iz = 1:n_z_diagnostic
            in_sl = abs(z_diag - z_diagnostic(iz)) < 0.005;
            if sum(in_sl) > 10
                r_rms_history(it, iz)    = sqrt(mean(r_diag(in_sl).^2));
                n_particles_vs_z(it, iz) = sum(in_sl);
            end
        end
    end

    %% ==================== PER-1000-STEP DIAGNOSTICS ====================
    if mod(it, 1000) == 0

        active_idx = find(active_particles);
        n_active   = length(active_idx);

        %% --- Wall loss rate ---
        step_history(end+1)      = it;
        wall_loss_history(end+1) = particles_lost_to_walls;

        if length(step_history) >= 2
            d_steps  = step_history(end)      - step_history(end-1);
            d_losses = wall_loss_history(end)  - wall_loss_history(end-1);
            loss_rate = d_losses / max(d_steps, 1);
            fprintf('\n  [WALL LOSS] total=%d  last_1000=%d  rate=%.2e/step', ...
                    particles_lost_to_walls, d_losses, loss_rate);
        end

        %% --- Accounting closure ---
        active_idx_all = find(active_particles);
        total_accounted = particles_lost_to_cathode + ...
                          particles_lost_to_walls   + ...
                          particles_out_of_bounds   + ...
                          particles_transmitted     + ...
                          length(active_idx_all);
        unaccounted = n_created - total_accounted;
        if unaccounted ~= 0
            fprintf('\n  [ACCT WARN] unaccounted=%d  created=%d  accounted=%d', ...
                    unaccounted, n_created, total_accounted);
        else
            fprintf('\n  [ACCT OK]   closure=0  created=%d', n_created);
        end

        %% --- Transmission projection ---
        if it > 2000
            n_crossed_anode = sum(particle_crossed_anode(1:n_created));
            n1 = sum(active_particles(1:n_created));
            n2 = sum(particle_crossed_anode(1:n_created));
            n_in_drift = n1 + n2;
            %n_in_drift      = sum(active_particles(1:n_created) & ...
            %                     particle_crossed_anode(1:n_created));

            fprintf('\n  [TRANS] anode=%d  transmitted=%d  in_drift=%d', ...
                    n_crossed_anode, particles_transmitted, n_in_drift);

            if n_crossed_anode > 0
                fprintf('  eff=%.1f%%', ...
                        100*particles_transmitted/n_crossed_anode);
            end

            if current_t > 270e-9 && length(wall_loss_history) >= 2
                steps_rem  = nt - it;
                d_steps    = step_history(end)     - step_history(end-1);
                d_losses   = wall_loss_history(end) - wall_loss_history(end-1);
                rate       = d_losses / max(d_steps, 1);
                proj_exit  = particles_transmitted + ...
                             max(0, n_in_drift - rate*steps_rem);
                if n_crossed_anode > 0
                    fprintf('  proj_final=%.1f%%', ...
                            100*proj_exit/n_crossed_anode);
                end
            end
        end

        %% --- Energy distribution ---
        if n_active > 100
            pz_d  = pz_particles(active_idx);
            pr_d  = pr_particles(active_idx);
            pt_d  = ptheta_particles(active_idx);
            pm_d  = sqrt(pz_d.^2 + pr_d.^2 + pt_d.^2);
            gam_d = sqrt(1 + (pm_d/(m_e*c)).^2);
            KE_d  = (gam_d - 1) * 0.511;   % MeV

            %% Drift-tube particles only (z > 0.254 m) for meaningful mean
            in_dt  = z_particles(active_idx) > 0.254;
            if sum(in_dt) > 50
                KE_dt = KE_d(in_dt);
                fprintf('\n  [KE drift] mean=%.4f MeV  std=%.4f MeV  min=%.4f  max=%.4f', ...
                        mean(KE_dt), std(KE_dt), min(KE_dt), max(KE_dt));
            end
        end

        %% --- Beam radial distribution ---
        if n_active > 0
            z_act = z_particles(active_idx);
            r_act = r_particles(active_idx);
            in_dr = z_act > 0.500;
            if any(in_dr)
                r_dr = r_act(in_dr);
                fprintf('\n  [BEAM r] drift RMS=%.1fmm  max=%.1fmm  >75mm=%d(%.1f%%)', ...
                        sqrt(mean(r_dr.^2))*1000, max(r_dr)*1000, ...
                        sum(r_dr > 0.075), ...
                        100*sum(r_dr > 0.075)/length(r_dr));
            end
        end

        %% --- Current summary ---
        fprintf('\n  [CURRENT] cathode=%.1fA  anode=%.1fA  exit=%.1fA', ...
                I_cathode(it), I_anode(it), I_exit(it));

        %% --- SC summary ---
        %if ENABLE_SPACE_CHARGE && exist('Ez_sc','var')
        %   fprintf('\n  [SC] Ez_max=%.3f MV/m  Er_max=%.3f MV/m', ...
        %            max(abs(Ez_sc(:)))/1e6, max(abs(Er_sc(:)))/1e6);
        % end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% New SC Monitor %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       %% In Block 3, replace the SC field monitor block with this:

        %% --- KE at crossings (once enough data) ---
        n_anode_rec = sum(particle_KE_at_anode(1:n_created) > 0);
        n_exit_rec  = sum(particle_KE_at_exit(1:n_created)  > 0);
        if n_anode_rec > 100
            KE_an_MeV = particle_KE_at_anode(1:n_created);
            KE_an_MeV = KE_an_MeV(KE_an_MeV > 0) / 1e6;
            fprintf('\n  [KE@anode] mean=%.4f MeV  n=%d', mean(KE_an_MeV), n_anode_rec);
        end
        if n_exit_rec > 100
            KE_ex_MeV = particle_KE_at_exit(1:n_created);
            KE_ex_MeV = KE_ex_MeV(KE_ex_MeV > 0) / 1e6;
            fprintf('\n  [KE@exit]  mean=%.4f MeV  n=%d', mean(KE_ex_MeV), n_exit_rec);
        end

        fprintf('\n');

    end  %% mod(it,1000)==0

    %% ==================== SNAPSHOT CAPTURE for P1 ====================
    %%  Four fixed-time snapshots during pulse flat-top, see line 517
    if ENABLE_SNAPSHOTS == true && any(abs(current_t - snapshot_times) < dt/2)
        snapshot_count = snapshot_count + 1;
        active_idx     = find(active_particles);
        drift_idx      = active_idx(z_particles(active_idx) > 0.254);

        snapshot_data(snapshot_count).time       = current_t;
        snapshot_data(snapshot_count).z          = z_particles(drift_idx);
        snapshot_data(snapshot_count).r          = r_particles(drift_idx);
        snapshot_data(snapshot_count).pz         = pz_particles(drift_idx);
        snapshot_data(snapshot_count).pr         = pr_particles(drift_idx);
        snapshot_data(snapshot_count).ptheta     = ptheta_particles(drift_idx);
        snapshot_data(snapshot_count).gamma      = gamma_particles(drift_idx);
        snapshot_data(snapshot_count).weight     = weight_particles(drift_idx);
        snapshot_data(snapshot_count).n_particles = length(drift_idx);

        fprintf('\n  [SNAPSHOT %d] t=%.1f ns  %d drift particles\n', ...
                snapshot_count, current_t*1e9, length(drift_idx));
    end

    %% ==================== BETATRON AVERAGING SNAPSHOTS ====================
    %%  Early, late, and P1 mid-pulse snapshot arrays.
    if ENABLE_BETATRON_AVERAGING == true

        if ENABLE_MULTIPULSE == true

            %% Multi-pulse snapshot capture
            if ENABLE_SNAPSHOTS == true
                active_snap = find(active_particles);
                if ~isempty(active_snap)
                    snap_data.z = z_particles(active_snap);
                    snap_data.r = r_particles(active_snap);
                    snap_data.pz = pz_particles(active_snap);
                    snap_data.pr = pr_particles(active_snap);
                    snap_data.ptheta = ptheta_particles(active_snap);
                    snap_data.gamma = gamma_particles(active_snap);
                    snap_data.weight = weight_particles(active_snap);
                    snap_data.t = current_t;

                    %% P1 snapshots
                    if snapshot_p1_count < N_SNAPSHOTS
                        for ks = 1:N_SNAPSHOTS
                            if abs(current_t - SNAPSHOT_P1_TIMES(ks)) < dt*0.51 && ...
                               isempty(snapshot_p1{ks})
                                snapshot_p1{ks} = snap_data;
                                snapshot_p1_count = snapshot_p1_count + 1;
                            end
                        end
                    end
                    %% P2 snapshots
                    if snapshot_p2_count < N_SNAPSHOTS
                        for ks = 1:N_SNAPSHOTS
                            if abs(current_t - SNAPSHOT_P2_TIMES(ks)) < dt*0.51 && ...
                               isempty(snapshot_p2{ks})
                                snapshot_p2{ks} = snap_data;
                                snapshot_p2_count = snapshot_p2_count + 1;
                            end
                        end
                    end
                    %% P3 snapshots (only if n_pulses >= 3)
                    if pulse_config.n_pulses >= 3 && snapshot_p3_count < N_SNAPSHOTS
                        for ks = 1:N_SNAPSHOTS
                            if abs(current_t - SNAPSHOT_P3_TIMES(ks)) < dt*0.51 && ...
                               isempty(snapshot_p3{ks})
                                snapshot_p3{ks} = snap_data;
                                snapshot_p3_count = snapshot_p3_count + 1;
                            end
                        end
                    end
                    %% P4 snapshots (only if n_pulses >= 4)
                    if pulse_config.n_pulses >= 4 && snapshot_p4_count < N_SNAPSHOTS
                        for ks = 1:N_SNAPSHOTS
                            if abs(current_t - SNAPSHOT_P4_TIMES(ks)) < dt*0.51 && ...
                               isempty(snapshot_p4{ks})
                                snapshot_p4{ks} = snap_data;
                                snapshot_p4_count = snapshot_p4_count + 1;
                            end
                        end
                    end
                end
            end

        else

            %% Single-pulse snapshot capture (V3 existing logic)
            %% Early beam snapshots
            for is = 1:N_SNAPSHOTS_EARLY
                if abs(current_t - SNAPSHOT_EARLY_TIMES(is)) < dt/2
                    if isempty(snapshot_early{is})
                        active_idx = find(active_particles);
                        snapshot_early{is} = struct( ...
                            'z',       z_particles(active_idx), ...
                            'r',       r_particles(active_idx), ...
                            'pr',      pr_particles(active_idx), ...
                            'pz',      pz_particles(active_idx), ...
                            'ptheta',  ptheta_particles(active_idx), ...
                            'gamma',   gamma_particles(active_idx), ...
                            'weight',  weight_particles(active_idx), ...
                            'time',    current_t, ...
                            'n_total', length(active_idx));
                        snapshot_early_count = snapshot_early_count + 1;
                        current_ions = 0;
                        if ENABLE_ION_ACCUMULATION && ENABLE_SPACE_CHARGE
                            current_ions = sum(ion_density_grid(:)) * ...
                                           ion_physics.superparticle_weight;
                        end
                        fprintf('\n  [EARLY snap %d/%d] t=%.1f ns  n=%d  ions=%.1e\n', ...
                                snapshot_early_count, N_SNAPSHOTS_EARLY, ...
                                current_t*1e9, length(active_idx), current_ions);
                    end
                end
            end

            %% Late beam snapshots
            for is = 1:N_SNAPSHOTS_LATE
                if abs(current_t - SNAPSHOT_LATE_TIMES(is)) < dt/2
                    if isempty(snapshot_late{is})
                        active_idx = find(active_particles);
                        snapshot_late{is} = struct( ...
                            'z',       z_particles(active_idx), ...
                            'r',       r_particles(active_idx), ...
                            'pr',      pr_particles(active_idx), ...
                            'pz',      pz_particles(active_idx), ...
                            'ptheta',  ptheta_particles(active_idx), ...
                            'gamma',   gamma_particles(active_idx), ...
                            'weight',  weight_particles(active_idx), ...
                            'time',    current_t, ...
                            'n_total', length(active_idx));
                        snapshot_late_count = snapshot_late_count + 1;
                        current_ions = 0;
                        if ENABLE_ION_ACCUMULATION && ENABLE_SPACE_CHARGE
                            current_ions = sum(ion_density_grid(:)) * ...
                                           ion_physics.superparticle_weight;
                        end
                        fprintf('\n  [LATE snap %d/%d] t=%.1f ns  n=%d  ions=%.1e\n', ...
                                snapshot_late_count, N_SNAPSHOTS_LATE, ...
                                current_t*1e9, length(active_idx), current_ions);
                    end
                end
            end

            %% P1 mid-pulse snapshots
            for is = 1:N_SNAPSHOTS
                if abs(current_t - SNAPSHOT_P1_TIMES(is)) < dt/2
                    if isempty(snapshot_p1{is})
                        active_idx = find(active_particles);
                        snapshot_p1{is} = struct( ...
                            'z',       z_particles(active_idx), ...
                            'r',       r_particles(active_idx), ...
                            'pr',      pr_particles(active_idx), ...
                            'pz',      pz_particles(active_idx), ...
                            'ptheta',  ptheta_particles(active_idx), ...
                            'gamma',   gamma_particles(active_idx), ...
                            'weight',  weight_particles(active_idx), ...
                            'time',    current_t, ...
                            'n_total', length(active_idx));
                        snapshot_p1_count = snapshot_p1_count + 1;
                        fprintf('\n  [P1 snap %d/%d] t=%.1f ns  n=%d\n', ...
                                snapshot_p1_count, N_SNAPSHOTS, ...
                                current_t*1e9, length(active_idx));
                    end
                end
            end

        end  %% ENABLE_MULTIPULSE

    end  %% ENABLE_BETATRON_AVERAGING

%%%%%%%%%%%%%%%%%%%%%%%%% Steady State Beam Capture %%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== STEADY-STATE BEAM CAPTURE ====================
%% [CHANGED] Time-based trigger replaces hardcoded it==6000
%% Captures at TWISS_PULSE1_TIME = 205ns regardless of dt or t_start
if abs(current_t - TWISS_PULSE1_TIME) < dt/2 && ...
   ~exist('steady_state_beam', 'var')
    fprintf('\n=== Steady-state beam capture at t=%.1f ns ===\n', current_t*1e9);
    active_idx = find(active_particles);
    steady_state_beam = struct( ...
        'z',       z_particles(active_idx), ...
        'r',       r_particles(active_idx), ...
        'pr',      pr_particles(active_idx), ...
        'pz',      pz_particles(active_idx), ...
        'ptheta',  ptheta_particles(active_idx), ...
        'gamma',   gamma_particles(active_idx), ...
        'weight',  weight_particles(active_idx), ...
        'vz',      pz_particles(active_idx) ./ ...
                   (gamma_particles(active_idx) * m_e), ...
        'time',    current_t, ...
        'n_total', length(active_idx));
    fprintf('  Captured %d particles  z=%.1f–%.1f mm\n', ...
            steady_state_beam.n_total, ...
            min(steady_state_beam.z)*1000, ...
            max(steady_state_beam.z)*1000);
end
%%%%%%%%%%%%%%%%%%%%%%%%%% Multi-pulse regime snapshots %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% Steady State Beam Capture %%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== STEADY-STATE BEAM CAPTURE ====================
%% Unified loop — captures steady_state_beam_p1/p2/p3/p4 at TWISS_PULSE_TIMES
%% One capture per active pulse, triggered by time, guarded against double capture
%% Fields identical across all pulses — post-processing scripts work unchanged

if ENABLE_MULTIPULSE == true
    n_captures = pulse_config.n_pulses;
else
    n_captures = 1;
end

for ip = 1:n_captures
    capture_var = sprintf('steady_state_beam_p%d', ip);
    if abs(current_t - TWISS_PULSE_TIMES(ip)) < dt/2 && ...
       ~exist(capture_var, 'var')

        fprintf('\n=== Steady-state beam capture P%d at t=%.1f ns ===\n', ...
                ip, current_t*1e9);
        active_idx = find(active_particles);

        beam_snap = struct( ...
            'z',       z_particles(active_idx), ...
            'r',       r_particles(active_idx), ...
            'pr',      pr_particles(active_idx), ...
            'pz',      pz_particles(active_idx), ...
            'ptheta',  ptheta_particles(active_idx), ...
            'gamma',   gamma_particles(active_idx), ...
            'weight',  weight_particles(active_idx), ...
            'vz',      pz_particles(active_idx) ./ ...
                       (gamma_particles(active_idx) * m_e), ...
            'time',    current_t, ...
            'pulse',   ip, ...
            'n_total', length(active_idx));

        assignin('base', capture_var, beam_snap);

        fprintf('  P%d: Captured %d particles  z=%.1f-%.1f mm\n', ...
                ip, beam_snap.n_total, ...
                min(beam_snap.z)*1000, ...
                max(beam_snap.z)*1000);
    end
end
%%%%%%%%%%%%%%%%%%%%%%% Added for Figure 8 grid capture %%%%%%%%%%%%%%%%%%%%%%% 
% Add this to the main loop ion accumulation block alongside the 
% steady_state_beams capture:
%% Ion grid snapshot at TWISS_PULSE_TIMES — feeds Fig 8
for ip = 1:pulse_config.n_pulses
    if abs(current_t - TWISS_PULSE_TIMES(ip)) < dt/2 && ...
       (numel(ion_diag.snapshot_grids) < ip || ...
        isempty(ion_diag.snapshot_grids{ip}))
        ion_diag.snapshot_grids{ip} = ion_density_grid;
        fprintf('  Ion grid snapshot P%d saved at t=%.1f ns\n', ...
                ip, current_t*1e9);
    end
end
%% Backward compatibility alias — P1 capture available as steady_state_beam
%% Post-processing scripts using steady_state_beam continue to work unchanged
if exist('steady_state_beam_p1', 'var') && ~exist('steady_state_beam', 'var')
    steady_state_beam = steady_state_beam_p1;
end
%%%%%%%%%%%%%%%%%%%%%%%%%% End of Steady State Beam Capture %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% Fifth section start %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% End of the secton four %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% Fifth section start %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end  %% for it = 1:nt
%% =====================================================================
%% ==================== END OF MAIN TIME LOOP =========================
%% =====================================================================

fprintf('\n\nSimulation complete.\n');
fprintf('Total wall time: %.1f min\n', toc(tic_start)/60);
fprintf('Total wall time: %.1f hr\n', toc(tic_start)/60/60);

%%%%%%%%%%%%%%%%%%%%%%% UPDATED PULSE METRICS AND FIGURE 1 %%%%%%%%%%%%%%%%%%%%%%




%%%%% ALL OTHER FIGURES PLACEDIN THE SEPARATE SCRIPTS %%%%%%%%%%%%%%%%%%%%%%%








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% COMPLETE UPDATED SAVE BLOCK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ================================================================
%% WALL TIME
%% ================================================================
wall_time_min = toc(wall_clock_start) / 60;
fprintf('  Wall time: %.1f minutes\n', wall_time_min);

%% ================================================================
%% SAVE BLOCK
%% ================================================================
fprintf('\n================================================================\n');
fprintf('  SAVE BLOCK — Test %s  |  Mode: %s\n', TEST_ID, SAVE_MODE);
fprintf('================================================================\n');

sim_timestamp = datestr(now, 'yyyymmdd_HHMM');
sim_date_str  = datestr(now, 'yyyy-mm-dd HH:MM');
save_folder   = sprintf('./%s_%s/', TEST_ID, sim_timestamp);

fprintf('\n  Test ID:      %s\n', TEST_ID);
fprintf('  Timestamp:    %s\n',  sim_date_str);
fprintf('  Save folder:  %s\n',  save_folder);
fprintf('  Save mode:    %s\n',  SAVE_MODE);

%% ----------------------------------------------------------------
%% NONE mode
%% ----------------------------------------------------------------
if strcmpi(SAVE_MODE, 'NONE')
    fprintf('\n  [NONE mode] Nothing saved automatically.\n');
    fprintf('  Workspace remains open for manual saving.\n');
    fprintf('  To save manually when ready:\n');
    fprintf('    mkdir(''%s'')\n',   save_folder);
    fprintf('    save(''%s%s_%s.mat'')\n', ...
            save_folder, TEST_ID, sim_timestamp);
    fprintf('================================================================\n');

else
    %% Create folder
    if ~exist(save_folder, 'dir')
        mkdir(save_folder);
        fprintf('\n  Created folder: %s\n', save_folder);
    end

    %% ============================================================
    %% VARIABLE LISTS
    %% ============================================================

    %% Core — all non-NONE modes
    save_vars_core = { ...
        'TEST_ID', 'TEST_MACHINE', 'TEST_NUMBER', ...
        'TEST_NUMBER_LAPTOP', 'TEST_NUMBER_HPC', ...
        'SAVE_MODE', 'sim_timestamp', 'sim_date_str', ...
        'wall_time_min', ...
        'n_report', 'n_created', 'particles_transmitted', ...
        'particles_at_anode', ...
        'pulse_config', 'pulse_windows', 'gas_params', ...
        'ENABLE_GAS_SCATTERING', 'ENABLE_ION_ACCUMULATION', ...
        'ENABLE_MULTIPULSE', 'SCATTERING_METHOD', ...
        'I_cath_ss_all', 'I_exit_ss_all', ...
        'exit_eff_all', 'anode_eff_all', ...
        'pulse_metrics', 't', 'dt'};

    %% Diagnostics — DIAGNOSTICS / FULL / HANDOFF modes
    save_vars_diag = { ...
        'steady_state_beams', ...
        'slice_data_all', 'slice_data', ...
        'I_cathode', 'I_anode', 'I_exit', ...
        'r_rms_history', 'z_diagnostic', ...
        'sc_field_max', 'particle_weight_history', ...
        'scatter_diag', 'ion_diag', ...
        'PLOTS_AVAILABLE', 'TWISS_PULSE_TIMES', ...
        'pulse_colors', 'pulse_markers', ...
        't_plot_min', 't_plot_max', ...
        'm_e', 'c', 'e_charge', 'eps0', ...
        'slice_edges', 'slice_width', 'n_slices', ...
        'hist2d_all', 'beam_cmap', ...
        'pulse_colors_cell', 'pulse_markers_list', ...
        'n_report', 'pulse_windows', ...
        %% Ion accumulation grid and geometry — NEW
        'ion_density_grid', ...
        'sc_z', 'sc_r', 'sc_nz', 'sc_nr', 'sc_r_max', ...
        'iz_peak', 'iz_pk', ...
        'ion_long', 'ion_radial', ...
        'r_env_p1', 'r_env_p2', ...
        'r_mean_ion', 'r_rms_ion', ...
        %% Ion physics summary scalars — for Test 22 comparison
        'total_ionization_events', ...
        'ionization_rate_per_electron', ...
        'peak_ion_count', 'peak_local_density', ...
        'ion_to_gas_ratio', ...
        'sc_field_electron', 'sc_field_ion', ...
        'sc_field_ratio'};

    %% HANDOFF mode — full particle arrays
    save_vars_handoff = {};
    if strcmpi(SAVE_MODE, 'HANDOFF')
        handoff_candidates = { ...
            'particle_source_pulse', ...
            'particle_crossed_anode', ...
            'particle_crossed_exit', ...
            'particle_t_at_anode', ...
            'particle_t_at_exit', ...
            'particle_KE_at_anode', ...
            'particle_KE_at_exit', ...
            'particle_r_at_anode', ...
            'weight_particles', ...
            'z_particles', 'r_particles', ...
            'pz_particles', 'pr_particles', ...
            'gamma_particles', 'active_particles', ...
            'steady_state_beam_p1', 'steady_state_beam_p2', ...
            'steady_state_beam_p3', 'steady_state_beam_p4'};
        for iv = 1:numel(handoff_candidates)
            if exist(handoff_candidates{iv}, 'var')
                save_vars_handoff{end+1} = handoff_candidates{iv};
            end
        end
        fprintf('  HANDOFF mode: %d particle array variables found.\n', ...
                numel(save_vars_handoff));
    end

    %% Combine by mode
    switch upper(SAVE_MODE)
        case 'MINIMAL'
            all_save_vars = save_vars_core;
        case 'DIAGNOSTICS'
            all_save_vars = [save_vars_core, save_vars_diag];
        case 'FULL'
            all_save_vars = [save_vars_core, save_vars_diag];
        case 'HANDOFF'
            all_save_vars = [save_vars_core, save_vars_diag, ...
                             save_vars_handoff];
        otherwise
            all_save_vars = save_vars_core;
    end

    %% Filter to existing variables
    vars_to_save = {};
    vars_missing = {};
    for iv = 1:numel(all_save_vars)
        if exist(all_save_vars{iv}, 'var')
            vars_to_save{end+1} = all_save_vars{iv};
        else
            vars_missing{end+1} = all_save_vars{iv};
        end
    end

    fprintf('\n  Variables to save:  %d\n', numel(vars_to_save));
    if ~isempty(vars_missing)
        fprintf('  Skipped (not in workspace): %d\n', numel(vars_missing));
        for iv = 1:numel(vars_missing)
            fprintf('    skipped: %s\n', vars_missing{iv});
        end
    end

    %% ============================================================
    %% SAVE .MAT FILE
    %% ============================================================
    mat_filename = sprintf('%s%s_%s.mat', ...
                           save_folder, TEST_ID, sim_timestamp);
    mat_saved = false;
    try
        save(mat_filename, vars_to_save{:}, '-v7.3');
        mat_info  = dir(mat_filename);
        mat_saved = true;
        fprintf('\n  .mat saved:  %s\n',    mat_filename);
        fprintf('  File size:   %.1f MB\n', mat_info.bytes/1e6);
    catch ME
        fprintf('  [ERROR] .mat save failed: %s\n', ME.message);
    end

    %% ============================================================
    %% CSV SUMMARY ROW
    %% ============================================================

    %% Safe CSV_MODE default
    if ~exist('CSV_MODE','var')
        CSV_MODE = 'LOCAL';
        fprintf('  [WARNING] CSV_MODE not set — defaulting to LOCAL\n');
    end

    if strcmpi(CSV_MODE, 'PARENT')
        csv_path = './PierceGun_TestLog.csv';
    else
        csv_path = sprintf('%sPierceGun_TestLog_%s.csv', ...
                           save_folder, TEST_ID);
    end

    %% Collect per-pulse beam metrics safely
    eff_p1  = NaN;  eff_p2  = NaN;
    emit_p1 = NaN;  emit_p2 = NaN;
    rRMS_p1 = NaN;  rRMS_p2 = NaN;
    curr_p1 = NaN;  curr_p2 = NaN;

    if exist('exit_eff_all','var')
        if numel(exit_eff_all) >= 1; eff_p1 = exit_eff_all(1); end
        if numel(exit_eff_all) >= 2; eff_p2 = exit_eff_all(2); end
    end
    if exist('slice_data_all','var') && exist('n_report','var')
        for ip_csv = 1:min(n_report, 2)
            sd_csv    = slice_data_all{ip_csv};
            valid_csv = ~isnan([sd_csv.emittance]);
            if any(valid_csv)
                if ip_csv == 1
                    emit_p1 = mean([sd_csv(valid_csv).emittance]);
                    rRMS_p1 = mean([sd_csv(valid_csv).r_rms]) * 1000;
                    curr_p1 = mean([sd_csv(valid_csv).current]);
                else
                    emit_p2 = mean([sd_csv(valid_csv).emittance]);
                    rRMS_p2 = mean([sd_csv(valid_csv).r_rms]) * 1000;
                    curr_p2 = mean([sd_csv(valid_csv).current]);
                end
            end
        end
    end

    %% Collect ion physics metrics safely
    total_ions_csv  = NaN;  peak_ions_csv   = NaN;
    ion_gas_ratio   = NaN;  sc_ratio_csv    = NaN;
    peak_ion_z_csv  = NaN;  ion_centroid_csv = NaN;

    if exist('ion_density_grid','var') && sum(ion_density_grid(:)) > 0
        total_ions_csv   = sum(ion_density_grid(:));
        peak_ions_csv    = max(ion_density_grid(:));
    end
    if exist('ion_to_gas_ratio','var')
        ion_gas_ratio = ion_to_gas_ratio;
    end
    if exist('sc_field_ratio','var')
        sc_ratio_csv = sc_field_ratio;
    end
    if exist('iz_pk','var') && exist('sc_z','var')
        peak_ion_z_csv = sc_z(iz_pk)*1000;
    end
    if exist('r_mean_ion','var')
        ion_centroid_csv = r_mean_ion*1000;
    end

    %% Transmission and scatter stats
    wall_loss_pct = 100 * (1 - particles_transmitted / max(n_created,1));
    trans_pct     = 100 * particles_transmitted / max(n_created,1);
    pressure_mbar = gas_params.P / 133.322;
    sc_events     = 0;
    if exist('scatter_diag','var') && ...
       exist('ENABLE_GAS_SCATTERING','var') && ENABLE_GAS_SCATTERING
        if isfield(scatter_diag,'event_count')
            sc_events = scatter_diag.event_count;
        end
    end

    %% Safe ENABLE_SC default
    if ~exist('ENABLE_SC','var'); ENABLE_SC = false; end

    %% Write CSV
    write_header = ~exist(csv_path, 'file');
    fid = fopen(csv_path, 'a');
    if fid == -1
        fprintf('  [WARNING] Cannot open CSV: %s\n', csv_path);
    else
        if write_header
            fprintf(fid, ['TestID,Machine,DateTime,nPulses,' ...
                'Pressure_mbar,SAVE_MODE,' ...
                'P1_ExitEff_pct,P2_ExitEff_pct,' ...
                'P1_Emittance_mmmrad,P2_Emittance_mmmrad,' ...
                'P1_rRMS_mm,P2_rRMS_mm,' ...
                'P1_Current_A,P2_Current_A,' ...
                'WallLoss_pct,Transmission_pct,' ...
                'SC_enabled,Gas_enabled,IonAccum_enabled,' ...
                'ScatterEvents,' ...
                'TotalIons,PeakIons,' ...
                'IonGasRatio,SC_FieldRatio,' ...
                'PeakIon_z_mm,IonCentroid_r_mm,' ...
                'Runtime_min\n']);
            fprintf('  CSV header written: %s\n', csv_path);
        end
        fprintf(fid, '%s,%s,%s,%d,%.3e,%s,', ...
                TEST_ID, TEST_MACHINE, sim_date_str, ...
                n_report, pressure_mbar, SAVE_MODE);
        fprintf(fid, '%.2f,%.2f,',  eff_p1,  eff_p2);
        fprintf(fid, '%.4f,%.4f,',  emit_p1, emit_p2);
        fprintf(fid, '%.2f,%.2f,',  rRMS_p1, rRMS_p2);
        fprintf(fid, '%.3f,%.3f,',  curr_p1, curr_p2);
        fprintf(fid, '%.2f,%.2f,',  wall_loss_pct, trans_pct);
        fprintf(fid, '%d,%d,%d,',   ...
                ENABLE_SC, ENABLE_GAS_SCATTERING, ...
                ENABLE_ION_ACCUMULATION);
        fprintf(fid, '%d,',         sc_events);
        fprintf(fid, '%.3e,%.3e,',  total_ions_csv, peak_ions_csv);
        fprintf(fid, '%.3e,%.3e,',  ion_gas_ratio,  sc_ratio_csv);
        fprintf(fid, '%.1f,%.1f,',  peak_ion_z_csv, ion_centroid_csv);
        fprintf(fid, '%.1f\n',      wall_time_min);
        fclose(fid);
        fprintf('  CSV row appended: %s\n', csv_path);
    end

    %% ============================================================
    %% INTERACTIVE FIGURE SAVE MENU
    %% ============================================================
    if ~strcmpi(SAVE_MODE, 'MINIMAL')
        all_figs = findall(0, 'Type','figure');

        %% Sort figures by Number for natural display order
        fig_nums = arrayfun(@(f) get(f,'Number'), all_figs);
        [~, sort_idx] = sort(fig_nums, 'ascend');
        all_figs = all_figs(sort_idx);
        n_figs   = numel(all_figs);

        if n_figs == 0
            fprintf('\n  No open figures to save.\n');
        else
            fprintf('\n================================================================\n');
            fprintf('  FIGURE SAVE MENU — %d figures open\n', n_figs);
            fprintf('================================================================\n');

            fig_names = cell(n_figs, 1);
            for ifig = 1:n_figs
                fname = get(all_figs(ifig), 'Name');
                if isempty(fname)
                    fname = sprintf('Figure_%d', ...
                            get(all_figs(ifig), 'Number'));
                end
                fig_names{ifig} = fname;
                fprintf('  [%2d]  Fig %d  —  %s\n', ...
                        ifig, get(all_figs(ifig),'Number'), fname);
            end

            fprintf('----------------------------------------------------------------\n');
            fprintf('  ALL   — save all figures as PNG\n');
            fprintf('  NONE  — skip figure saving\n');
            fprintf('  or enter numbers:  3,5,7\n');
            fprintf('----------------------------------------------------------------\n');

            user_input = strtrim(upper(input('  Your selection: ', 's')));

            if strcmpi(user_input, 'NONE')
                fig_indices = [];
                fprintf('  Figure saving skipped.\n');
            elseif strcmpi(user_input, 'ALL')
                fig_indices = 1:n_figs;
                fprintf('  Saving all %d figures.\n', n_figs);
            else
                parts = strsplit(user_input, {',',' '});
                fig_indices = [];
                for ip = 1:numel(parts)
                    val = str2double(strtrim(parts{ip}));
                    if ~isnan(val) && val >= 1 && val <= n_figs
                        fig_indices(end+1) = round(val);
                    end
                end
                fprintf('  Saving %d selected figure(s).\n', ...
                        numel(fig_indices));
            end

            %% Save selected figures as PNG
            saved_count = 0;
            for ifig = 1:numel(fig_indices)
                idx        = fig_indices(ifig);
                fig        = all_figs(idx);
                raw_name   = fig_names{idx};
                clean_name = regexprep(raw_name,  '[^\w\s-]', '');
                clean_name = regexprep(clean_name, '\s+',     '_');
                clean_name = regexprep(clean_name, '_+',      '_');
                png_file   = sprintf('%s%s_%s_%s.png', ...
                             save_folder, TEST_ID, ...
                             sim_timestamp, clean_name);
                try
                    exportgraphics(fig, png_file, 'Resolution', 150);
                    fprintf('    saved: %s\n', png_file);
                    saved_count = saved_count + 1;
                catch
                    try
                        print(fig, png_file, '-dpng', '-r150');
                        fprintf('    saved (print): %s\n', png_file);
                        saved_count = saved_count + 1;
                    catch ME2
                        fprintf('    [ERROR] Fig %d: %s\n', ...
                                idx, ME2.message);
                    end
                end
            end
            fprintf('  %d / %d figure(s) saved as PNG.\n', ...
                    saved_count, numel(fig_indices));
        end
    end  %% figure menu

    %% ============================================================
    %% FINAL SUMMARY
    %% ============================================================
    fprintf('\n================================================================\n');
    fprintf('  SAVE COMPLETE — %s\n', TEST_ID);
    fprintf('================================================================\n');
    fprintf('  Folder:    %s\n', save_folder);
    if mat_saved
        fprintf('  .mat file: %s\n', mat_filename);
    else
        fprintf('  .mat file: [NOT SAVED — see error above]\n');
    end
    fprintf('  CSV log:   %s\n', csv_path);
    fprintf('  Mode:      %s\n', SAVE_MODE);
    fprintf('  Timestamp: %s\n', sim_date_str);
    fprintf('  Runtime:   %.1f minutes\n', wall_time_min);
    fprintf('\n  To reload this session:\n');
    if mat_saved
        fprintf('    load(''%s'')\n', mat_filename);
    end
    fprintf('================================================================\n');

end  %% end non-NONE block
%% ================================================================
%% END SAVE BLOCK
%% ================================================================
%%%%%%%%%%%%%%%%%%%%% Conditional HANDOFF Creation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ================================================================
%% HANDOFF FILE CREATION — conditional on SAVE_MODE = 'HANDOFF' only
%% Only generated when pretests and tuning are complete
%% ================================================================
if strcmpi(SAVE_MODE, 'HANDOFF')

    fprintf('\n================================================================\n');
    fprintf('  CREATING HANDOFF FILE FOR NEXT ACCELERATION STAGE\n');
    fprintf('  Test %s  |  Generating 3 versions: A / B / C\n', TEST_ID);
    fprintf('================================================================\n');

%% ---- n_created safety check -------------------------------------------
if ~exist('n_created','var') || isempty(n_created) || ...
   ~isscalar(n_created)     || n_created < 1
    fprintf('  ERROR: n_created invalid  cannot create handoff.\n');
    fprintf('================================================================\n');
    return
end
n_created = round(double(n_created));
fprintf('  n_created = %d (verified)\n', n_created);

%% ---- Force all crossing arrays to correct shape and length -------------
%% Use a helper pattern: extract, reshape to row, extend, reassign
%% This handles ALL edge cases: scalar, column, row, short, struct field

pte  = double(particle_t_at_exit(:)');    %% force row vector, double
pke  = double(particle_KE_at_exit(:)');
pce  = logical(particle_crossed_exit(:)');
pra  = double(particle_r_at_anode(:)');
wp   = double(weight_particles(:)');

%% Extend to n_created if shorter
if numel(pte)  < n_created,  pte(n_created)  = 0;     end
if numel(pke)  < n_created,  pke(n_created)  = 0;     end
if numel(pce)  < n_created,  pce(n_created)  = false; end
if numel(pra)  < n_created,  pra(n_created)  = 0;     end
if numel(wp)   < n_created,  wp(n_created)   = 0;     end

fprintf('  Array shapes verified:\n');
fprintf('    particle_t_at_exit:    %d elements\n', numel(pte));
fprintf('    particle_KE_at_exit:   %d elements\n', numel(pke));
fprintf('    particle_crossed_exit: %d elements\n', numel(pce));
fprintf('    particle_r_at_anode:   %d elements\n', numel(pra));
fprintf('    weight_particles:      %d elements\n', numel(wp));

%% ---- Build masks using LOCAL copies (not original arrays) --------------
crossed_mask  = pce(1:n_created);
t_exit_ns     = pte(1:n_created) * 1e9;
KE_exit_all   = pke(1:n_created);

mask_A = crossed_mask & (t_exit_ns >= 190) & (t_exit_ns <= 270);
mask_B = crossed_mask;
KE_threshold_MeV = 1.0;
mask_C = crossed_mask & (KE_exit_all >= KE_threshold_MeV * 1e6);

fprintf('  Version A (flat-top 190-270ns):   %d particles\n', sum(mask_A));
fprintf('  Version B (all crossing):         %d particles\n', sum(mask_B));
fprintf('  Version C (KE > %.1f MeV):        %d particles\n', ...
        KE_threshold_MeV, sum(mask_C));

%% ---- Recompute flat-top scalars if needed ------------------------------
if ~exist('I_exit_ss','var') || ~exist('I_cath_ss','var')
    t_ns_full = t * 1e9;
    flat_mask = (t_ns_full >= 190) & (t_ns_full <= 270);
    I_exit_ss = mean(I_exit(flat_mask));
    I_cath_ss = mean(I_cathode(flat_mask));
    fprintf('  NOTE: I_exit_ss recomputed from I_exit array.\n');
end

%% ====================================================================
%% VERSION LOOP  uses local copies pte, pke, pra, wp throughout
%% ====================================================================
for ver_idx = 1:3
    switch ver_idx
        case 1
            use_mask      = mask_A;
            version_label = 'VERSION_A';
            version_desc  = 'Flat-top only (190-270ns)  idealized steady state';
        case 2
            use_mask      = mask_B;
            version_label = 'VERSION_B';
            version_desc  = 'Full pulse  all particles  realistic rise/fall';
        case 3
            use_mask      = mask_C;
            version_label = 'VERSION_C';
            version_desc  = sprintf('Natural pulse  KE > %.1f MeV threshold', ...
                                    KE_threshold_MeV);
    end

    idx = find(use_mask);   %% row index vector

    if isempty(idx)
        fprintf('\n  %s: No particles found  skipped.\n', version_label);
        continue
    end

    fprintf('\n  Processing %s (%d particles)...\n', version_label, numel(idx));

    %% Index into LOCAL copies  guaranteed correct length and shape
    t_cross   = pte(idx);   %% row vector
    KE_eV     = pke(idx);
    r_anode   = pra(idx);
    w_vec     = wp(idx);

    %% Phase space reconstruction
    gam_h  = 1 + KE_eV / (m_e * c^2 / e_charge);
    beta_h = sqrt(1 - 1./gam_h.^2);
    p_h    = gam_h .* m_e .* beta_h .* c;

    %% Build struct  all fields from local variables, no re-indexing
    ho                         = struct();
    ho.description             = sprintf('Pierce Gun PIC V3  %s', version_desc);
    ho.version                 = version_label;
    ho.date                    = datestr(now);
    ho.z_handoff               = 8.305;
    ho.n_particles             = numel(idx);       %% numel not length
    ho.t_cross                 = t_cross;
    ho.KE_eV                   = KE_eV;
    ho.KE_MeV                  = KE_eV / 1e6;
    ho.gamma                   = gam_h;
    ho.beta                    = beta_h;
    ho.pz                      = p_h;
    ho.r_at_anode              = r_anode;
    ho.weight                  = w_vec;

    %% Statistics
    ho.KE_mean_MeV             = mean(ho.KE_MeV);
    ho.KE_std_MeV              = std(ho.KE_MeV);
    ho.KE_min_MeV              = min(ho.KE_MeV);
    ho.KE_max_MeV              = max(ho.KE_MeV);
    ho.t_mean_ns               = mean(t_cross) * 1e9;
    ho.t_min_ns                = min(t_cross)  * 1e9;
    ho.t_max_ns                = max(t_cross)  * 1e9;
    ho.pulse_duration_ns       = ho.t_max_ns - ho.t_min_ns;
    ho.I_peak_A                = I_exit_ss;
    ho.transmission_pct        = 100 * numel(idx) / n_created;
    ho.flatop_transmission_pct = 100 * I_exit_ss / max(I_cath_ss, 1);

    %% Time-resolved current profile
    t_bins      = linspace(ho.t_min_ns - 1, ho.t_max_ns + 1, 101);
    t_centers   = 0.5 * (t_bins(1:end-1) + t_bins(2:end));
    [n_bin, ~]  = histcounts(t_cross * 1e9, t_bins);
    dt_bin      = mean(diff(t_bins)) * 1e-9;
    w_pos       = w_vec(w_vec > 0);
    w_mean      = mean(w_pos);
    ho.pulse_t_ns      = t_centers;
    ho.pulse_I_A       = n_bin * w_mean * e_charge / dt_bin;
    ho.pulse_I_peak_A  = max(ho.pulse_I_A);

    %% Save
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Use save_folder as path prefix — underscore separators — no spaces
    if exist('save_folder','var') && exist(save_folder,'dir')
             fname = sprintf('%shandoff_%s_%s_%s.mat', ...
                    save_folder, TEST_ID, version_label, sim_timestamp);
    else
    %% Fallback if Block 2 did not run or SAVE_MODE = NONE
    fname = sprintf('handoff_%s_%s_%s.mat', ...
                    TEST_ID, version_label, ...
                    datestr(now, 'yyyymmdd_HHMMSS'));
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf('  === %s SUMMARY ===\n',        version_label);
    fprintf('  Description:        %s\n',    version_desc);
    fprintf('  Particles:          %d\n',    ho.n_particles);
    fprintf('  KE mean:            %.4f MeV\n', ho.KE_mean_MeV);
    fprintf('  KE std:             %.4f MeV  (%.2f%% spread)\n', ...
            ho.KE_std_MeV, 100*ho.KE_std_MeV/max(ho.KE_mean_MeV,1e-9));
    fprintf('  KE range:           %.4f - %.4f MeV\n', ...
            ho.KE_min_MeV, ho.KE_max_MeV);
    fprintf('  Arrival window:     %.1f - %.1f ns\n', ...
            ho.t_min_ns, ho.t_max_ns);
    fprintf('  Pulse duration:     %.1f ns\n',  ho.pulse_duration_ns);
    fprintf('  Peak current:       %.1f A\n',   ho.pulse_I_peak_A);
    fprintf('  Transmission:       %.1f%%\n',   ho.transmission_pct);
    fprintf('  Saved to:           %s\n',       fname);

end  %% version loop

fprintf('\n================================================================\n');
fprintf('  ALL HANDOFF FILES CREATED\n');
fprintf('  VERSION_A  idealized flat-top for benchmarking\n');
fprintf('  VERSION_B  full realistic pulse with rise/fall\n');
fprintf('  VERSION_C  natural pulse with KE threshold applied\n');
fprintf('================================================================\n');
%%%%%%%%%%%%%%%%%%%%% Handoff File Creation End %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    fprintf('\n  [HANDOFF skipped] SAVE_MODE = %s\n', SAVE_MODE);
    fprintf('  Set SAVE_MODE = ''HANDOFF'' when tuning is complete\n');
    fprintf('  to generate handoff files for next acceleration stage.\n');

end  %% HANDOFF conditional
%% ================================================================
%% END HANDOFF FILE CREATION
%% ================================================================

%%%%%%%%%%%%%%%%%%%% Updated Helper Functions 02.12.2026 %%%%%%%%%%%%%%%%%%%%%%%
%% ======================== HELPER FUNCTIONS (EXTENDED) ====================
%%%%%%%%%%%%%%%%%%%%%%%%% New Helper  Function for dual pulse %%%%%%%%%%%%%%%%%
%% ==================== HELPER FUNCTIONS (at end of file) ====================
function factor = pulse_shape_func(t, pulse_start, pulse_rise, pulse_flat, pulse_fall)
    % Single pulse (backward compatible)
    if t < pulse_start
        factor = 0;
    elseif t < pulse_start + pulse_rise
        phase = (t - pulse_start) / pulse_rise;
        factor = 0.5 * (1 + sin(pi * (phase - 0.5)));
    elseif t < pulse_start + pulse_rise + pulse_flat
        factor = 1;
    elseif t < pulse_start + pulse_rise + pulse_flat + pulse_fall
        phase = (t - pulse_start - pulse_rise - pulse_flat) / pulse_fall;
        factor = 0.5 * (1 + sin(pi * (0.5 - phase)));
    else
        factor = 0;
    end
end

function factor = pulse_shape_multipulse(t, config)
    % Multi-pulse capability
    factor = 0;  % Start with no field
    
    for ip = 1:config.n_pulses
        t_pulse = t - config.pulse_starts(ip);
        
        if t_pulse < 0
            continue;  % Before this pulse starts
        elseif t_pulse < config.rise_time
            % Rising edge
            phase = t_pulse / config.rise_time;
            pulse_factor = 0.5 * (1 + sin(pi * (phase - 0.5)));
        elseif t_pulse < config.rise_time + config.flat_time
            % Flat top
            pulse_factor = 1;
        elseif t_pulse < config.rise_time + config.flat_time + config.fall_time
            % Falling edge
            phase = (t_pulse - config.rise_time - config.flat_time) / config.fall_time;
            pulse_factor = 0.5 * (1 + sin(pi * (0.5 - phase)));
        else
            % After this pulse ends
            pulse_factor = 0;
        end
        
        % Take maximum (allows pulse overlap if needed)
        factor = max(factor, pulse_factor);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% New Updated Bz Br functions %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Bz_func // Br_func %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Bz = calculate_Bz_solenoid(z_pos, r_pos, t_curr, ...
    sol1, sol2, sol3, sol4, sol5, sol7, sol8, sol9, sol10, sol11, sol12, ...
    sol14, sol15, sol16, sol17, sol18, sol19, ...
    sol20, sol21, sol22, sol23, sol24, sol25, sol26, sol27, sol28, sol29, ...
    sol30, sol31, sol32, sol33, sol34, sol35, sol36, ...
    sol38, sol39, sol40, sol41, sol42, sol43, ...
    sol45, sol46, sol47, sol48, sol49)
    
    % ========================================================================
    % SOLENOID TIMING - INDEPENDENT OF EMISSION PULSE
    % ========================================================================
    % Single-pulse mode: covers t=150-270ns (emission) + margins
    % Multi-pulse mode: covers t=150-870ns (all 4 pulses) + margins
    %
    % For single-pulse (current test):
    %   Emission: 150-270ns
    %   Solenoids: 100-370ns (50ns early, 100ns late)
    % ========================================================================
    
    % Timing parameters (adjust for multi-pulse if needed)
    t_first_pulse_start = 150e-9;    % First emission pulse
    t_last_pulse_end = 270e-9;       % Last pulse end (single-pulse mode)
    
    t_sol_start = 100e-9;            % Start 50ns before emission
    t_sol_ramp = 50e-9;              % 50ns ramp time
    t_sol_flat_start = t_sol_start + t_sol_ramp;  % 150ns
    t_sol_end = t_last_pulse_end + 100e-9;        % 370ns (100ns after pulse)
    
    % Compute solenoid amplitude factor (time-dependent, NOT pulse-dependent!)
    if t_curr < t_sol_start
        solenoid_factor = 0.0;  % Before energization
        
    elseif t_curr < t_sol_flat_start
        % Ramp-up (smooth cosine)
        t_rel = t_curr - t_sol_start;
        solenoid_factor = 0.5 * (1 - cos(pi * t_rel / t_sol_ramp));
        
    elseif t_curr < t_sol_end
        % Flat-top: FULL STRENGTH (independent of emission pulse!)
        solenoid_factor = 1.0;
        
    else
        % Stay on for particle transport
        solenoid_factor = 1.0;
    end
    
    % Sum all solenoid contributions
    Bz = solenoid_factor * (...
         solenoid_Bz(z_pos, r_pos, sol1) + solenoid_Bz(z_pos, r_pos, sol2) + ...
         solenoid_Bz(z_pos, r_pos, sol3) + solenoid_Bz(z_pos, r_pos, sol4) + ...
         solenoid_Bz(z_pos, r_pos, sol5) + solenoid_Bz(z_pos, r_pos, sol7) + ...
         solenoid_Bz(z_pos, r_pos, sol8) + solenoid_Bz(z_pos, r_pos, sol9) + ...
         solenoid_Bz(z_pos, r_pos, sol10) + solenoid_Bz(z_pos, r_pos, sol11) + ...
         solenoid_Bz(z_pos, r_pos, sol12) + solenoid_Bz(z_pos, r_pos, sol14) + ...
         solenoid_Bz(z_pos, r_pos, sol15) + solenoid_Bz(z_pos, r_pos, sol16) + ...
         solenoid_Bz(z_pos, r_pos, sol17) + solenoid_Bz(z_pos, r_pos, sol18) + ...
         solenoid_Bz(z_pos, r_pos, sol19) + solenoid_Bz(z_pos, r_pos, sol20) + ...
         solenoid_Bz(z_pos, r_pos, sol21) + solenoid_Bz(z_pos, r_pos, sol22) + ...
         solenoid_Bz(z_pos, r_pos, sol23) + solenoid_Bz(z_pos, r_pos, sol24) + ...
         solenoid_Bz(z_pos, r_pos, sol25) + solenoid_Bz(z_pos, r_pos, sol26) + ...
         solenoid_Bz(z_pos, r_pos, sol27) + solenoid_Bz(z_pos, r_pos, sol28) + ...
         solenoid_Bz(z_pos, r_pos, sol29) + solenoid_Bz(z_pos, r_pos, sol30) + ...
         solenoid_Bz(z_pos, r_pos, sol31) + solenoid_Bz(z_pos, r_pos, sol32) + ...
         solenoid_Bz(z_pos, r_pos, sol33) + solenoid_Bz(z_pos, r_pos, sol34) + ...
         solenoid_Bz(z_pos, r_pos, sol35) + solenoid_Bz(z_pos, r_pos, sol36) + ...
         solenoid_Bz(z_pos, r_pos, sol38) + solenoid_Bz(z_pos, r_pos, sol39) + ...
         solenoid_Bz(z_pos, r_pos, sol40) + solenoid_Bz(z_pos, r_pos, sol41) + ...
         solenoid_Bz(z_pos, r_pos, sol42) + solenoid_Bz(z_pos, r_pos, sol43) + ...
         solenoid_Bz(z_pos, r_pos, sol45) + solenoid_Bz(z_pos, r_pos, sol46) + ...
         solenoid_Bz(z_pos, r_pos, sol47) + solenoid_Bz(z_pos, r_pos, sol48) + ...
         solenoid_Bz(z_pos, r_pos, sol49));
end

function Br = calculate_Br_solenoid(z_pos, r_pos, t_curr, ...
    sol1, sol2, sol3, sol4, sol5, sol7, sol8, sol9, sol10, sol11, sol12, ...
    sol14, sol15, sol16, sol17, sol18, sol19, ...
    sol20, sol21, sol22, sol23, sol24, sol25, sol26, sol27, sol28, sol29, ...
    sol30, sol31, sol32, sol33, sol34, sol35, sol36, ...
    sol38, sol39, sol40, sol41, sol42, sol43, ...
    sol45, sol46, sol47, sol48, sol49)
    
    % Same timing as Bz
    t_first_pulse_start = 150e-9;
    t_last_pulse_end = 270e-9;
    
    t_sol_start = 100e-9;
    t_sol_ramp = 50e-9;
    t_sol_flat_start = t_sol_start + t_sol_ramp;
    t_sol_end = t_last_pulse_end + 100e-9;
    
    if t_curr < t_sol_start
        solenoid_factor = 0.0;
    elseif t_curr < t_sol_flat_start
        t_rel = t_curr - t_sol_start;
        solenoid_factor = 0.5 * (1 - cos(pi * t_rel / t_sol_ramp));
    elseif t_curr < t_sol_end
        solenoid_factor = 1.0;
    else
        solenoid_factor = 1.0;
    end
    
    Br = solenoid_factor * (...
         solenoid_Br(z_pos, r_pos, sol1) + solenoid_Br(z_pos, r_pos, sol2) + ...
         solenoid_Br(z_pos, r_pos, sol3) + solenoid_Br(z_pos, r_pos, sol4) + ...
         solenoid_Br(z_pos, r_pos, sol5) + solenoid_Br(z_pos, r_pos, sol7) + ...
         solenoid_Br(z_pos, r_pos, sol8) + solenoid_Br(z_pos, r_pos, sol9) + ...
         solenoid_Br(z_pos, r_pos, sol10) + solenoid_Br(z_pos, r_pos, sol11) + ...
         solenoid_Br(z_pos, r_pos, sol12) + solenoid_Br(z_pos, r_pos, sol14) + ...
         solenoid_Br(z_pos, r_pos, sol15) + solenoid_Br(z_pos, r_pos, sol16) + ...
         solenoid_Br(z_pos, r_pos, sol17) + solenoid_Br(z_pos, r_pos, sol18) + ...
         solenoid_Br(z_pos, r_pos, sol19) + solenoid_Br(z_pos, r_pos, sol20) + ...
         solenoid_Br(z_pos, r_pos, sol21) + solenoid_Br(z_pos, r_pos, sol22) + ...
         solenoid_Br(z_pos, r_pos, sol23) + solenoid_Br(z_pos, r_pos, sol24) + ...
         solenoid_Br(z_pos, r_pos, sol25) + solenoid_Br(z_pos, r_pos, sol26) + ...
         solenoid_Br(z_pos, r_pos, sol27) + solenoid_Br(z_pos, r_pos, sol28) + ...
         solenoid_Br(z_pos, r_pos, sol29) + solenoid_Br(z_pos, r_pos, sol30) + ...
         solenoid_Br(z_pos, r_pos, sol31) + solenoid_Br(z_pos, r_pos, sol32) + ...
         solenoid_Br(z_pos, r_pos, sol33) + solenoid_Br(z_pos, r_pos, sol34) + ...
         solenoid_Br(z_pos, r_pos, sol35) + solenoid_Br(z_pos, r_pos, sol36) + ...
         solenoid_Br(z_pos, r_pos, sol38) + solenoid_Br(z_pos, r_pos, sol39) + ...
         solenoid_Br(z_pos, r_pos, sol40) + solenoid_Br(z_pos, r_pos, sol41) + ...
         solenoid_Br(z_pos, r_pos, sol42) + solenoid_Br(z_pos, r_pos, sol43) + ...
         solenoid_Br(z_pos, r_pos, sol45) + solenoid_Br(z_pos, r_pos, sol46) + ...
         solenoid_Br(z_pos, r_pos, sol47) + solenoid_Br(z_pos, r_pos, sol48) + ...
         solenoid_Br(z_pos, r_pos, sol49));
end

% Keep atomic functions unchanged
function Bz = solenoid_Bz(z, r, sol)
    in_radius = r <= sol.R;
    z_factor = 0.5 * (tanh(2*(z - (sol.z_c - sol.L/2))/sol.L) - ...
                      tanh(2*(z - (sol.z_c + sol.L/2))/sol.L));
    Bz = sol.B * in_radius .* z_factor;
end

function Br = solenoid_Br(z, r, sol)
    in_radius = r <= sol.R;
    r_factor = -r/2;
    z_deriv = (2/sol.L) * (sech(2*(z - (sol.z_c - sol.L/2))/sol.L).^2 - ...
                           sech(2*(z - (sol.z_c + sol.L/2))/sol.L).^2);
    Br = sol.B * in_radius .* r_factor .* z_deriv;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End of the modelV3 script %%%%%%%%%%%%%%%%%%%%%