function results = runAllTests()
% RUNALLTESTS  Physics unit checks + race rules / adversarial controllers.
%   results = runAllTests()      (from any folder)
    here = fileparts(mfilename('fullpath'));
    addpath(here);
    setupPaths();
    results = runtests({fullfile(here, 'testPhysics.m'), fullfile(here, 'testRules.m')});
    disp(table(results));
    fprintf('PASSED %d / %d\n', sum([results.Passed]), numel(results));
end
