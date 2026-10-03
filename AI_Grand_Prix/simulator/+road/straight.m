function p = straight(len, grade, adjust)
% STRAIGHT  A straight road piece.
%
%   p = road.straight(length)
%   p = road.straight(length, grade)            grade in % (uphill +)
%   p = road.straight(length, grade, "adjust")  buildPath may lengthen or
%                                               shorten it to close a circuit
%
%   See also: road.corner, road.chicane, road.surface, buildPath
    if nargin < 2 || isempty(grade), grade = 0; end
    isAdjust = nargin >= 3 && (isequal(adjust, true) || strcmpi(string(adjust), "adjust"));
    if ~(len > 0), error('road:straight', 'length must be > 0'); end
    p = road.piece("straight", len, 0, grade, isAdjust);
end
