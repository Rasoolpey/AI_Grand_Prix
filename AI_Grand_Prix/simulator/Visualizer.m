classdef Visualizer < handle
% VISUALIZER  Top-down race-map visualiser with F1 map aesthetic.
%
%   ╔══════════════════════════════════════╗
%   ║  SIMULATOR FILE — DO NOT MODIFY     ║
%   ╚══════════════════════════════════════╝
%
%   Renders a top-down race map with:
%     - Green grass background
%     - Asphalt track surface with kerb stripes
%     - Trees and pit buildings around the circuit
%     - Formula 1 silhouette car (body + front wing + rear wing)
%     - Team colour per car
%     - HUD overlay (time / speed / exits)
%
%   Usage (called automatically by RaceSimulation):
%     viz = Visualizer(track);
%     viz.update(vehicle, t, nOffTrack);

    % ------------------------------------------------------------------ %
    properties (Access = private)
        fig         % figure handle
        ax          % main axes
        carBody     % main chassis patch
        carFWing    % front wing patch
        carRWing    % rear wing patch
        carNose     % nose cone patch
        headingArrow % direction indicator line
        trailLine   % position trail
        trailX      % trail buffer x
        trailY      % trail buffer y
        trailMax    % max trail length
        timeText    % HUD
        speedText
        exitText
        teamColor   % [r g b] - chosen at construction
    end

    % ------------------------------------------------------------------ %
    properties (Constant)
        GRASS     = [0.36 0.62 0.30]    % flat green grass
        ASPHALT   = [0.28 0.28 0.30]    % dark asphalt
        KERB_R    = [0.88 0.12 0.12]    % kerb red
        KERB_W    = [0.96 0.96 0.96]    % kerb white
        SAND      = [0.80 0.72 0.50]    % run-off / gravel
        PIT_WALL  = [0.92 0.90 0.86]    % pit building walls
    end

    % ------------------------------------------------------------------ %
    methods

        function obj = Visualizer(track, teamColor)
        % VISUALIZER(track)  Open race window, draw map, place decorations.
            if nargin < 2 || isempty(teamColor)
                teamColor = [0.95 0.18 0.18];   % default: red car
            end
            obj.teamColor = teamColor;
            obj.trailMax  = 1200;
            obj.trailX    = nan(obj.trailMax, 1);
            obj.trailY    = nan(obj.trailMax, 1);

            % ---- Figure ----
            obj.fig = figure( ...
                'Name',        'AI Grand Prix — Race Map', ...
                'Color',       obj.GRASS, ...
                'NumberTitle', 'off', ...
                'Position',    [60, 60, 1100, 820]);

            % ---- Axes ----
            obj.ax = axes(obj.fig, ...
                'Color',       obj.GRASS, ...
                'XColor',      'none', ...
                'YColor',      'none', ...
                'DataAspectRatio', [1 1 1]);
            hold(obj.ax, 'on');
            axis(obj.ax, 'equal');
            axis(obj.ax, 'tight');

            % expand axis limits a bit for decorations
            cl = track.centreline;
            pad = 25;
            xlim(obj.ax, [min(cl(:,1))-pad, max(cl(:,1))+pad]);
            ylim(obj.ax, [min(cl(:,2))-pad, max(cl(:,2))+pad]);

            % ---- Draw grass background patch ----
            xl = xlim(obj.ax); yl = ylim(obj.ax);
            patch(obj.ax, [xl(1) xl(2) xl(2) xl(1)], ...
                          [yl(1) yl(1) yl(2) yl(2)], ...
                obj.GRASS, 'EdgeColor', 'none', 'HandleVisibility', 'off');

            % ---- Draw track map (asphalt + kerbs + lines) ----
            obj.drawTrackMap(track);

            % ---- Decorations ----
            obj.placeDecorations(track);

            % ---- Position trail ----
            obj.trailLine = plot(obj.ax, nan, nan, '-', ...
                'Color', [teamColor, 0.55], 'LineWidth', 2.0);

            % ---- F1 car (3 patches + arrow) ----
            [bx, by] = Visualizer.carBodyPts();
            obj.carBody = patch(obj.ax, bx, by, teamColor, ...
                'EdgeColor', 'k', 'LineWidth', 0.6, 'FaceAlpha', 1.0);

            [fx, fy] = Visualizer.fwingPts();
            obj.carFWing = patch(obj.ax, fx, fy, teamColor * 0.85, ...
                'EdgeColor', 'k', 'LineWidth', 0.5);

            [rx, ry] = Visualizer.rwingPts();
            obj.carRWing = patch(obj.ax, rx, ry, teamColor * 0.80, ...
                'EdgeColor', 'k', 'LineWidth', 0.5);

            [nx, ny] = Visualizer.nosePts();
            obj.carNose = patch(obj.ax, nx, ny, [0.15 0.15 0.15], ...
                'EdgeColor', 'none');

            obj.headingArrow = plot(obj.ax, [0 0], [0 0], ...
                'w-', 'LineWidth', 2.0);

            % ---- HUD overlays ----
            obj.timeText = text(obj.ax, xl(1)+2, yl(2)-3, 'T: 0.00 s', ...
                'Color', 'w', 'FontSize', 12, 'FontWeight', 'bold', ...
                'BackgroundColor', [0 0 0 0.45], ...
                'Margin', 4, 'Interpreter', 'none');

            obj.speedText = text(obj.ax, xl(1)+2, yl(2)-9, 'V: 0.0 m/s', ...
                'Color', [0.3 1.0 0.4], 'FontSize', 12, 'FontWeight', 'bold', ...
                'BackgroundColor', [0 0 0 0.45], ...
                'Margin', 4, 'Interpreter', 'none');

            obj.exitText = text(obj.ax, xl(1)+2, yl(2)-15, 'Exits: 0', ...
                'Color', [1.0 0.85 0.15], 'FontSize', 12, 'FontWeight', 'bold', ...
                'BackgroundColor', [0 0 0 0.45], ...
                'Margin', 4, 'Interpreter', 'none');

            title(obj.ax, sprintf('AI Grand Prix — %s', track.name), ...
                'Color', [0.15 0.15 0.15], 'FontSize', 14, 'FontWeight', 'bold');
        end

        % -------------------------------------------------------------- %
        function update(obj, vehicle, t, nOffTrack)
        % UPDATE  Refresh car position and HUD each simulation step.

            x = vehicle.x;  y = vehicle.y;  h = vehicle.theta;
            cosH = cos(h);  sinH = sin(h);

            % Rotate & translate each car part
            % NOTE: must unpack [bx,by] first — MATLAB drops 2nd return value inline
            [bx, by] = Visualizer.carBodyPts();  Visualizer.movePatch(obj.carBody,  bx, by, x, y, cosH, sinH);
            [fx, fy] = Visualizer.fwingPts();    Visualizer.movePatch(obj.carFWing, fx, fy, x, y, cosH, sinH);
            [rx, ry] = Visualizer.rwingPts();    Visualizer.movePatch(obj.carRWing, rx, ry, x, y, cosH, sinH);
            [nx, ny] = Visualizer.nosePts();     Visualizer.movePatch(obj.carNose,  nx, ny, x, y, cosH, sinH);

            % Heading arrow
            aLen = 4.0;
            set(obj.headingArrow, ...
                'XData', [x, x + aLen*cosH], ...
                'YData', [y, y + aLen*sinH]);

            % Trail
            obj.trailX = [obj.trailX(2:end); x];
            obj.trailY = [obj.trailY(2:end); y];
            set(obj.trailLine, 'XData', obj.trailX, 'YData', obj.trailY);

            % HUD
            set(obj.timeText,  'String', sprintf('T: %.2f s', t));
            set(obj.speedText, 'String', sprintf('V: %.1f m/s', vehicle.v));
            if nOffTrack > 0
                set(obj.exitText, 'String', sprintf('Exits: %d  ⚠', nOffTrack), ...
                    'Color', [1.0 0.25 0.10]);
            else
                set(obj.exitText, 'String', 'Exits: 0', 'Color', [1.0 0.85 0.15]);
            end
        end

    end % public methods

    % ------------------------------------------------------------------ %
    %  Private drawing helpers                                            %
    % ------------------------------------------------------------------ %
    methods (Access = private)

        function drawTrackMap(obj, track)
        % Draw the full track with asphalt fill, kerbs, and markings.
            ax = obj.ax;
            N  = size(track.centreline, 1);
            halfW = track.width / 2;

            % --- Asphalt fill (closed polygon: left boundary + reversed right) ---
            lX = [track.leftBoundary(:,1);  track.leftBoundary(1,1)];
            lY = [track.leftBoundary(:,2);  track.leftBoundary(1,2)];
            rX = [track.rightBoundary(:,1); track.rightBoundary(1,1)];
            rY = [track.rightBoundary(:,2); track.rightBoundary(1,2)];

            fill(ax, [lX; flipud(rX)], [lY; flipud(rY)], ...
                obj.ASPHALT, 'EdgeColor', 'none', 'HandleVisibility', 'off');

            % --- Kerb stripes (alternating red / white, 3.0 m each) ---
            kerbLen = 3.0;    % metres per kerb block
            kerbW   = 0.80;   % kerb depth in metres
            nK      = floor(track.lapLength / kerbLen);
            for k = 0 : nK-1
                d1 = k * kerbLen;
                d2 = min(d1 + kerbLen, track.lapLength);
                [~, i1] = min(abs(track.cumDist - d1));
                [~, i2] = min(abs(track.cumDist - d2));
                if i1 == i2, continue; end

                col = Visualizer.KERB_W * mod(k,2) + Visualizer.KERB_R * mod(k+1,2);

                % Left kerb
                Visualizer.drawKerbBlock(ax, ...
                    track.leftBoundary(i1,:), track.leftBoundary(i2,:), ...
                    track.normals(i1,:), track.normals(i2,:), kerbW, col);
                % Right kerb
                Visualizer.drawKerbBlock(ax, ...
                    track.rightBoundary(i1,:), track.rightBoundary(i2,:), ...
                    -track.normals(i1,:), -track.normals(i2,:), kerbW, col);
            end

            % --- White boundary lines ---
            plot(ax, [lX; lX(1)], [lY; lY(1)], '-', ...
                'Color', 'w', 'LineWidth', 1.8, 'HandleVisibility', 'off');
            plot(ax, [rX; rX(1)], [rY; rY(1)], '-', ...
                'Color', 'w', 'LineWidth', 1.8, 'HandleVisibility', 'off');

            % --- Dashed centreline ---
            cX = [track.centreline(:,1); track.centreline(1,1)];
            cY = [track.centreline(:,2); track.centreline(1,2)];
            plot(ax, cX, cY, '--', 'Color', [0.8 0.8 0.8 0.5], ...
                'LineWidth', 0.7, 'HandleVisibility', 'off');

            % --- Chequered start/finish box ---
            sfPt = track.centreline(1,:);
            sfN  = track.normals(1,:);
            sfT  = [sfN(2), -sfN(1)];   % tangent direction
            sqSz = halfW / 4;
            nSq  = 8;   % squares across + along
            for row = 0:nSq-1
                for col = 0:nSq-1
                    if mod(row+col, 2) == 0, sqCol = 'w'; else, sqCol = 'k'; end
                    p0 = sfPt - halfW*sfN + col*2*sqSz*sfN + row*sqSz*sfT;
                    p1 = p0 + 2*sqSz*sfN;
                    p2 = p1 + sqSz*sfT;
                    p3 = p0 + sqSz*sfT;
                    patch(ax, [p0(1) p1(1) p2(1) p3(1)], ...
                               [p0(2) p1(2) p2(2) p3(2)], sqCol, ...
                        'EdgeColor', 'none', 'HandleVisibility', 'off');
                end
            end

            % --- Pit lane label ---
            text(ax, sfPt(1) + 3*sfT(1), sfPt(2) + 3*sfT(2), 'S/F', ...
                'Color', [0.2 0.2 0.2], 'FontSize', 8, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center');
        end

        function placeDecorations(obj, track)
        % Scatter trees and pit buildings around the circuit.
            ax  = obj.ax;
            xl  = xlim(ax);  yl = ylim(ax);
            rng(42);   % fixed seed for reproducibility

            % Minimum clearance from any boundary point
            allBnd = [track.leftBoundary; track.rightBoundary];

            % ---- Trees (green filled circles) ----
            nTrees = 35;
            placed  = 0;
            maxTry  = nTrees * 30;
            radTree = 3.0;   % visual radius metres
            minClear = track.width * 1.8;

            for t = 1:maxTry
                if placed >= nTrees, break; end
                px = xl(1) + rand*(xl(2)-xl(1));
                py = yl(1) + rand*(yl(2)-yl(1));
                % Check clearance from all boundary points
                dists = sqrt((allBnd(:,1)-px).^2 + (allBnd(:,2)-py).^2);
                if min(dists) < minClear, continue; end
                % Draw tree: dark green circle + lighter crown
                th = linspace(0, 2*pi, 20);
                treeDark  = [0.18 0.45 0.18];
                treeMid   = [0.25 0.60 0.22];
                treeLit   = [0.35 0.72 0.28];
                fill(ax, px + radTree*cos(th), py + radTree*sin(th), ...
                    treeDark, 'EdgeColor', 'none', 'HandleVisibility', 'off');
                r2 = radTree * 0.75;
                fill(ax, px + r2*cos(th+0.4), py + r2*sin(th+0.4), ...
                    treeMid,  'EdgeColor', 'none', 'HandleVisibility', 'off');
                r3 = radTree * 0.45;
                fill(ax, px + r3*cos(th-0.3), py + r3*sin(th-0.3), ...
                    treeLit, 'EdgeColor', 'none', 'HandleVisibility', 'off');
                placed = placed + 1;
            end

            % ---- Pit buildings (coloured rectangles) ----
            buildingDefs = {
                % [x_offset from SF, y_offset] [w h] [r g b]
                [-5,  15,  18, 7,  0.88 0.30 0.20];  % red garages
                [-5,  22,  10, 4,  0.92 0.90 0.86];  % pit wall
                [ 40, 15,  14, 6,  0.94 0.76 0.22];  % hospitality
                [ 55, 22,   8, 5,  0.92 0.90 0.86];  % media centre
            };
            sfPt = track.centreline(1,:);
            sfN  = track.normals(1,:);
            sfT  = [sfN(2), -sfN(1)];   % tangent (along straight)
            for k = 1:size(buildingDefs,1)
                b    = buildingDefs{k};
                bPt  = sfPt + b(1)*sfT + b(2)*sfN;
                bW   = b(3); bH = b(4);
                bCol = [b(5), b(6), b(7)];
                patch(ax, ...
                    bPt(1) + [0 bW bW 0], ...
                    bPt(2) + [0 0 bH bH], ...
                    bCol, 'EdgeColor', [0.3 0.3 0.3], 'LineWidth', 0.8, ...
                    'HandleVisibility', 'off');
                % Roof shading
                patch(ax, ...
                    bPt(1) + [0 bW bW 0], ...
                    bPt(2) + [bH bH bH+1.5 bH+1.5], ...
                    bCol * 0.7, 'EdgeColor', 'none', 'HandleVisibility', 'off');
            end
        end

    end % private methods

    % ------------------------------------------------------------------ %
    %  Static helpers                                                     %
    % ------------------------------------------------------------------ %
    methods (Static, Access = private)

        % --- Kerb block polygon ---
        function drawKerbBlock(ax, p1, p2, n1, n2, kw, col)
            outer1 = p1 + kw * n1;
            outer2 = p2 + kw * n2;
            patch(ax, [p1(1) p2(1) outer2(1) outer1(1)], ...
                      [p1(2) p2(2) outer2(2) outer1(2)], col, ...
                'EdgeColor', 'none', 'HandleVisibility', 'off');
        end

        % --- Move a patch (rotate + translate) ---
        function movePatch(p, bx, by, x, y, cosH, sinH)
            rx = cosH * bx - sinH * by + x;
            ry = sinH * bx + cosH * by + y;
            set(p, 'XData', rx, 'YData', ry);
        end

        % --- F1 car body points (local, nose at +x) ---
        function [bx, by] = carBodyPts()
            % Main chassis + cockpit silhouette (scale ~2.4m long)
            bx = [1.20  0.90  0.55  0.10 -0.30 -0.80 -1.05 ...
                 -1.05 -0.80 -0.30  0.10  0.55  0.90  1.20];
            by = [ 0.00  0.14  0.20  0.22  0.26  0.24  0.18 ...
                  -0.18 -0.24 -0.26 -0.22 -0.20 -0.14  0.00];
        end

        % --- Front wing points ---
        function [fx, fy] = fwingPts()
            fx = [0.70  1.05  1.05  0.70];
            fy = [-0.62 -0.62  0.62  0.62];
        end

        % --- Rear wing points ---
        function [rx, ry] = rwingPts()
            rx = [-0.90 -1.20 -1.20 -0.90];
            ry = [-0.50 -0.50  0.50  0.50];
        end

        % --- Nose cone (dark tip) ---
        function [nx, ny] = nosePts()
            nx = [0.85  1.30  1.30  0.85];
            ny = [-0.09 -0.01  0.01  0.09];
        end

    end % static methods
end % classdef
