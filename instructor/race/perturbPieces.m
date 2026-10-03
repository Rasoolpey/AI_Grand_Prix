function pieces = perturbPieces(pieces, seed, amount)
% PERTURBPIECES  A hidden variation of a path: same pieces, different sizes.
%
%   pieces = perturbPieces(pieces, seed)          lengths and radii +-15 %
%   pieces = perturbPieces(pieces, seed, amount)
%
%   Straights get a new length and corners a new radius (same angle, same
%   direction), each scaled by a factor in [1-amount, 1+amount] drawn from
%   a private random stream (seed), so the global rng is untouched and the
%   same seed always gives the same path.  buildPath re-closes circuits.
%
%   Use:  course = practiceTechnical(@(p) perturbPieces(p, 3));
%
%   See also: balanceSweep, buildPath
    if nargin < 3, amount = 0.15; end
    rs = RandStream('mt19937ar', 'Seed', seed);
    for i = 1:numel(pieces)
        f = 1 + amount * (2 * rand(rs) - 1);
        switch pieces(i).kind
            case "straight"
                pieces(i).length = pieces(i).length * f;
            case "corner"
                pieces(i).length = pieces(i).length * f;   % same angle: R and arc length scale together
                pieces(i).kappa  = pieces(i).kappa / f;
        end
    end
end
