% Main function to create GUI and plot ERPs
function plotERPGUI_component2(events)
if nargin < 1
    events = 1;
end

% Create main figure
mainFig = uifigure('Name', 'ERP Analysis Tool', ...
    'Position', [100 100 1600 600], ...
    'MenuBar', 'none', ...
    'ToolBar', 'none',...
    'WindowButtonDownFcn', @startDragSelection,...
    'WindowButtonMotionFcn',@mouseMove);%, 'WindowButtonUpFcn', @mouseUp);
% Turn off active modes if they are on
zoom off;
pan off;
rotate3d off;

% Define main grid layout with 1 row and 3 columns
mainGrid = uigridlayout(mainFig, [1, 3]);
mainGrid.ColumnWidth = {'0.2x', '0.6x', '0.2x'}; % Relative sizing for left, middle, and right panels
mainGrid.RowHeight = {'1x'}; % Only one row

% Left Panel (Side menu)
leftPanel = uipanel(mainGrid, ...
    'Tag','LeftPanel', ...
    'BackgroundColor', [0.94 0.94 0.94]);
leftGrid = uigridlayout(leftPanel, [10, 1]); % Define sections within the side panel


% Middle Panel for Plots
plotPanel = uipanel(mainGrid, 'Tag','PlotPanel');
plotGrid = uigridlayout(plotPanel, [2, 1]); % 2 rows for two plots

% Right Panel
rightPanel = uipanel(mainGrid, ...
    'Tag','RightPanel', ...
    'BackgroundColor', [0.94 0.94 0.94]);

rightGrid = uigridlayout(rightPanel, [5, 1]); % Define sections for topoplots and other controls
%
%     % Create panel for plot
%     plotPanel = uipanel('Parent', mainFig, ...
%                         'Tag','PlotPanel',...
%                        'Position', [0.2 0 0.6 1]);

% Create two axes for plots
axes1 = axes('Parent', plotGrid, ...
    'Tag','PlotPanel1',...
    'Units', 'normalized', ...
    'Position', [0.35 0.35 0.8 0.4]);


axes2 = axes('Parent', plotPanel, ...
    'Tag','PlotPanel2',...
    'Position', [0.1 0.05 0.8 0.4]);

% Side panel ax for the topoplots
axes3 = axes('Parent', rightPanel, ...
    'Position', [0.1 0.7 0.8 0.2]);

middlePanel = uipanel('Parent', plotGrid, ...
    'Tag','PlotPanel2',...
    'Position', [0.1 0.05 0.8 0.4]);

%middleLayout = uigridlayout(middlePanel, [2 1]);
% Excel preview
tableData = {'P1',0,0,0,0,};
columnNames = {'Component', 'Start', 'End', 'Peak', 'Latency', 'Avg Power'};
componentsTable = uitable(middlePanel, 'Data', tableData, ...
    'ColumnName', columnNames, ...
    'ColumnEditable', true, ...
    'Units', 'normalized', ...
    'Position', [0 0 0.3 0.3]); % Fill the entire middlePanel);


% File Selection Section
createLabel(leftPanel, 'Select EEG File:', 20, 580);
fileList = dir('*.set');
fileNames = {fileList.name};
fileDropdown = uicontrol('Parent', leftPanel, ...
    'Style', 'popupmenu', ...
    'Tag','Files',...
    'String', fileNames, ...
    'Value', 1,...
    'Position', [20 550 200 30], ...
    'Callback', @fileSelected);

% File Selection Section
%createLabel(sidePanel, 'Select EEG File:', 20, 580);
%fileList = dir('*.set');
%fileNames = {fileList.name};
folderButton = uicontrol('Parent', leftPanel, ...
    'Style', 'pushbutton', ...
    'String', 'Select Folder', ...
    'Position', [20 520 95 30], ...
    'Callback', @selectNewDir);

% Event Selection Section
createLabel(leftPanel, 'Select Event Types:', 20, 500);
eventList = uicontrol('Parent', leftPanel, ...
    'Style', 'listbox', ...
    'String', {'Select a file first'}, ...
    'Position', [20 440 200 60], ... % Made taller for multiple selections
    'Max', 2, ... % Enable multiple selection
    'Value', 1, ...
    'Callback', @updatePlot);

% Time Window Section
createLabel(leftPanel, 'Time Window (ms):', 20, 420);
startTime = uicontrol('Parent', leftPanel, ...
    'Style', 'edit', ...
    'String', '-200', ...
    'Position', [20 390 95 30], ...
    'Callback', @updatePlot);
endTime = uicontrol('Parent', leftPanel, ...
    'Style', 'edit', ...
    'String', '800', ...
    'Position', [125 390 95 30], ...
    'Callback', @updatePlot);

% Channel/Component Selection Section
createLabel(leftPanel, 'Available Channels/ICs:', 20, 340);
channelList = uicontrol('Parent', leftPanel, ...
    'Style', 'listbox', ...
    'String', {'Select a file first'}, ...
    'Position', [20 240 80 100], ...
    'Max', 2, ... % Enable multiple selection
    'Value', 1);%, ...
%'Callback', @updateTopoplots2);

%     channelList = uicontrol('Parent', sidePanel, ...
%                            'Style', 'listbox', ...
%                            'String', {'Select a file first'}, ...
%                            'Position', [20 240 200 100], ...
%                            'Max', 2, ... % Enable multiple selection
%                            'Value', 1, ...
%                            'Callback', @updatePlot);
% Add forward/backward buttons
forwardBtn = uicontrol('Parent', leftPanel, ...
    'Style', 'pushbutton', ...
    'String', '>>', ...
    'Position', [105 280 30 20], ...
    'Callback', @moveForward);

backwardBtn = uicontrol('Parent', leftPanel, ...
    'Style', 'pushbutton', ...
    'String', '<<', ...
    'Position', [105 260 30 20], ...
    'Callback', @moveBackward);

% Add rejected list
rejectedList = uicontrol('Parent', leftPanel, ...
    'Style', 'listbox', ...
    'String', {}, ...
    'Position', [140 240 80 100], ...
    'Max', 2);%, ...
%'Callback', @updateTopoplots2);

% Select All/None Buttons for Channels
selectAll = uicontrol('Parent', leftPanel, ...
    'Style', 'pushbutton', ...
    'String', 'Select All', ...
    'Position', [20 210 95 30], ...
    'Callback', {@selectChannels, 'all'});

selectNone = uicontrol('Parent', leftPanel, ...
    'Style', 'pushbutton', ...
    'String', 'Select None', ...
    'Position', [125 210 95 30], ...
    'Callback', {@selectChannels, 'none'});

% Data Type Toggle
dataTypeToggle = uicontrol('Parent', leftPanel, ...
    'Style', 'togglebutton', ...
    'String', 'Show Component ERPs', ...
    'Position', [20 160 200 30], ...
    'Value', 0, ...
    'Callback', @dataTypeToggled);

createLabel(leftPanel, 'Data Modification:', 20, 140);


mouse_x = uicontrol('Parent', leftPanel, ...
    'Style', 'text', ...
    'String', 'Mouse X', ...
    'Tag','MouseX',...
    'Position', [20 110 95 30]);

mouse_y = uicontrol('Parent', leftPanel, ...
    'Style', 'text', ...
    'String', 'Mouse Y', ...
    'Tag','MouseY',...
    'Position', [125 110 95 30]);
%
% Save Section
createLabel(leftPanel, 'Save Suffix:', 20, 80);
suffixBox = uicontrol('Parent', leftPanel, ...
    'Style', 'edit', ...
    'String', 'New', ...
    'Position', [20 60 200 20]);

%createLabel(sidePanel, 'Save Dataset:', 20, 60);
saveButton = uicontrol('Parent', leftPanel, ...
    'Style', 'pushbutton', ...
    'String', 'Save', ...
    'Position', [20 10 200 30], ...
    'Callback', @saveDataset);

% mouse positions handles
userData.mouse_x = mouse_x;
userData.mouse_y = mouse_y;
% Store handles and data in figure UserData
userData.axes1 = axes1;
%     userData.axes2 = axes2;
%     userData.axes3 = axes3;
%     userData.axes4 = axes4;
%     userData.axes5 = axes5;
%     userData.axes6 = axes6;

userData.availableList = channelList;
userData.rejectedList = rejectedList;
userData.originalEEG = []; % Store original data

userData.plotPanel = plotPanel;
userData.fileDropdown = fileDropdown;
userData.eventList = eventList;
if isempty(events)
    eventChoiceStrings = eventList.String(eventList.Value);
else
    eventChoiceStrings = events;
end
userData.eventChoiceStrings = eventChoiceStrings;
userData.suffixBox = suffixBox;
userData.dataTypeToggle = dataTypeToggle;
userData.channelList = channelList;
userData.startTime = startTime;
userData.endTime = endTime;
userData.currentEEG = [];
userData.tempEEG = [];
userData.componentsTable = componentsTable;
set(mainFig, 'UserData', userData);
end

function reloadDirectory(source, ~)

mainFig = getMainFigure(source);
userData = get(mainFig, 'UserData');
fileList = dir('*.set');
fileNames = {fileList.name};
userData.fileDropdown.String = fileNames;

set(mainFig,'UserData',userData);

end

function selectNewDir(source, ~)

newdir = uigetdir();
cd(newdir)
reloadDirectory(source)

end

function plotChannelLocations(mainFig)

userData = get(mainFig,'UserData');
EEG = userData.currentEEG;
%ax = userData.axes3;
topoplot([],EEG.chanlocs, 'style', 'blank',  'electrodes', 'labelpoint', 'chaninfo', EEG.chaninfo);

end

function saveDataset(source, ~)
mainFig = getMainFigure(source);
userData = get(mainFig, 'UserData');

if isempty(userData.currentEEG)
    return;
end

% Get the suffix from the textbox
suffix = get(userData.suffixBox, 'String');

% Get the current file name
fileList = get(userData.fileDropdown, 'String');
selectedIdx = get(userData.fileDropdown, 'Value');
currentFile = fileList{selectedIdx};

% Split the filename and extension
[~, name, ext] = fileparts(currentFile);

% Create new filename with suffix
if ~isempty(suffix)
    newFilename = [name '_' suffix ext];
else
    newFilename = [name '_modified' ext];
end

% Save the dataset in the current directory
try
    EEG = userData.tempEEG;
    EEG = pop_saveset(EEG, 'filename', newFilename, 'filepath', pwd);
    reloadDirectory(source);
    %loadNewFile(source,newFilename);

    %Load new file
    sprintf('File Saved Sucessfully as : %s',newFilename);

    %msgbox(['File saved as: ' newFilename], 'Save Successful');
catch err

    errordlg(['Error saving file: ' err.message], 'Error');
end
end

function loadNewFile(source,filename)

mainFig = getMainFigure(source);
userData = get(mainFig,'UserData');
val = find(strcmp(userData.fileDropdown.String,filename));
userData.fileDropdown.Value = val;
fileSelected(findobj(mainFig,'Tag','Files'));
reloadDirectory(source);


end

% Helper function to create labels
function createLabel(parent, text, x, y)
uicontrol('Parent', parent, ...
    'Style', 'text', ...
    'String', text, ...
    'Position', [x y 200 20], ...
    'BackgroundColor', [0.94 0.94 0.94], ...
    'HorizontalAlignment', 'left');
end

% Callback for file selection
function fileSelected(source, ~)

try
    mainFig = getMainFigure(source);
catch
    mainFig = Source;
end
userData = get(mainFig, 'UserData');

% Get selected file
fileList = get(source, 'String');
selectedIdx = get(source, 'Value');
selectedFile = fileList{selectedIdx};

try
    EEG = pop_loadset(selectedFile);
    userData.currentEEG = EEG;
    userData.originalEEG = EEG; % Store original data
    userData.tempEEG = EEG;

    % Update event type list
    eventTypes = unique({EEG.event.type});
    set(userData.eventList, 'String', eventTypes);
    try
        newvals = [];
        for i = 1:length(userData.eventChoiceStrings)
            newval = find(strcmp(eventTypes,userData.eventChoiceStrings(i)));
            if any(newval)
                newvals = [newvals, newval];
            end
        end
        userData.eventList.Value = newvals;

    catch

    end

    %set(userData.eventList, 'Value', 1);
    try
        items = {userData.currentEEG.chanlocs.labels};
    catch
        items = {1:EEG.nbchan};
    end

    set(userData.availableList, 'String', items);
    % Clear Rejected Selection
    set(userData.rejectedList, 'Value', []); % Clear selection
    set(userData.rejectedList, 'String', {});
    newChoiceStringsValues = [];

    % Update channel list based on current mode
    updateChannelList(mainFig);

    % Update UserData and plot
    set(mainFig, 'UserData', userData);

    % Plot topoplots
    plotChannelLocations(mainFig);

    updatePlot(source, []);

catch err
    errordlg(['Error loading file: ' err.message], 'Error');
end
end

% Modified updateTopoplots function with loop prevention
function updateTopoplots(mainFig, clickedTime, label)
userData = get(mainFig, 'UserData');

% Check if we're already updating topoplots to prevent infinite loop
if isfield(userData, 'updatingTopoplots') && userData.updatingTopoplots
    return;
end

% Set flag to prevent recursive calls
userData.updatingTopoplots = true;
set(mainFig, 'UserData', userData);

try
    if isempty(userData.currentEEG) || isempty(userData.tempEEG)
        return;
    end

    % Get the current event types
    eventList = get(userData.eventList, 'String');
    selectedEventIdx = get(userData.eventList, 'Value');
    selectedEvents = eventList(selectedEventIdx);

    % Calculate time indices based on current window settings
    startTime = str2double(get(userData.startTime, 'String'));
    endTime = str2double(get(userData.endTime, 'String'));
    times = linspace(startTime, endTime, (endTime-startTime)*userData.currentEEG.srate/1000);
    [~, timeIdx] = min(abs(times - clickedTime));

    % Get ERP data for both original and preview
    [origData, ~] = getERPData(userData.originalEEG, selectedEvents, times);
    [prevData, ~] = getERPData(userData.tempEEG, selectedEvents, times);

    % Plot original data topoplot
    axes(userData.axes4);
    cla(userData.axes4);
    if ~isempty(userData.originalEEG.chanlocs)
        topoplot(origData(:, timeIdx), userData.originalEEG.chanlocs, ...
            'electrodes', 'on', 'style', 'map');
        title(sprintf('Original at %.0f ms', clickedTime));
        colorbar;
    end

    % Plot preview data topoplot
    axes(userData.axes5);
    cla(userData.axes5);
    if ~isempty(userData.tempEEG.chanlocs)
        topoplot(prevData(:, timeIdx), userData.tempEEG.chanlocs, ...
            'electrodes', 'on', 'style', 'map');
        title(sprintf('Preview at %.0f ms', clickedTime));
        colorbar;
    end

    % Update component topoplot if in component mode
    if get(userData.dataTypeToggle, 'Value') && isfield(userData.currentEEG, 'icaact')
        axes(userData.axes6);
        cla(userData.axes6);

        chanorcomp = str2double(label(3:end));
        if ~isempty(userData.currentEEG.chanlocs)
            topoplot(userData.currentEEG.icawinv(:,chanorcomp), userData.currentEEG.chanlocs, ...
                'chaninfo', userData.currentEEG.chaninfo, 'electrodes','on'); axis square;

            title(['IC' num2str(chanorcomp)]);
            %topoplot([], userData.currentEEG.chanlocs, 'style', 'blank', ...
            %        'electrodes', 'labelpoint', 'chaninfo', userData.currentEEG.chaninfo);
            %title('Channel Locations');
        end
    end
catch err
    warning('Error in updateTopoplots: %s', err.message);
end

% Clear the update flag
userData.updatingTopoplots = false;
set(mainFig, 'UserData', userData);
end


% Modified updateTopoplots function with loop prevention
function updateTopoplots2(source,x)
label = source.String(source.Value);
mainFig = getMainFigure(source);
userData = get(mainFig, 'UserData');

% Check if we're already updating topoplots to prevent infinite loop
if isfield(userData, 'updatingTopoplots') && userData.updatingTopoplots
    return;
end

% Set flag to prevent recursive calls
userData.updatingTopoplots = true;
set(mainFig, 'UserData', userData);

try
    if isempty(userData.currentEEG) || isempty(userData.tempEEG)
        return;
    end

    % Update component topoplot if in component mode
    if get(userData.dataTypeToggle, 'Value') && isfield(userData.currentEEG, 'icaact')
        axes(userData.axes6);
        cla(userData.axes6);
        label = label{:};
        chanorcomp = str2double(label(3:end));
        if ~isempty(userData.currentEEG.chanlocs)
            topoplot(userData.currentEEG.icawinv(:,chanorcomp), userData.currentEEG.chanlocs, ...
                'chaninfo', userData.currentEEG.chaninfo, 'electrodes','on'); axis square;

            title(['IC' num2str(chanorcomp)]);
            %topoplot([], userData.currentEEG.chanlocs, 'style', 'blank', ...
            %        'electrodes', 'labelpoint', 'chaninfo', userData.currentEEG.chaninfo);
            %title('Channel Locations');
        end
    end
catch err
    warning('Error in updateTopoplots: %s', err.message);
end

% Clear the update flag
userData.updatingTopoplots = false;
set(mainFig, 'UserData', userData);
end

% Helper function to get ERP data (unchanged)
function [erpData, times] = getERPData(EEG, eventTypes, times)
% Find indices of specified event types
eventIndices = [];
for i = 1:length(eventTypes)
    eventIndices = [eventIndices, find(strcmp({EEG.event.type}, eventTypes{i}))];
end

% Calculate sample indices
startSample = round(times(1)*EEG.srate/1000) + abs(EEG.xmin*1000)*(EEG.srate/1000);
endSample = round(times(end)*EEG.srate/1000) + abs(EEG.xmin*1000)*(EEG.srate/1000);

% Initialize data matrix
epochs = zeros(EEG.nbchan, endSample-startSample+1, length(eventIndices));

% Extract epochs
for i = 1:length(eventIndices)
    epochs(:,:,i) = EEG.data(:, startSample:endSample, EEG.event(eventIndices(i)).epoch);
end

% Calculate average
erpData = mean(epochs, 3);
end

% Callback for data type toggle
function dataTypeToggled(source, ~)
mainFig = getMainFigure(source);
userData = get(mainFig, 'UserData');

% Clear rejected list when switching modes
set(userData.rejectedList, 'String', {});

% Update available list
updateChannelList(mainFig);

% Update plot with current settings
updatePlot(source, []);
end

% Function to update channel/component list
function updateChannelList(mainFig)
userData = get(mainFig, 'UserData');
if isempty(userData.currentEEG)
    return;
end

% Get currently rejected items
rejectedItems = get(userData.rejectedList, 'String');

% Check if showing components or channels
if get(userData.dataTypeToggle, 'Value') && isfield(userData.currentEEG, 'icaact')
    % Show components
    numComps = size(userData.currentEEG.icaact, 1);
    items = cellstr(num2str((1:numComps)', 'IC%2d'));
else
    % Show channels
    items = {userData.currentEEG.chanlocs.labels};
end

% Remove any items that are in the rejected list
items = setdiff(items, rejectedItems, 'stable');

% Update available list
set(userData.channelList, 'String', items);
%set(userData.availableList, 'String', items);
%set(userData.rejectedList, 'Value', []); % Clear selection
end

% Callback for select all/none buttons
function selectChannels(source, ~, mode)
mainFig = getMainFigure(source);
userData = get(mainFig, 'UserData');
items = get(userData.availableList, 'String');

if strcmp(mode, 'all')
    set(userData.availableList, 'Value', 1:length(items));
else % none
    set(userData.availableList, 'Value', []);
end

updatePlot(source, []);
end

% Helper function to get main figure handle
function mainFig = getMainFigure(source)
mainFig = source;
while ~strcmp(get(mainFig, 'Type'), 'figure')
    mainFig = get(mainFig, 'Parent');
end
end

% Callback for plot updates

function updatePlot(source, ~)
mainFig = getMainFigure(source);
userData = get(mainFig, 'UserData');

if isempty(userData.currentEEG)
    return;
end

% Get current settings
eventList = get(userData.eventList, 'String');
selectedEventIdx = get(userData.eventList, 'Value');
selectedEvent = eventList(selectedEventIdx);
userData.eventChoiceStrings = selectedEvent;

% Get time window
startTime = str2double(get(userData.startTime, 'String'));
endTime = str2double(get(userData.endTime, 'String'));
timeWindow = [startTime endTime];

% Get rejected items
rejectedItems = get(userData.rejectedList, 'String');

% Create temporary EEG with rejections applied
tempEEG = userData.currentEEG;


% Clear existing plots
cla(userData.axes1);
%cla(userData.axes2);

% Plot in both axes
% For original data (topo plot)
ax = axes(userData.axes1);
hold(ax,"on")

if get(userData.dataTypeToggle, 'Value') && isfield(userData.currentEEG, 'icaact')
    plotComponentERP(userData.originalEEG, selectedEvent, timeWindow, 1:size(userData.originalEEG.icaact, 1));
else
    meanERP = plotEventERP(userData.originalEEG, selectedEvent, timeWindow, 1:userData.originalEEG.nbchan);
end
userData.meanERP = meanERP;
title('Original Data');
ax = axes(userData.axes1);
hold(ax,"off")

% For modified data (bottom plot)
%     axes(userData.axes2);
%     if ~isempty(rejectedItems)
%         % Separate ICs and channels
%         icMask = cellfun(@(x) strncmp(x, 'IC', 2), rejectedItems);
%
%         % Handle IC rejections
%         if any(icMask)
%             icNums = cellfun(@(x) str2double(x(3:end)), rejectedItems(icMask));
%             tempEEG = pop_subcomp(tempEEG, icNums, 0);
%             tempEEG.icaact = eeg_getdatact(tempEEG, 'component', [1:size(tempEEG.icaweights,1)]);
%             userData.tempEEG = tempEEG;
%         end
%
%         % Handle channel interpolation
%         chanLabels = rejectedItems(~icMask);
%         if ~isempty(chanLabels)
%             [~, chanInds] = ismember(chanLabels, {tempEEG.chanlocs.labels});
%             chanInds = chanInds(chanInds > 0); % Remove any zero indices
%             if ~isempty(chanInds)
%                 tempEEG = pop_interp(tempEEG, chanInds, 'spherical');
%                 userData.tempEEG = tempEEG;
%             end
%         end
%     end
%
%     % Plot the modified data
%     if get(userData.dataTypeToggle, 'Value') && isfield(tempEEG, 'icaact')
%         % Get remaining components (not rejected)
%         allComps = 1:size(tempEEG.icaact, 1);
%         if ~isempty(rejectedItems)
%             rejectedComps = cellfun(@(x) str2double(x(3:end)), rejectedItems(icMask));
%             remainingComps = setdiff(allComps, rejectedComps);
%
%             %plotComponentERP(tempEEG, selectedEvent, timeWindow, 1:size(tempEEG.icaact, 1));
%             plotEventERP(tempEEG, selectedEvent, timeWindow, 1:tempEEG.nbchan);
%         else
%             %plotComponentERP(userData.originalEEG, selectedEvent, timeWindow, 1:size(userData.originalEEG.icaact, 1));
%             plotEventERP(userData.originalEEG, selectedEvent, timeWindow, 1:userData.originalEEG.nbchan);
%         end
%     else
%         plotEventERP(tempEEG, selectedEvent, timeWindow, 1:tempEEG.nbchan);
%
%     end
%     title('Preview with Rejections');

userData.tempEEG = tempEEG;
set(mainFig, 'UserData', userData);
end

% Modified plotEventERP function with channel selection
function meanERP = plotEventERP(EEG, eventType, timeWindow, selectedChannels)
% Find indices of specified event type
eventIndices = [];
for i=1:length(eventType)
    eventIndices = [eventIndices, find(strcmp({EEG.event.type}, eventType(i)))];
end
% Calculate time vector
times = linspace(timeWindow(1), timeWindow(2), diff(timeWindow)*EEG.srate/1000);

% Initialize matrix for selected channels only
numSamples = length(times);
epochs = zeros(length(eventIndices), numSamples, length(selectedChannels));

% Extract epochs for selected channels
for i = 1:length(eventIndices)
    startSample = round(timeWindow(1)*EEG.srate/1000)+abs(EEG.xmin*1000)*(EEG.srate/1000);
    endSample = round(timeWindow(2)*EEG.srate/1000)+abs(EEG.xmin*1000)*(EEG.srate/1000);

    if startSample > 0 && endSample <= EEG.xmax*1000
        for chanIdx = 1:length(selectedChannels)
            chan = selectedChannels(chanIdx);
            epochs(i, :, chanIdx) = EEG.data(chan, startSample:endSample-1, EEG.event(i).epoch);
        end
    end
end

% Calculate average ERPs
meanERP = squeeze(mean(epochs, 1));

% Plot ERPs for selected channels
h = plot(times, meanERP);
grid on;
xlabel('Time (ms)');
ylabel('Amplitude (µV)');
title(['Average ERP for Event ']);

% Create custom data tips for selected channels
for i = 1:length(h)
    set(h(i), 'UserData', EEG.chanlocs(selectedChannels(i)).labels);
end


%datacursormode on;
for i = 1:length(h)
    %set(h(i), 'ButtonDownFcn', {@lineCallback, h(i)});
end
%dcm = datacursormode(gcf);
%set(dcm, 'UpdateFcn', @customDatatipFunction);


end

% Modified plotComponentERP function with component selection

% Modified plotComponentERP function with proper component plotting
function plotComponentERP(EEG, eventType, timeWindow, selectedComponents)
% Find indices of specified event type
eventIndices = [];
for i=1:length(eventType)
    eventIndices = [eventIndices, find(strcmp({EEG.event.type}, eventType(i)))];
end

% Calculate time vector
times = linspace(timeWindow(1), timeWindow(2), diff(timeWindow)*EEG.srate/1000);

% Initialize matrix for selected components
numSamples = length(times);
compEpochs = zeros(length(eventIndices), numSamples, length(selectedComponents));

% Calculate samples for extraction
startSample = round(timeWindow(1)*EEG.srate/1000)+abs(EEG.xmin*1000)*(EEG.srate/1000);
endSample = round(timeWindow(2)*EEG.srate/1000)+abs(EEG.xmin*1000)*(EEG.srate/1000);
sampleLength = endSample - startSample;

% Check if we have ICA weights and sphere
if ~isempty(EEG.icaweights) && ~isempty(EEG.icasphere)
    % Extract epochs for selected components
    for epochIdx = 1:length(eventIndices)
        % Get the current epoch data
        epochData = EEG.data(:, startSample:endSample-1, EEG.event(epochIdx).epoch);

        % Transform data to component space for this epoch
        compData = (EEG.icaweights * EEG.icasphere) * epochData;

        % Store only selected components
        for compIdx = 1:length(selectedComponents)
            comp = selectedComponents(compIdx);
            compEpochs(epochIdx, :, compIdx) = compData(comp, :);
        end
    end

    % Calculate average component ERPs
    meanCompERP = squeeze(mean(compEpochs, 1));

    % If only one component is selected, ensure proper dimensionality
    if length(selectedComponents) == 1
        meanCompERP = meanCompERP(:)';
    end

    % Plot component ERPs
    h = plot(times, meanCompERP);
    grid on;
    xlabel('Time (ms)');
    ylabel('Component Amplitude');
    title(['Component ERPs for Event ']);

    % Create custom data tips for components
    for i = 1:length(h)
        set(h(i), 'UserData', ['IC' num2str(selectedComponents(i))]);
    end

    % Add legend with component numbers
    %legendLabels = arrayfun(@(x) ['IC' num2str(x)], selectedComponents, 'UniformOutput', false);
    %legend(legendLabels, 'Location', 'best');

    % Set custom datatip function
    dcm = datacursormode(gcf);
    %set(dcm, 'UpdateFcn', @customDatatipFunction);
else
    text(0.5, 0.5, 'No ICA data available', 'HorizontalAlignment', 'center');
    axis off;
end

%datacursormode on;
for i = 1:length(h)
    %set(h(i), 'ButtonDownFcn', {@lineCallback, h(i)});
end
dcm = datacursormode(gcf);
%set(dcm, 'UpdateFcn', @customDatatipFunction);
end

% Modified customDatatipFunction with loop prevention
function output_txt = customDatatipFunction(obj, event_obj)
% Get the line that was clicked and figure
lineHandle = event_obj.Target;
mainFig = get(lineHandle, 'Parent');
while ~strcmp(get(mainFig, 'Type'), 'figure')
    mainFig = get(mainFig, 'Parent');
end

% Get the position and user data
pos = event_obj.Position;
label = get(lineHandle, 'UserData');
clickedTime = pos(1);

% Update topoplots with the clicked time
try
    %updateTopoplots(mainFig, clickedTime, label);
catch err
    warning('Error updating topoplots: %s', err.message);
end

% Create datatip text
if strncmp(label, 'IC', 2)
    output_txt = {['Component: ' label], ...
        ['Time: ' num2str(pos(1), '%.1f') ' ms'], ...
        ['Amplitude: ' num2str(pos(2), '%.2f')]};
else
    output_txt = {['Channel: ' label], ...
        ['Time: ' num2str(pos(1), '%.1f') ' ms'], ...
        ['Amplitude: ' num2str(pos(2), '%.2f') ' µV']};
end
end

% Add this new function:
function lineCallback(src, ~, lineHandle)
% Toggle line selection
if strcmp(get(lineHandle, 'LineStyle'), '-')
    set(lineHandle, 'LineStyle', '--', 'LineWidth', 4);
else
    set(lineHandle, 'LineStyle', '-', 'LineWidth', 0.5);
end
end


% Update the moveForward function:
function moveForward(source, ~)
mainFig = getMainFigure(source);
userData = get(mainFig, 'UserData');

% Get selected items from available list
availStr = get(userData.availableList, 'String');
availVal = get(userData.availableList, 'Value');

if isempty(availVal)
    return;
end

% Get current rejected itemsupdateplot
rejStr = get(userData.rejectedList, 'String');

% Move selected items to rejected list
selectedItems = availStr(availVal);
rejStr = [rejStr; selectedItems(:)];  % Ensure column vector

% Update rejected list
set(userData.rejectedList, 'String', rejStr);

% Update available list
updateChannelList(mainFig);

% Update plots
updatePlot(source, []);
end

% Update the moveBackward function:
function moveBackward(source, ~)
mainFig = getMainFigure(source);
userData = get(mainFig, 'UserData');

% Get selected items from rejected list
rejStr = get(userData.rejectedList, 'String');
rejVal = get(userData.rejectedList, 'Value');

if isempty(rejVal)
    return;
end

% Remove selected items from rejected list
rejStr(rejVal) = [];
set(userData.rejectedList, 'String', rejStr, 'Value', []);

% Update available list
updateChannelList(mainFig);

% Update plots
updatePlot(source, []);
end

function startDragSelection(src, ~)
% Initialize rubber band selection
mainFig = getMainFigure(src);
ax = src.UserData.axes1;
point1 = ax.CurrentPoint(1, 1:2);

if strcmp(src.SelectionType,'normal')

    rbbox;
    point2 = ax.CurrentPoint(1, 1:2);

    % Calculate selection boundaries
    xStart = min(point1(1), point2(1));
    xEnd = max(point1(1), point2(1));

    % Update component info
    updateComponentInfo(src,xStart, xEnd);

    % Highlight selected area
    % Remove any existing selection patch
    delete(findobj(ax, 'Tag', 'SelectionPatch'));

    % Create new selection patch
    yLimits = ax.YLim;
    patch(ax, [xStart xStart xEnd xEnd], [yLimits(1) yLimits(2) yLimits(2) yLimits(1)], ...
        [.3 .6 1], 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'Tag', 'SelectionPatch');

elseif strcmp(src.SelectionType,'alt')
    ax = src.UserData.axes1;
    point1 = ax.CurrentPoint(1, 1:2);
    data = mainFig.UserData.meanERP;
    xStart = point1(1);
    yStart = point1(2);

    % Change peak and latency
    mainFig = getMainFigure(src);
    startTime_og = str2double(mainFig.UserData.startTime.String);
    srate = mainFig.UserData.currentEEG.srate;
    startBin = realTimeToBin(point1,srate,startTime_og);

    selectedData = data(startBin, :);
    [maxVal, maxIdx] = max(abs(selectedData(:)));
    [relTimeIdx, chanIdx] = ind2sub(size(selectedData), maxIdx); % Get relative time index in selectedData
    peak = selectedData(relTimeIdx, chanIdx);
    latency = binToRealTime(relTimeIdx, srate, startTime_og);
    mainFig.UserData.componentsTable.Data{4} = peak;
    mainFig.UserData.componentsTable.Data{5} = latency;

    % Plot X on the region
    yLimits = ax.YLim;
    % Remove any existing selection patch
    delete(findobj(ax, 'Tag', 'SelectionPeak'));
    patch(ax,[xStart xStart xStart xStart], [yLimits(1) yLimits(2) yLimits(2) yLimits(1)], ...
        'MarkerSize',10, 'Tag', 'SelectionPeak')

    %patch(ax, [xStart xStart xEnd xEnd], [yLimits(1) yLimits(2) yLimits(2) yLimits(1)], ...
    %   [.3 .6 1], 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'Tag', 'SelectionPatch');

elseif strcmp(src.SelectionType,'extend')

end
end

function realTime = binToRealTime(bin, srate, startTime)
% Convert bin index to real time (ms)
% bin: the data point index (starting from 1)
% srate: sampling rate in Hz (samples per second)
% startTime: start time of the epoch in milliseconds (usually negative if centered on stimulus)

realTime = ((bin - 1) / srate) * 1000 + startTime;
end

function bin = realTimeToBin(realTime, srate, startTime)
% Convert real time (ms) to the nearest bin index
% realTime: the time in milliseconds
% srate: sampling rate in Hz
% startTime: start time of the epoch in milliseconds

bin = round(((realTime - startTime) / 1000) * srate) + 1;
end

function updateComponentInfo(src,startTime, endTime)
% Get data within selection
mainFig = getMainFigure(src);
data = mainFig.UserData.meanERP;

% Define the time range based on the start and end time strings
startTime_og = str2double(mainFig.UserData.startTime.String);
endTime_og = str2double(mainFig.UserData.endTime.String);
times = startTime_og:endTime_og; % Define times array within the range

% Defining srate
srate = mainFig.UserData.currentEEG.srate;

% Calculate start and end time bins in original data s freq.
startBin = realTimeToBin(startTime,srate,startTime_og);
endBin = realTimeToBin(endTime,srate,startTime_og);
% Find indices within the time range
selectedData = data(startBin:endBin, :);

% Calculate metrics
[maxVal, maxIdx] = max(abs(selectedData(:))); % Find peak value and its index in the subset
[relTimeIdx, chanIdx] = ind2sub(size(selectedData), maxIdx); % Get relative time index in selectedData
peak = selectedData(relTimeIdx, chanIdx);

% Map relative index back to absolute time
latency = binToRealTime(relTimeIdx + startBin, srate, startTime_og);

% Calculate average power in selected data range
avgPower = mean(selectedData(:).^2);

% Update info fields
mainFig.UserData.componentsTable.Data{2} = startTime;
mainFig.UserData.componentsTable.Data{3} = endTime;
mainFig.UserData.componentsTable.Data{4} = peak;
mainFig.UserData.componentsTable.Data{5} = latency;
mainFig.UserData.componentsTable.Data{6} = avgPower;

end

function mouseMove(src, ~)
% Retrieve the handle to the target axes
%try
ax = src.UserData.axes1; % Adjust if there are multiple axes
cp = get(ax, 'CurrentPoint'); % Current mouse position

% Get axis limits
xLimits = get(ax, 'XLim');
yLimits = get(ax, 'YLim');

% Check if mouse is within the axis limits
if cp(1,1) >= xLimits(1) && cp(1,1) <= xLimits(2) && ...
        cp(1,2) >= yLimits(1) && cp(1,2) <= yLimits(2)
    % Update only if within plot area
    set(findobj(src, 'Tag', 'MouseX'), 'String', num2str(cp(1,1)));
    set(findobj(src, 'Tag', 'MouseY'), 'String', num2str(cp(1,2)));
else
    % Optionally, clear or hide the display when outside plot
    set(findobj(src, 'Tag', 'MouseX'), 'String', '');
    set(findobj(src, 'Tag', 'MouseY'), 'String', '');
end
%catch
%end
end

function mouseDown(~, ~)
% Get current point in the axes
ax = axes('Parent', gcf);
cp = get(ax, 'CurrentPoint');
startPoint = cp(1, 1:2); % Store the starting point
set(gcf, 'WindowButtonMotionFcn', @mouseMove2,startPoint); % Set movement function
end

function mouseMove2(src, startPoint)
% Update the figure while dragging
ax = axes('Parent', gcf);
cp = get(ax, 'CurrentPoint'); % Current position
hold(ax, 'on');
rectangle('Position', [startPoint(1), startPoint(2), ...
    cp(1,1)-startPoint(1), cp(1,2)-startPoint(2)], ...
    'FaceColor', [0.5 0.5 0.5], 'EdgeColor', 'none'); % Draw rectangle
hold(ax, 'off');
end

function mouseUp(~, ~)
ax = axes('Parent', gcf);
% Finalize the background color when the mouse button is released
cp = get(ax, 'CurrentPoint');
rectangle('Position', [startPoint(1), startPoint(2), ...
    cp(1,1)-startPoint(1), cp(1,2)-startPoint(2)], ...
    'FaceColor', rand(1,3), 'EdgeColor', 'none'); % Fill with random color
set(gcf, 'WindowButtonMotionFcn', ''); % Clear the motion function
startPoint = []; % Reset start point
end


