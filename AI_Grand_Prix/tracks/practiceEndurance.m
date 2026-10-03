function course = practiceEndurance(variation)
% PRACTICEENDURANCE  C3 - Endurance (practice version), 5 laps.
%
%   ~430 m fast circuit: a long main straight, two R 28 m sweepers, a short
%   climb, a long descending back straight and one hairpin.  The climb and
%   the descent cancel: every lap ends at its start height.
%
%   Tests: battery (energy over 5 laps), aero (drag vs downforce in the
%   sweepers), rolling resistance, and the controller's energy strategy.
%
%   See also: buildPath, loadPath
    pieces = [ ...
        road.straight(100, 0, "adjust"), ...          % main straight
        road.corner(28, 105, "L"), ...                % sweeper 1
        road.straight(15, 5, "adjust"), ...           % short climb
        road.corner(28, 105, "L", 5), ...             % sweeper 2, still climbing
        road.straight(140, -3.2, "adjust"), ...       % back straight, downhill
        road.corner(10, 150, "L"), ...                % hairpin
        road.straight(30), ...
    ];
    if nargin >= 1 && ~isempty(variation), pieces = variation(pieces); end   % instructor: hidden variations
    course = buildPath(pieces, 'Name', "Endurance", 'Type', "circuit", 'Laps', 5, ...
        'Width', 6, 'TimeLimit', 360);
end
