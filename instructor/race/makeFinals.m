function F = makeFinals(seed, varargin)
% MAKEFINALS  Build, verify and save the race-day paths and their T_ref (D9, WP11).
%
%   F = makeFinals(seed)              seed = a secret number chosen shortly before the event
%   F = makeFinals(seed, 'Save', false, 'Preview', true)
%
%   Reads the PRIVATE layouts in finals/finalTemplates.m (git-ignored), varies
%   every straight length and corner radius (+-15 %, perturbPieces with the
%   seed), mirrors circuits for odd seeds, and builds each path.  Then for
%   every final path it checks:
%     - buildPath's own checks (closure, height, no overlap)
%     - the reference car + reference controller finishes with no penalty
%     - the duration is inside the target range
%   and measures T_ref = that reference time (the single T_ref definition, §5).
%
%   Saves finals/finals.mat: courses (RacePath), ids, tref, seed, created.
%   Keep the seed and the file private; do not commit them.
%
%   See also: finalTemplates, perturbPieces, qualify, raceDay

    o = inputParser();
    o.addParameter('Save', true);
    o.addParameter('Preview', false);
    o.parse(varargin{:});
    here = fileparts(mfilename('fullpath'));
    finals = fullfile(here, 'finals');
    addpath(finals);
    T = finalTemplates();

    target = struct('drag', [8 16], 'technical', [25 75], 'endurance', [90 190]);
    refDesign = struct('team', "Reference");
    cat = parts();
    for q = cat.partNames, refDesign.(q) = cat.(q)(2).id; end
    refCar = buildCar(refDesign);
    style = controllerStyles();  refCfg = style(1).config;

    F = struct('ids', [T.id], 'courses', {cell(1, numel(T))}, 'tref', zeros(1, numel(T)), ...
        'seed', seed, 'created', string(datetime('now')));
    for k = 1:numel(T)
        pieces = perturbPieces(T(k).pieces, seed * 100 + k);
        opts = T(k).opts;
        isCirc = any(strcmp(string(opts(1:2:end)), "Type")) && opts{find(strcmp(string(opts(1:2:end)), "Type")) * 2} == "circuit";
        if isCirc && mod(seed, 2) == 1
            for i = 1:numel(pieces), pieces(i).kappa = -pieces(i).kappa; end    % mirrored: runs the other way round
        end
        course = buildPath(pieces, opts{:});
        clear refController
        r = RaceSimulation(course, refCar, @refController, refCfg);
        if ~r.finished || r.penalty > 0
            error('makeFinals:verify', '%s: the reference car did not finish cleanly (%s, penalty %d). Try another seed.', ...
                course.name, r.dnfReason, r.penalty);
        end
        rng_ = target.(T(k).id);
        ok = r.totalTime >= rng_(1) && r.totalTime <= rng_(2);
        fprintf('%-26s %6.0f m  x%d  T_ref %7.2f s  (target %d-%d s) %s\n', course.name, course.length, course.laps, ...
            r.totalTime, rng_(1), rng_(2), string(ifelse(ok, 'OK', '<-- OUTSIDE TARGET')));
        F.courses{k} = course;
        F.tref(k) = r.totalTime;
    end

    if o.Results.Preview
        fig = figure('Color', 'w', 'Position', [50 50 1400 450]);
        tl = tiledlayout(fig, 1, numel(T));
        for k = 1:numel(T)
            ax = nexttile(tl);  F.courses{k}.plot(ax);  title(ax, F.courses{k}.name);
        end
    end
    if o.Results.Save
        if ~exist(finals, 'dir'), mkdir(finals); end
        save(fullfile(finals, 'finals.mat'), 'F');
        fprintf('Saved %s  (private: never commit)\n', fullfile(finals, 'finals.mat'));
    end
end

function v = ifelse(c, a, b)
    if c, v = a; else, v = b; end
end
