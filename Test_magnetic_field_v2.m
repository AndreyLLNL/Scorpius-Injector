% Updated test_magnetic_field_v2.m for 49 solenoids (extended to 8305mm)
% Includes all transport solenoids and steering magnets
clear all; close all;

% Define pulse shape (constant 1 for visualization)
pulse_shape = @(t) 1;
correction = 1.313; % Solenoid geometric factor

%% ========================= DEFINE ALL 49 SOLENOIDS =========================

% Original solenoids 1-2
solenoid1 = struct();
solenoid1.name = 'Cathode solenoid';
solenoid1.B_peak = -0.0450;      % -450 Gauss (bucking coil)
solenoid1.z_center = -0.279;     % -279mm
solenoid1.z_length = 0.106;      % 106mm
solenoid1.r_inner = 0.451;       % 451mm

solenoid2 = struct();
solenoid2.name = 'Focus solenoid';
solenoid2.B_peak = 0.0135;       % 135 Gauss
solenoid2.z_center = 0.372;      % 372mm
solenoid2.z_length = 0.195;      % 195mm
solenoid2.r_inner = 0.245;       % 245mm

% Drift tube solenoids 3-19 (as before)
solenoid3 = struct();
solenoid3.name = 'Drift solenoid 1';
solenoid3.B_peak = 0.0075;       % 75 Gauss
solenoid3.z_center = 1.14461;    % 1144.61mm
solenoid3.z_length = 0.120;
solenoid3.r_inner = 0.245;

solenoid4 = struct();
solenoid4.name = 'Drift solenoid 2';
solenoid4.B_peak = 0.0075;
solenoid4.z_center = 1.26757;
solenoid4.z_length = 0.120;
solenoid4.r_inner = 0.245;

solenoid5 = struct();
solenoid5.name = 'Drift solenoid 3';
solenoid5.B_peak = 0.0050;
solenoid5.z_center = 1.36927;
solenoid5.z_length = 0.060;
solenoid5.r_inner = 0.245;

solenoid6 = struct();
solenoid6.name = 'Steering magnet 1';
solenoid6.B_peak = 0.0000;       % Currently OFF
solenoid6.z_center = 1.41200;
solenoid6.z_length = 0.020;
solenoid6.r_inner = 0.245;

solenoid7 = struct();
solenoid7.name = 'Drift solenoid 4';
solenoid7.B_peak = 0.0025;
solenoid7.z_center = 1.49223;
solenoid7.z_length = 0.100;
solenoid7.r_inner = 0.245;

solenoid8 = struct();
solenoid8.name = 'Drift solenoid 5';
solenoid8.B_peak = 0.0025;
solenoid8.z_center = 1.59393;
solenoid8.z_length = 0.100;
solenoid8.r_inner = 0.245;

solenoid9 = struct();
solenoid9.name = 'Drift solenoid 6';
solenoid9.B_peak = 0.0025;
solenoid9.z_center = 1.71689;
solenoid9.z_length = 0.100;
solenoid9.r_inner = 0.245;

solenoid10 = struct();
solenoid10.name = 'Drift solenoid 7';
solenoid10.B_peak = 0.0025;
solenoid10.z_center = 1.81860;
solenoid10.z_length = 0.090;
solenoid10.r_inner = 0.245;

solenoid11 = struct();
solenoid11.name = 'Drift solenoid 8';
solenoid11.B_peak = 0.0020;
solenoid11.z_center = 1.94156;
solenoid11.z_length = 0.110;
solenoid11.r_inner = 0.245;

solenoid12 = struct();
solenoid12.name = 'Drift solenoid 9';
solenoid12.B_peak = 0.0020;
solenoid12.z_center = 2.04326;
solenoid12.z_length = 0.110;
solenoid12.r_inner = 0.245;

solenoid13 = struct();
solenoid13.name = 'Steering magnet 2';
solenoid13.B_peak = 0.0000;      % Currently OFF
solenoid13.z_center = 2.11200;
solenoid13.z_length = 0.020;
solenoid13.r_inner = 0.245;

solenoid14 = struct();
solenoid14.name = 'Drift solenoid 10';
solenoid14.B_peak = 0.0020;
solenoid14.z_center = 2.16622;
solenoid14.z_length = 0.090;
solenoid14.r_inner = 0.245;

solenoid15 = struct();
solenoid15.name = 'Drift solenoid 11';
solenoid15.B_peak = 0.0020;
solenoid15.z_center = 2.26793;
solenoid15.z_length = 0.100;
solenoid15.r_inner = 0.245;

solenoid16 = struct();
solenoid16.name = 'Drift solenoid 12';
solenoid16.B_peak = 0.0015;
solenoid16.z_center = 2.39089;
solenoid16.z_length = 0.110;
solenoid16.r_inner = 0.245;

solenoid17 = struct();
solenoid17.name = 'Drift solenoid 13';
solenoid17.B_peak = 0.0015;
solenoid17.z_center = 2.49259;
solenoid17.z_length = 0.110;
solenoid17.r_inner = 0.245;

solenoid18 = struct();
solenoid18.name = 'Drift solenoid 14';
solenoid18.B_peak = 0.0015;
solenoid18.z_center = 2.61555;
solenoid18.z_length = 0.090;
solenoid18.r_inner = 0.245;

solenoid19 = struct();
solenoid19.name = 'Drift solenoid 15';
solenoid19.B_peak = 0.0015;
solenoid19.z_center = 2.71726;
solenoid19.z_length = 0.100;
solenoid19.r_inner = 0.245;

%% ========================= NEW SOLENOIDS 20-49 =========================

solenoid20 = struct();
solenoid20.name = 'Drift solenoid 16';
solenoid20.B_peak = 0.0015;
solenoid20.z_center = 2.84022;
solenoid20.z_length = 0.100;
solenoid20.r_inner = 0.245;

solenoid21 = struct();
solenoid21.name = 'Drift solenoid 17';
solenoid21.B_peak = 0.0015;
solenoid21.z_center = 2.94192;
solenoid21.z_length = 0.100;
solenoid21.r_inner = 0.245;

solenoid22 = struct();
solenoid22.name = 'Drift solenoid 18';
solenoid22.B_peak = 0.0015;
solenoid22.z_center = 3.06488;
solenoid22.z_length = 0.100;
solenoid22.r_inner = 0.245;

solenoid23 = struct();
solenoid23.name = 'Drift solenoid 19';
solenoid23.B_peak = 0.0015;
solenoid23.z_center = 3.16658;
solenoid23.z_length = 0.100;
solenoid23.r_inner = 0.245;

solenoid24 = struct();
solenoid24.name = 'Drift solenoid 20';
solenoid24.B_peak = 0.0015;
solenoid24.z_center = 3.28954;
solenoid24.z_length = 0.100;
solenoid24.r_inner = 0.245;

solenoid25 = struct();
solenoid25.name = 'Drift solenoid 21';
solenoid25.B_peak = 0.0015;
solenoid25.z_center = 3.39125;
solenoid25.z_length = 0.100;
solenoid25.r_inner = 0.245;

solenoid26 = struct();
solenoid26.name = 'Drift solenoid 22';
solenoid26.B_peak = 0.0015;
solenoid26.z_center = 3.51421;
solenoid26.z_length = 0.100;
solenoid26.r_inner = 0.245;

solenoid27 = struct();
solenoid27.name = 'Drift solenoid 23';
solenoid27.B_peak = 0.0015;
solenoid27.z_center = 3.61591;
solenoid27.z_length = 0.100;
solenoid27.r_inner = 0.245;

solenoid28 = struct();
solenoid28.name = 'Drift solenoid 24';
solenoid28.B_peak = 0.0015;
solenoid28.z_center = 3.73887;
solenoid28.z_length = 0.100;
solenoid28.r_inner = 0.245;

solenoid29 = struct();
solenoid29.name = 'Drift solenoid 25';
solenoid29.B_peak = 0.0015;
solenoid29.z_center = 3.84058;
solenoid29.z_length = 0.100;
solenoid29.r_inner = 0.245;

solenoid30 = struct();
solenoid30.name = 'Drift solenoid 26';
solenoid30.B_peak = 0.0015;
solenoid30.z_center = 3.96354;
solenoid30.z_length = 0.100;
solenoid30.r_inner = 0.245;

solenoid31 = struct();
solenoid31.name = 'Drift solenoid 27';
solenoid31.B_peak = 0.0015;
solenoid31.z_center = 4.06524;
solenoid31.z_length = 0.100;
solenoid31.r_inner = 0.245;

solenoid32 = struct();
solenoid32.name = 'Drift solenoid 28';
solenoid32.B_peak = 0.0015;
solenoid32.z_center = 4.18820;
solenoid32.z_length = 0.100;
solenoid32.r_inner = 0.245;

solenoid33 = struct();
solenoid33.name = 'Drift solenoid 29';
solenoid33.B_peak = 0.0015;
solenoid33.z_center = 4.28993;
solenoid33.z_length = 0.100;
solenoid33.r_inner = 0.245;

solenoid34 = struct();
solenoid34.name = 'Drift solenoid 30';
solenoid34.B_peak = 0.0015;
solenoid34.z_center = 4.41289;
solenoid34.z_length = 0.100;
solenoid34.r_inner = 0.245;

solenoid35 = struct();
solenoid35.name = 'Drift solenoid 31';
solenoid35.B_peak = 0.0015;
solenoid35.z_center = 4.51459;
solenoid35.z_length = 0.100;
solenoid35.r_inner = 0.245;

solenoid36 = struct();
solenoid36.name = 'Drift solenoid 32';
solenoid36.B_peak = 0.0015;
solenoid36.z_center = 4.63755;
solenoid36.z_length = 0.100;
solenoid36.r_inner = 0.245;

solenoid37 = struct();
solenoid37.name = 'Steering magnet 3';
solenoid37.B_peak = 0.0000;      % Currently OFF
solenoid37.z_center = 4.67700;
solenoid37.z_length = 0.100;
solenoid37.r_inner = 0.245;

solenoid38 = struct();
solenoid38.name = 'Drift solenoid 33';
solenoid38.B_peak = 0.0015;
solenoid38.z_center = 4.73925;
solenoid38.z_length = 0.100;
solenoid38.r_inner = 0.245;

solenoid39 = struct();
solenoid39.name = 'Drift solenoid 34';
solenoid39.B_peak = 0.0015;
solenoid39.z_center = 4.86221;
solenoid39.z_length = 0.100;
solenoid39.r_inner = 0.245;

solenoid40 = struct();
solenoid40.name = 'Drift solenoid 35';
solenoid40.B_peak = 0.0015;
solenoid40.z_center = 4.96392;
solenoid40.z_length = 0.100;
solenoid40.r_inner = 0.245;

solenoid41 = struct();
solenoid41.name = 'Drift solenoid 36';
solenoid41.B_peak = 0.0015;
solenoid41.z_center = 5.08688;
solenoid41.z_length = 0.100;
solenoid41.r_inner = 0.245;

solenoid42 = struct();
solenoid42.name = 'Drift solenoid 37';
solenoid42.B_peak = 0.0015;
solenoid42.z_center = 5.18858;
solenoid42.z_length = 0.100;
solenoid42.r_inner = 0.245;

solenoid43 = struct();
solenoid43.name = 'Drift solenoid 38';
solenoid43.B_peak = 0.0015;
solenoid43.z_center = 5.31154;
solenoid43.z_length = 0.100;
solenoid43.r_inner = 0.245;

solenoid44 = struct();
solenoid44.name = 'Steering magnet 4';
solenoid44.B_peak = 0.0000;      % Currently OFF
solenoid44.z_center = 5.37700;
solenoid44.z_length = 0.100;
solenoid44.r_inner = 0.245;

solenoid45 = struct();
solenoid45.name = 'Drift solenoid 39';
solenoid45.B_peak = 0.0015;
solenoid45.z_center = 5.41324;
solenoid45.z_length = 0.100;
solenoid45.r_inner = 0.245;

solenoid46 = struct();
solenoid46.name = 'Drift solenoid 40';
solenoid46.B_peak = 0.0015;
solenoid46.z_center = 5.53620;
solenoid46.z_length = 0.100;
solenoid46.r_inner = 0.245;

solenoid47 = struct();
solenoid47.name = 'Drift solenoid 41';
solenoid47.B_peak = 0.0015;
solenoid47.z_center = 5.63791;
solenoid47.z_length = 0.100;
solenoid47.r_inner = 0.245;

solenoid48 = struct();
solenoid48.name = 'Drift solenoid 42';
solenoid48.B_peak = 0.0015;
solenoid48.z_center = 5.76087;
solenoid48.z_length = 0.100;
solenoid48.r_inner = 0.245;

solenoid49 = struct();
solenoid49.name = 'Drift solenoid 43';
solenoid49.B_peak = 0.0015;
solenoid49.z_center = 7.44800;  % Large gap to accelerator section
solenoid49.z_length = 0.100;
solenoid49.r_inner = 0.245;

%% ========================= MAGNETIC FIELD FUNCTIONS =========================

Bz_solenoid = @(z, r, solenoid) solenoid.B_peak * ...
    (r <= solenoid.r_inner) * ...
    correction * 0.5 * (tanh(2*(z - (solenoid.z_center - solenoid.z_length/2))/solenoid.z_length) - ...
           tanh(2*(z - (solenoid.z_center + solenoid.z_length/2))/solenoid.z_length));

Br_solenoid = @(z, r, solenoid) -solenoid.B_peak * (r/2) * ...
    (r <= solenoid.r_inner) * ...
    (2/solenoid.z_length) * ...
    (sech(2*(z - (solenoid.z_center - solenoid.z_length/2))/solenoid.z_length).^2 - ...
     sech(2*(z - (solenoid.z_center + solenoid.z_length/2))/solenoid.z_length).^2);

%% ========================= COMBINED FIELDS FROM ALL 49 SOLENOIDS =========================

% Create cell array of all solenoids for easy iteration
solenoids = cell(1, 49);
for i = 1:49
    solenoids{i} = eval(sprintf('solenoid%d', i));
end

% Combined Bz field
Bz_total = @(z, r, t) pulse_shape(t) * sum(cell2mat(cellfun(@(sol) Bz_solenoid(z, r, sol), solenoids, 'UniformOutput', false)));

% Combined Br field  
Br_total = @(z, r, t) pulse_shape(t) * sum(cell2mat(cellfun(@(sol) Br_solenoid(z, r, sol), solenoids, 'UniformOutput', false)));

%% ========================= PLOT EXTENDED MAGNETIC FIELD =========================

plot_extended_magnetic_field_49(solenoids, Bz_total, Br_total);

fprintf('\n=== Magnetic Field Configuration Complete ===\n');
fprintf('  Total solenoids: 49\n');
fprintf('  Transport solenoids: 45 (active)\n');
fprintf('  Steering magnets: 4 (Sol 6, 13, 37, 44 - currently OFF)\n');
fprintf('  Beamline length: 8305 mm\n');
fprintf('  Field range: 15-450 Gauss\n');

%% ========================= PLOTTING FUNCTION =========================

function plot_extended_magnetic_field_49(solenoids, Bz_func, Br_func)
    % Define z-axis for field calculation (extended to 8305mm)
    z_diag = linspace(-500, 8500, 9001) * 1e-3;  % mm to m
    r_diag = 0.0001;  % 0.1mm off-axis (avoid singularity)
    r_beam = 0.040;   % 40mm typical beam radius
    
    % Calculate field components
    Bz_diag = zeros(size(z_diag));
    Br_at_beam = zeros(size(z_diag));
    
    fprintf('\nCalculating magnetic field profile...\n');
    for i = 1:length(z_diag)
        if mod(i, 1000) == 0
            fprintf('  Progress: %.1f%%\n', 100*i/length(z_diag));
        end
        Bz_diag(i) = Bz_func(z_diag(i), r_diag, 190e-9);  % At 190ns (steady state)
        Br_at_beam(i) = Br_func(z_diag(i), r_beam, 190e-9);
    end
    
    %% FIGURE 1: Full beamline view (-500 to 8500 mm)
    figure('Position', [50, 50, 1600, 900], 'Name', 'Complete Magnetic Field Profile - All 49 Solenoids');
    
    % Axial field
    subplot(2,1,1);
    plot(z_diag*1000, Bz_diag*1e4, 'b-', 'LineWidth', 2);
    hold on;
    
    % Add solenoid position indicators (colored bars at bottom)
    y_indicator = -480;
    steering_magnets = [6, 13, 37, 44];
    
    for i = 1:length(solenoids)
        sol = solenoids{i};
        z_start = (sol.z_center - sol.z_length/2) * 1000;
        z_end = (sol.z_center + sol.z_length/2) * 1000;
        
        if ismember(i, steering_magnets)
            % Steering magnets in red
            plot([z_start, z_end], [y_indicator, y_indicator], 'r-', 'LineWidth', 4);
        else
            % Transport solenoids in various colors
            if i == 1
                color = 'r';
            elseif i == 2
                color = 'g';
            else
                color = 'm';
            end
            plot([z_start, z_end], [y_indicator, y_indicator], 'Color', color, 'LineWidth', 3);
        end
    end
    
    % Add key position markers
    xline(0, 'k--', 'Cathode', 'LineWidth', 1, 'Alpha', 0.5);
    xline(254, 'k--', 'Anode', 'LineWidth', 1, 'Alpha', 0.5);
    xline(600, 'k--', 'Drift Start', 'LineWidth', 1, 'Alpha', 0.5);
    xline(2760, 'k--', 'Original Exit', 'LineWidth', 1.5, 'Alpha', 0.7);
    xline(8305, 'k--', 'Extended Exit', 'LineWidth', 2, 'Alpha', 0.7);
    
    xlabel('Z Position [mm]', 'FontSize', 12);
    ylabel('Bz Field [Gauss]', 'FontSize', 12);
    title('Axial Magnetic Field Profile - Complete 49-Solenoid System', 'FontSize', 14);
    grid on;
    ylim([-500, 200]);
    xlim([-500, 8500]);
    
    % Add legend
    text(-200, 150, 'Cathode Sol (−450G)', 'Color', 'r', 'FontSize', 9);
    text(400, 150, 'Focus Sol (135G)', 'Color', 'g', 'FontSize', 9);
    text(2000, 150, 'Drift Sols (15-75G)', 'Color', 'm', 'FontSize', 9);
    text(5000, 150, 'Steering (OFF)', 'Color', 'r', 'FontSize', 9);
    
    % Radial field at beam edge
    subplot(2,1,2);
    plot(z_diag*1000, Br_at_beam*1e4, 'r-', 'LineWidth', 2);
    hold on;
    
    % Add key position markers
    xline(0, 'k--', 'LineWidth', 1, 'Alpha', 0.5);
    xline(254, 'k--', 'LineWidth', 1, 'Alpha', 0.5);
    xline(600, 'k--', 'LineWidth', 1, 'Alpha', 0.5);
    xline(2760, 'k--', 'LineWidth', 1.5, 'Alpha', 0.7);
    xline(8305, 'k--', 'LineWidth', 2, 'Alpha', 0.7);
    
    % Add solenoid edge indicators (fringe fields)
    for i = 1:length(solenoids)
        sol = solenoids{i};
        xline((sol.z_center - sol.z_length/2)*1000, 'k:', 'LineWidth', 0.5);
        xline((sol.z_center + sol.z_length/2)*1000, 'k:', 'LineWidth', 0.5);
    end
    
    xlabel('Z Position [mm]', 'FontSize', 12);
    ylabel(sprintf('Br Field at r=%.0f mm [Gauss]', r_beam*1000), 'FontSize', 12);
    title('Radial Field at Beam Edge', 'FontSize', 14);
    grid on;
    xlim([-500, 8500]);
    ylim([-60, 60]);
    
    sgtitle('Extended Beamline Magnetic Field: 49 Solenoids (-500mm to +8305mm)', 'FontSize', 16);
    
    %% FIGURE 2: Zoomed views of critical regions
    figure('Position', [100, 100, 1600, 900], 'Name', 'Magnetic Field - Critical Regions');
    
    % Cathode-anode-focus region
    subplot(2,2,1);
    z_zoom1 = linspace(-500, 800, 1301) * 1e-3;
    Bz_zoom1 = zeros(size(z_zoom1));
    for i = 1:length(z_zoom1)
        Bz_zoom1(i) = Bz_func(z_zoom1(i), r_diag, 190e-9);
    end
    plot(z_zoom1*1000, Bz_zoom1*1e4, 'b-', 'LineWidth', 2);
    hold on;
    xline(0, 'k--', 'Cathode');
    xline(254, 'k--', 'Anode');
    xlabel('Z [mm]');
    ylabel('Bz [Gauss]');
    title('Cathode-Anode-Focus Region');
    grid on;
    ylim([-500, 200]);
    
    % First drift solenoids
    subplot(2,2,2);
    z_zoom2 = linspace(800, 2000, 1201) * 1e-3;
    Bz_zoom2 = zeros(size(z_zoom2));
    for i = 1:length(z_zoom2)
        Bz_zoom2(i) = Bz_func(z_zoom2(i), r_diag, 190e-9);
    end
    plot(z_zoom2*1000, Bz_zoom2*1e4, 'b-', 'LineWidth', 2);
    xlabel('Z [mm]');
    ylabel('Bz [Gauss]');
    title('First Drift Solenoids (800-2000mm)');
    grid on;
    ylim([-50, 100]);
    
    % Mid-drift region
    subplot(2,2,3);
    z_zoom3 = linspace(2500, 4500, 2001) * 1e-3;
    Bz_zoom3 = zeros(size(z_zoom3));
    for i = 1:length(z_zoom3)
        Bz_zoom3(i) = Bz_func(z_zoom3(i), r_diag, 190e-9);
    end
    plot(z_zoom3*1000, Bz_zoom3*1e4, 'b-', 'LineWidth', 2);
    xlabel('Z [mm]');
    ylabel('Bz [Gauss]');
    title('Mid-Drift Region (2500-4500mm)');
    grid on;
    ylim([0, 25]);
    
    % End drift region
    subplot(2,2,4);
    z_zoom4 = linspace(5000, 8300, 3301) * 1e-3;
    Bz_zoom4 = zeros(size(z_zoom4));
    for i = 1:length(z_zoom4)
        Bz_zoom4(i) = Bz_func(z_zoom4(i), r_diag, 190e-9);
    end
    plot(z_zoom4*1000, Bz_zoom4*1e4, 'b-', 'LineWidth', 2);
    hold on;
    xline(7448, 'r--', 'Sol 49');
    xlabel('Z [mm]');
    ylabel('Bz [Gauss]');
    title('End Region (5000-8300mm)');
    grid on;
    ylim([0, 25]);
    
    sgtitle('Critical Regions - Detailed Magnetic Field Views', 'FontSize', 16);
    
    fprintf('  Magnetic field plots complete!\n');
end