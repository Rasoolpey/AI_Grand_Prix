function raceDay(varargin)
% RACEDAY  Show the races on the projector: every car on track at once (D8).
%
%   raceDay                          every final path, then the standings
%   raceDay('Paths', 2)              only the second final path
%   raceDay('Static', true)          fallback: standings and path tables only
%   raceDay('SaveFrames', folder)    no animation: save still frames (rehearsal / checks)
%
%   Plays the runs in <Out>/runs.mat (written by finalRace or qualify): all
%   cars together, synchronised by race time, with a live running order.
%   Ghost cars: they do not touch.  Each race opens with a 3-2-1 countdown
%   and is paced to last about 'Seconds' on screen (the reference car's
%   time); cars still running after twice that are fast-forwarded.
%   Between scenes the view waits for a key press ('Pause', false: 4 s).
%
%   Options: 'Out' results folder (results/), 'Seconds' on-screen length of
%   a race (12), 'Speed' fixed playback multiplier instead (default: from
%   'Seconds'), 'Pause' (true).
%
%   See also: qualify, standings, Visualizer

    here = fileparts(mfilename('fullpath'));
    o = inputParser();
    o.addParameter('Out', fullfile(here, 'results'));
    o.addParameter('Paths', []);
    o.addParameter('Static', false);
    o.addParameter('Speed', []);
    o.addParameter('Seconds', 12);
    o.addParameter('Pause', true);
    o.addParameter('SaveFrames', "");
    o.parse(varargin{:});
    opt = o.Results;
    L = load(fullfile(opt.Out, 'runs.mat'), 'R', 'F');
    R = L.R;  F = L.F;
    S = standings(R, F);
    paths = opt.Paths;  if isempty(paths), paths = 1:numel(F.ids); end

    if ~opt.Static
        for p = 1:numel(paths)
            k = paths(p);
            runs = R(string({R.pathId}) == F.ids(k));
            broadcast(F.courses{k}, runs, F.tref(k), opt, k, sprintf('Race %d of %d', p, numel(paths)));
            pathBoard(runs, F, k, opt);
        end
    else
        for k = paths
            runs = R(string({R.pathId}) == F.ids(k));
            pathBoard(runs, F, k, opt);
        end
    end
    finalBoard(S, F, opt);
end

% ======================================================================= %
function broadcast(course, runs, tref, opt, k, raceLabel)
    fig = figure('Name', "AI Grand Prix - " + course.name, 'Color', [0.08 0.08 0.1], 'NumberTitle', 'off', ...
        'Position', [20 40 1500 860], 'MenuBar', 'none', 'ToolBar', 'none');
    ax = axes(fig, 'Position', [0.01 0.06 0.72 0.88]);
    Visualizer.drawCourse(ax, course);
    title(ax, raceLabel + "  -  " + course.name, 'Color', 'w', 'FontSize', 20);
    annotation(fig, 'textbox', [0.01 0.005 0.72 0.05], 'String', ...
        'Every car is driven by its own model, simulated on this computer with the same physics  -  ghost cars: they do not touch', ...
        'Color', [1 0.85 0.3], 'FontSize', 12, 'FontWeight', 'bold', 'EdgeColor', 'none', 'HorizontalAlignment', 'center');
    tower = axes(fig, 'Position', [0.75 0.06 0.24 0.88], 'Color', [0.12 0.12 0.15], 'XColor', 'none', ...
        'YColor', 'none', 'XLim', [0 1], 'YLim', [0 1]);
    hold(tower, 'on');
    clockTxt = text(tower, 0.05, 0.97, '', 'Color', 'w', 'FontSize', 16, 'FontWeight', 'bold', 'FontName', 'Consolas');

    n = numel(runs);
    rowH = min(0.055, 0.9 / max(n, 1));  rowFont = max(7, min(11, round(11 * rowH / 0.055 + 1)));
    g = cell(n, 1);  lbl = gobjects(n, 1);  rows = gobjects(n, 1);  dots = gobjects(n, 1);
    for i = 1:n
        aero = "none";  if isfield(runs(i).parts, 'aero'), aero = string(runs(i).parts.aero); end
        g{i} = Visualizer.makeCar(ax, runs(i).colour, aero);
        dots(i) = plot(ax, NaN, NaN, 'o', 'MarkerSize', 11, 'MarkerFaceColor', runs(i).colour, ...
            'MarkerEdgeColor', 'w', 'LineWidth', 1.2);
        lbl(i) = text(ax, NaN, NaN, " " + runs(i).teamName, 'Color', 'w', 'FontSize', 10, 'FontWeight', 'bold', ...
            'Interpreter', 'none');
        rows(i) = text(tower, 0.05, 0.9 - rowH * (i - 1), '', 'Color', 'w', 'FontSize', rowFont, 'FontName', 'Consolas', ...
            'Interpreter', 'none');
    end
    tEnd = max(arrayfun(@(r) max([r.log.t(:); 0]), runs));
    tEnd = min(tEnd, course.timeLimit);
    speed = opt.Speed;
    if isempty(speed)                                   % pace: the reference car takes 'Seconds' on screen
        base = tref;
        if ~isfinite(base) || base <= 0
            fin = [runs.finished];  base = median([runs(fin).time]);
            if isempty(base) || ~isfinite(base), base = tEnd; end
        end
        speed = max(base, 1) / opt.Seconds;
    end
    wCap = 2 * opt.Seconds;                             % after this, fast-forward the cars still running
    toRace = @(w) w * speed + max(w - wCap, 0) * (max(tEnd - wCap * speed, 0) / 2 - speed);

    if opt.SaveFrames ~= ""
        if ~exist(opt.SaveFrames, 'dir'), mkdir(opt.SaveFrames); end
        for frac = [0.3 0.7 1]
            drawAt(frac * tEnd);
            exportgraphics(fig, fullfile(opt.SaveFrames, sprintf('path%d_%02.0f.png', k, 100 * frac)), 'Resolution', 70);
        end
        close(fig);
        return;
    end
    drawAt(0);
    countdown(ax, course);
    t0 = tic;
    while isvalid(fig)
        t = toRace(toc(t0));
        drawAt(min(t, tEnd));
        drawnow;
        if t >= tEnd, break; end
    end
    waitScene(opt);
    if isvalid(fig), close(fig); end

    function drawAt(t)
        prog = -inf(n, 1);  status = strings(n, 1);
        for j = 1:n
            lg = runs(j).log;
            if isempty(lg.t), status(j) = "DNF"; continue; end
            m = max(1, min(numel(lg.t), floor(t / 0.02)));
            Visualizer.placeCar(g{j}, double(lg.x(m)), double(lg.y(m)), double(lg.theta(m)));
            set(dots(j), 'XData', double(lg.x(m)), 'YData', double(lg.y(m)));
            set(lbl(j), 'Position', [double(lg.x(m)) + 2.5, double(lg.y(m)) + 2.5, 0]);
            prog(j) = double(lg.progress(m));
            if runs(j).finished && t >= runs(j).time
                status(j) = sprintf('%7.2f s', runs(j).totalTime);
                prog(j) = 1e9 - runs(j).totalTime;             % finished cars on top, by time
            elseif runs(j).dnf && m == numel(lg.t)
                status(j) = "DNF";  prog(j) = -1e9 + prog(j);
            elseif course.laps > 1
                status(j) = sprintf('lap %d/%d', lg.lap(m), course.laps);
            else
                status(j) = sprintf('%5.0f m', prog(j));
            end
        end
        [~, ord] = sort(prog, 'descend');
        for p = 1:n
            j = ord(p);
            set(rows(j), 'Position', [0.05, 0.9 - rowH * (p - 1), 0], ...
                'String', sprintf('P%-2d %-14.14s %s', p, runs(j).teamName, status(j)), 'Color', runs(j).colour * 0.5 + 0.5);
        end
        set(clockTxt, 'String', sprintf('%6.1f s   ref %.1f s', t, tref));
    end
end

function countdown(ax, course)
% Starting lights: 3, 2, 1, GO.
    c = mean(course.centreline, 1);
    h = text(ax, c(1), c(2), '', 'Color', [1 0.85 0.3], 'FontSize', 90, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    for s = ["3", "2", "1", "GO!"]
        if ~isvalid(h), return; end
        set(h, 'String', s);  drawnow;  pause(0.7);
    end
    if isvalid(h), delete(h); end
end

function pathBoard(runs, F, k, opt)
    sc = zeros(numel(runs), 1);
    for i = 1:numel(runs)
        if runs(i).finished, sc(i) = min(120, 100 * F.tref(k) / runs(i).totalTime); end
    end
    [~, ord] = sort(sc, 'descend');
    lines = sprintf('%-4s %-18s %9s %8s %7s', 'Pos', 'Team', 'Time', 'Penalty', 'Score');
    for p = 1:numel(ord)
        r = runs(ord(p));
        if r.finished
            lines = [lines newline sprintf('%-4d %-18.18s %8.2fs %7ds %7.1f', p, r.teamName, r.totalTime, r.penalty, sc(ord(p)))]; %#ok<AGROW>
        else
            lines = [lines newline sprintf('%-4d %-18.18s %9s %8s %7.1f  %s', p, r.teamName, 'DNF', '', 0, r.dnfReason)]; %#ok<AGROW>
        end
    end
    fprintf('\n%s  (T_ref %.2f s)\n%s\n', F.courses{k}.name, F.tref(k), lines);
    board(sprintf('%s  -  results  (T_ref %.2f s)', F.courses{k}.name, F.tref(k)), lines, opt, sprintf('board%d', k));
end

function finalBoard(S, F, opt)
    sc = S{:, startsWith(S.Properties.VariableNames, 'score_')};
    lines = sprintf('%-4s %-18s', 'Pos', 'Team');
    for k = 1:numel(F.ids), lines = [lines sprintf(' %10s', F.ids(k))]; end %#ok<AGROW>
    lines = [lines sprintf(' %8s %6s', 'Overall', 'Paths')];
    for i = 1:height(S)
        lines = [lines newline sprintf('%-4d %-18.18s', S.rank(i), S.teamName(i)) sprintf(' %10.1f', sc(i, :)) ...
            sprintf(' %8.1f %4d/%d', S.overall(i), S.pathsFinished(i), numel(F.ids))]; %#ok<AGROW>
    end
    [best, where] = max(sc(:));
    [i, k] = ind2sub(size(sc), where);
    lines = [lines newline newline sprintf('Overall champion: %s', S.teamName(1)) newline ...
        sprintf('Best single path: %s on %s (%.1f)', S.teamName(i), F.ids(k), best) newline ...
        'Best engineering explanation / Best use of the agent: judged from the engineering logs'];
    fprintf('\nOVERALL STANDINGS  (overall = 0.6 x mean + 0.4 x min)\n%s\n', lines);
    board('Overall standings   (0.6 x mean + 0.4 x min of the path scores)', lines, opt, 'standings');
end

function board(ttl, lines, opt, name)
    fig = figure('Color', [0.08 0.08 0.1], 'Position', [40 40 1300 820], 'NumberTitle', 'off', 'Name', ttl, ...
        'MenuBar', 'none', 'ToolBar', 'none');
    ax = axes(fig, 'Position', [0 0 1 1], 'Color', [0.08 0.08 0.1], 'XColor', 'none', 'YColor', 'none', ...
        'XLim', [0 1], 'YLim', [0 1]);
    text(ax, 0.04, 0.95, ttl, 'Color', [1 0.85 0.3], 'FontSize', 20, 'FontWeight', 'bold', 'Interpreter', 'none');
    nLines = numel(strfind(lines, newline)) + 1;
    fs = max(7, min(13, floor(370 / nLines)));       % ~31 lines fit at 13 pt
    text(ax, 0.04, 0.88, lines, 'Color', 'w', 'FontSize', fs, 'FontName', 'Consolas', 'VerticalAlignment', 'top', ...
        'Interpreter', 'none');
    if opt.SaveFrames ~= ""
        exportgraphics(fig, fullfile(opt.SaveFrames, name + ".png"), 'Resolution', 70);
        close(fig);
    else
        waitScene(opt);
    end
end

function waitScene(opt)
    if opt.SaveFrames ~= "", return; end
    if opt.Pause
        fprintf('  (press a key in the figure to continue)\n');
        try, waitforbuttonpress; catch, end
    else
        pause(4);
    end
end
