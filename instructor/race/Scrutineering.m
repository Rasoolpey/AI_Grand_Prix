classdef Scrutineering < handle
% SCRUTINEERING  The "every car is checked" screen that finalRace shows first.
%
%   scr = Scrutineering(M, F, opt)      one line per model
%   scr.mark(i, status, colour, name)   update model i's line
%   scr.done()                          wait for a key (or 3 s), then close
%
%   See also: finalRace

    properties (Access = private)
        fig; rows; foot; opt; n
    end

    methods
        function obj = Scrutineering(M, F, opt)
            obj.opt = opt;  obj.n = numel(M);
            vis = 'on';  if opt.SaveFrames ~= "", vis = 'off'; end
            obj.fig = figure('Name', 'AI Grand Prix - scrutineering', 'Color', [0.08 0.08 0.1], 'NumberTitle', 'off', ...
                'Position', [20 40 1500 860], 'MenuBar', 'none', 'ToolBar', 'none', 'Visible', vis);
            ax = axes(obj.fig, 'Position', [0 0 1 1], 'Color', [0.08 0.08 0.1], 'XColor', 'none', 'YColor', 'none', ...
                'XLim', [0 1], 'YLim', [0 1]);
            hold(ax, 'on');
            text(ax, 0.04, 0.95, 'SCRUTINEERING', 'Color', [1 0.85 0.3], 'FontSize', 28, 'FontWeight', 'bold');
            text(ax, 0.04, 0.895, sprintf(['%d cars, %d races (%s). Every car is checked, then driven by its own ' ...
                'model here, on this computer, with the same physics.'], obj.n, numel(F.ids), strjoin(F.ids, ', ')), ...
                'Color', [0.8 0.8 0.85], 'FontSize', 13);
            nCol = 1 + (obj.n > 16);  perCol = ceil(obj.n / nCol);
            rowH = min(0.045, 0.78 / perCol);  fs = max(8, min(15, round(15 * rowH / 0.045)));
            obj.rows = gobjects(obj.n, 1);
            for i = 1:obj.n
                c = floor((i - 1) / perCol);  r = mod(i - 1, perCol);
                obj.rows(i) = text(ax, 0.04 + 0.48 * c, 0.83 - rowH * r, sprintf('%-22.22s waiting', M(i).label), ...
                    'Color', [0.55 0.55 0.6], 'FontSize', fs, 'FontName', 'Consolas', 'Interpreter', 'none');
            end
            obj.foot = text(ax, 0.04, 0.035, '', 'Color', [1 0.85 0.3], 'FontSize', 15, 'FontWeight', 'bold');
            drawnow;
        end

        function mark(obj, i, status, colour, name)
            if ~isvalid(obj.fig), return; end
            set(obj.rows(i), 'String', sprintf('%-22.22s %s', name, status), 'Color', colour);
            drawnow;
        end

        function done(obj)
            if ~isvalid(obj.fig), return; end
            if obj.opt.SaveFrames ~= ""
                set(obj.foot, 'String', 'All cars checked.');
                if ~exist(obj.opt.SaveFrames, 'dir'), mkdir(obj.opt.SaveFrames); end
                exportgraphics(obj.fig, fullfile(obj.opt.SaveFrames, 'scrutineering.png'), 'Resolution', 70);
            elseif obj.opt.Pause
                set(obj.foot, 'String', 'All cars checked.  Press a key to start the first race.');
                fprintf('  (press a key in the figure to continue)\n');
                try, waitforbuttonpress; catch, end
            else
                set(obj.foot, 'String', 'All cars checked.  The first race starts now.');
                pause(3);
            end
            if isvalid(obj.fig), close(obj.fig); end
        end
    end
end
