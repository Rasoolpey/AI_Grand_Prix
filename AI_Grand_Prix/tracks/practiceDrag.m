function course = practiceDrag(variation)
% PRACTICEDRAG  C1 - Drag strip (practice version).
%
%   150 m flat straight from a standing start, then a 10 m stop box and
%   20 m of run-off before the barrier.  Finish = cross the line, then stop.
%   Stop past the box (in the run-off): +3 s.  Hit the barrier: DNF.
%
%   Tests: motor, gearing, mass (acceleration) and tyres (braking).
%
%   See also: buildPath, loadPath
    pieces = road.straight(180);
    if nargin >= 1 && ~isempty(variation), pieces = variation(pieces); end   % instructor: hidden variations
    course = buildPath(pieces, 'Name', "Drag strip", 'Type', "open", 'Width', 6, ...
        'StopBox', 10, 'FinishRunoff', 20, 'TimeLimit', 30, 'Checkpoints', 25);
end
