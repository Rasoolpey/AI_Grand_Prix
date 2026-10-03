function F = driveForce(car, v, throttle)
% DRIVEFORCE  Motor force at the wheels (equation 2).
%
%   F = driveForce(car, v, throttle)
%
%   F_drive = throttle * min(P / v, F_gear), and 0 at or above v_gear.
%   v is floored at 0.5 m/s so the force stays finite from standstill.
%   Works element-wise on vectors v.  Grip is NOT applied here.
%
%   See also: stepCar, gripLimit

    if nargin < 3, throttle = 1; end
    F = throttle .* min(car.power ./ max(v, 0.5), car.Fgear);
    F(v >= car.vGear) = 0;
end
