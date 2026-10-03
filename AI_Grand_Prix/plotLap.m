function fig = plotLap(results)
% PLOTLAP  Diagnostic plots for one practiceRace run.
%
%   plotLap(r)            r = practiceRace('Path', 'technical', 'Headless', true)
%   fig = plotLap(r)
%
%   Six panels (x axis = distance along the path, all laps):
%     1. Trajectory coloured by GRIP USE (0 = none, 1 = at the limit,
%        red crosses = understeer: the car asked for more grip than it has)
%     2. Speed vs the safe corner speed from eq. 6, and the benchmark profile
%     3. Throttle (+) and brake (-)
%     4. Battery energy left (Wh)
%     5. Elevation profile and grade
%     6. Friction circle: every step's grip use (sideways vs drive/brake)
%
%   See also: practiceRace, benchmarkTime, cornerSpeed

    if nargin < 1 || ~isstruct(results) || ~isfield(results, 'log')
        error('plotLap:input', 'Give plotLap the results of practiceRace, e.g. r = practiceRace(''Headless'', true); plotLap(r)');
    end
    r = results(1);
    lg = r.log;  course = r.course;  car = r.car;
    if isempty(lg.t), error('plotLap:empty', 'The run has no steps (the controller failed at once): %s', r.dnfReason); end
    d = lg.progress;

    fig = figure('Name', "AI Grand Prix - Lap report - " + course.name, 'Color', [0.10 0.10 0.12], ...
        'NumberTitle', 'off', 'Position', [30 30 1400 820]);
    tl = tiledlayout(fig, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    style = @(ax) set(ax, 'Color', [0.13 0.13 0.16], 'XColor', [0.75 0.75 0.75], 'YColor', [0.75 0.75 0.75], ...
        'GridColor', [0.35 0.35 0.35], 'FontSize', 9, 'XGrid', 'on', 'YGrid', 'on');
    ttl = @(ax, s) title(ax, s, 'Color', 'w', 'FontWeight', 'bold');

    % 1. Trajectory coloured by grip use
    ax = nexttile(tl);  style(ax);  hold(ax, 'on');
    course.plot(ax);
    surface(ax, [lg.x'; lg.x'], [lg.y'; lg.y'], zeros(2, numel(lg.x)), [lg.gripUse'; lg.gripUse'], ...
        'FaceColor', 'none', 'EdgeColor', 'interp', 'LineWidth', 2.2);
    colormap(ax, turbo);  clim(ax, [0 1]);
    cb = colorbar(ax);  cb.Color = [0.75 0.75 0.75];  cb.Label.String = 'grip use';
    us = lg.understeer;
    if any(us), plot(ax, lg.x(us), lg.y(us), 'rx', 'MarkerSize', 4); end
    plot(ax, lg.x(1), lg.y(1), 'g^', 'MarkerFaceColor', 'g');
    ttl(ax, 'Trajectory (colour = grip use, x = understeer)');

    % 2. Speed vs safe corner speed (eq. 6) and benchmark
    ax = nexttile(tl);  style(ax);  hold(ax, 'on');
    vc = cornerSpeed(car, lg.curvature, atan(lg.grade / 100), lg.muFactor);
    vc(~isfinite(vc)) = NaN;
    b = benchmarkTime(car, course);
    vTop = max([lg.v; car.vGear]) * 1.15;
    plot(ax, b.s, b.v, '-', 'Color', [0.6 0.6 0.6], 'LineWidth', 1);
    plot(ax, d, min(vc, vTop), ':', 'Color', [1 0.55 0.2], 'LineWidth', 1.5);
    plot(ax, d, lg.v, '-', 'Color', [0.3 0.85 1], 'LineWidth', 1.5);
    yline(ax, car.vGear, '--', 'v_{gear}', 'Color', [0.8 0.8 0.8], 'LabelHorizontalAlignment', 'left');
    ylim(ax, [0 vTop]);  xlim(ax, [0 max(d(end), 1)]);
    xlabel(ax, 'distance (m)');  ylabel(ax, 'speed (m/s)');
    legend(ax, {'benchmark (estimate)', 'safe corner speed, eq. 6', 'your speed'}, 'TextColor', 'w', ...
        'Color', [0.2 0.2 0.2], 'Location', 'southoutside', 'Orientation', 'horizontal');
    ttl(ax, 'Speed vs the corner limit');

    % 3. Throttle / brake
    ax = nexttile(tl);  style(ax);  hold(ax, 'on');
    thr = max(lg.throttle, 0);  brk = min(lg.throttle, 0);
    area(ax, d, thr, 'FaceColor', [0.2 0.8 0.3], 'EdgeColor', 'none', 'FaceAlpha', 0.7);
    area(ax, d, brk, 'FaceColor', [0.95 0.3 0.2], 'EdgeColor', 'none', 'FaceAlpha', 0.7);
    ylim(ax, [-1.1 1.1]);  xlim(ax, [0 max(d(end), 1)]);
    xlabel(ax, 'distance (m)');  ylabel(ax, 'brake (-)   throttle (+)');
    ttl(ax, 'Throttle and brake');

    % 4. Battery
    ax = nexttile(tl);  style(ax);  hold(ax, 'on');
    plot(ax, d, lg.energyJ / 3600, '-', 'Color', [0.3 0.7 1], 'LineWidth', 1.8);
    ylim(ax, [0 car.batteryWh * 1.05]);  xlim(ax, [0 max(d(end), 1)]);
    xlabel(ax, 'distance (m)');  ylabel(ax, 'energy left (Wh)');
    ttl(ax, sprintf('Battery: %.1f of %d Wh used', r.energyUsedWh, car.batteryWh));

    % 5. Elevation and grade
    ax = nexttile(tl);  style(ax);  hold(ax, 'on');
    yyaxis(ax, 'left');  plot(ax, d, lg.z, '-', 'Color', [0.85 0.75 0.5], 'LineWidth', 1.8);  ylabel(ax, 'elevation (m)');
    yyaxis(ax, 'right'); plot(ax, d, lg.grade, ':', 'Color', [0.7 0.7 0.7]);  ylabel(ax, 'grade (%)');
    ax.YAxis(1).Color = [0.85 0.75 0.5];  ax.YAxis(2).Color = [0.7 0.7 0.7];
    xlim(ax, [0 max(d(end), 1)]);  xlabel(ax, 'distance (m)');
    ttl(ax, 'Elevation');

    % 6. Friction circle
    ax = nexttile(tl);  style(ax);  hold(ax, 'on');  axis(ax, 'equal');
    th = linspace(0, 2*pi, 100);
    plot(ax, cos(th), sin(th), 'w-', 'LineWidth', 1.2);
    G = max(lg.G, eps);
    scatter(ax, -lg.Fy ./ G, lg.Fx ./ G, 6, lg.v, 'filled', 'MarkerFaceAlpha', 0.5);
    colormap(ax, parula);
    xlim(ax, [-1.25 1.25]);  ylim(ax, [-1.25 1.25]);
    xlabel(ax, 'left  <-  sideways  ->  right');  ylabel(ax, 'brake  <-  ->  drive');
    ttl(ax, 'Friction circle (colour = speed)');

    if r.dnf
        head = sprintf('%s - DNF: %s', course.name, r.dnfReason);  col = [1 0.45 0.35];
    else
        head = sprintf('%s - %.2f s + %d s penalty = %.2f s   |   benchmark %.2f s   |   off-track %d, barrier %d', ...
            course.name, r.time, r.penalty, r.totalTime, b.time, r.nOffTrack, r.nBarrier);
        col = [0.4 0.95 0.4];
    end
    title(tl, head, 'Color', col, 'FontWeight', 'bold');
    if nargout == 0, clear fig; end
end
