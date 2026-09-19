function plotLap(results)
% PLOTLAP  Generate diagnostic telemetry plots from a practiceRace run.
%
%   plotLap(results)
%
%   INPUTS:
%     results — struct returned by practiceRace()
%
%   OUTPUTS:
%     4-panel figure:
%       1. Vehicle trajectory overlaid on track (coloured by speed)
%       2. Speed profile vs track distance
%       3. Actual steering angle vs track distance
%       4. Cross-track error vs track distance
%
%   This is the primary diagnostic tool.  Your AI agent should call
%   plotLap after every practiceRace to diagnose failures and regressions.
%
%   EXAMPLE:
%     r = practiceRace('Headless', true);
%     plotLap(r);
%
%   See also: practiceRace, AGENT_GUIDE.md

    if nargin < 1 || ~isstruct(results)
        error('plotLap: provide the results struct from practiceRace().\n  Example: r = practiceRace(''Headless'',true); plotLap(r);');
    end

    lg    = results.log;
    track = results.track;
    n     = numel(lg.t);

    % ------------------------------------------------------------------ %
    %  Compute along-track distance for each logged position             %
    % ------------------------------------------------------------------ %
    trackDist = zeros(n, 1);
    for i = 1:n
        [idx, ~, ~]   = track.findNearest(lg.x(i), lg.y(i));
        trackDist(i)  = track.cumDist(idx);
    end

    % ------------------------------------------------------------------ %
    %  Create figure                                                      %
    % ------------------------------------------------------------------ %
    fig = figure( ...
        'Name',        'AI Grand Prix — Lap Diagnostics', ...
        'Color',       [0.10 0.10 0.12], ...
        'NumberTitle', 'off', ...
        'Position',    [40, 40, 1280, 820]);

    darkAxOpts = { ...
        'Color',     [0.13 0.13 0.16], ...
        'XColor',    [0.75 0.75 0.75], ...
        'YColor',    [0.75 0.75 0.75], ...
        'GridColor', [0.30 0.30 0.30], ...
        'GridAlpha', 0.5, ...
        'FontSize',  9 };

    % ============================================================ %
    %  Panel 1 — Trajectory coloured by speed                      %
    % ============================================================ %
    ax1 = subplot(2, 2, 1, 'Parent', fig, darkAxOpts{:});
    hold(ax1, 'on');
    axis(ax1, 'equal');
    grid(ax1, 'on');

    track.plot(ax1);

    % Coloured trajectory line using surface trick
    X = [lg.x(:)'; lg.x(:)'];
    Y = [lg.y(:)'; lg.y(:)'];
    Z = zeros(2, n);
    C = [lg.v(:)'; lg.v(:)'];
    surface(ax1, X, Y, Z, C, ...
        'FaceColor', 'none', 'EdgeColor', 'interp', 'LineWidth', 2);
    colormap(ax1, 'turbo');
    caxis(ax1, [0, Vehicle.MAX_SPEED]);
    cb = colorbar(ax1);
    cb.Color       = [0.75 0.75 0.75];
    cb.Label.String = 'Speed  (m/s)';
    cb.Label.Color  = [0.75 0.75 0.75];

    % Start / end markers
    plot(ax1, lg.x(1),   lg.y(1),   'g^', 'MarkerSize', 9,  'MarkerFaceColor', 'g');
    plot(ax1, lg.x(end), lg.y(end), 'rs', 'MarkerSize', 9,  'MarkerFaceColor', 'r');

    title(ax1, 'Trajectory  (colour = speed)', 'Color', 'w', 'FontWeight', 'bold');
    xlabel(ax1, 'x  (m)'); ylabel(ax1, 'y  (m)');

    % ============================================================ %
    %  Panel 2 — Speed profile                                     %
    % ============================================================ %
    ax2 = subplot(2, 2, 2, 'Parent', fig, darkAxOpts{:});
    hold(ax2, 'on'); grid(ax2, 'on');

    plot(ax2, trackDist, lg.v, '-', 'Color', [0.3 0.85 1.0], 'LineWidth', 1.5);
    yline(ax2, Vehicle.MAX_SPEED, '--', 'Color', [1 0.4 0.3], 'LineWidth', 1.2, ...
        'Label', 'Max speed', 'LabelHorizontalAlignment', 'left');

    % Shade off-track regions red
    offMask = lg.offTrack;
    if any(offMask)
        offStart = find(diff([0; offMask]) == 1);
        offEnd   = find(diff([offMask; 0]) == -1);
        for k = 1:numel(offStart)
            d1 = trackDist(offStart(k));
            d2 = trackDist(offEnd(k));
            patch(ax2, [d1 d2 d2 d1], [0 0 Vehicle.MAX_SPEED Vehicle.MAX_SPEED], ...
                [1 0.2 0.2], 'FaceAlpha', 0.25, 'EdgeColor', 'none', 'HandleVisibility','off');
        end
    end

    title(ax2, 'Speed Profile  (red = off-track)', 'Color', 'w', 'FontWeight', 'bold');
    xlabel(ax2, 'Track distance  (m)');
    ylabel(ax2, 'Speed  (m/s)');
    ylim(ax2, [0, Vehicle.MAX_SPEED * 1.12]);
    xlim(ax2, [0, max(trackDist)]);

    % ============================================================ %
    %  Panel 3 — Actual steering angle                             %
    % ============================================================ %
    ax3 = subplot(2, 2, 3, 'Parent', fig, darkAxOpts{:});
    hold(ax3, 'on'); grid(ax3, 'on');

    plot(ax3, trackDist, lg.steeringAngle, '-', 'Color', [0.9 0.55 1.0], 'LineWidth', 1.5);
    plot(ax3, trackDist, lg.steering * Vehicle.MAX_STEER_ANGLE, '--', ...
        'Color', [0.6 0.6 0.6], 'LineWidth', 0.8);
    yline(ax3,  Vehicle.MAX_STEER_ANGLE, '--', 'Color', [1 0.4 0.3], 'LineWidth', 1);
    yline(ax3, -Vehicle.MAX_STEER_ANGLE, '--', 'Color', [1 0.4 0.3], 'LineWidth', 1);
    yline(ax3, 0, ':', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8);

    legend(ax3, 'Actual steering angle', 'Commanded (×gain)', ...
        'Color', [0.2 0.2 0.2], 'TextColor', 'w', 'EdgeColor', [0.4 0.4 0.4]);

    title(ax3, 'Steering Angle  (red dashed = saturation limit)', 'Color', 'w', 'FontWeight', 'bold');
    xlabel(ax3, 'Track distance  (m)');
    ylabel(ax3, 'Angle  (rad)');
    ylim(ax3, [-Vehicle.MAX_STEER_ANGLE*1.4, Vehicle.MAX_STEER_ANGLE*1.4]);
    xlim(ax3, [0, max(trackDist)]);

    % ============================================================ %
    %  Panel 4 — Cross-track error                                 %
    % ============================================================ %
    ax4 = subplot(2, 2, 4, 'Parent', fig, darkAxOpts{:});
    hold(ax4, 'on'); grid(ax4, 'on');

    halfW = track.width / 2;
    dMax  = max(trackDist);

    % Safe zone fill
    patch(ax4, [0, dMax, dMax, 0], [halfW, halfW, -halfW, -halfW], ...
        [0.1 0.5 0.1], 'FaceAlpha', 0.18, 'EdgeColor', 'none');

    plot(ax4, trackDist, lg.crossTrackErr, '-', 'Color', [1.0 0.85 0.2], 'LineWidth', 1.5);
    yline(ax4,  halfW, '--', 'Color', [1 0.4 0.3], 'LineWidth', 1.2, ...
        'Label', 'Left edge', 'LabelHorizontalAlignment', 'left');
    yline(ax4, -halfW, '--', 'Color', [1 0.4 0.3], 'LineWidth', 1.2, ...
        'Label', 'Right edge', 'LabelHorizontalAlignment', 'left');
    yline(ax4, 0, ':', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8);

    title(ax4, 'Cross-Track Error  (+ = left of centreline)', 'Color', 'w', 'FontWeight', 'bold');
    xlabel(ax4, 'Track distance  (m)');
    ylabel(ax4, 'Error  (m)');
    xlim(ax4, [0, dMax]);

    % ------------------------------------------------------------------ %
    %  Figure super-title                                                 %
    % ------------------------------------------------------------------ %
    if results.dnf
        ttl = sprintf('Diagnostics — DNF  |  %s', results.dnfReason);
        tCol = [1 0.4 0.3];
    else
        ttl = sprintf('Diagnostics — Lap %.2f s  |  Exits %d  |  Collisions %d  |  Score %.2f', ...
            results.lapTime, results.nOffTrack, results.nCollision, results.score);
        tCol = [0.3 0.9 0.3];
    end
    sgtitle(fig, ttl, 'Color', tCol, 'FontSize', 12, 'FontWeight', 'bold');

end
