% Copyright (C) 2020 Imperial College London.
% All rights reserved.
%
% This program is a free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% This software tool was developed with support from the UKIERI and
% the Commonwealth Scholarship Commission, UK

classdef Kick_Simulator_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        KickDesignLabel                matlab.ui.control.Label
        Actuator1Label                 matlab.ui.control.Label
        Actuator2Label                 matlab.ui.control.Label
        WallDisplacementmmLabel        matlab.ui.control.Label
        WallDisplacementmmEditField    matlab.ui.control.NumericEditField
        Actuator1sEditFieldLabel       matlab.ui.control.Label
        Actuator1sEditField            matlab.ui.control.NumericEditField
        PauseatthepeaksEditFieldLabel  matlab.ui.control.Label
        PauseatthepeaksEditField       matlab.ui.control.NumericEditField
        WallDisplacementmmLabel_2      matlab.ui.control.Label
        WallDisplacementmmEditField_2  matlab.ui.control.NumericEditField
        Actuator2sEditFieldLabel       matlab.ui.control.Label
        Actuator2sEditField            matlab.ui.control.NumericEditField
        PauseatthepeaksEditField_2Label  matlab.ui.control.Label
        PauseatthepeaksEditField_2     matlab.ui.control.NumericEditField
        StartwithActuatorLabel         matlab.ui.control.Label
        StartwithActuatorDropDown      matlab.ui.control.DropDown
        NoofKicksEditField_2Label      matlab.ui.control.Label
        NoofKicksEditField_2           matlab.ui.control.NumericEditField
        NoofKicksEditField_3Label      matlab.ui.control.Label
        NoofKicksEditField_3           matlab.ui.control.NumericEditField
        DelayBetweenKickssLabel        matlab.ui.control.Label
        DelayBetweenKickssEditField    matlab.ui.control.NumericEditField
        FetalKickSimulatorLabel        matlab.ui.control.Label
        KickingActionLabel             matlab.ui.control.Label
        StartKickingButton             matlab.ui.control.Button
        DelayBetweenActuatorssLabel    matlab.ui.control.Label
        DelayBetweenActuatorssEditField  matlab.ui.control.NumericEditField
        FeedbackLabel                  matlab.ui.control.Label
        DelayBetweenKickssLabel_2      matlab.ui.control.Label
        DelayBetweenKickssEditField_2  matlab.ui.control.NumericEditField
        KickDurationLabel              matlab.ui.control.Label
        StatusEditFieldLabel           matlab.ui.control.Label
        StatusEditField                matlab.ui.control.EditField
        KickModeDropDownLabel          matlab.ui.control.Label
        KickModeDropDown               matlab.ui.control.DropDown
        WarningEditFieldLabel          matlab.ui.control.Label
        WarningEditField               matlab.ui.control.EditField
        ConnecttheArduinoButton        matlab.ui.control.Button
        UIAxes                         matlab.ui.control.UIAxes
        SamplingPeriodsEditFieldLabel  matlab.ui.control.Label
        SamplingPeriodsEditField       matlab.ui.control.NumericEditField
        UIAxes_2                       matlab.ui.control.UIAxes
        DaqSettingLabel                matlab.ui.control.Label
        DataSamplingrateKHzEditFieldLabel  matlab.ui.control.Label
        DataSamplingrateKHzEditField   matlab.ui.control.NumericEditField
        ActuatorTipDropDownLabel       matlab.ui.control.Label
        ActuatorTipDropDown            matlab.ui.control.DropDown
        SaveDataButton                 matlab.ui.control.Button
        MaximumForceLabel              matlab.ui.control.Label
        Actuator1NEditFieldLabel       matlab.ui.control.Label
        Actuator1NEditField            matlab.ui.control.NumericEditField
        Actuator2NEditFieldLabel       matlab.ui.control.Label
        Actuator2NEditField            matlab.ui.control.NumericEditField
        WallGapCorrectionmmEditFieldLabel  matlab.ui.control.Label
        WallGapCorrectionmmEditField   matlab.ui.control.NumericEditField
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            clc; % Can't use clear here: Because in that case comment bix does not work
            %
            % Setting up the Arduino connection by calling the relavent function
            ConnecttheArduinoButtonPushed(app);
            %
        end

        % Button pushed function: StartKickingButton
        function StartKickingButtonPushed(app, event)
            % Decleration of the golbal variables
            global act1 act2 gap_between_act_wall no_load_speed full_load_speed m_act1 m_act2 check_if_kicking_on check_if_arduino_connected SensorData ...
                SamplingTiming F_Sensor1_max F_Sensor2_max
            %
            cd 'C:\Users\akg18\Box Sync\My Documents\Academic- PhD_Imperial\Research Work\My Work\Test_Bed\Codes\Kick_Simulator'
            SensorData = zeros(1,16); % This is the variable for stroing the sensor data from the daq; it needs to be initialized
            SamplingTiming = zeros(1,1); % This is the variable for stroing the data sampling timing from the daq; it needs to be initialized
            %
            try % In case some error is generated in this section, which can happen due to power or connection loss, the program execution goes to the catch statement
                %
                % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Check if arduino is not connected ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                if(check_if_arduino_connected == 0)
                    app.StatusEditField.Value = 'Connect the arduino hardware and press the "Connect the Arduino" button.';
                    app.WarningEditField.Value = ''; % Clearing the Warning messsage box
                    beep;
                    clear all % To clear the previous arduino object
                    return
                end
                %
                % Check if kicking is already going on
                if(check_if_kicking_on == 1)
                    app.StatusEditField.Value = 'Kicking is going on. Wait until it finishes...';
                    beep;
                    return % The function returns to the main terminal
                end
                %
                % If the arduino board is connected and no kicking is going on, the following commands will be executed
                %
                %xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
                %
                % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Calculation of parameters by reading the user input ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                %
                tot_disp1 = app.WallDisplacementmmEditField.Value + gap_between_act_wall; % total displacement for actuator1
                tot_disp2 = app.WallDisplacementmmEditField_2.Value + gap_between_act_wall; % total displacement for actuator2
                pos1 = (tot_disp1+2)/m_act1; % position variable for actuator1; 2 is added to compensate for the slowness in last two mm
                pos2 = (tot_disp2+2)/m_act2; % position variable for actuator2; 2 is added to compensate for the slowness in last two mm
                % full_load_speed is calculated in a way so the delay_time will not allow the movement for last 2 mm.
                %
                delay_time1 = gap_between_act_wall/no_load_speed + app.WallDisplacementmmEditField.Value/full_load_speed...
                    + app.PauseatthepeaksEditField.Value; % delay time for actuator1 in sec
                delay_time2 = gap_between_act_wall/no_load_speed + app.WallDisplacementmmEditField_2.Value/full_load_speed...
                    + app.PauseatthepeaksEditField_2.Value; % delay time for actuator2 in sec
                return_delay_time1 = tot_disp1/no_load_speed; % Returning delay time for actuator1
                return_delay_time2 = tot_disp2/no_load_speed; % Returning delay time for actuator2
                additional_delay1 = app.DelayBetweenKickssEditField.Value - 2*gap_between_act_wall/no_load_speed; % delay between kicks
                additional_delay2 = app.DelayBetweenKickssEditField_2.Value - 2*gap_between_act_wall/no_load_speed;
                %
                % Following variables keeps the count of kicking. These are initialized with total no. of kicks desired
                kick_count_act1 = app.NoofKicksEditField_2.Value; % No. of kicks for actuator1
                kick_count_act2 = app.NoofKicksEditField_3.Value; % No. of kicks for actuator2
                %
                % Initialization of the kick duration and the Status and Warning message boxes
                app.Actuator1sEditField.Value = 0;
                app.Actuator2sEditField.Value = 0;
                app.StatusEditField.Value = '';
                app.WarningEditField.Value = '';
                %
                % Check for minimum no of kicks
                if(kick_count_act1 <= 0 && kick_count_act2 <= 0)
                    app.StatusEditField.Value = 'Specify the number of kicks.';
                    beep;
                    return % The function returns to the main terminal
                end
                %
                % Check for the position variable limits
                if (pos1 > 1 || pos2 > 1)
                    app.StatusEditField.Value = 'Maximum allowed wall displacement is surpassed.';
%                     app.WarningEditField.Value = 'Maximum displacement for cylindrical tip = 24 mm and for hemispherical tip = 19 mm.';
                    beep;
                    return % This will end the executin of this function
                end
                %
                % Updating the status check variable for the kicking
                check_if_kicking_on = 1; % It indicates some kicking is going on. This variable will be cleared at the end of kicking
                %
                % XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Starting the data acquisition by the DAQ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                %
                % Setting up the device and the session
                dev = daq.getDevices(); % Stores the available daq devices
                ds = daq.createSession(dev(1,1).Vendor.ID); % Creates a session object for configuring and operating data acquisition devices from the specified vendor
                %
                % Adding the analog input pins and setting up the terminal configuration for each pins
                channel_ID = {'ai0','ai1','ai2','ai3','ai4','ai5','ai6','ai7','ai8','ai9','ai10','ai11','ai12','ai13','ai14','ai15'}; % Listing of all analog ports
                ch = addAnalogInputChannel(ds,dev(1,1).ID,channel_ID,'Voltage'); % Adding the analog input channels for the session
                for i=1:16
                    ch(1,i).TerminalConfig = 'SingleEnded'; % Configring the channels as 'SingleEnded'
                end
                %
                % Setting up the data sampling rate
                if (app.DataSamplingrateKHzEditField.Value <= 25)
                    ds.Rate = 1000*app.DataSamplingrateKHzEditField.Value; % reading the sampling rate value in Hz
                else
                    app.StatusEditField.Value = 'Maximum data sampling rate is 25KHz.';
                    beep;
                    return
                end
                ds.NotifyWhenDataAvailableExceeds = round(ds.Rate/4);
                ds.IsContinuous = true; % For contunuous sampling
                %
                Lstnr = addlistener(ds,'DataAvailable',@plotData); % Adding a listner for the event when data is available
                startBackground(ds); % Starting the session on background
                %
                % XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Actuating the kicks ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                %****************************************************************************************************************************************
                %
                tic; % To keep track of the sampling period
                app.StatusEditField.Value = 'Kicking is going on...';
                app.WarningEditField.Value = '';
                app.StartKickingButton.Enable = 0; % Disabling the StartKicking button
                % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Kick Mode = Single ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                %
                if (app.KickModeDropDown.Value == '            Single')
                    if app.StartwithActuatorDropDown.Value == '1' % Actuator1 will be fired
                        %
                        if(additional_delay1 < 0 && app.DelayBetweenKickssEditField.Value ~= 0)
                            % In case the dely between kicks is not the default value (= 0) or the calculated additinal delay is < 0
                            % the following warning will be diplayed
                            app.WarningEditField.Value = '"Delay Between Kicks" is less than the minimum delay required.';
                            beep;
                        end
                        %
                        while(kick_count_act1 > 0) % Until the variable is greater than 0, the kicking will continue
                            writePosition(act1,pos1);
                            pause(delay_time1); % Allows the actuator to reach the maximum position
                            writePosition(act1,0);
                            pause(return_delay_time1); % Allows the actuator to return to minimum position
                            %
                            % Check for additional delay between consequitive kicks
                            if(additional_delay1 > 0)
                                pause(additional_delay1); % Additional delay between consequitive kicks
                            end
                            %
                            kick_count_act1 = kick_count_act1 - 1; % Reduction of the kick counting variable
                        end
                        %
                    else % Actuator2 will be fired
                        %
                        if(additional_delay2 < 0 && app.DelayBetweenKickssEditField_2.Value ~= 0)
                            app.WarningEditField.Value = '"Delay Between Kicks" is less than the minimum delay required.';
                            beep;
                        end
                        %
                        while(kick_count_act2 > 0) % Until the variable is greater than 0, the kicking will continue
                            writePosition(act2,pos2);
                            pause(delay_time2); % Allows the actuator to reach the maximum position
                            writePosition(act2, 0);
                            pause(return_delay_time2); % Allows the actuator to reach the minimum position
                            %
                            % Check for additional delay between consequitive kicks
                            if(additional_delay2 > 0)
                                pause(additional_delay2); % Additional delay between consequitive kicks
                            end
                            %
                            kick_count_act2 = kick_count_act2 - 1; % Reduction of the kick counting variable
                        end
                    end
                    %
                    % Display the kick durations
                    app.Actuator1sEditField.Value = (delay_time1 + return_delay_time1 - 2 * gap_between_act_wall/no_load_speed);
                    app.Actuator2sEditField.Value = (delay_time2 + return_delay_time2 - 2 * gap_between_act_wall/no_load_speed);
                    % Delay at the pick is included in the kick duration
                    %
                    % XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                    %
                    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Kick Mode = Dual: Simulteneous ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    %
                elseif (app.KickModeDropDown.Value == 'Dual: Simulteneous')
                    %
                    if (app.StartwithActuatorDropDown.Value == '1')
                        kick_count_act = kick_count_act1;
                    else
                        kick_count_act = kick_count_act2;
                    end
                    %
                    while(kick_count_act > 0)
                        writePosition(act1,pos1);
                        writePosition(act2,pos2);
                        %
                        if (delay_time1 < delay_time2) % If the delay required for actuator1 is less than actuator2
                            pause(delay_time1); % Pause for lower delay
                            writePosition(act1,0); % Write the return position to actuator1
                            pause(delay_time2 - delay_time1); % Pause for the rest of the delay
                            writePosition(act2,0); % Write the return position to actuator2
                            pause (return_delay_time2); % Pause for the higher delay as return_delay_time2 > return_delay_time1,
                            % The next cycle starts together
                            %
                        else % delay_time1 > delay_time_2
                            pause(delay_time2);
                            writePosition(act2,0);
                            pause(delay_time1 - delay_time2);
                            writePosition(act1,0);
                            pause (return_delay_time1);
                        end
                        %
                        kick_count_act = kick_count_act - 1;
                    end
                    %
                    % Display the kick durations
                    app.Actuator1sEditField.Value = (delay_time1 + return_delay_time1 - 2 * gap_between_act_wall/no_load_speed);
                    app.Actuator2sEditField.Value = (delay_time2 + return_delay_time2 - 2 * gap_between_act_wall/no_load_speed);
                    % Delay at the pick is included in the kick duration
                    %
                    % XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                    %
                    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Kick Mode = Dual: Consequitve ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    %
                elseif (app.KickModeDropDown.Value == 'Dual: Consequitive')
                    max_kick_count = max(kick_count_act1, kick_count_act2);
                    %
                    % Actuating the kicks
                    if app.StartwithActuatorDropDown.Value == '1' % Actuator 1 will be fired first
                        %
                        while (max_kick_count > 0) % loop for multiple kicks
                            %
                            if (kick_count_act1 > 0) % Individual actuator will be checked before each kicking
                                writePosition(act1,pos1);
                                pause(delay_time1); % Allows the actuator to reach the maximum position
                                writePosition(act1,0);
                                pause(return_delay_time1); % Allows the actuator to return to minimum position
                                %
                                kick_count_act1 = kick_count_act1 - 1; % reduce the kick counting variable
                                %
                            end
                            %
                            if (kick_count_act2 > 0)
                                writePosition(act2,pos2);
                                pause(delay_time2); % Allows the actuator to reach the maximum position
                                writePosition(act2, 0);
                                pause(return_delay_time2); % Allows the actuator to reach the minimum position
                                %
                                kick_count_act2 = kick_count_act2 - 1;
                            end
                            %
                            max_kick_count = max_kick_count - 1;
                        end
                        %
                    else % Actuator 2 will be fired first
                        while (max_kick_count > 0) % loop for multiple kicks
                            %
                            if (kick_count_act2 > 0)
                                writePosition(act2,pos2);
                                pause(delay_time2); % Allows the actuator to reach the maximum position
                                writePosition(act2, 0);
                                pause(return_delay_time2); % Allows the actuator to reach the minimum position
                                %
                                kick_count_act2 = kick_count_act2 - 1;
                            end
                            if (kick_count_act1 > 0)
                                writePosition(act1,pos1);
                                pause(delay_time1); % Allows the actuator to reach the maximum position
                                writePosition(act1,0);
                                pause(return_delay_time1); % Allows the actuator to return to minimum position
                                %
                                kick_count_act1 = kick_count_act1 - 1; % reduce the kick counting variable
                                %
                            end
                            %
                            max_kick_count = max_kick_count - 1;
                        end
                    end
                    %
                    % Display the kick durations
                    app.Actuator1sEditField.Value = (delay_time1 + return_delay_time1 - 2 * gap_between_act_wall/no_load_speed);
                    app.Actuator2sEditField.Value = (delay_time2 + return_delay_time2 - 2 * gap_between_act_wall/no_load_speed);
                    % Delay at the pick is included in the kick duration
                    %
                    % XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                    %
                    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Kick Mode = Dual: Random ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    %
                else
                    max_kick_count = max(kick_count_act1, kick_count_act2);
                    %
                    % Actuating the kicks
                    if (app.StartwithActuatorDropDown.Value == '1') % Actuator1 will be fired first
                        %
                        while (max_kick_count > 0) % loop for multiple kicks
                            %
                            act1_kick = 0; % Variable to mark whether actuator1 is kicking within an iteration
                            %
                            if (kick_count_act1 > 0) % If actuator1 is kicking
                                writePosition(act1,pos1);
                                kick_count_act1 = kick_count_act1 - 1; % reducing the kick counting variable for actuator1
                                act1_kick = 1; % This variable indicates whether actuator1 is kicking or not, inside an iteration
                            end
                            %
                            if (kick_count_act2 > 0) % If actuator2 is kicking
                                %
                                kick_count_act2 = kick_count_act2 - 1; % reducing the kick counting variable for actuator2
                                %
                                if (act1_kick == 1) % if the actuator1 is kicking
                                    %
                                    if(app.DelayBetweenActuatorssEditField.Value < delay_time1) % If the delay between actuators is smaller, that delay will be made first
                                        pause(app.DelayBetweenActuatorssEditField.Value);
                                        writePosition(act2,pos2); % After the delay, the actuator2 will start
                                        %
                                        if ((delay_time1 - app.DelayBetweenActuatorssEditField.Value) < delay_time2)
                                            pause(delay_time1 - app.DelayBetweenActuatorssEditField.Value);
                                            writePosition(act1,0);
                                            pause(delay_time2 - (delay_time1 - app.DelayBetweenActuatorssEditField.Value));
                                            writePosition(act2,0);
                                            pause(max(return_delay_time2,(return_delay_time1-(delay_time2 - (delay_time1 - app.DelayBetweenActuatorssEditField.Value)))));
                                        else
                                            pause(delay_time2);
                                            writePosition(act2,0);
                                            pause(delay_time1 - (app.DelayBetweenActuatorssEditField.Value + delay_time2));
                                            writePosition(act1,0);
                                            pause(max(return_delay_time1,(return_delay_time2 - (delay_time1 - (app.DelayBetweenActuatorssEditField.Value + delay_time2)))));
                                        end
                                        %
                                    else % If the delay for actuator1 is smaller, that delay will be made first
                                        pause(delay_time1);
                                        writePosition(act1,0); % After the delay, the actuator1 will start to return to the origin
                                        pause(app.DelayBetweenActuatorssEditField.Value - delay_time1); % Rest of the delay before starting the actuator2
                                        writePosition(act2,pos2); % Starting the actuator2
                                        %
                                        if (return_delay_time1 <= (app.DelayBetweenActuatorssEditField.Value - delay_time1)) % Actuator1 has already returned to origin
                                            pause(delay_time2);
                                            writePosition(act2,0); % Actuator2 start returning
                                            pause(return_delay_time2);
                                        else
                                            if ((return_delay_time1 - (app.DelayBetweenActuatorssEditField.Value - delay_time1)) <= delay_time2)
                                                pause(delay_time2); % Actuator1 will return to origin by this time
                                                writePosition(act2,0); % Actuator2 start returning
                                                pause(return_delay_time2);
                                            else
                                                pause(delay_time2);
                                                writePosition(act2,0); % Actuator2 start returning
                                                pause(max(return_delay_time2,(return_delay_time1 - ((app.DelayBetweenActuatorssEditField.Value - delay_time1) + delay_time2))));
                                                % after starting the return journey of actuator1
                                            end
                                        end
                                        %
                                    end
                                    %
                                else % Actuator1 is not kicking
                                    writePosition(act2,pos2);
                                    pause(delay_time2);
                                    writePosition(act2,0);
                                    pause(return_delay_time2);
                                end
                                %
                            else % If actuator2 is not kicking
                                if (act1_kick == 1) % If the actuator1 is kicking; probably, this condition is always gonna be true when actuator2 is not kicking
                                    pause(delay_time1);
                                    writePosition(act1,0);
                                    pause(return_delay_time1);
                                end
                            end
                            %
                            max_kick_count = max_kick_count - 1;
                            %
                        end
                        %
                    else % Actuator2 is kicking first
                        while (max_kick_count > 0) % loop for multiple kicks
                            %
                            act2_kick = 0;
                            %
                            if (kick_count_act2 > 0) % If actuator2 is kicking
                                writePosition(act2,pos2);
                                kick_count_act2 = kick_count_act2 - 1; % reducing the kick counting variable for the actuator2
                                act2_kick = 1; % This variable indicates whether actuator2 is kicking or not inside an iteration
                            end
                            %
                            if (kick_count_act1 > 0) % If actuator1 is kicking
                                %
                                kick_count_act1 = kick_count_act1 - 1; % reducing the kick counting variable for actuator1
                                %
                                if (act2_kick == 1) % if the actuator2 is kicking
                                    %
                                    if(app.DelayBetweenActuatorssEditField.Value < delay_time2) % If the delay between actuators is smaller, that delay will be made first
                                        pause(app.DelayBetweenActuatorssEditField.Value);
                                        writePosition(act1,pos1); % After the delay, the actuator1 will start
                                        %
                                        if ((delay_time2 - app.DelayBetweenActuatorssEditField.Value) < delay_time1)
                                            pause(delay_time2 - app.DelayBetweenActuatorssEditField.Value);
                                            writePosition(act2,0);
                                            pause(delay_time1 - (delay_time2 - app.DelayBetweenActuatorssEditField.Value));
                                            writePosition(act1,0);
                                            pause(max(return_delay_time1,(return_delay_time2-(delay_time1 - (delay_time2 - app.DelayBetweenActuatorssEditField.Value)))));
                                        else
                                            pause(delay_time1);
                                            writePosition(act1,0);
                                            pause(delay_time2 - (app.DelayBetweenActuatorssEditField.Value + delay_time1));
                                            writePosition(act2,0);
                                            pause(max(return_delay_time2,(return_delay_time1 - (delay_time2 - (app.DelayBetweenActuatorssEditField.Value + delay_time1)))));
                                        end
                                        %
                                    else % If the delay for actuator2 is smaller, that delay will be made first
                                        pause(delay_time2);
                                        writePosition(act2,0); % After the delay, the actuator2 will start to return to the origin
                                        pause(app.DelayBetweenActuatorssEditField.Value - delay_time2); % Rest of the delay before starting the actuator1
                                        writePosition(act1,pos1); % Starting the actuator1
                                        %
                                        if (return_delay_time2 <= (app.DelayBetweenActuatorssEditField.Value - delay_time2)) % Actuator2 has already returned to origin
                                            pause(delay_time1);
                                            writePosition(act1,0); % Actuator1 start returning
                                            pause(return_delay_time1);
                                        else % Actuator2 has not reached to origin yet
                                            if ((return_delay_time2 - (app.DelayBetweenActuatorssEditField.Value - delay_time2)) <= delay_time1)
                                                pause(delay_time1); % Actuator2 will return to origin before the end of this time
                                                writePosition(act1,0); % Actuator1 start returning
                                                pause(return_delay_time1);
                                            else
                                                pause(delay_time1); % Actuator2 will not return to origin by the end of this time
                                                writePosition(act1,0); % Actuator1 start returning
                                                pause(max(return_delay_time1,(return_delay_time2 - ((app.DelayBetweenActuatorssEditField.Value - delay_time2) + delay_time1))));
                                                % ((app.DelayBetweenActuatorssEditField.Value - delay_time2) + delay_time1) = time already spent after
                                                % starting the return journey of actuator2
                                            end
                                        end
                                        %
                                    end
                                    %
                                else % Actuator2 is not kicking
                                    writePosition(act1,pos1);
                                    pause(delay_time1);
                                    writePosition(act1,0);
                                    pause(return_delay_time1);
                                end
                                %
                            else % If actuator1 is not kicking
                                if (act2_kick == 1) % If the actuator2 is kicking;
                                    % probably, this condition is always gonna be true when actuator1 is not kicking
                                    pause(delay_time2);
                                    writePosition(act2,0);
                                    pause(return_delay_time2);
                                end
                            end
                            %
                            max_kick_count = max_kick_count - 1;
                            %
                        end
                    end
                    %
                    % Display the kick durations
                    app.Actuator1sEditField.Value = (delay_time1 + return_delay_time1 - 2 * gap_between_act_wall/no_load_speed);
                    app.Actuator2sEditField.Value = (delay_time2 + return_delay_time2 - 2 * gap_between_act_wall/no_load_speed);
                    %
                end
                %
                % XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                %
                % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Post-Processing and Closing of the session ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                %
                stop (ds); % Stopping the data acquisition
                Total_Sampling_period = toc; % Calculating the total data sampling time
                app.SamplingPeriodsEditField.Value = Total_Sampling_period; % Upadting the total sampling period field
                %
                % Updating the status variables and the message box
                app.StatusEditField.Value = 'Kicking has finished.';
                app.StartKickingButton.Enable = 1; % Enabling the button
                check_if_kicking_on = 0; % Updating the status check variable for the kicking; Required for the next button press
                beep;
                %
                % Plotting the force vs time graph
                timeAxis = (linspace(0,Total_Sampling_period,length(SensorData)))'; % length(sensor1) gives the no. of element
                V_Sensor1 = SensorData(:,15);
                F_Sensor1 = 2.4357*V_Sensor1.^3-4.1656*V_Sensor1.^2+11.882*V_Sensor1; % Conversion to force value in N
                V_Sensor2 = SensorData(:,16);
                F_Sensor2 = 2.3545*V_Sensor2.^3-4.2152*V_Sensor2.^2+14.028*V_Sensor2; % Conversion to force value in N
                plot(app.UIAxes,timeAxis,F_Sensor1,'b',timeAxis,F_Sensor2,'m');
                legend(app.UIAxes,{'Actuator1','Actuator2'});
                ylabel(app.UIAxes,'Force (N)');
                plot(app.UIAxes_2,timeAxis,SensorData(:,1:14))
                %
                % Getting the maximum value reaction force
                F_Sensor1_1s_avg = mean(F_Sensor1(1:ds.Rate)); % Average of the 1st 1s of force data
                F_Sensor2_1s_avg = mean(F_Sensor2(1:ds.Rate));
                F_Sensor1_max = max(F_Sensor1)- F_Sensor1_1s_avg; % Determining the maximum force from the sensor1
                F_Sensor2_max = max(F_Sensor2) - F_Sensor2_1s_avg; % Determining the maximum force from the sensor2
                app.Actuator1NEditField.Value = F_Sensor1_max; % Writing the maximum force value at the feedback section
                app.Actuator2NEditField.Value = F_Sensor2_max;
            catch
                app.StatusEditField.Value = 'Connection is lost. Try to reconnect';
                app.WarningEditField.Value = '';
                app.StartKickingButton.Enable = 1; % Enabling the button
                clear all; % Important to clear; otherwise arduino resetting will not work
            end
            %
            % Callback function for plotting the daq data
            function plotData(~,event)
                ylabel(app.UIAxes,'Sensor response (V)');
                plot(app.UIAxes,event.TimeStamps,event.Data(:,15:16))
                plot(app.UIAxes_2,event.TimeStamps,event.Data(:,1:14))
                SensorData = [SensorData; event.Data];
                SamplingTiming = [SamplingTiming; event.TimeStamps];
            end
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            delete(app);
            clear all; % This important, because it removes the arduino object at the of the code
        end

        % Button pushed function: ConnecttheArduinoButton
        function ConnecttheArduinoButtonPushed(app, event)
            % initializing the message box
            app.StatusEditField.Value = 'Trying to Set up the Arduino connection...';
            app.WarningEditField.Value = '';
            % Changing the directory for storing the data
            cd 'C:\Users\akg18\Box Sync\My Documents\Academic- PhD_Imperial\Research Work\My Work\Test_Bed\Codes\Kick_Simulator'
            pause(1); % So that you can see the above message
            %
            % Decleration of the golbal variables
            global a1 act1 act2 gap_between_act_wall no_load_speed full_load_speed m_act1 m_act2 check_if_kicking_on check_if_arduino_connected
            %
            % Difining the constants
            if app.ActuatorTipDropDown.Value == 'Hemispherical'
                gap_between_act_wall = 28 + app.WallGapCorrectionmmEditField.Value; % mm
                full_load_speed = 11.3; % mm/s
            else
                gap_between_act_wall = 24.5 + app.WallGapCorrectionmmEditField.Value; % mm
                full_load_speed = 12.08; % mm/s
            end
            no_load_speed = 12.43; % mm/s
            m_act1 = 45.216; % Tangent of the displacement vs position variable curve for actutor 1
            m_act2 = 46.831; % Tangent of the displacement vs position variable curve for actutor 1
            %
            % Declaring some checking variables
            check_if_kicking_on = 0;
            check_if_arduino_connected = 0;
            %
            % Setting up the connection
            try
                a1 = arduino('COM10','Mega2560'); % Create an arduino object.
                % Connect to the actuators in digital pin 3 and 2. Specs for max and min pulse duration
                % is taken from the datasheet of the actuator
                act1 = servo(a1, 'D2','MinPulseDuration', 1e-3, 'MaxPulseDuration', 2e-3);
                act2 = servo(a1, 'D3','MinPulseDuration', 1e-3, 'MaxPulseDuration', 2e-3);
                %
                % Setting 0 as the initial position
                writePosition(act1, 0);
                writePosition(act2, 0);
                %
                % Updating the connection status
                check_if_arduino_connected = 1; % Updating the status of the connection variable
                app.StatusEditField.Value = 'Arduino board is connected successfully.';% Updating the message box
                %
            catch % In case of error occures while setting up the connection, the following commands will be executed
                app.StatusEditField.Value = 'Arduino Connection is not found. Check the USB cable and try again.';
                %                 clear all; % This line does not clear the base workspace
                %                 evalin('base','clear all'); % to clear the variables in the base workspace
                return
            end
            %
            clearvars -except a1 act1 act2 gap_between_act_wall no_load_speed full_load_speed m_act1 m_act2 check_if_kicking_on check_if_arduino_connected
            % All the other variables except the above mentioned will be cleared. This is necessary as we couldn't use the clear all at the beginning.
        end

        % Value changed function: KickModeDropDown
        function KickModeDropDownValueChanged(app, event)
            Kick_mode_value = app.KickModeDropDown.Value;
            %
            if (Kick_mode_value == '      Dual: Random')
                %
                app.DelayBetweenActuatorssEditField.Editable = 1;
                app.DelayBetweenActuatorssEditField.Value = 0; % Initializes the value
                %
                % Fields for Actuator 1
                app.NoofKicksEditField_2.Editable = 1;
                app.WallDisplacementmmEditField.Editable = 1;
                app.PauseatthepeaksEditField.Editable = 1;
                app.DelayBetweenKickssEditField.Editable = 0; % "Delay Between Kicks" is not available in this mode
                app.DelayBetweenKickssEditField.Value = 0; % Changed back to default value
                %
                % Fields for Actuator 2
                app.NoofKicksEditField_3.Editable = 1;
                app.WallDisplacementmmEditField_2.Editable = 1;
                app.PauseatthepeaksEditField_2.Editable = 1;
                app.DelayBetweenKickssEditField_2.Editable = 0; % "Delay Between Kicks" is not available in this mode
                app.DelayBetweenKickssEditField_2.Value = 0;
                %
                app.WarningEditField.Value = '"Delay Between Kicks" is not available in this mode.';
                %
            elseif (Kick_mode_value == '            Single')
                %
                app.DelayBetweenActuatorssEditField.Editable = 0; % "Delay between actuators" is not available in this mode
                app.DelayBetweenActuatorssEditField.Value = 0; % Changed back to default value
                %
                % Fields for Actuator 1
                app.NoofKicksEditField_2.Editable = 1;
                app.WallDisplacementmmEditField.Editable = 1;
                app.PauseatthepeaksEditField.Editable = 1;
                app.DelayBetweenKickssEditField.Editable = 1; % "Delay Between Kicks" is available in this mode
                %
                % Fields for Actuator 2
                app.NoofKicksEditField_3.Editable = 1;
                app.WallDisplacementmmEditField_2.Editable = 1;
                app.PauseatthepeaksEditField_2.Editable = 1;
                app.DelayBetweenKickssEditField_2.Editable = 1;
                %
                app.WarningEditField.Value = '"Delay Between Actuators" is not available in this mode.';
                %
            else % In 'Dual: Simulteneous' and 'Dual: Consequitive' mode
                app.DelayBetweenActuatorssEditField.Editable = 0; % "Delay between actuators" is not available in this mode
                app.DelayBetweenActuatorssEditField.Value = 0; % Changed back to default value
                %
                % Fields for Actuator 1
                app.NoofKicksEditField_2.Editable = 1;
                app.WallDisplacementmmEditField.Editable = 1;
                app.PauseatthepeaksEditField.Editable = 1;
                app.DelayBetweenKickssEditField.Editable = 0; % "Delay Between Kicks" is not available in this mode
                app.DelayBetweenKickssEditField.Value = 0; % Changed back to default value
                %
                % Fields for Actuator 2
                app.NoofKicksEditField_3.Editable = 1;
                app.WallDisplacementmmEditField_2.Editable = 1;
                app.PauseatthepeaksEditField_2.Editable = 1;
                app.DelayBetweenKickssEditField_2.Editable = 0; % "Delay Between Kicks" is not available in this mode
                app.DelayBetweenKickssEditField_2.Value = 0; % Changed back to default value
                %
                if ((Kick_mode_value == 'Dual: Simulteneous') & (app.StartwithActuatorDropDown.Value == '1')) % Additional condition in case the mode is 'Dual: Simulteneous'
                    app.NoofKicksEditField_3.Editable = 0; % No. of kicks will be taken from the Actuator1
                    app.NoofKicksEditField_3.Value = 0;
                    %
                elseif ((Kick_mode_value == 'Dual: Simulteneous') & (app.StartwithActuatorDropDown.Value == '1'))
                    app.NoofKicksEditField_2.Editable = 0; % No. of kicks will be taken from the Actuator2
                    app.NoofKicksEditField_2.Value = 0;
                end
                %
                app.WarningEditField.Value = '"Delay Between Actuators" & "Delay Between Kicks" are not available in this mode';
                %
            end
            %
        end

        % Value changed function: StartwithActuatorDropDown
        function StartwithActuatorDropDownValueChanged(app, event)
            start_with_actuator_value = app.StartwithActuatorDropDown.Value;
            %
            if ((start_with_actuator_value == '1') & (app.KickModeDropDown.Value == '            Single'))
                % Turn on the Actuator 1
                app.NoofKicksEditField_2.Editable = 1;
                app.WallDisplacementmmEditField.Editable = 1;
                app.PauseatthepeaksEditField.Editable = 1;
                app.DelayBetweenKickssEditField.Editable = 1;
                %
                % Turn off the Actuator 2
                app.NoofKicksEditField_3.Editable = 0;
                app.NoofKicksEditField_3.Value = 0; % Resetting the No. of Kicks to 0 so that Actuator 2 is disabled
                app.WallDisplacementmmEditField_2.Editable = 0;
                app.PauseatthepeaksEditField_2.Editable = 0;
                app.DelayBetweenKickssEditField_2.Editable = 0;
                %
            elseif ((start_with_actuator_value == '2') & (app.KickModeDropDown.Value == '            Single'))
                % Turn off the Actuator 1
                app.NoofKicksEditField_2.Editable = 0;
                app.NoofKicksEditField_2.Value = 0; % Resetting the No. of Kicks to 0 so that Actuator 1 is disabled
                app.WallDisplacementmmEditField.Editable = 0;
                app.PauseatthepeaksEditField.Editable = 0;
                app.DelayBetweenKickssEditField.Editable = 0;
                %
                % Turn on the Actuator 2
                app.NoofKicksEditField_3.Editable = 1;
                app.WallDisplacementmmEditField_2.Editable = 1;
                app.PauseatthepeaksEditField_2.Editable = 1;
                app.DelayBetweenKickssEditField_2.Editable = 1;
                %
            elseif ((start_with_actuator_value == '1') & (app.KickModeDropDown.Value == 'Dual: Simulteneous'))
                app.NoofKicksEditField_2.Editable = 1; % No. of kick in Actuator1 becomes editable
                app.NoofKicksEditField_3.Editable = 0;
                app.NoofKicksEditField_3.Value = 0;
                %
            elseif ((start_with_actuator_value == '2') & (app.KickModeDropDown.Value == 'Dual: Simulteneous'))
                app.NoofKicksEditField_2.Editable = 0;
                app.NoofKicksEditField_2.Value = 0;
                app.NoofKicksEditField_3.Editable = 1; % No. of kick in Actuator2 becomes editable
            end
        end

        % Value changed function: ActuatorTipDropDown, 
        % WallGapCorrectionmmEditField
        function ActuatorTipDropDownValueChanged(app, event)
            global gap_between_act_wall full_load_speed
            
            if app.ActuatorTipDropDown.Value == 'Hemispherical'
                gap_between_act_wall = 28 + app.WallGapCorrectionmmEditField.Value; % mm
                full_load_speed = 11.3; % mm/s
            else
                gap_between_act_wall = 24.5 + app.WallGapCorrectionmmEditField.Value; % mm
                full_load_speed = 12.08; % mm/s
            end
        end

        % Button pushed function: SaveDataButton
        function SaveDataButtonPushed(app, event)
            global SensorData SamplingTiming F_Sensor1_max F_Sensor2_max
            %
            CombinedData = [SensorData SamplingTiming]; % Combining the sensor data and the corresponding sampling time
            %
            % Saving the sensor data
            try
                file_list = ls('Sensor_Data');
                file_Name = file_list (end, end-6:end-4);
            catch
                fopen('Sensor_Data\SensorData_000.txt','w');
                fclose('all');
                file_list = ls('Sensor_Data');
                file_Name = file_list (end, end-6:end-4);
            end
            file_Name = str2double(file_Name)+1;
            file_Name_sensor = sprintf('SensorData_%03d.txt', file_Name);
            file_Name_sensor = strcat('C:\Users\akg18\Box Sync\My Documents\Academic- PhD_Imperial\Research Work\My Work\Test_Bed\Codes\Kick_Simulator\Sensor_Data\',file_Name_sensor);
            save (file_Name_sensor,'CombinedData', '-ascii');
            %
            % Saving kick profile data
            kick_profile_data = {'Actuator tip',app.ActuatorTipDropDown.Value; 'Kick mode',app.KickModeDropDown.Value;...
                'Start with Actuator',app.StartwithActuatorDropDown.Value;'Delay between actuators',app.DelayBetweenActuatorssEditField.Value;...
                'Act1: No. of Kicks',app.NoofKicksEditField_2.Value; 'Act1: Wall displacement',app.WallDisplacementmmEditField.Value;...
                'Act1: Pause at the peak',app.PauseatthepeaksEditField.Value;'Act1: Delay between kicks',app.DelayBetweenKickssEditField.Value;...
                'Act2: No. of Kicks',app.NoofKicksEditField_3.Value; 'Act2: Wall displacement',app.WallDisplacementmmEditField_2.Value;...
                'Act2: Pause at the peak',app.PauseatthepeaksEditField_2.Value;'Act2: Delay between kicks',app.DelayBetweenKickssEditField_2.Value;...
                'Data Sampling rate (KHz)',app.DataSamplingrateKHzEditField.Value;'Act1: Kick duration',app.Actuator1sEditField.Value;...
                'Act2: Kick duration',app.Actuator2sEditField.Value;'Total sampling period (s)',app.SamplingPeriodsEditField.Value;...
                'Maximum force in actuator1', app.Actuator1NEditField.Value; 'Maximum force in actuator2', app.Actuator2NEditField.Value};
            %
            T = table(kick_profile_data);
            file_name_kick_profile = sprintf('KickProfile_%03d.txt', file_Name);
            cd 'C:\Users\akg18\Box Sync\My Documents\Academic- PhD_Imperial\Research Work\My Work\Test_Bed\Codes\Kick_Simulator\Sensor_Data'
            writetable(T,file_name_kick_profile); % Writing in the result.xlsx
            %
            cd 'C:\Users\akg18\Box Sync\My Documents\Academic- PhD_Imperial\Research Work\My Work\Test_Bed\Codes\Kick_Simulator' % Needed to go back at the end of saving
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 869 650];
            app.UIFigure.Name = 'UI Figure';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create KickDesignLabel
            app.KickDesignLabel = uilabel(app.UIFigure);
            app.KickDesignLabel.HorizontalAlignment = 'center';
            app.KickDesignLabel.FontSize = 17;
            app.KickDesignLabel.FontWeight = 'bold';
            app.KickDesignLabel.Position = [14 619 103 22];
            app.KickDesignLabel.Text = 'Kick Design';

            % Create Actuator1Label
            app.Actuator1Label = uilabel(app.UIFigure);
            app.Actuator1Label.FontWeight = 'bold';
            app.Actuator1Label.Position = [24 482 65 22];
            app.Actuator1Label.Text = 'Actuator 1';

            % Create Actuator2Label
            app.Actuator2Label = uilabel(app.UIFigure);
            app.Actuator2Label.FontWeight = 'bold';
            app.Actuator2Label.Position = [24 372 65 22];
            app.Actuator2Label.Text = 'Actuator 2';

            % Create WallDisplacementmmLabel
            app.WallDisplacementmmLabel = uilabel(app.UIFigure);
            app.WallDisplacementmmLabel.HorizontalAlignment = 'center';
            app.WallDisplacementmmLabel.Position = [50 444 136 22];
            app.WallDisplacementmmLabel.Text = 'Wall Displacement (mm)';

            % Create WallDisplacementmmEditField
            app.WallDisplacementmmEditField = uieditfield(app.UIFigure, 'numeric');
            app.WallDisplacementmmEditField.Position = [193 443 36 22];

            % Create Actuator1sEditFieldLabel
            app.Actuator1sEditFieldLabel = uilabel(app.UIFigure);
            app.Actuator1sEditFieldLabel.HorizontalAlignment = 'center';
            app.Actuator1sEditFieldLabel.Position = [92 119 78 22];
            app.Actuator1sEditFieldLabel.Text = 'Actuator 1 (s)';

            % Create Actuator1sEditField
            app.Actuator1sEditField = uieditfield(app.UIFigure, 'numeric');
            app.Actuator1sEditField.Editable = 'off';
            app.Actuator1sEditField.Position = [183 119 46 22];

            % Create PauseatthepeaksEditFieldLabel
            app.PauseatthepeaksEditFieldLabel = uilabel(app.UIFigure);
            app.PauseatthepeaksEditFieldLabel.HorizontalAlignment = 'right';
            app.PauseatthepeaksEditFieldLabel.Position = [65 423 120 22];
            app.PauseatthepeaksEditFieldLabel.Text = 'Pause at the peak (s)';

            % Create PauseatthepeaksEditField
            app.PauseatthepeaksEditField = uieditfield(app.UIFigure, 'numeric');
            app.PauseatthepeaksEditField.Position = [193 423 36 22];

            % Create WallDisplacementmmLabel_2
            app.WallDisplacementmmLabel_2 = uilabel(app.UIFigure);
            app.WallDisplacementmmLabel_2.HorizontalAlignment = 'center';
            app.WallDisplacementmmLabel_2.Position = [48 323 136 22];
            app.WallDisplacementmmLabel_2.Text = 'Wall Displacement (mm)';

            % Create WallDisplacementmmEditField_2
            app.WallDisplacementmmEditField_2 = uieditfield(app.UIFigure, 'numeric');
            app.WallDisplacementmmEditField_2.Editable = 'off';
            app.WallDisplacementmmEditField_2.Position = [191 324 36 22];

            % Create Actuator2sEditFieldLabel
            app.Actuator2sEditFieldLabel = uilabel(app.UIFigure);
            app.Actuator2sEditFieldLabel.HorizontalAlignment = 'center';
            app.Actuator2sEditFieldLabel.Position = [92 98 78 22];
            app.Actuator2sEditFieldLabel.Text = 'Actuator 2 (s)';

            % Create Actuator2sEditField
            app.Actuator2sEditField = uieditfield(app.UIFigure, 'numeric');
            app.Actuator2sEditField.Editable = 'off';
            app.Actuator2sEditField.Position = [183 98 46 22];

            % Create PauseatthepeaksEditField_2Label
            app.PauseatthepeaksEditField_2Label = uilabel(app.UIFigure);
            app.PauseatthepeaksEditField_2Label.HorizontalAlignment = 'right';
            app.PauseatthepeaksEditField_2Label.Position = [60 303 120 22];
            app.PauseatthepeaksEditField_2Label.Text = 'Pause at the peak (s)';

            % Create PauseatthepeaksEditField_2
            app.PauseatthepeaksEditField_2 = uieditfield(app.UIFigure, 'numeric');
            app.PauseatthepeaksEditField_2.Editable = 'off';
            app.PauseatthepeaksEditField_2.Position = [191 303 36 22];

            % Create StartwithActuatorLabel
            app.StartwithActuatorLabel = uilabel(app.UIFigure);
            app.StartwithActuatorLabel.HorizontalAlignment = 'center';
            app.StartwithActuatorLabel.Position = [79 537 107 28];
            app.StartwithActuatorLabel.Text = 'Start with: Actuator';

            % Create StartwithActuatorDropDown
            app.StartwithActuatorDropDown = uidropdown(app.UIFigure);
            app.StartwithActuatorDropDown.Items = {'1', '2'};
            app.StartwithActuatorDropDown.ValueChangedFcn = createCallbackFcn(app, @StartwithActuatorDropDownValueChanged, true);
            app.StartwithActuatorDropDown.Position = [192 540 36 22];
            app.StartwithActuatorDropDown.Value = '1';

            % Create NoofKicksEditField_2Label
            app.NoofKicksEditField_2Label = uilabel(app.UIFigure);
            app.NoofKicksEditField_2Label.HorizontalAlignment = 'center';
            app.NoofKicksEditField_2Label.Position = [116 464 70 22];
            app.NoofKicksEditField_2Label.Text = 'No. of Kicks';

            % Create NoofKicksEditField_2
            app.NoofKicksEditField_2 = uieditfield(app.UIFigure, 'numeric');
            app.NoofKicksEditField_2.Position = [193 464 36 22];

            % Create NoofKicksEditField_3Label
            app.NoofKicksEditField_3Label = uilabel(app.UIFigure);
            app.NoofKicksEditField_3Label.HorizontalAlignment = 'right';
            app.NoofKicksEditField_3Label.Position = [97 344 70 22];
            app.NoofKicksEditField_3Label.Text = 'No. of Kicks';

            % Create NoofKicksEditField_3
            app.NoofKicksEditField_3 = uieditfield(app.UIFigure, 'numeric');
            app.NoofKicksEditField_3.Editable = 'off';
            app.NoofKicksEditField_3.Position = [191 344 36 22];

            % Create DelayBetweenKickssLabel
            app.DelayBetweenKickssLabel = uilabel(app.UIFigure);
            app.DelayBetweenKickssLabel.HorizontalAlignment = 'center';
            app.DelayBetweenKickssLabel.Position = [49 402 136 22];
            app.DelayBetweenKickssLabel.Text = 'Delay Between Kicks (s)';

            % Create DelayBetweenKickssEditField
            app.DelayBetweenKickssEditField = uieditfield(app.UIFigure, 'numeric');
            app.DelayBetweenKickssEditField.Position = [193 402 36 22];

            % Create FetalKickSimulatorLabel
            app.FetalKickSimulatorLabel = uilabel(app.UIFigure);
            app.FetalKickSimulatorLabel.HorizontalAlignment = 'center';
            app.FetalKickSimulatorLabel.FontSize = 20;
            app.FetalKickSimulatorLabel.FontWeight = 'bold';
            app.FetalKickSimulatorLabel.Position = [455 617 199 24];
            app.FetalKickSimulatorLabel.Text = 'Fetal Kick Simulator';

            % Create KickingActionLabel
            app.KickingActionLabel = uilabel(app.UIFigure);
            app.KickingActionLabel.HorizontalAlignment = 'center';
            app.KickingActionLabel.FontSize = 17;
            app.KickingActionLabel.FontWeight = 'bold';
            app.KickingActionLabel.Position = [492 578 125 22];
            app.KickingActionLabel.Text = 'Kicking Action';

            % Create StartKickingButton
            app.StartKickingButton = uibutton(app.UIFigure, 'push');
            app.StartKickingButton.ButtonPushedFcn = createCallbackFcn(app, @StartKickingButtonPushed, true);
            app.StartKickingButton.FontWeight = 'bold';
            app.StartKickingButton.FontColor = [1 0.0745 0.651];
            app.StartKickingButton.Position = [492 527 137 36];
            app.StartKickingButton.Text = 'Start Kicking';

            % Create DelayBetweenActuatorssLabel
            app.DelayBetweenActuatorssLabel = uilabel(app.UIFigure);
            app.DelayBetweenActuatorssLabel.HorizontalAlignment = 'center';
            app.DelayBetweenActuatorssLabel.Position = [94 509 90 28];
            app.DelayBetweenActuatorssLabel.Text = {'Delay Between '; 'Actuators (s)'};

            % Create DelayBetweenActuatorssEditField
            app.DelayBetweenActuatorssEditField = uieditfield(app.UIFigure, 'numeric');
            app.DelayBetweenActuatorssEditField.Editable = 'off';
            app.DelayBetweenActuatorssEditField.Position = [192 515 36 22];

            % Create FeedbackLabel
            app.FeedbackLabel = uilabel(app.UIFigure);
            app.FeedbackLabel.HorizontalAlignment = 'center';
            app.FeedbackLabel.FontSize = 17;
            app.FeedbackLabel.FontWeight = 'bold';
            app.FeedbackLabel.Position = [14 159 84 22];
            app.FeedbackLabel.Text = 'Feedback';

            % Create DelayBetweenKickssLabel_2
            app.DelayBetweenKickssLabel_2 = uilabel(app.UIFigure);
            app.DelayBetweenKickssLabel_2.HorizontalAlignment = 'center';
            app.DelayBetweenKickssLabel_2.Position = [47 282 136 22];
            app.DelayBetweenKickssLabel_2.Text = 'Delay Between Kicks (s)';

            % Create DelayBetweenKickssEditField_2
            app.DelayBetweenKickssEditField_2 = uieditfield(app.UIFigure, 'numeric');
            app.DelayBetweenKickssEditField_2.Editable = 'off';
            app.DelayBetweenKickssEditField_2.Position = [191 282 36 22];

            % Create KickDurationLabel
            app.KickDurationLabel = uilabel(app.UIFigure);
            app.KickDurationLabel.FontWeight = 'bold';
            app.KickDurationLabel.Position = [24 138 84 22];
            app.KickDurationLabel.Text = 'Kick Duration';

            % Create StatusEditFieldLabel
            app.StatusEditFieldLabel = uilabel(app.UIFigure);
            app.StatusEditFieldLabel.HorizontalAlignment = 'right';
            app.StatusEditFieldLabel.Position = [255 56 36 22];
            app.StatusEditFieldLabel.Text = 'Status';

            % Create StatusEditField
            app.StatusEditField = uieditfield(app.UIFigure, 'text');
            app.StatusEditField.Editable = 'off';
            app.StatusEditField.FontWeight = 'bold';
            app.StatusEditField.FontColor = [1 0 0];
            app.StatusEditField.Position = [312 50 512 30];

            % Create KickModeDropDownLabel
            app.KickModeDropDownLabel = uilabel(app.UIFigure);
            app.KickModeDropDownLabel.HorizontalAlignment = 'center';
            app.KickModeDropDownLabel.FontWeight = 'bold';
            app.KickModeDropDownLabel.Position = [24 562 66 28];
            app.KickModeDropDownLabel.Text = 'Kick Mode';

            % Create KickModeDropDown
            app.KickModeDropDown = uidropdown(app.UIFigure);
            app.KickModeDropDown.Items = {'            Single', 'Dual: Simulteneous', 'Dual: Consequitive', '      Dual: Random'};
            app.KickModeDropDown.ValueChangedFcn = createCallbackFcn(app, @KickModeDropDownValueChanged, true);
            app.KickModeDropDown.Position = [99 565 129 22];
            app.KickModeDropDown.Value = '            Single';

            % Create WarningEditFieldLabel
            app.WarningEditFieldLabel = uilabel(app.UIFigure);
            app.WarningEditFieldLabel.HorizontalAlignment = 'right';
            app.WarningEditFieldLabel.Position = [255 22 46 22];
            app.WarningEditFieldLabel.Text = 'Warning';

            % Create WarningEditField
            app.WarningEditField = uieditfield(app.UIFigure, 'text');
            app.WarningEditField.Editable = 'off';
            app.WarningEditField.FontWeight = 'bold';
            app.WarningEditField.FontColor = [1 0 0];
            app.WarningEditField.Position = [312 16 512 30];

            % Create ConnecttheArduinoButton
            app.ConnecttheArduinoButton = uibutton(app.UIFigure, 'push');
            app.ConnecttheArduinoButton.ButtonPushedFcn = createCallbackFcn(app, @ConnecttheArduinoButtonPushed, true);
            app.ConnecttheArduinoButton.FontWeight = 'bold';
            app.ConnecttheArduinoButton.FontColor = [0.4706 0.6706 0.1882];
            app.ConnecttheArduinoButton.Position = [332 527 137 36];
            app.ConnecttheArduinoButton.Text = 'Connect the Arduino';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'Force applied by the actuators')
            xlabel(app.UIAxes, 'Time (s)')
            ylabel(app.UIAxes, 'Sensor response (V)')
            app.UIAxes.XGrid = 'on';
            app.UIAxes.YGrid = 'on';
            app.UIAxes.Position = [276 307 559 209];

            % Create SamplingPeriodsEditFieldLabel
            app.SamplingPeriodsEditFieldLabel = uilabel(app.UIFigure);
            app.SamplingPeriodsEditFieldLabel.HorizontalAlignment = 'center';
            app.SamplingPeriodsEditFieldLabel.FontWeight = 'bold';
            app.SamplingPeriodsEditFieldLabel.Position = [24 13 118 22];
            app.SamplingPeriodsEditFieldLabel.Text = 'Sampling Period (s)';

            % Create SamplingPeriodsEditField
            app.SamplingPeriodsEditField = uieditfield(app.UIFigure, 'numeric');
            app.SamplingPeriodsEditField.Editable = 'off';
            app.SamplingPeriodsEditField.Position = [183 11 46 22];

            % Create UIAxes_2
            app.UIAxes_2 = uiaxes(app.UIFigure);
            title(app.UIAxes_2, 'Response from the sensors')
            xlabel(app.UIAxes_2, 'Time (s)')
            ylabel(app.UIAxes_2, 'Sensor response (V)')
            app.UIAxes_2.XGrid = 'on';
            app.UIAxes_2.YGrid = 'on';
            app.UIAxes_2.Position = [273 94 559 207];

            % Create DaqSettingLabel
            app.DaqSettingLabel = uilabel(app.UIFigure);
            app.DaqSettingLabel.FontSize = 17;
            app.DaqSettingLabel.FontWeight = 'bold';
            app.DaqSettingLabel.Position = [14 217 100 22];
            app.DaqSettingLabel.Text = 'Daq Setting';

            % Create DataSamplingrateKHzEditFieldLabel
            app.DataSamplingrateKHzEditFieldLabel = uilabel(app.UIFigure);
            app.DataSamplingrateKHzEditFieldLabel.HorizontalAlignment = 'center';
            app.DataSamplingrateKHzEditFieldLabel.Position = [43 192 142 22];
            app.DataSamplingrateKHzEditFieldLabel.Text = 'Data Sampling rate (KHz)';

            % Create DataSamplingrateKHzEditField
            app.DataSamplingrateKHzEditField = uieditfield(app.UIFigure, 'numeric');
            app.DataSamplingrateKHzEditField.Position = [192 192 37 22];
            app.DataSamplingrateKHzEditField.Value = 1;

            % Create ActuatorTipDropDownLabel
            app.ActuatorTipDropDownLabel = uilabel(app.UIFigure);
            app.ActuatorTipDropDownLabel.HorizontalAlignment = 'right';
            app.ActuatorTipDropDownLabel.FontWeight = 'bold';
            app.ActuatorTipDropDownLabel.Position = [24 591 74 22];
            app.ActuatorTipDropDownLabel.Text = 'Actuator Tip';

            % Create ActuatorTipDropDown
            app.ActuatorTipDropDown = uidropdown(app.UIFigure);
            app.ActuatorTipDropDown.Items = {'  Cylindrical', 'Hemispherical'};
            app.ActuatorTipDropDown.ValueChangedFcn = createCallbackFcn(app, @ActuatorTipDropDownValueChanged, true);
            app.ActuatorTipDropDown.Position = [127 591 100 22];
            app.ActuatorTipDropDown.Value = '  Cylindrical';

            % Create SaveDataButton
            app.SaveDataButton = uibutton(app.UIFigure, 'push');
            app.SaveDataButton.ButtonPushedFcn = createCallbackFcn(app, @SaveDataButtonPushed, true);
            app.SaveDataButton.FontWeight = 'bold';
            app.SaveDataButton.FontColor = [1 0 0];
            app.SaveDataButton.Position = [650 527 137 36];
            app.SaveDataButton.Text = 'Save Data';

            % Create MaximumForceLabel
            app.MaximumForceLabel = uilabel(app.UIFigure);
            app.MaximumForceLabel.FontWeight = 'bold';
            app.MaximumForceLabel.Position = [24 75 97 22];
            app.MaximumForceLabel.Text = 'Maximum Force';

            % Create Actuator1NEditFieldLabel
            app.Actuator1NEditFieldLabel = uilabel(app.UIFigure);
            app.Actuator1NEditFieldLabel.HorizontalAlignment = 'center';
            app.Actuator1NEditFieldLabel.Position = [91 58 80 22];
            app.Actuator1NEditFieldLabel.Text = 'Actuator 1 (N)';

            % Create Actuator1NEditField
            app.Actuator1NEditField = uieditfield(app.UIFigure, 'numeric');
            app.Actuator1NEditField.Editable = 'off';
            app.Actuator1NEditField.Position = [183 58 46 22];

            % Create Actuator2NEditFieldLabel
            app.Actuator2NEditFieldLabel = uilabel(app.UIFigure);
            app.Actuator2NEditFieldLabel.HorizontalAlignment = 'center';
            app.Actuator2NEditFieldLabel.Position = [91 37 80 22];
            app.Actuator2NEditFieldLabel.Text = 'Actuator 2 (N)';

            % Create Actuator2NEditField
            app.Actuator2NEditField = uieditfield(app.UIFigure, 'numeric');
            app.Actuator2NEditField.Editable = 'off';
            app.Actuator2NEditField.Position = [183 37 46 22];

            % Create WallGapCorrectionmmEditFieldLabel
            app.WallGapCorrectionmmEditFieldLabel = uilabel(app.UIFigure);
            app.WallGapCorrectionmmEditFieldLabel.HorizontalAlignment = 'center';
            app.WallGapCorrectionmmEditFieldLabel.FontWeight = 'bold';
            app.WallGapCorrectionmmEditFieldLabel.Position = [24 249 153 22];
            app.WallGapCorrectionmmEditFieldLabel.Text = 'Wall Gap Correction (mm)';

            % Create WallGapCorrectionmmEditField
            app.WallGapCorrectionmmEditField = uieditfield(app.UIFigure, 'numeric');
            app.WallGapCorrectionmmEditField.ValueChangedFcn = createCallbackFcn(app, @ActuatorTipDropDownValueChanged, true);
            app.WallGapCorrectionmmEditField.Position = [191 249 36 22];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Kick_Simulator_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end