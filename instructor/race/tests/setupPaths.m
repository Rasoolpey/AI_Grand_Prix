function root = setupPaths()
% SETUPPATHS  Put the simulator, practice paths and instructor tools on the path.
    here = fileparts(mfilename('fullpath'));
    root = fullfile(here, '..', '..', '..', 'AI_Grand_Prix');
    addpath(fullfile(root, 'simulator'), fullfile(root, 'simulator', 'physics'), fullfile(root, 'tracks'), ...
            fullfile(here, '..', 'controllers'), fullfile(here, '..'), here);
end
