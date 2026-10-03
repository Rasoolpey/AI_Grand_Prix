function v = cornerSpeed(car, kappa, alpha, muFactor)
% CORNERSPEED  Safe steady cornering speed (equation 6).
%
%   v = cornerSpeed(car, kappa, alpha, muFactor)
%
%   kappa     path curvature 1/R (1/m); the sign is ignored
%   alpha     road angle (rad), default 0
%   muFactor  grip factor of the surface (wet < 1), default 1
%
%   The tyres must supply m v^2 |kappa| sideways and can supply
%   mu (m g cos(alpha) + 1/2 rho C_L A v^2), so
%
%       v^2 = mu g cos(alpha) / (|kappa| - mu rho C_L A / (2 m))
%
%   If the denominator is <= 0 (or kappa = 0, a straight) grip does not
%   limit the speed and v = Inf: power and gearing do.  This is the limit
%   with NO braking or driving in the corner; braking uses part of the
%   budget, so the real limit while braking is lower.
%   Works element-wise on vectors.
%
%   See also: gripLimit, stepCar

    if nargin < 3, alpha = 0; end
    if nargin < 4, muFactor = 1; end
    mu    = car.mu .* muFactor;
    denom = abs(kappa) - mu .* car.rho .* car.ClA ./ (2 * car.mass);
    v     = sqrt(mu .* car.g .* cos(alpha) ./ max(denom, realmin));
    v(denom <= 0) = Inf;
end
