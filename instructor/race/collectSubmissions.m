function T = collectSubmissions(inbox, varargin)
% COLLECTSUBMISSIONS  Unpack every submission_<team>.zip and scan the code.
%
%   T = collectSubmissions(inbox)        inbox = the shared folder (or a USB copy)
%   T = collectSubmissions(inbox, 'Into', folder)   default: instructor/race/submissions
%
%   For each zip: unpacks into <Into>/<team>/ (replacing an older copy),
%   reads manifest.json and scans the code.  The scan FLAGS (it does not
%   block) anything a controller has no reason to do: system/shell calls,
%   eval-like calls, file writes or deletes, network, Java/Python, exit,
%   changing folders or the path, and non-.m files (e.g. .p, .mex).
%   qualify refuses flagged teams unless you pass 'AllowFlagged' after
%   reading the code yourself.
%
%   Running each team in its own MATLAB process (qualify) contains crashes
%   and hangs; it is NOT a security sandbox.  Read flagged code.
%
%   T: table with team, folder, submitted, cost, motor, battery, tyres,
%      aero, gearing, flagged, findings
%
%   See also: submitCar, qualify

    o = inputParser();
    o.addParameter('Into', fullfile(fileparts(mfilename('fullpath')), 'submissions'));
    o.parse(varargin{:});
    into = o.Results.Into;
    if ~exist(into, 'dir'), mkdir(into); end

    zips = dir(fullfile(inbox, 'submission_*.zip'));
    rows = {};
    for k = 1:numel(zips)
        zf = fullfile(zips(k).folder, zips(k).name);
        team = erase(erase(zips(k).name, 'submission_'), '.zip');
        dest = fullfile(into, team);
        if exist(dest, 'dir'), rmdir(dest, 's'); end
        mkdir(dest);
        try
            unzip(zf, dest);
        catch ME
            warning('collectSubmissions:unzip', '%s: cannot unzip (%s)', zips(k).name, ME.message);
            continue;
        end
        man = struct('team', string(team), 'submitted', "", 'cost', NaN, 'design', struct());
        mf = fullfile(dest, 'manifest.json');
        if exist(mf, 'file')
            try, man = jsondecode(fileread(mf)); catch, end
        end
        [flagged, findings] = scanCode(dest);
        d = getf(man, 'design', struct());
        rows(end+1, :) = {string(getf(man, 'team', team)), string(dest), string(getf(man, 'submitted', "")), ...
            getf(man, 'cost', NaN), string(getf(d, 'motor', "")), string(getf(d, 'battery', "")), ...
            string(getf(d, 'tyres', "")), string(getf(d, 'aero', "")), string(getf(d, 'gearing', "")), ...
            flagged, strjoin(findings, '; ')}; %#ok<AGROW>
    end
    T = cell2table(rows, 'VariableNames', {'team', 'folder', 'submitted', 'cost', 'motor', 'battery', 'tyres', ...
        'aero', 'gearing', 'flagged', 'findings'});
    writetable(T, fullfile(into, 'collected.csv'));
    fprintf('Collected %d submissions into %s (%d flagged for review)\n', height(T), into, sum(T.flagged));
    for k = find(T.flagged)'
        fprintf('  FLAGGED %s: %s\n', T.team(k), T.findings(k));
    end
end

function [flagged, findings] = scanCode(folder)
    findings = strings(0);
    risky = ["system", "dos", "unix", "eval", "evalin", "evalc", "assignin", "feval", "str2func", "builtin", ...
             "delete", "rmdir", "movefile", "copyfile", "mkdir", "save", "fopen", "fwrite", "writematrix", ...
             "writetable", "web", "webread", "webwrite", "urlread", "urlwrite", "websave", "ftp", "tcpclient", ...
             "udpport", "exit", "quit", "cd", "addpath", "rmpath", "path", "setenv", "parpool", "batch", ...
             "parfeval", "timer", "load", "pause", "input", "keyboard"];
    files = dir(fullfile(folder, '**', '*'));
    files = files(~[files.isdir]);
    for f = files'
        [~, ~, ext] = fileparts(f.name);
        if ~ismember(lower(ext), {'.m', '.json', '.txt', '.md'})
            findings(end+1) = sprintf('%s: unexpected file type', f.name); %#ok<AGROW>
            continue;
        end
        if ~strcmpi(ext, '.m'), continue; end
        code = splitlines(string(fileread(fullfile(f.folder, f.name))));
        for li = 1:numel(code)
            line = regexprep(code(li), '%.*$', '');                 % drop comments
            line = regexprep(line, '''[^'']*''|"[^"]*"', '""');      % drop string contents
            if startsWith(strtrim(line), "!")
                findings(end+1) = sprintf('%s:%d shell escape (!)', f.name, li); %#ok<AGROW>
            end
            hit = regexp(line, "(?<![\w.])(" + strjoin(risky, "|") + ")(?=\s*(\(|$|\s))", 'match');
            hit = hit(~ismember(hit, ["cd"]) | ~contains(line, "obs."));
            for h = hit
                findings(end+1) = sprintf('%s:%d %s', f.name, li, h); %#ok<AGROW>
            end
            if contains(line, ["java.", "py.", "System."])
                findings(end+1) = sprintf('%s:%d java/python/.NET call', f.name, li); %#ok<AGROW>
            end
        end
    end
    flagged = ~isempty(findings);
end

function v = getf(s, f, d)
    if isstruct(s) && isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = d; end
end
