classdef Visualizer < handle
% VISUALIZER  Top-down race view with an F1-map look and a live HUD.
%
%   ╔══════════════════════════════════════╗
%   ║  SIMULATOR FILE — DO NOT MODIFY     ║
%   ╚══════════════════════════════════════╝
%
%   viz = Visualizer(course, car)      % opened by RaceSimulation when not headless
%   viz.update(state, info, hud)
%
%   Map: grass, road shaded by height (lighter = higher), kerbs, run-off and
%   barriers, checkpoints, chequered finish line, stop box, wet patches (blue).
%   HUD: time, speed, throttle/brake bar, battery, grade, lap and checkpoint,
%   penalties, and the FRICTION-CIRCLE DOT: the dot shows how much of the
%   tyres' grip is in use (centre = none, on the circle = at the limit,
%   red = understeer: the car asked for more grip than the tyres have).
%
%   Static helpers (used by raceDay for many cars):
%     ax = Visualizer.drawCourse(ax, course)
%     g  = Visualizer.makeCar(ax, colour, aeroId)
%     Visualizer.placeCar(g, x, y, theta)
%
%   See also: RaceSimulation, practiceRace

    properties (Access = private)
        fig; ax; carG; trail; trailX; trailY
        hudText; thrBar; brkBar; batBar; fcDot; fcAx
    end

    properties (Constant)
        GRASS   = [0.36 0.62 0.30]
        ASPHALT = [0.28 0.28 0.30]
        KERB_R  = [0.88 0.12 0.12]
        KERB_W  = [0.96 0.96 0.96]
        SAND    = [0.82 0.75 0.55]
        WET     = [0.25 0.45 0.85]
    end

    methods
        function obj = Visualizer(course, car)
            obj.fig = figure('Name', "AI Grand Prix - " + course.name, 'Color', Visualizer.GRASS, ...
                'NumberTitle', 'off', 'Position', [60 60 1150 820]);
            obj.ax = axes(obj.fig, 'Position', [0.02 0.02 0.72 0.92]);
            Visualizer.drawCourse(obj.ax, course);
            title(obj.ax, "AI Grand Prix - " + course.name + "   |   " + car.team, 'Color', [0.1 0.1 0.1], 'FontSize', 13);

            obj.trailX = nan(1500, 1);  obj.trailY = nan(1500, 1);
            obj.trail = plot(obj.ax, nan, nan, '-', 'Color', [car.colour 0.6], 'LineWidth', 2);
            obj.carG  = Visualizer.makeCar(obj.ax, car.colour, car.parts.aero);
            Visualizer.placeCar(obj.carG, course.centreline(1,1), course.centreline(1,2), course.heading(1));

            % ---- HUD panel ----
            hud = axes(obj.fig, 'Position', [0.76 0.40 0.22 0.54], 'Color', [0.08 0.08 0.10], ...
                'XColor', 'none', 'YColor', 'none', 'XLim', [0 1], 'YLim', [0 1]);
            hold(hud, 'on');
            obj.hudText = text(hud, 0.06, 0.97, '', 'Color', 'w', 'FontName', 'Consolas', ...
                'FontSize', 11, 'VerticalAlignment', 'top', 'Interpreter', 'none');
            barY = 0.06;  barH = 0.05;
            rectangle(hud, 'Position', [0.06 barY 0.88 barH], 'EdgeColor', [0.5 0.5 0.5]);
            obj.thrBar = patch(hud, 0.5 + [0 0 0 0], barY + [0 0 barH barH], [0.2 0.85 0.3], 'EdgeColor', 'none');
            obj.brkBar = patch(hud, 0.5 + [0 0 0 0], barY + [0 0 barH barH], [0.95 0.25 0.2], 'EdgeColor', 'none');
            plot(hud, [0.5 0.5], barY + [0 barH], 'w-');
            text(hud, 0.06, barY + barH + 0.03, 'brake  |  throttle', 'Color', [0.7 0.7 0.7], 'FontSize', 8);
            rectangle(hud, 'Position', [0.06 0.17 0.88 0.04], 'EdgeColor', [0.5 0.5 0.5]);
            obj.batBar = patch(hud, 0.06 + [0 0.88 0.88 0], 0.17 + [0 0 0.04 0.04], [0.3 0.7 1], 'EdgeColor', 'none');
            text(hud, 0.06, 0.235, 'battery', 'Color', [0.7 0.7 0.7], 'FontSize', 8);

            % ---- Friction circle ----
            obj.fcAx = axes(obj.fig, 'Position', [0.79 0.06 0.16 0.24], 'Color', [0.08 0.08 0.10], ...
                'XColor', 'none', 'YColor', 'none', 'XLim', [-1.3 1.3], 'YLim', [-1.3 1.3], 'DataAspectRatio', [1 1 1]);
            hold(obj.fcAx, 'on');
            th = linspace(0, 2*pi, 80);
            plot(obj.fcAx, cos(th), sin(th), '-', 'Color', [0.8 0.8 0.8], 'LineWidth', 1.5);
            plot(obj.fcAx, [-1 1], [0 0], ':', 'Color', [0.4 0.4 0.4]);
            plot(obj.fcAx, [0 0], [-1 1], ':', 'Color', [0.4 0.4 0.4]);
            text(obj.fcAx, 0, 1.18, 'drive', 'Color', [0.7 0.7 0.7], 'FontSize', 7, 'HorizontalAlignment', 'center');
            text(obj.fcAx, 0, -1.18, 'brake', 'Color', [0.7 0.7 0.7], 'FontSize', 7, 'HorizontalAlignment', 'center');
            text(obj.fcAx, -1.22, 0, 'L', 'Color', [0.7 0.7 0.7], 'FontSize', 7);
            text(obj.fcAx, 1.12, 0, 'R', 'Color', [0.7 0.7 0.7], 'FontSize', 7);
            title(obj.fcAx, 'grip in use', 'Color', [0.85 0.85 0.85], 'FontSize', 9);
            obj.fcDot = plot(obj.fcAx, 0, 0, 'o', 'MarkerSize', 10, 'MarkerFaceColor', [0.3 1 0.4], 'MarkerEdgeColor', 'w');
        end

        function update(obj, s, info, h)
            if ~isvalid(obj.fig), return; end
            Visualizer.placeCar(obj.carG, s.x, s.y, s.theta);
            obj.trailX = [obj.trailX(2:end); s.x];  obj.trailY = [obj.trailY(2:end); s.y];
            set(obj.trail, 'XData', obj.trailX, 'YData', obj.trailY);
            if h.laps > 1, lapStr = sprintf('Lap      %d / %d\n', h.lap, h.laps); else, lapStr = ''; end
            pen = 5 * h.nOff + 10 * h.nBarrier;
            set(obj.hudText, 'String', sprintf(['Time  %7.2f s\nSpeed %5.1f m/s\n      %5.0f km/h\n%s' ...
                'Check  %3d / %d\nGrade  %+5.1f %%\nOff-track %d  Barrier %d\nPenalty  +%d s\nBattery %4.0f %%'], ...
                h.t, s.v, 3.6 * s.v, lapStr, min(h.nextCp, h.K), h.K, h.grade, h.nOff, h.nBarrier, pen, 100 * h.batteryFrac));
            thr = max(h.throttle, 0);  brk = max(-h.throttle, 0);
            set(obj.thrBar, 'XData', 0.5 + 0.44 * [0 thr thr 0]);
            set(obj.brkBar, 'XData', 0.5 - 0.44 * [0 brk brk 0]);
            set(obj.batBar, 'XData', 0.06 + 0.88 * [0 h.batteryFrac h.batteryFrac 0]);
            g = max(info.G, eps);
            col = [0.3 1 0.4];
            if info.understeer, col = [1 0.2 0.2]; elseif info.gripUse > 0.9, col = [1 0.8 0.2]; end
            set(obj.fcDot, 'XData', -info.Fy / g, 'YData', info.Fx / g, 'MarkerFaceColor', col);
        end
    end

    methods (Static)
        function ax = drawCourse(ax, course)
            hold(ax, 'on');
            set(ax, 'Color', Visualizer.GRASS, 'XColor', 'none', 'YColor', 'none', 'DataAspectRatio', [1 1 1]);
            cl = course.centreline;  pad = 20;
            xl = [min(cl(:,1)) - pad, max(cl(:,1)) + pad];  yl = [min(cl(:,2)) - pad, max(cl(:,2)) + pad];
            patch(ax, xl([1 2 2 1]), yl([1 1 2 2]), Visualizer.GRASS, 'EdgeColor', 'none');
            closed = course.isCircuit();
            wrap = @(P) Visualizer.closeIf(P, closed);
            nrm = course.normals;  hw = course.width / 2;  wall = hw + course.runoff;

            % run-off (sand) and barriers
            Lw = wrap(cl + wall * nrm);  Rw = wrap(cl - wall * nrm);
            Visualizer.band(ax, Lw, wrap(cl + hw * nrm), Visualizer.SAND);
            Visualizer.band(ax, wrap(cl - hw * nrm), Rw, Visualizer.SAND);
            plot(ax, Lw(:,1), Lw(:,2), '-', 'Color', [0.55 0.55 0.6], 'LineWidth', 2.5);
            plot(ax, Rw(:,1), Rw(:,2), '-', 'Color', [0.55 0.55 0.6], 'LineWidth', 2.5);
            if ~closed
                E = course.lineAt(course.numPoints());
                plot(ax, E([1 3]), E([2 4]), '-', 'Color', [0.55 0.55 0.6], 'LineWidth', 4);
            end

            % road shaded by height: lighter = higher
            L = wrap(course.leftBoundary);  R = wrap(course.rightBoundary);
            z = course.z;  if closed, z(end+1) = z(1); end
            zr = max(z) - min(z);  if zr < 0.1, zr = 1; end
            shade = 0.85 + 0.45 * (z - min(z)) / zr;
            C = reshape(Visualizer.ASPHALT, 1, 1, 3) .* shade';
            C = repmat(C, 2, 1, 1);
            wet = course.muFactor < 1;  if closed, wet(end+1) = wet(1); end
            for c = 1:3
                Cc = C(:,:,c);  Cc(:, wet) = 0.6 * Cc(:, wet) + 0.4 * Visualizer.WET(c);  C(:,:,c) = Cc;
            end
            surface(ax, [L(:,1)'; R(:,1)'], [L(:,2)'; R(:,2)'], zeros(2, size(L,1)), C, ...
                'EdgeColor', 'none', 'FaceColor', 'interp');

            % kerbs at the edges of corners
            kerb = abs(course.kappa) > 1/60;
            for side = [1 -1]
                B = cl + side * hw * nrm;  B2 = cl + side * (hw + 0.7) * nrm;
                blk = floor(course.s / 2);
                for k = unique(blk(kerb))'
                    i = find(blk == k & kerb);
                    if numel(i) < 2, continue; end
                    col = Visualizer.KERB_R;  if mod(k, 2), col = Visualizer.KERB_W; end
                    P = [B(i,:); flipud(B2(i,:))];
                    patch(ax, P(:,1), P(:,2), col, 'EdgeColor', 'none');
                end
            end
            plot(ax, L(:,1), L(:,2), 'w-', 'LineWidth', 1.2);
            plot(ax, R(:,1), R(:,2), 'w-', 'LineWidth', 1.2);

            % checkpoints, stop box, finish
            for k = 1:numel(course.checkpointS)
                Q = course.lineAt(course.checkpointIdx(k));  Q = Q - [0 0 0 0];
                c0 = (Q(1:2) + Q(3:4)) / 2;  dQ = (Q(3:4) - Q(1:2)) / 2 * hw / wall;
                plot(ax, c0(1) + [-1 1] * dQ(1), c0(2) + [-1 1] * dQ(2), ':', 'Color', [1 1 1 0.35]);
            end
            if ~isnan(course.stopBox(1))
                i1 = course.indexAt(course.stopBox(1));  i2 = course.indexAt(course.stopBox(2));
                P = [course.leftBoundary(i1:i2,:); flipud(course.rightBoundary(i1:i2,:))];
                patch(ax, P(:,1), P(:,2), [1 0.85 0.1], 'FaceAlpha', 0.25, 'EdgeColor', [1 0.85 0.1]);
                text(ax, cl(i2,1), cl(i2,2), ' STOP', 'Color', [1 0.9 0.2], 'FontWeight', 'bold', 'FontSize', 9);
            end
            Visualizer.chequered(ax, course, course.finishIdx);
            xlim(ax, xl);  ylim(ax, yl);
        end

        function g = makeCar(ax, colour, aeroId)
        % F1-style car, ~2.4 m long; the rear wing is bigger with the downforce kit.
            if nargin < 3, aeroId = "none"; end
            g.body = patch(ax, nan, nan, colour, 'EdgeColor', 'k', 'LineWidth', 0.6);
            g.fw   = patch(ax, nan, nan, colour * 0.85, 'EdgeColor', 'k', 'LineWidth', 0.5);
            g.rw   = patch(ax, nan, nan, colour * 0.8, 'EdgeColor', 'k', 'LineWidth', 0.5);
            g.tyre = patch(ax, nan, nan, [0.1 0.1 0.1], 'EdgeColor', 'none');
            g.bx = [1.2 0.9 0.55 0.1 -0.3 -0.8 -1.05 -1.05 -0.8 -0.3 0.1 0.55 0.9 1.2];
            g.by = [0 0.14 0.2 0.22 0.26 0.24 0.18 -0.18 -0.24 -0.26 -0.22 -0.2 -0.14 0];
            g.fx = [0.7 1.05 1.05 0.7];  g.fy = [-0.62 -0.62 0.62 0.62];
            rwDepth = 0.30;  if aeroId == "downforce", rwDepth = 0.5; elseif aeroId == "none", rwDepth = 0.15; end
            g.rx = [-0.9 -0.9 - rwDepth -0.9 - rwDepth -0.9];  g.ry = [-0.5 -0.5 0.5 0.5];
            tx = [-0.35 0.35 0.35 -0.35];  ty = [0 0 0.16 0.16];
            g.tx = [tx + 0.6, NaN, tx + 0.6, NaN, tx - 0.6, NaN, tx - 0.6];
            g.ty = [ty + 0.3, NaN, ty - 0.46, NaN, ty + 0.3, NaN, ty - 0.46];
        end

        function placeCar(g, x, y, th)
            c = cos(th);  s = sin(th);
            mv = @(px, py) deal(c * px - s * py + x, s * px + c * py + y);
            [X, Y] = mv(g.bx, g.by);  set(g.body, 'XData', X, 'YData', Y);
            [X, Y] = mv(g.fx, g.fy);  set(g.fw,   'XData', X, 'YData', Y);
            [X, Y] = mv(g.rx, g.ry);  set(g.rw,   'XData', X, 'YData', Y);
            [X, Y] = mv(g.tx, g.ty);  set(g.tyre, 'XData', X, 'YData', Y);
        end
    end

    methods (Static, Access = private)
        function P = closeIf(P, closed)
            if closed, P(end+1,:) = P(1,:); end
        end

        function band(ax, A, B, col)
            X = [A(:,1)'; B(:,1)'];  Y = [A(:,2)'; B(:,2)'];
            surface(ax, X, Y, zeros(size(X)), 'FaceColor', col, 'EdgeColor', 'none');
        end

        function chequered(ax, course, idx)
            c = course.centreline(idx,:);  n = course.normals(idx,:);  t = [n(2), -n(1)];
            hw = course.width / 2;  nSq = 8;  sq = course.width / nSq;
            for row = 0:1
                for col = 0:nSq-1
                    p0 = c - hw * n + col * sq * n + (row - 1) * sq * t;
                    P = [p0; p0 + sq * n; p0 + sq * n + sq * t; p0 + sq * t];
                    f = [1 1 1];  if mod(row + col, 2), f = [0 0 0]; end
                    patch(ax, P(:,1), P(:,2), f, 'EdgeColor', 'none');
                end
            end
        end
    end
end
