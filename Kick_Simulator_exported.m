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
        PauseatthepicksLabel           matlab.ui.control.Label
        PauseatthepicksEditField       matlab.ui.control.NumericEditField
        WallDisplacementmmLabel_2      matlab.ui.control.Label
        WallDisplacementmmEditField_2  matlab.ui.control.NumericEditField
        Actuator2sEditFieldLabel       matlab.ui.control.Label
        Actuator2sEditField            matlab.ui.control.NumericEditField
        PauseatthepicksLabel_2         matlab.ui.control.Label
        PauseatthepicksEditField_2     matlab.ui.control.NumericEditField
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
        TotalSamplingPeriodsEditFieldLabel  matlab.ui.control.Label
        TotalSamplingPeriodsEditField  matlab.ui.control.NumericEditField
    end

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
            global a1 a2 act1 act2 gap_between_act_wall no_load_speed full_load_speed m_act1 m_act2 check_if_kicking_on check_if_arduino_connected ...
                sensor1 sensor2 data_number
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
                % Updating the status check variable for the kicking
                check_if_kicking_on = 1; % It indicates some kicking i going on. This variable will be cleared at the end of kicking
                %
                %xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
                %
                % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Calculation of parameters by reading the user input ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                %
                tot_disp1 = app.WallDisplacementmmEditField.Value + gap_between_act_wall; % total displacement for actuator1
                tot_disp2 = app.WallDisplacementmmEditField_2.Value + gap_between_act_wall; % total displacement for actuator2
                pos1 = tot_disp1/m_act1; % position variable for actuator1
                pos2 = tot_disp2/m_act2; % position variable for actuator2
                delay_time1 = gap_between_act_wall/no_load_speed + app.WallDisplacementmmEditField.Value/full_load_speed...
                    + app.PauseatthepicksEditField.Value; % delay time for actuator1 in sec
                delay_time2 = gap_between_act_wall/no_load_speed + app.WallDisplacementmmEditField_2.Value/full_load_speed...
                    + app.PauseatthepicksEditField_2.Value; % delay time for actuator2 in sec
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
                % Check for the position variable
                if (pos1 > 1 || pos2 > 1)
                    app.WarningEditField.Value = 'Maximum allowed wall displacement: actuator1 = 36 mm, actuator2 = 38 mm.';
                    beep;
                    return % This will end the executin of this function
                end
                %
                %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Defining a timer for force data acquisition ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                %****************************************************************************************************************************************
                %
                ti = timer; % Define a timer object
                ti.TimerFcn =@my_timer_func;
                ti.ExecutionMode = 'fixedRate';
                ti.period = 0.1; % Setting a frequency of 25 Hz
                data_number = 1; % initialing the variable to keep track of the data recording
                %
                % Defining the settings for the real time plot
                plot(app.UIAxes,0,0); % Refreshing the plot to remove the previous data                
                h1 = animatedline (app.UIAxes, 'Color', 'b', 'DisplayName', 'Sensor1');                
                h2 = animatedline (app.UIAxes, 'DisplayName', 'Sensor2');
                legend ([h1 h2],'Location','southwest', 'Box','off');
                %
                tic
                start(ti);
                %
                % XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                %
                %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Actuating the kicks ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                %****************************************************************************************************************************************
                %
                app.StatusEditField.Value = 'Kicking is going on...';
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
                            pause(delay_time1); % Allows the actuator to return to minimum position
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
                            pause(delay_time2); % Allows the actuator to reach the minimum position
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
                    app.Actuator1sEditField.Value = 2 * (delay_time1 - gap_between_act_wall/no_load_speed) - app.PauseatthepicksEditField.Value;
                    app.Actuator2sEditField.Value = 2 * (delay_time2 - gap_between_act_wall/no_load_speed) - app.PauseatthepicksEditField_2.Value;
                    %
                    % XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                    %
                    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Kick Mode = Dual: Simulteneous ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    %
                elseif (app.KickModeDropDown.Value == 'Dual: Simulteneous')
                    %
                    if (kick_count_act1 ~= kick_count_act2) % This condition has to be met for this mode
                        app.WarningEditField.Value = 'Wrong input: In this mode, no. of kicks in actuator1 and actuator2 needs to be equal.';
                        beep;
                    else
                        while(kick_count_act1 > 0) % Since the no. of kicks in both actuators are same, any one of them can be used
                            writePosition(act1,pos1);
                            writePosition(act2,pos2);
                            %
                            if (delay_time1 < delay_time2) % If the delay required for actuator1 is less than actuator2
                                pause(delay_time1); % Pause for lower delay
                                writePosition(act1,0); % Write the return position to actuator1
                                pause(delay_time2 - delay_time1); % Pause for the rest of the delay
                                writePosition(act2,0); % Write the return position to actuator2
                                pause (delay_time2); % Pause for the higher delay, so that next cycle starts together
                                %
                            else % delay_time1 > delay_time_2
                                pause(delay_time2);
                                writePosition(act2,0);
                                pause(delay_time1 - delay_time2);
                                writePosition(act1,0);
                                pause (delay_time1);
                            end
                            %
                            kick_count_act1 = kick_count_act1 - 1;
                        end
                        %
                        % Display the kick durations
                        app.Actuator1sEditField.Value = 2 * (delay_time1 - gap_between_act_wall/no_load_speed) - app.PauseatthepicksEditField.Value;
                        app.Actuator2sEditField.Value = 2 * (delay_time2 - gap_between_act_wall/no_load_speed) - app.PauseatthepicksEditField_2.Value;
                        %
                        % Warning for non-zero delay between kicks or actuators
                        %                         if(app.DelayBetweenKickssEditField.Value ~= 0 || app.DelayBetweenKickssEditField_2.Value ~= 0)
                        %                             app.WarningEditField.Value = '"Delay Between Kicks" is not used in this mode.';
                        %                             beep;
                        %                         end
                        %
                    end
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
                                pause(delay_time1); % Allows the actuator to return to minimum position
                                %
                                kick_count_act1 = kick_count_act1 - 1; % reduce the kick counting variable
                                %
                            end
                            %
                            if (kick_count_act2 > 0)
                                writePosition(act2,pos2);
                                pause(delay_time2); % Allows the actuator to reach the maximum position
                                writePosition(act2, 0);
                                pause(delay_time2); % Allows the actuator to reach the minimum position
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
                                pause(delay_time2); % Allows the actuator to reach the minimum position
                                %
                                kick_count_act2 = kick_count_act2 - 1;
                            end
                            if (kick_count_act1 > 0)
                                writePosition(act1,pos1);
                                pause(delay_time1); % Allows the actuator to reach the maximum position
                                writePosition(act1,0);
                                pause(delay_time1); % Allows the actuator to return to minimum position
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
                    app.Actuator1sEditField.Value = 2 * (delay_time1 - gap_between_act_wall/no_load_speed) - app.PauseatthepicksEditField.Value;
                    app.Actuator2sEditField.Value = 2 * (delay_time2 - gap_between_act_wall/no_load_speed) - app.PauseatthepicksEditField_2.Value;
                    %
                    % % Warning for non-zero delay between kicks or actuators
                    %                     if(app.DelayBetweenKickssEditField.Value ~= 0 || app.DelayBetweenKickssEditField_2 ~=0)
                    %                         app.WarningEditField.Value = '"Delay Between Kicks" is not used in this mode.';
                    %                         beep;
                    %                     end
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
                                            pause(max(delay_time2,(delay_time1-(delay_time2 - (delay_time1 - app.DelayBetweenActuatorssEditField.Value)))));
                                        else
                                            pause(delay_time2);
                                            writePosition(act2,0);
                                            pause(delay_time1 - (app.DelayBetweenActuatorssEditField.Value + delay_time2));
                                            writePosition(act1,0);
                                            pause(max(delay_time1,(delay_time2 - (delay_time1 - (app.DelayBetweenActuatorssEditField.Value + delay_time2)))));
                                        end
                                        %
                                    else % If the delay for actuator1 is smaller, that delay will be made first
                                        pause(delay_time1);
                                        writePosition(act1,0); % After the delay, the actuator1 will start to return to the origin
                                        pause(app.DelayBetweenActuatorssEditField.Value - delay_time1); % Rest of the delay before starting the actuator2
                                        writePosition(act2,pos2); % Starting the actuator2
                                        %
                                        %%%%%%%%%%%%%%%%%%% Rechek the below code
                                        if (delay_time1 <= (app.DelayBetweenActuatorssEditField.Value - delay_time1)) % Actuator1 has already returned to origin
                                            pause(delay_time2);
                                            writePosition(act2,0); % Actuator2 start returning
                                            pause(delay_time2);
                                        else
                                            if ((delay_time1 - (app.DelayBetweenActuatorssEditField.Value - delay_time1)) <= delay_time2)
                                                pause(delay_time2); % Actuator1 will return to origin by this time
                                                writePosition(act2,0); % Actuator2 start returning
                                                pause(delay_time2);
                                            else
                                                pause(delay_time2);
                                                writePosition(act2,0); % Actuator2 start returning
                                                pause(max(delay_time2,(delay_time1 - ((app.DelayBetweenActuatorssEditField.Value - delay_time1) + delay_time2))));
                                                % (app.DelayBetweenActuatorssEditField.Value - delay_time1) + delay_time2 = time already spent
                                                % after starting the return journey of actuator1
                                            end
                                        end
                                        %%%%%%%%%%%%%%%%%%%%%%%%
                                    end
                                    %
                                else % Actuator1 is not kicking
                                    writePosition(act2,pos2);
                                    pause(delay_time2);
                                    writePosition(act2,0);
                                    pause(delay_time2);
                                end
                                %
                            else % If actuator2 is not kicking
                                if (act1_kick == 1) % If the actuator1 is kicking; probably, this condition is always gonna be true when actuator2 is not kicking
                                    pause(delay_time1);
                                    writePosition(act1,0);
                                    pause(delay_time1);
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
                                            pause(max(delay_time1,(delay_time2-(delay_time1 - (delay_time2 - app.DelayBetweenActuatorssEditField.Value)))));
                                        else
                                            pause(delay_time1);
                                            writePosition(act1,0);
                                            pause(delay_time2 - (app.DelayBetweenActuatorssEditField.Value + delay_time1));
                                            writePosition(act2,0);
                                            pause(max(delay_time2,(delay_time1 - (delay_time2 - (app.DelayBetweenActuatorssEditField.Value + delay_time1)))));
                                        end
                                        %
                                    else % If the delay for actuator2 is smaller, that delay will be made first
                                        pause(delay_time2);
                                        writePosition(act2,0); % After the delay, the actuator2 will start to return to the origin
                                        pause(app.DelayBetweenActuatorssEditField.Value - delay_time2); % Rest of the delay before starting the actuator1
                                        writePosition(act1,pos1); % Starting the actuator1
                                        %
                                        %%%%%%%%%%%%%%%%%%% Rechek the below code
                                        if (delay_time2 <= (app.DelayBetweenActuatorssEditField.Value - delay_time2)) % Actuator2 has already returned to origin
                                            pause(delay_time1);
                                            writePosition(act1,0); % Actuator1 start returning
                                            pause(delay_time1);
                                        else % Actuator2 has not reached to origin yet
                                            if ((delay_time2 - (app.DelayBetweenActuatorssEditField.Value - delay_time2)) <= delay_time1)
                                                pause(delay_time1); % Actuator2 will return to origin before the end of this time
                                                writePosition(act1,0); % Actuator1 start returning
                                                pause(delay_time1);
                                            else
                                                pause(delay_time1); % Actuator2 will not return to origin by the end of this time
                                                writePosition(act1,0); % Actuator1 start returning
                                                pause(max(delay_time1,(delay_time2 - ((app.DelayBetweenActuatorssEditField.Value - delay_time2) + delay_time1))));
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
                                    pause(delay_time1);
                                end
                                %
                            else % If actuator1 is not kicking
                                if (act2_kick == 1) % If the actuator2 is kicking;
                                    % probably, this condition is always gonna be true when actuator1 is not kicking
                                    pause(delay_time2);
                                    writePosition(act2,0);
                                    pause(delay_time2);
                                end
                            end
                            %
                            max_kick_count = max_kick_count - 1;
                            %
                        end
                    end
                    %
                    % Display the kick durations
                    app.Actuator1sEditField.Value = 2 * (delay_time1 - gap_between_act_wall/no_load_speed) - app.PauseatthepicksEditField.Value;
                    app.Actuator2sEditField.Value = 2 * (delay_time2 - gap_between_act_wall/no_load_speed) - app.PauseatthepicksEditField_2.Value;
                    %
                    %                     %
                    %                     if(app.DelayBetweenKickssEditField.Value ~= 0 || app.DelayBetweenKickssEditField_2.Value ~= 0)
                    %                         app.WarningEditField.Value = '"Delay Between Kicks" is not used in this mode.';
                    %                         beep;
                    %                     end
                    %
                end
                %
                % XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                %
                % Change of status at the end of kicking
                app.StatusEditField.Value = 'Kicking has finished.';
                beep;
                %
                % Updating the status check variable for the kicking
                check_if_kicking_on = 0; % Required for the next button press
                %
                % Stopping the timer
                %
                stop (ti);
                Total_Sampling_period = toc;
                app.TotalSamplingPeriodsEditField.Value = Total_Sampling_period; % Upadting the total sampling period field
                %
                % Plotting the force vs time graph
                %                 timeAxis1 = (linspace(0,Total_Sampling_period,length(sensor1)))';
                %                 timeAxis2 = (linspace(0,Total_Sampling_period,length(sensor2)))';
                %                 plot(app.UIAxes,timeAxis1,sensor1,timeAxis2,sensor2);
                %
                %
            catch
                app.StatusEditField.Value = 'Connection is lost. Try to reconnect';
                app.WarningEditField.Value = '';
                %
                clear all;
            end
            %
            function my_timer_func(~,~)
                %
                % Reading the analog voltages from the arduino pins
                sensor1(data_number)= readVoltage(a2,'A1');
                sensor2(data_number) = readVoltage(a2,'A2');
                %
                % Real-time Plotting
                addpoints(h1,toc,sensor1(data_number));
                addpoints(h2,toc,sensor2(data_number));
                drawnow;
                %
                data_number = data_number+1;
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
            pause(1); % So that you can see the above message
            %
            % Decleration of the golbal variables
            global a1 a2 act1 act2 gap_between_act_wall no_load_speed full_load_speed m_act1 m_act2 check_if_kicking_on check_if_arduino_connected
            %
            % Difining the constants
            gap_between_act_wall = 9; % mm
            no_load_speed = 11.72; % mm/s
            full_load_speed = 7.24; % mm/s
            m_act1 = 45.475; % Tangent of the displacement vs position variable curve for actutor 1
            m_act2 = 47.091; % Tangent of the displacement vs position variable curve for actutor 1
            %
            % Declaring some checking variables
            check_if_kicking_on = 0;
            check_if_arduino_connected = 0;
            %
            % Setting up the connection
            try
                a1 = arduino('COM10','Mega2560'); % Creat an arduino object.
                a2 = arduino('COM4','UNO');
                % In case of an already existing connection or no connection, the program will go to catch
                %
                % Connect to the actuators in digital pin 9 and 10. Specs for max and min pulse duration
                % is taken from the datasheet of the actuator
                act1 = servo(a1, 'D3','MinPulseDuration', 1e-3, 'MaxPulseDuration', 2e-3);
                act2 = servo(a1, 'D2','MinPulseDuration', 1e-3, 'MaxPulseDuration', 2e-3);
                %
                % Setting 0 as the initial position
                writePosition(act1, 0);
                writePosition(act2, 0);
                %
                % Updating the status of the connection
                check_if_arduino_connected = 1;
                %
                % Updating the message box
                app.StatusEditField.Value = 'Arduino board is connected successfully.';
                %
            catch % In case of error occures while setting up the connection, the following commands will be executed
                try
                    % Check if the connection is already there
                    isvalid(a1); % Gives error message if a1 is not a arduino object => Program execution goes to catch.
                    isvalid(a2);
                    % In case the above statement generates no error message, arduino connection already exists.
                    app.StatusEditField.Value = 'Connection already exists.';
                    check_if_arduino_connected = 1; % Updating the arduino connection checking variable
                catch
                    app.StatusEditField.Value = 'Connections are not found. Check the USB cable and try again.';
                    clear all; % This line does not clear the base workspace
                    evalin('base','clear all'); % to clear the variables in the base workspace
                    return
                end
            end
            %
            clearvars -except a1 a2 act1 act2 gap_between_act_wall no_load_speed full_load_speed m_act1 m_act2 check_if_kicking_on...
                check_if_arduino_connected sensor1 sensor2 data_number
            % All the other variables except the above mentioned will be cleared. This is necessary as we couldn't use the clear all at the beginning.
        end

        % Value changed function: KickModeDropDown
        function KickModeDropDownValueChanged(app, event)
            if (app.KickModeDropDown.Value == '      Dual: Random')
                %
                app.DelayBetweenActuatorssEditField.Editable = 1; % "Delay between actuator" is available in this mode
                app.DelayBetweenActuatorssEditField.Value = 0; % Initializes the value
                %
                app.DelayBetweenKickssEditField.Editable = 0; % "Delay between kicks" is not available in this mode
                app.DelayBetweenKickssEditField.Value = 0; % Changed back to default value
                app.DelayBetweenKickssEditField_2.Editable = 0;
                app.DelayBetweenKickssEditField_2.Value = 0;
                %
            elseif ((app.KickModeDropDown.Value == '            Single'))
                %
                app.DelayBetweenActuatorssEditField.Editable = 0; % "Delay between actuators" is not available in this mode
                app.DelayBetweenActuatorssEditField.Value = 0; % Changed back to default value
                %
                app.DelayBetweenKickssEditField.Editable = 1; % "Delay between kicks" is available in this mode
                app.DelayBetweenKickssEditField.Value = 0; % Initializes the value
                app.DelayBetweenKickssEditField_2.Editable = 1;
                app.DelayBetweenKickssEditField_2.Value = 0; % Initializes the value
                
                %
            else % In 'Dual: Simulteneous' and 'Dual: Consequitive' mode
                app.DelayBetweenActuatorssEditField.Editable = 0; % "Delay between actuators" is not available in this mode
                app.DelayBetweenActuatorssEditField.Value = 0; % Changed back to default value
                %
                app.DelayBetweenKickssEditField.Editable = 0; % "Delay between kicks" is not available in this mode
                app.DelayBetweenKickssEditField.Value = 0;
                app.DelayBetweenKickssEditField_2.Editable = 0;
                app.DelayBetweenKickssEditField_2.Value = 0;
                %
            end
            %
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure
            app.UIFigure = uifigure;
            app.UIFigure.Position = [100 100 730 690];
            app.UIFigure.Name = 'UI Figure';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create KickDesignLabel
            app.KickDesignLabel = uilabel(app.UIFigure);
            app.KickDesignLabel.HorizontalAlignment = 'center';
            app.KickDesignLabel.FontSize = 17;
            app.KickDesignLabel.FontWeight = 'bold';
            app.KickDesignLabel.Position = [25 600 103 22];
            app.KickDesignLabel.Text = 'Kick Design';

            % Create Actuator1Label
            app.Actuator1Label = uilabel(app.UIFigure);
            app.Actuator1Label.FontWeight = 'bold';
            app.Actuator1Label.Position = [37 463 65 22];
            app.Actuator1Label.Text = 'Actuator 1';

            % Create Actuator2Label
            app.Actuator2Label = uilabel(app.UIFigure);
            app.Actuator2Label.FontWeight = 'bold';
            app.Actuator2Label.Position = [37 329 65 22];
            app.Actuator2Label.Text = 'Actuator 2';

            % Create WallDisplacementmmLabel
            app.WallDisplacementmmLabel = uilabel(app.UIFigure);
            app.WallDisplacementmmLabel.HorizontalAlignment = 'center';
            app.WallDisplacementmmLabel.Position = [55 413 136 22];
            app.WallDisplacementmmLabel.Text = 'Wall Displacement (mm)';

            % Create WallDisplacementmmEditField
            app.WallDisplacementmmEditField = uieditfield(app.UIFigure, 'numeric');
            app.WallDisplacementmmEditField.Position = [198 412 36 22];

            % Create Actuator1sEditFieldLabel
            app.Actuator1sEditFieldLabel = uilabel(app.UIFigure);
            app.Actuator1sEditFieldLabel.HorizontalAlignment = 'center';
            app.Actuator1sEditFieldLabel.Position = [97 145 78 22];
            app.Actuator1sEditFieldLabel.Text = 'Actuator 1 (s)';

            % Create Actuator1sEditField
            app.Actuator1sEditField = uieditfield(app.UIFigure, 'numeric');
            app.Actuator1sEditField.Editable = 'off';
            app.Actuator1sEditField.Position = [188 145 46 22];

            % Create PauseatthepicksLabel
            app.PauseatthepicksLabel = uilabel(app.UIFigure);
            app.PauseatthepicksLabel.HorizontalAlignment = 'right';
            app.PauseatthepicksLabel.Position = [75 386 115 22];
            app.PauseatthepicksLabel.Text = 'Pause at the pick (s)';

            % Create PauseatthepicksEditField
            app.PauseatthepicksEditField = uieditfield(app.UIFigure, 'numeric');
            app.PauseatthepicksEditField.Position = [198 386 36 22];

            % Create WallDisplacementmmLabel_2
            app.WallDisplacementmmLabel_2 = uilabel(app.UIFigure);
            app.WallDisplacementmmLabel_2.HorizontalAlignment = 'center';
            app.WallDisplacementmmLabel_2.Position = [55 277 136 22];
            app.WallDisplacementmmLabel_2.Text = 'Wall Displacement (mm)';

            % Create WallDisplacementmmEditField_2
            app.WallDisplacementmmEditField_2 = uieditfield(app.UIFigure, 'numeric');
            app.WallDisplacementmmEditField_2.Position = [198 278 36 22];

            % Create Actuator2sEditFieldLabel
            app.Actuator2sEditFieldLabel = uilabel(app.UIFigure);
            app.Actuator2sEditFieldLabel.HorizontalAlignment = 'center';
            app.Actuator2sEditFieldLabel.Position = [97 124 78 22];
            app.Actuator2sEditFieldLabel.Text = 'Actuator 2 (s)';

            % Create Actuator2sEditField
            app.Actuator2sEditField = uieditfield(app.UIFigure, 'numeric');
            app.Actuator2sEditField.Editable = 'off';
            app.Actuator2sEditField.Position = [188 124 46 22];

            % Create PauseatthepicksLabel_2
            app.PauseatthepicksLabel_2 = uilabel(app.UIFigure);
            app.PauseatthepicksLabel_2.HorizontalAlignment = 'right';
            app.PauseatthepicksLabel_2.Position = [72 252 115 22];
            app.PauseatthepicksLabel_2.Text = 'Pause at the pick (s)';

            % Create PauseatthepicksEditField_2
            app.PauseatthepicksEditField_2 = uieditfield(app.UIFigure, 'numeric');
            app.PauseatthepicksEditField_2.Position = [198 252 36 22];

            % Create StartwithActuatorLabel
            app.StartwithActuatorLabel = uilabel(app.UIFigure);
            app.StartwithActuatorLabel.HorizontalAlignment = 'center';
            app.StartwithActuatorLabel.Position = [85 524 107 28];
            app.StartwithActuatorLabel.Text = 'Start with: Actuator';

            % Create StartwithActuatorDropDown
            app.StartwithActuatorDropDown = uidropdown(app.UIFigure);
            app.StartwithActuatorDropDown.Items = {'1', '2'};
            app.StartwithActuatorDropDown.Position = [198 527 36 22];
            app.StartwithActuatorDropDown.Value = '1';

            % Create NoofKicksEditField_2Label
            app.NoofKicksEditField_2Label = uilabel(app.UIFigure);
            app.NoofKicksEditField_2Label.HorizontalAlignment = 'center';
            app.NoofKicksEditField_2Label.Position = [118 439 70 22];
            app.NoofKicksEditField_2Label.Text = 'No. of Kicks';

            % Create NoofKicksEditField_2
            app.NoofKicksEditField_2 = uieditfield(app.UIFigure, 'numeric');
            app.NoofKicksEditField_2.Position = [198 439 36 22];

            % Create NoofKicksEditField_3Label
            app.NoofKicksEditField_3Label = uilabel(app.UIFigure);
            app.NoofKicksEditField_3Label.HorizontalAlignment = 'right';
            app.NoofKicksEditField_3Label.Position = [104 304 70 22];
            app.NoofKicksEditField_3Label.Text = 'No. of Kicks';

            % Create NoofKicksEditField_3
            app.NoofKicksEditField_3 = uieditfield(app.UIFigure, 'numeric');
            app.NoofKicksEditField_3.Position = [198 304 36 22];

            % Create DelayBetweenKickssLabel
            app.DelayBetweenKickssLabel = uilabel(app.UIFigure);
            app.DelayBetweenKickssLabel.HorizontalAlignment = 'center';
            app.DelayBetweenKickssLabel.Position = [54 360 136 22];
            app.DelayBetweenKickssLabel.Text = 'Delay Between Kicks (s)';

            % Create DelayBetweenKickssEditField
            app.DelayBetweenKickssEditField = uieditfield(app.UIFigure, 'numeric');
            app.DelayBetweenKickssEditField.Position = [198 360 36 22];

            % Create FetalKickSimulatorLabel
            app.FetalKickSimulatorLabel = uilabel(app.UIFigure);
            app.FetalKickSimulatorLabel.HorizontalAlignment = 'center';
            app.FetalKickSimulatorLabel.FontSize = 20;
            app.FetalKickSimulatorLabel.FontWeight = 'bold';
            app.FetalKickSimulatorLabel.Position = [343 650 199 24];
            app.FetalKickSimulatorLabel.Text = 'Fetal Kick Simulator';

            % Create KickingActionLabel
            app.KickingActionLabel = uilabel(app.UIFigure);
            app.KickingActionLabel.HorizontalAlignment = 'center';
            app.KickingActionLabel.FontSize = 17;
            app.KickingActionLabel.FontWeight = 'bold';
            app.KickingActionLabel.Position = [383 600 125 22];
            app.KickingActionLabel.Text = 'Kicking Action';

            % Create StartKickingButton
            app.StartKickingButton = uibutton(app.UIFigure, 'push');
            app.StartKickingButton.ButtonPushedFcn = createCallbackFcn(app, @StartKickingButtonPushed, true);
            app.StartKickingButton.FontWeight = 'bold';
            app.StartKickingButton.FontColor = [1 0.0745 0.651];
            app.StartKickingButton.Position = [293 548 137 36];
            app.StartKickingButton.Text = 'Start Kicking';

            % Create DelayBetweenActuatorssLabel
            app.DelayBetweenActuatorssLabel = uilabel(app.UIFigure);
            app.DelayBetweenActuatorssLabel.HorizontalAlignment = 'center';
            app.DelayBetweenActuatorssLabel.Position = [97 493 90 28];
            app.DelayBetweenActuatorssLabel.Text = {'Delay Between '; 'Actuators (s)'};

            % Create DelayBetweenActuatorssEditField
            app.DelayBetweenActuatorssEditField = uieditfield(app.UIFigure, 'numeric');
            app.DelayBetweenActuatorssEditField.Editable = 'off';
            app.DelayBetweenActuatorssEditField.Position = [198 498 36 22];

            % Create FeedbackLabel
            app.FeedbackLabel = uilabel(app.UIFigure);
            app.FeedbackLabel.HorizontalAlignment = 'center';
            app.FeedbackLabel.FontSize = 17;
            app.FeedbackLabel.FontWeight = 'bold';
            app.FeedbackLabel.Position = [22 187 84 22];
            app.FeedbackLabel.Text = 'Feedback';

            % Create DelayBetweenKickssLabel_2
            app.DelayBetweenKickssLabel_2 = uilabel(app.UIFigure);
            app.DelayBetweenKickssLabel_2.HorizontalAlignment = 'center';
            app.DelayBetweenKickssLabel_2.Position = [54 227 136 22];
            app.DelayBetweenKickssLabel_2.Text = 'Delay Between Kicks (s)';

            % Create DelayBetweenKickssEditField_2
            app.DelayBetweenKickssEditField_2 = uieditfield(app.UIFigure, 'numeric');
            app.DelayBetweenKickssEditField_2.Position = [198 227 36 22];

            % Create KickDurationLabel
            app.KickDurationLabel = uilabel(app.UIFigure);
            app.KickDurationLabel.FontWeight = 'bold';
            app.KickDurationLabel.Position = [45 166 84 22];
            app.KickDurationLabel.Text = 'Kick Duration';

            % Create StatusEditFieldLabel
            app.StatusEditFieldLabel = uilabel(app.UIFigure);
            app.StatusEditFieldLabel.HorizontalAlignment = 'right';
            app.StatusEditFieldLabel.Position = [70 51 40 22];
            app.StatusEditFieldLabel.Text = 'Status';

            % Create StatusEditField
            app.StatusEditField = uieditfield(app.UIFigure, 'text');
            app.StatusEditField.Editable = 'off';
            app.StatusEditField.FontWeight = 'bold';
            app.StatusEditField.FontColor = [1 0 0];
            app.StatusEditField.Position = [125 50 473 25];

            % Create KickModeDropDownLabel
            app.KickModeDropDownLabel = uilabel(app.UIFigure);
            app.KickModeDropDownLabel.HorizontalAlignment = 'center';
            app.KickModeDropDownLabel.Position = [37 556 65 28];
            app.KickModeDropDownLabel.Text = 'Kick Mode';

            % Create KickModeDropDown
            app.KickModeDropDown = uidropdown(app.UIFigure);
            app.KickModeDropDown.Items = {'            Single', 'Dual: Simulteneous', 'Dual: Consequitive', '      Dual: Random'};
            app.KickModeDropDown.ValueChangedFcn = createCallbackFcn(app, @KickModeDropDownValueChanged, true);
            app.KickModeDropDown.Position = [105 559 129 22];
            app.KickModeDropDown.Value = '            Single';

            % Create WarningEditFieldLabel
            app.WarningEditFieldLabel = uilabel(app.UIFigure);
            app.WarningEditFieldLabel.HorizontalAlignment = 'right';
            app.WarningEditFieldLabel.Position = [60 22 50 22];
            app.WarningEditFieldLabel.Text = 'Warning';

            % Create WarningEditField
            app.WarningEditField = uieditfield(app.UIFigure, 'text');
            app.WarningEditField.Editable = 'off';
            app.WarningEditField.FontWeight = 'bold';
            app.WarningEditField.FontColor = [1 0 0];
            app.WarningEditField.Position = [125 21 473 25];

            % Create ConnecttheArduinoButton
            app.ConnecttheArduinoButton = uibutton(app.UIFigure, 'push');
            app.ConnecttheArduinoButton.ButtonPushedFcn = createCallbackFcn(app, @ConnecttheArduinoButtonPushed, true);
            app.ConnecttheArduinoButton.FontWeight = 'bold';
            app.ConnecttheArduinoButton.FontColor = [0.4706 0.6706 0.1882];
            app.ConnecttheArduinoButton.Position = [461 548 137 36];
            app.ConnecttheArduinoButton.Text = 'Connect the Arduino';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'Force applied by the actuators')
            xlabel(app.UIAxes, 'Time (s)')
            ylabel(app.UIAxes, 'Force (N)')
            app.UIAxes.XGrid = 'on';
            app.UIAxes.YGrid = 'on';
            app.UIAxes.Position = [271 178 410 283];

            % Create TotalSamplingPeriodsEditFieldLabel
            app.TotalSamplingPeriodsEditFieldLabel = uilabel(app.UIFigure);
            app.TotalSamplingPeriodsEditFieldLabel.HorizontalAlignment = 'center';
            app.TotalSamplingPeriodsEditFieldLabel.Position = [45 89 140 22];
            app.TotalSamplingPeriodsEditFieldLabel.Text = 'Total Sampling Period (s)';

            % Create TotalSamplingPeriodsEditField
            app.TotalSamplingPeriodsEditField = uieditfield(app.UIFigure, 'numeric');
            app.TotalSamplingPeriodsEditField.Editable = 'off';
            app.TotalSamplingPeriodsEditField.Position = [188 88 46 22];
        end
    end

    methods (Access = public)

        % Construct app
        function app = Kick_Simulator_exported

            % Create and configure components
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