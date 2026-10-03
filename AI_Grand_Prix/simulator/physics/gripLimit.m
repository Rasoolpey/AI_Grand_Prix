function G = gripLimit(car, v, alpha, muFactor)
% GRIPLIMIT  The tyres' total grip budget G = mu * N (equation 5).
%
%   G = gripLimit(car, v, alpha, muFactor)
%
%   Braking, driving and turning share this one budget:
%   sqrt(Fx^2 + Fy^2) <= G.   muFactor < 1 on a wet patch (default 1).
%   Works element-wise on vectors.
%
%   See also: cornerSpeed, roadForces

    if nargin < 3, alpha = 0; end
    if nargin < 4, muFactor = 1; end
    [~, ~, ~, N] = roadForces(car, v, alpha);
    G = car.mu .* muFactor .* N;
end
