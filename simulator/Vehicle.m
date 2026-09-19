classdef Vehicle < handle
% VEHICLE  2-D kinematic bicycle model for the AI Grand Prix simulator.
%
%   ╔══════════════════════════════════════╗
%   ║  SIMULATOR FILE — DO NOT MODIFY     ║
%   ╚══════════════════════════════════════╝
%
%   State:
%     x, y        — position (m)
%     theta       — heading (rad), 0 = East, pi/2 = North
%     v           — longitudinal speed (m/s)
%     steeringAngle — actual front-wheel steering angle (rad)
%
%   Controller outputs are clamped by physical constraints before application.
%   You cannot exceed MAX_SPEED or MAX_STEER_ANGLE by commanding extreme values.

    % ------------------------------------------------------------------ %
    %  Public read-only state                                             %
    % ------------------------------------------------------------------ %
    properties (GetAccess = public, SetAccess = private)
        x             (1,1) double = 0   % position x (m)
        y             (1,1) double = 0   % position y (m)
        theta         (1,1) double = 0   % heading (rad)
        v             (1,1) double = 0   % speed   (m/s)
        steeringAngle (1,1) double = 0   % actual steering angle (rad)
    end

    % ------------------------------------------------------------------ %
    %  Fixed physical limits — identical for all teams                   %
    % ------------------------------------------------------------------ %
    properties (Constant)
        WHEELBASE       = 0.5    % m   — bicycle model wheelbase
        MAX_SPEED       = 10.0   % m/s — top speed
        MAX_ACCEL       = 3.0    % m/s² — maximum acceleration
        MAX_BRAKE       = 6.0    % m/s² — maximum braking deceleration
        MAX_STEER_ANGLE = 0.5    % rad  — maximum front-wheel angle (~28.6°)
        MAX_STEER_RATE  = 1.0    % rad/s — maximum steering change rate
    end

    % ------------------------------------------------------------------ %
    %  Methods                                                            %
    % ------------------------------------------------------------------ %
    methods

        function obj = Vehicle(x0, y0, theta0)
        % VEHICLE(x0, y0, theta0)  Initialise vehicle at given pose.
        %
        %   x0     — initial x position (m)
        %   y0     — initial y position (m)
        %   theta0 — initial heading (rad), default = 0 (East)
            if nargin >= 1, obj.x     = x0;     end
            if nargin >= 2, obj.y     = y0;     end
            if nargin >= 3, obj.theta = theta0; end
            obj.v             = 0;
            obj.steeringAngle = 0;
        end

        % -------------------------------------------------------------- %
        function step(obj, throttle, steering, dt)
        % STEP(throttle, steering, dt)  Advance physics by one timestep.
        %
        %   throttle : [-1, +1]  -1 = max brake, +1 = max accel
        %   steering : [-1, +1]  -1 = full left,  +1 = full right
        %   dt       : timestep (s)

            % Clamp commanded inputs to valid range
            throttle = max(-1, min(1, double(throttle)));
            steering = max(-1, min(1, double(steering)));

            % ---- Steering: rate-limited first-order response ----
            targetSteer = steering * obj.MAX_STEER_ANGLE;
            maxDelta    = obj.MAX_STEER_RATE * dt;
            delta       = targetSteer - obj.steeringAngle;
            obj.steeringAngle = obj.steeringAngle + max(-maxDelta, min(maxDelta, delta));

            % ---- Acceleration / braking ----
            if throttle >= 0
                accel = throttle * obj.MAX_ACCEL;
            else
                accel = throttle * obj.MAX_BRAKE;   % throttle < 0 → braking
            end

            % ---- Speed update (Euler, clamped) ----
            obj.v = obj.v + accel * dt;
            obj.v = max(0, min(obj.MAX_SPEED, obj.v));

            % ---- Kinematic bicycle model (front-axle reference) ----
            % dtheta/dt = v * tan(delta) / L
            if abs(obj.steeringAngle) > 1e-6
                R      = obj.WHEELBASE / tan(obj.steeringAngle);
                dTheta = (obj.v * dt) / R;
            else
                dTheta = 0;
            end

            obj.x     = obj.x + obj.v * cos(obj.theta) * dt;
            obj.y     = obj.y + obj.v * sin(obj.theta) * dt;
            obj.theta = obj.theta + dTheta;

            % Normalise heading to [-pi, pi]
            obj.theta = atan2(sin(obj.theta), cos(obj.theta));
        end

        % -------------------------------------------------------------- %
        function obs = buildObs(obj, track, dt)
        % BUILDOBS  Construct the obs struct delivered to controller(obs, config).
            obs.position     = [obj.x, obj.y];
            obs.heading      = obj.theta;
            obs.speed        = obj.v;
            obs.trackWidth   = track.width;
            obs.dt           = dt;
            obs.previewPoints = track.getPreviewPoints(obj.x, obj.y, obj.theta, 20);
        end

        % -------------------------------------------------------------- %
        function s = getState(obj)
        % GETSTATE  Return current vehicle state as a plain struct.
            s.x             = obj.x;
            s.y             = obj.y;
            s.theta         = obj.theta;
            s.v             = obj.v;
            s.steeringAngle = obj.steeringAngle;
        end

    end % methods
end % classdef
