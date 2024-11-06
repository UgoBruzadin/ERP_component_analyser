function erpComponentAnalyzer
    % Create main figure
    fig = uifigure('Name', 'ERP Component Analyzer', 'Position', [100 100 1200 800]);
    
    % Create main grid layout
    gl = uigridlayout(fig, [2 3]);
    gl.RowHeight = {'4fr', '1fr'};
    gl.ColumnWidth = {'1fr', '2fr', '1fr'};
    
    % Left Panel - File and Channel Selection
    leftPanel = uipanel(gl);
    leftLayout = uigridlayout(leftPanel, [8 1]);
    leftLayout.RowHeight = {'fit', 'fit', 'fit', '2fr', 'fit', '2fr', 'fit', 'fit'};
    
    % Directory selection
    uibutton(leftLayout, 'Text', 'Select Directory', 'ButtonPushedFcn', @selectDirectory);
    
    % Dropdown for .set files
    fileDropLabel = uilabel(leftLayout, 'Text', 'Select .set file:');
    fileDropdown = uidropdown(leftLayout, 'Items', {''}, ...
        'ValueChangedFcn', @fileSelected);
    
    % Events listbox
    eventLabel = uilabel(leftLayout, 'Text', 'Events:');
    eventList = uilistbox(leftLayout, 'Items', {''}, ...
        'MultiSelect', 'on');
    
    % Channel selection
    channelLabel = uilabel(leftLayout, 'Text', 'Channels:');
    channelList = uilistbox(leftLayout, 'Items', {''}, ...
        'MultiSelect', 'on');
    
    % Select All/None buttons for channels
    btnLayout = uigridlayout(leftLayout, [1 2]);
    btnLayout.RowHeight = {'fit'};
    uibutton(btnLayout, 'Text', 'Select All', 'ButtonPushedFcn', @(btn,event) selectAllChannels(channelList));
    uibutton(btnLayout, 'Text', 'Select None', 'ButtonPushedFcn', @(btn,event) deselectAllChannels(channelList));
    
    % Middle Panel - ERP Plot and Excel View
    middlePanel = uipanel(gl);
    middleLayout = uigridlayout(middlePanel, [2 1]);
    middleLayout.RowHeight = {'4fr', '1fr'};
    
    % ERP Plot area
    erpAxes = uiaxes(middleLayout);
    hold(erpAxes, 'on');
    title(erpAxes, 'ERP Plot');
    xlabel(erpAxes, 'Time (ms)');
    ylabel(erpAxes, 'Amplitude (µV)');
    
    % Excel preview
    tableData = {};
    columnNames = {'Component', 'Start', 'End', 'Peak', 'Latency', 'Avg Power'};
    previewTable = uitable(middleLayout, 'Data', tableData, ...
        'ColumnName', columnNames, ...
        'ColumnEditable', false);
    
    % Right Panel - Component Information
    rightPanel = uipanel(gl);
    rightLayout = uigridlayout(rightPanel, [8 1]);
    rightLayout.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
    
    % Component name input
    uilabel(rightLayout, 'Text', 'Component Name:');
    componentName = uieditfield(rightLayout, 'Value', '');
    
    % Component info display
    uilabel(rightLayout, 'Text', 'Component Information:');
    
    % Info fields grid
    infoLayout = uigridlayout(rightLayout, [5 2]);
    infoLayout.RowHeight = repmat({'fit'}, 1, 5);
    
    % Labels and value fields for component info
    [peakField] = addInfoField(infoLayout, 'Peak:', 1);
    [latencyField] = addInfoField(infoLayout, 'Latency:', 2);
    [startField] = addInfoField(infoLayout, 'Start Time:', 3);
    [endField] = addInfoField(infoLayout, 'End Time:', 4);
    [powerField] = addInfoField(infoLayout, 'Avg Power:', 5);
    
    % Save component button
    uibutton(rightLayout, 'Text', 'Save Component', ...
        'ButtonPushedFcn', @saveComponent);
    
    % Store necessary data in figure's UserData
    fig.UserData.currentData = struct();
    fig.UserData.components = {};
    fig.UserData.infoFields = struct('peak', peakField, ...
                                   'latency', latencyField, ...
                                   'start', startField, ...
                                   'end', endField, ...
                                   'power', powerField);
    
    % Enable drag selection on ERP plot
    erpAxes.ButtonDownFcn = @startDragSelection;
    
    % Callback functions
    function selectDirectory(~, ~)
        dirPath = uigetdir();
        if dirPath ~= 0
            setfiles = dir(fullfile(dirPath, '*.set'));
            fileDropdown.Items = {setfiles.name};
            fig.UserData.currentPath = dirPath;
        end
    end
    
    function fileSelected(~, ~)
        try
            filename = fileDropdown.Value;
            fullpath = fullfile(fig.UserData.currentPath, filename);
            % Load EEGLab set file
            EEG = pop_loadset('filename', filename, 'filepath', fig.UserData.currentPath);
            
            % Update events list
            if isfield(EEG, 'event')
                uniqueEvents = unique({EEG.event.type});
                eventList.Items = uniqueEvents;
            end
            
            % Update channels list
            if isfield(EEG, 'chanlocs')
                channelLabels = {EEG.chanlocs.labels};
                channelList.Items = channelLabels;
            end
            
            % Store EEG data
            fig.UserData.currentData.EEG = EEG;
            
            % Plot initial ERP
            updateERPPlot();
        catch ME
            errordlg(['Error loading file: ' ME.message]);
        end
    end
    
    function startDragSelection(src, ~)
        % Initialize rubber band selection
        point1 = src.CurrentPoint(1, 1:2);
        rbbox;
        point2 = src.CurrentPoint(1, 1:2);
        
        % Calculate selection boundaries
        xStart = min(point1(1), point2(1));
        xEnd = max(point1(1), point2(1));
        
        % Update component info
        updateComponentInfo(xStart, xEnd);
        
        % Highlight selected area
        % Remove any existing selection patch
        delete(findobj(erpAxes, 'Tag', 'SelectionPatch'));
        
        % Create new selection patch
        yLimits = erpAxes.YLim;
        patch(erpAxes, [xStart xStart xEnd xEnd], [yLimits(1) yLimits(2) yLimits(2) yLimits(1)], ...
            [0.8 0.8 1], 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'Tag', 'SelectionPatch');
    end
    
    function updateComponentInfo(startTime, endTime)
        % Get data within selection
        data = fig.UserData.currentData.EEG.data;
        times = fig.UserData.currentData.EEG.times;
        
        % Find indices within time range
        timeIdx = times >= startTime & times <= endTime;
        selectedData = data(:, timeIdx);
        
        % Calculate metrics
        [maxVal, maxIdx] = max(abs(selectedData(:)));
        [chanIdx, timeIdx] = ind2sub(size(selectedData), maxIdx);
        peak = selectedData(chanIdx, timeIdx);
        latency = times(find(timeIdx, 1) + timeIdx - 1);
        avgPower = mean(selectedData(:).^2);
        
        % Update info fields
        fig.UserData.infoFields.peak.Value = num2str(peak);
        fig.UserData.infoFields.latency.Value = num2str(latency);
        fig.UserData.infoFields.start.Value = num2str(startTime);
        fig.UserData.infoFields.end.Value = num2str(endTime);
        fig.UserData.infoFields.power.Value = num2str(avgPower);
    end
    
    function saveComponent(~, ~)
        % Get current component info
        name = componentName.Value;
        if isempty(name)
            errordlg('Please enter a component name');
            return;
        end
        
        % Create new row for table
        newRow = {name, ...
            str2double(fig.UserData.infoFields.start.Value), ...
            str2double(fig.UserData.infoFields.end.Value), ...
            str2double(fig.UserData.infoFields.peak.Value), ...
            str2double(fig.UserData.infoFields.latency.Value), ...
            str2double(fig.UserData.infoFields.power.Value)};
        
        % Update table
        currentData = previewTable.Data;
        previewTable.Data = [currentData; newRow];
        
        % Clear component name
        componentName.Value = '';
    end
    
    function updateERPPlot()
        % Clear current plot
        cla(erpAxes);
        
        % Get selected channels and events
        selectedChannels = channelList.Value;
        selectedEvents = eventList.Value;
        
        if isempty(selectedChannels) || isempty(selectedEvents)
            return;
        end
        
        % Plot ERP for selected channels and events
        EEG = fig.UserData.currentData.EEG;
        plot(erpAxes, EEG.times, mean(EEG.data(1:end,:), 1));
        xlabel(erpAxes, 'Time (ms)');
        ylabel(erpAxes, 'Amplitude (µV)');
        title(erpAxes, 'ERP');
        grid(erpAxes, 'on');
    end
end

% Helper functions
function [valueField] = addInfoField(parent, label, row)
    uilabel(parent, 'Text', label);
    valueField = uieditfield(parent, 'Value', '', 'Editable', false);
end

function selectAllChannels(channelList)
    channelList.Value = channelList.Items;
end

function deselectAllChannels(channelList)
    channelList.Value = {};
end