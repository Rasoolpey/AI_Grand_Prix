function [flagged, findings] = scanModelCode(folder)
% SCANMODELCODE  Flag code a student model has no reason to contain.
%
%   [flagged, findings] = scanModelCode(folder)
%
%   Flags (it does not block): system/shell calls, eval-like calls, file
%   writes or deletes, network, Java/Python, exit, changing folders or the
%   path, and files other than .m/.json/.txt/.md (e.g. .p, .mex).
%   Comments and string contents are ignored.  It is a review aid, NOT a
%   security sandbox: read flagged code before you allow it.
%
%   See also: collectSubmissions, finalRace
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
