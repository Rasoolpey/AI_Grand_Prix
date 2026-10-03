function p = piece(kind, len, kappa, grade, adjust, muFactor)
% PIECE  Internal: the common struct behind every road piece.
%   Use road.straight, road.corner, road.chicane, road.surface instead.
    if nargin < 4, grade = 0; end
    if nargin < 5, adjust = false; end
    if nargin < 6, muFactor = 1; end
    p = struct('kind', string(kind), 'length', double(len), 'kappa', double(kappa), ...
               'grade', double(grade), 'adjust', logical(adjust), 'muFactor', double(muFactor));
end
