function [Fdrag, Froll, Fgrade, N, Fdown] = roadForces(car, v, alpha, rollFactor)
% ROADFORCES  The forces the road and the air put on the car (equations 3, 4, 9).
%
%   [Fdrag, Froll, Fgrade, N, Fdown] = roadForces(car, v, alpha)
%   [...] = roadForces(car, v, alpha, rollFactor)    rollFactor 4 on mud (default 1)
%
%   v      speed (m/s)            alpha  road angle (rad), uphill > 0
%   Fdrag  = 1/2 rho C_D A v^2                       (eq. 3)
%   Fdown  = 1/2 rho C_L A v^2                       (eq. 3)
%   N      = m g cos(alpha) + Fdown                  (eq. 4)
%   Froll  = C_rr N  (x rollFactor on mud)           (eq. 4)
%   Fgrade = m g sin(alpha)  (uphill +, downhill -)  (eq. 9)
%   Works element-wise on vectors.
%
%   See also: stepCar, gripLimit

    if nargin < 3, alpha = 0; end
    if nargin < 4, rollFactor = 1; end
    q      = 0.5 * car.rho * v.^2;
    Fdrag  = q * car.CdA;
    Fdown  = q * car.ClA;
    N      = car.mass * car.g * cos(alpha) + Fdown;
    Froll  = car.Crr * N .* rollFactor;
    Fgrade = car.mass * car.g * sin(alpha);
end
