% %function getMousePosition()
%     % Create a figure
%     f = figure('WindowButtonMotionFcn', @mouseMove);
% 
%     % Create an axis
%     ax = axes('Parent', f);
%     plot(ax, rand(1, 10)); % Example plot
% 
%     function mouseMove(~, ~)
%         % Get current point in the axes
%         cp = get(ax, 'CurrentPoint');
%         % Display the current mouse position
%         fprintf('Mouse Position: X=%.2f, Y=%.2f\n', cp(1, 1), cp(1, 2));
%     end
% %end

function drawRectangleOnDrag
    % Create a figure
    f = figure('WindowButtonDownFcn', @mouseDown, 'WindowButtonUpFcn', @mouseUp);
    
    % Initialize variables to hold start mouse position
    startPoint = [];
    
    % Create an axis
    ax = axes('Parent', f);
    xlim(ax, [0 10]);
    ylim(ax, [0 10]);
    
    function mouseDown(~, ~)
        % Get current point in the axes
        cp = get(ax, 'CurrentPoint');
        startPoint = cp(1, 1:2); % Store the starting point
        set(f, 'WindowButtonMotionFcn', @mouseMove); % Set movement function
    end

    function mouseMove(~, ~)
        % Update the figure while dragging
        cp = get(ax, 'CurrentPoint'); % Current position
        hold(ax, 'on'); 
        rectangle('Position', [startPoint(1), startPoint(2), ...
            cp(1,1)-startPoint(1), cp(1,2)-startPoint(2)], ...
            'FaceColor', [0.5 0.5 0.5], 'EdgeColor', 'none'); % Draw rectangle
        hold(ax, 'off');
    end

    function mouseUp(~, ~)
        % Finalize the background color when the mouse button is released
        cp = get(ax, 'CurrentPoint');
        rectangle('Position', [startPoint(1), startPoint(2), ...
            cp(1,1)-startPoint(1), cp(1,2)-startPoint(2)], ...
            'FaceColor', rand(1,3), 'EdgeColor', 'none'); % Fill with random color
        set(f, 'WindowButtonMotionFcn', ''); % Clear the motion function
        startPoint = []; % Reset start point
    end
end
