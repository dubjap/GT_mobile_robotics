% Costum turtlebot class definition for use in GT mobile robotics education
%
% Properties:
%
% Functions:
%
% Robin Amsters - 2017

classdef Turtlebot_GT < handle
    properties
        ip           % IP address of the robot. By default this should be 192.168.42.1
        turtlebot    % turtlebot object from the MATLAB ROS toolbox
        vel_pub      % publisher object for the /cmd_vel node
        vel_msg      % Twist message that gets published by the velocity publisher
        s_set        % Defining starting coordinates
        odom_prev    % Previous position
    end
    methods
        function turtle = Turtlebot_GT(ip)
            turtle.ip = ip;
            rosshutdown;                                                      % To make sure there are no MATLAB nodes still running
            rosinit(ip);                                                      % Setting the connection between MATLAB and ROS
            turtle.turtlebot = turtlebot(ip);                                 % Initialize turtlebot object (depends on turtlebot support package)
            turtle.vel_pub = rospublisher('/cmd_vel', 'geometry_msgs/Twist'); % ROS publisher for velocity commands
            turtle.vel_msg = rosmessage(turtle.vel_pub);
            %             turtle.s_set = getOdometry(turtle.turtlebot);
            turtle.odom_prev = getOdometry(turtle.turtlebot);
        end
        
        function [ds,dth] = get_Odometry(turtle)
            % Return distance driven and angle turned since the last call
            % to this function.
            %
            % INPUTS:
            %   - None
            % OUTPUTS:
            %   - ds = Distance driven since the last function call. This
            %          is defined as: ds = sqrt(dx^2 + dy^2). With dx and
            %          dy the distance traveled along the x- and y-axes,
            %          respectively.
            %   - dth = Angle turned around the vertical axis since the
            %           last function call.
            
            % Get odometry data
            [odom,~] = getOdometry(turtle.turtlebot);
            
            % Extract relevant coordinates
            dx = odom.Position(1) - turtle.odom_prev.Position(1);
            dy = odom.Position(2) - turtle.odom_prev.Position(2);
            dth = wrapToPi(odom.Orientation(1) - turtle.odom_prev.Orientation(1));
            
            % Conversions
            ds = sqrt(dx^2 + dy^2);
            
            % Save current position for next call
            turtle.odom_prev = odom;
        end
        
        function [scan] = get_scan(turtle)
            % Get data from laser scanner
            %
            % INPUTS:
            %   - None
            % OUTPUTS:
            %   - scan = Laser scan measurements in a struct with field
            %   'Ranges' [360×1 double] and 'Angles' [360×1 double].
            %
            %   Example:
            %        scan = turtlebot.get_scan()                 % Get LIDAR scan data
            %        [x,y]=pol2cart(scan.Angles,scan.Ranges);    % Convert to Carthesian coordinates
            %        scatter(x,y);                               % Plot coordinates
            
            scan = getLaserScan(turtle.turtlebot);
        end
        
        function set_linear_angular_velocity(turtle, v,w)
            % Function to apply a linear and angular velocity to the robot
            %
            % INPUTS:
            %   - v = linear velocity along the X axis of the robot [m/s].
            %         A positive velocity makes the robot drive forwards. A
            %         negative velocity makes the robot drive backwards.
            %         Maximum speed is 0.2 m/s.
            %   - w = angular velocity around the Z axis of the robot
            %         [rad/s]. A positive velocity makes the robot turn
            %         counterclockwise. A negative velocity makes the robot
            %         turn clockwise.
            % OUTPUTS:
            %   - None
            
            % Set linear velocity
            turtle.vel_msg.Linear.X = v;
            % Set angular velocity
            turtle.vel_msg.Angular.Z = w;
            
            % Publish velocity message
            send(turtle.vel_pub,turtle.vel_msg);
        end
        
        function set_linear_velocity_radius(turtle, v, r)
            % Moves robot by setting a forward velocity and turning radius.
            %
            % INPUTS:
            %   - v = linear velocity along the X axis of the robot [m/s].
            %         A positive velocity makes the robot drive forwards. A
            %         negative velocity makes the robot drive backwards.
            %         Maximum speed is 0.2 m/s.
            %   - r = turning radius around the Z axis of the robot [m]. A 
            %         positive radius makes the robot turn counterclockwise. 
            %         A negative radius makes the robot turn clockwise. 
            % OUTPUTS:
            %   - None
            
            % Set linear velocity
            turtle.vel_msg.Linear.X = v;
            % Set angular velocity
            turtle.vel_msg.Angular.Z = v/r;
            
            % Publish velocity message
            send(turtle.vel_pub,turtle.vel_msg);
        end
        
        function drive_straight(turtle, distance, speed)
            % Let the robot drive a fixed distance at a certain speed
            %
            % INPUTS:
            %   - distance = distance to travel in meters.
            %   - speed = speed at which to drive in meters per second.
            %             A positive velocity makes the robot drive
            %             forwards. A negative velocity makes the robot
            %             drive backwards. Maximum speed is 0.2 m/s.
            % OUTPUTS:
            %   - None
            
            s = 0;
            turtle.set_linear_angular_velocity(speed, 0);
            
            while abs(s) < distance
                [ds,~] = get_Odometry(turtle);
                s = s + ds;
            end
            turtle.stop()
            
        end
        
        function drive_arc(turtle, speed, angle, r)
            % Let the robot drive a fixed distance at a certain speed
            %
            % INPUTS:
            %   - speed = speed at which to drive in meters per second.
            %             A positive velocity makes the robot drive
            %             forwards. A negative velocity makes the robot
            %             drive backwards. Maximum speed is 0.2 m/s.
            %   - angle = angle of arc segment to turn in radians
            %   - r = radius of the arc in meters. A positive radius makes
            %         the robot turn counterclockwise. A negative radius
            %         makes the robot turn clockwise.
            % OUTPUTS:
            %   - None
            
            th = 0;
            turtle.set_linear_velocity_radius(speed, r);
            
            while abs(th) < angle
                [~,dth] = get_Odometry(turtle);
                th = th + dth;
            end
            turtle.stop()
            
        end
        
        function turn_angle(turtle, angle, angular_speed)
            % Let the robot turn a fixed angle at a certain angular speed
            %
            % INPUTS:
            %   - angle = angle to turn in radians
            %   - angular_speed = speed at which to turn in radians per
            %                     second. A positive velocity makes the
            %                     robot turn counterclockwise. A negative
            %                     velocity makes the robot turn clockwise.
            % OUTPUTS:
            %   - None
            
            th = 0;
            turtle.set_linear_angular_velocity(0, angular_speed);
            
            while abs(th) < angle
                [~,dth] = get_Odometry(turtle);
                th = th + dth;
            end
            turtle.stop()
            
        end
        
        function stop(turtle)
            % Set all speeds of the robot to zerp
            %
            % INPUTS:
            %   -None
            % OUTPUTS:
            %   -None
            
            % Set all linear velocities and angular velocities to 0
            turtle.vel_msg.Linear.X = 0.0;
            turtle.vel_msg.Linear.Y = 0.0;
            turtle.vel_msg.Linear.Z = 0.0;
            turtle.vel_msg.Angular.X = 0;
            turtle.vel_msg.Angular.Y = 0;
            turtle.vel_msg.Angular.Z = 0;
            
            % Publish velocity message
            send(turtle.vel_pub,turtle.vel_msg);
        end
    end
end
