classdef Visualizer < handle
% VISUALIZER  Real-time 2-D race visualisation window.
%
%   ╔══════════════════════════════════════╗
%   ║  SIMULATOR FILE — DO NOT MODIFY     ║
%   ╚══════════════════════════════════════╝
%
%   Usage (called automatically by RaceSimulation when headless=false):
%     viz = Visualizer(track);
%     viz.update(vehicle, t, nOffTrack);

    properties (Access = private)
        fig          % figure handle
        ax           % main axes
        carPatch     % vehicle body (patch)
        arrowLine    % heading arrow (line)
        trailLine    % position trail (line)
        timeText     % HUD: elapsed time
        speedText    % HUD: speed
        exitText     % HUD: off-track count
        trailX       % trail x buffer
        trailY       % trail y buffer
        trailMax     % max trail length
    end

    methods

        function obj = Visualizer(track)
        % VISUALIZER(track)  Open the race window and draw the track.

            obj.trailMax = 800;
            obj.trailX   = nan(obj.trailMax, 1);
            obj.trailY   = nan(obj.trailMax, 1);

            % Figure
            obj.fig = figure( ...
                'Name',        'AI Grand Prix — Practice Race', ...
                'Color',       [0.08 0.08 0.10], ...
                'NumberTitle', 'off', ...
                'Position',    [80 80 960 720]);

            % Axes
            obj.ax = axes(obj.fig, ...
                'Color',       [0.12 0.12 0.14], ...
                'XColor',      [0.7 0.7 0.7], ...
                'YColor',      [0.7 0.7 0.7], ...
                'FontSize',    10, ...
                'DataAspectRatio', [1 1 1]);
            hold(obj.ax, 'on');
            axis(obj.ax, 'equal');
            grid(obj.ax, 'on');
            obj.ax.GridColor     = [0.25 0.25 0.25];
            obj.ax.GridAlpha     = 0.4;
            obj.ax.GridLineStyle = ':';

            % Draw static track
            track.plot(obj.ax);

            % Position trail (drawn before car so car is on top)
            obj.trailLine = plot(obj.ax, nan, nan, '-', ...
                'Color',     [0.2 0.7 1.0 0.6], ...
                'LineWidth', 1.5);

            % Car body — rectangle in local frame
            [bx, by] = Visualizer.carBody();
            obj.carPatch = patch(obj.ax, bx, by, [1 0.18 0.12], ...
                'EdgeColor', 'w', 'LineWidth', 0.8);

            % Heading arrow
            obj.arrowLine = plot(obj.ax, [0,0], [0,0], 'w-', 'LineWidth', 2);

            % HUD text overlays
            obj.timeText  = text(obj.ax, 0.02, 0.97, 'T: 0.00 s', ...
                'Units', 'normalized', 'Color', [0.9 0.9 0.9], ...
                'FontSize', 11, 'FontWeight', 'bold', ...
                'VerticalAlignment', 'top');
            obj.speedText = text(obj.ax, 0.02, 0.91, 'V: 0.0 m/s', ...
                'Units', 'normalized', 'Color', [0.3 0.9 0.3], ...
                'FontSize', 11, 'FontWeight', 'bold', ...
                'VerticalAlignment', 'top');
            obj.exitText  = text(obj.ax, 0.02, 0.85, 'Exits: 0', ...
                'Units', 'normalized', 'Color', [1.0 0.7 0.1], ...
                'FontSize', 11, 'FontWeight', 'bold', ...
                'VerticalAlignment', 'top');

            xlabel(obj.ax, 'x  (m)', 'Color', [0.7 0.7 0.7]);
            ylabel(obj.ax, 'y  (m)', 'Color', [0.7 0.7 0.7]);
            title(obj.ax, sprintf('AI Grand Prix — %s', track.name), ...
                'Color', 'w', 'FontSize', 13, 'FontWeight', 'bold');
        end

        % -------------------------------------------------------------- %
        function update(obj, vehicle, t, nOffTrack)
        % UPDATE(vehicle, t, nOffTrack)  Refresh the display each timestep.

            x = vehicle.x;
            y = vehicle.y;
            h = vehicle.theta;

            % ---- Update car position / rotation ----
            [bx, by] = Visualizer.carBody();
            cosH = cos(h); sinH = sin(h);
            rx = cosH * bx - sinH * by + x;
            ry = sinH * bx + cosH * by + y;
            set(obj.carPatch, 'XData', rx, 'YData', ry);

            % ---- Heading arrow ----
            arrowLen = 2.5;
            set(obj.arrowLine, ...
                'XData', [x, x + arrowLen * cos(h)], ...
                'YData', [y, y + arrowLen * sin(h)]);

            % ---- Position trail (ring buffer) ----
            obj.trailX = [obj.trailX(2:end); x];
            obj.trailY = [obj.trailY(2:end); y];
            set(obj.trailLine, 'XData', obj.trailX, 'YData', obj.trailY);

            % ---- HUD update ----
            set(obj.timeText,  'String', sprintf('T: %.2f s', t));
            set(obj.speedText, 'String', sprintf('V: %.1f m/s', vehicle.v));

            if nOffTrack > 0
                set(obj.exitText, 'String', sprintf('Exits: %d  ⚠', nOffTrack), ...
                    'Color', [1.0 0.3 0.1]);
            else
                set(obj.exitText, 'String', 'Exits: 0', ...
                    'Color', [1.0 0.7 0.1]);
            end
        end

    end % methods

    % ------------------------------------------------------------------ %
    %  Private helpers                                                    %
    % ------------------------------------------------------------------ %
    methods (Static, Access = private)

        function [bx, by] = carBody()
        % Return local-frame car body vertices (length × width = 1.4 × 0.7 m).
            L = 1.4; W = 0.7;
            bx = [-L/2,  L/2, L/2, -L/2, -L/2];
            by = [-W/2, -W/2, W/2,  W/2, -W/2];
        end

    end % static methods
end % classdef
