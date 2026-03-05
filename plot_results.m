function plot_results(hw, fields, beam)
% PLOT_RESULTS  Generate diagnostic plots for the Scorpius injector model.
%
% Creates four figures:
%   Fig 1 – On-axis magnetic field Bz(z) with solenoid locations
%   Fig 2 – 2-D colour map of |B|(r,z) in the transport section
%   Fig 3 – RMS beam-envelope R(z) with BPM readout markers
%   Fig 4 – Electrostatic potential phi(z) in the diode gap

    fprintf('Generating result plots...\n');

    % ------------------------------------------------------------------
    % Figure 1 – On-axis Bz(z) with solenoid footprints
    % ------------------------------------------------------------------
    figure(1);
    clf;
    ax1 = axes;
    plot(ax1, fields.z, fields.Bz_axis * 1e3, 'b-', 'LineWidth', 1.5);
    hold(ax1, 'on');

    % Shade each solenoid as a rectangle at the bottom
    ylims = ylim(ax1);
    ymin_patch = ylims(1);
    ymax_patch = ylims(1) + 0.1 * (ylims(2) - ylims(1));
    for s = 1:numel(hw.solenoids)
        sol = hw.solenoids(s);
        if isempty(sol.id), continue; end
        x_lo = sol.z_center - sol.length/2;
        x_hi = sol.z_center + sol.length/2;
        patch(ax1, [x_lo x_hi x_hi x_lo], ...
              [ymin_patch ymin_patch ymax_patch ymax_patch], ...
              [0.8 0.8 1.0], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    end
    hold(ax1, 'off');

    xlabel(ax1, 'z [m]');
    ylabel(ax1, 'B_z [mT]');
    title(ax1, 'Scorpius Injector – On-axis Magnetic Field B_z(z)');
    legend(ax1, 'B_z(z)', 'Solenoid locations', 'Location', 'best');
    grid(ax1, 'on');
    xlim(ax1, [fields.z(1), fields.z(end)]);

    % ------------------------------------------------------------------
    % Figure 2 – 2-D |B| colour map
    % ------------------------------------------------------------------
    figure(2);
    clf;
    B_mag = sqrt(fields.Br_2d.^2 + fields.Bz_2d.^2) * 1e3;   % [mT]
    imagesc(fields.z, fields.r * 1e3, B_mag);
    axis xy;
    colorbar;
    xlabel('z [m]');
    ylabel('r [mm]');
    title('Scorpius Injector – |B(r,z)| [mT]');
    colormap('hot');

    % ------------------------------------------------------------------
    % Figure 3 – RMS beam envelope R(z) with BPM markers
    % ------------------------------------------------------------------
    figure(3);
    clf;
    ax3 = axes;
    plot(ax3, beam.z, beam.R * 1e3, 'r-', 'LineWidth', 2);
    hold(ax3, 'on');

    % BPM markers
    bpm_z   = zeros(1, numel(hw.bpms));
    bpm_R   = zeros(1, numel(hw.bpms));
    for k = 1:numel(hw.bpms)
        bpm_z(k)   = beam.bpm_readings(k).z;
        bpm_R(k)   = beam.bpm_readings(k).R_mm;
    end
    valid = ~isnan(bpm_R);
    scatter(ax3, bpm_z(valid), bpm_R(valid), 60, 'gs', ...
            'MarkerFaceColor', 'g', 'DisplayName', 'BPM readings');

    hold(ax3, 'off');
    xlabel(ax3, 'z [m]');
    ylabel(ax3, 'RMS beam radius [mm]');
    title(ax3, 'Scorpius Injector – RMS Beam Envelope');
    legend(ax3, 'Envelope R(z)', 'BPM locations', 'Location', 'best');
    grid(ax3, 'on');
    xlim(ax3, [0, 8.5]);

    % ------------------------------------------------------------------
    % Figure 4 – Diode electrostatic potential
    % ------------------------------------------------------------------
    figure(4);
    clf;
    mask = fields.phi_diode ~= 0 | fields.Ez_diode ~= 0;
    z_diode = fields.z(mask);
    if ~isempty(z_diode)
        yyaxis left;
        plot(fields.z(mask), fields.phi_diode(mask) / 1e3, 'b-', ...
             'LineWidth', 1.5);
        ylabel('\phi [kV]');
        yyaxis right;
        plot(fields.z(mask), fields.Ez_diode(mask) / 1e6, 'r--', ...
             'LineWidth', 1.5);
        ylabel('E_z [MV/m]');
    end
    xlabel('z [m]');
    title('Scorpius Injector – Diode Electrostatic Fields');
    legend('\phi(z)', 'E_z(z)', 'Location', 'best');
    grid('on');

    fprintf('Plots generated (Figures 1-4).\n\n');
end
