function inbox = makeRehearsal(n, inbox, varargin)
% MAKEREHEARSAL  Auto-generate N fake team submissions for the race-day rehearsal (§8).
%
%   inbox = makeRehearsal(30)                 into results/rehearsal_inbox/
%   inbox = makeRehearsal(30, folder)
%   inbox = makeRehearsal(8, '', 'Hang', false)   no team that loops forever (for finalRace)
%
%   Each fake team: a random affordable design, the reference controller in
%   a random style, zipped exactly like submitCar does.  Team 1 crashes on
%   purpose (controller error), team 2 hangs (infinite loop) and team 3
%   calls system() (must be flagged by collectSubmissions).
%
%   Rehearsal:  inbox = makeRehearsal(30);
%               collectSubmissions(inbox);  makeFinals(seed);
%               tic; qualify('AllowFlagged', false); toc;  raceDay('SaveFrames', 'frames')
%   Or in this MATLAB:  inbox = makeRehearsal(8, '', 'Hang', false);  finalRace(inbox)
%   (finalRace runs every car in this MATLAB, so a team that loops forever would freeze it.)
%
%   See also: collectSubmissions, qualify, raceDay
    here = fileparts(mfilename('fullpath'));
    o = inputParser();  o.addParameter('Hang', true);  o.parse(varargin{:});
    if nargin < 2 || isempty(inbox), inbox = fullfile(here, 'results', 'rehearsal_inbox'); end
    if exist(inbox, 'dir'), rmdir(inbox, 's'); end
    mkdir(inbox);
    cat = parts();
    styles = controllerStyles();
    rs = RandStream('mt19937ar', 'Seed', 7);
    refCode = fileread(fullfile(here, 'controllers', 'refController.m'));
    refCode = regexprep(refCode, 'function command = refController\(obs, config\)', 'function command = controller(obs, config)', 'once');
    for t = 1:n
        while true
            d = struct('team', sprintf("Team%02d", t), 'colour', rand(rs, 1, 3) * 0.8 + 0.2);
            for p = cat.partNames, d.(p) = cat.(p)(randi(rs, 3)).id; end
            try, car = buildCar(d); break; catch, end
        end
        stage = fullfile(tempdir, sprintf('aigp_reh_%02d', t));
        if exist(stage, 'dir'), rmdir(stage, 's'); end
        mkdir(stage);
        code = refCode;
        if t == 1, code = strrep(code, '    car  = obs.car;', '    car  = obs.car;  if obs.time > 3, error(''deliberate crash''); end'); end
        if t == 2 && o.Results.Hang, code = strrep(code, '    car  = obs.car;', '    car  = obs.car;  if obs.time > 2, while true, end, end'); end
        if t == 3, code = strrep(code, '    car  = obs.car;', '    car  = obs.car;  if obs.time < 0, system(''echo hi''); end'); end
        writeText(fullfile(stage, 'controller.m'), code);
        st = styles(randi(rs, numel(styles)));
        writeText(fullfile(stage, 'robotConfig.m'), sprintf('function config = robotConfig()\n    config = jsondecode(''%s'');\nend\n', jsonencode(st.config)));
        writeText(fullfile(stage, 'carDesign.m'), sprintf(['function car = carDesign()\n    car.team = "%s";\n    car.colour = [%g %g %g];\n' ...
            '    car.motor = "%s";\n    car.battery = "%s";\n    car.tyres = "%s";\n    car.aero = "%s";\n    car.gearing = "%s";\nend\n'], ...
            d.team, d.colour, d.motor, d.battery, d.tyres, d.aero, d.gearing));
        man = struct('team', d.team, 'design', rmfield(d, 'colour'), 'colour', d.colour, 'cost', car.cost, ...
            'submitted', string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')), 'matlab', string(version), 'computer', "rehearsal");
        writeText(fullfile(stage, 'manifest.json'), jsonencode(man, 'PrettyPrint', true));
        zip(fullfile(inbox, sprintf('submission_%s.zip', d.team)), '*', stage);
        rmdir(stage, 's');
    end
    fprintf('%d rehearsal submissions in %s\n', n, inbox);
end

function writeText(f, s)
    fid = fopen(f, 'w');  fprintf(fid, '%s', s);  fclose(fid);
end
