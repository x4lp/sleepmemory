function mt_controlTask(dirRoot, cfg_window, iControlRun)
% ** function mt_controlTask(dirRoot, cfg_window, iControlRun)
% This function initiates the control task.
%
% USAGE:
%     mt_controlTask(dirRoot, cfg_window, iControlRun)
%
% >>> INPUT VARIABLES >>>
% NAME              TYPE        DESCRIPTION
% dirRoot           char        path to root working directory
% cfg_window        struct      contains window information
%   .screen         1X2 double  [screens ScreenNumber]
%   .window         1X5 double  [window windowRect], actual resolution
%   .window43       1X5 double  [window windowRect], 4:3 resolution
%   .center         1X2 double  [Xcenter Ycenter]
% iControlRun       double      number of control task run
%
%
% AUTHOR: Marco R�th, contact@marcorueth.com

%% Load parameters specified in mt_setup.m
load(fullfile(dirRoot,'setup','mt_params.mat'))   % load workspace information and properties

%% Set window parameters
% Specify the display window 
window             = cfg_window.window(1);

%% Initialize variables for measured parameters
cardShown    	= cardSequence{cfg_dlgs.memvers}{cfg_dlgs.sesstype}{iControlRun}';
cardClicked 	= zeros(length(cardShown), 1);
mouseData    	= zeros(length(cardShown), 3);
nCardsShown     = length(cardShown);

%% Start the game
% Get Session Time
sessTime        = datestr(now, 'HH:MM:SS');
TrialTime       = cell(length(cardShown),1);
HideCursor;

% Draw the rects to the screen
Priority(MaxPriority(window));
Screen('FillRect', window, cardColorControl, topCard);
Screen('FrameRect', window, frameColor, topCard, frameWidth);
Screen('FillRect', window, cardColors, rects);
Screen('FrameRect', window, frameColor, rects, frameWidth);
Screen('Flip', window, flipTime);
Priority(0);
WaitSecs(topCardDisplay);

for iCard = 1: nCardsShown 
    % Get Trial Time
    TrialTime{iCard}    = datestr(now, 'HH:MM:SS.FFF');
    cardCurrent         = cardShown(iCard);
    
    % Flip the card
    Priority(MaxPriority(window));
    Screen('FillRect', window, cardColorControl, topCard);
    Screen('FrameRect', window, frameColor, topCard, frameWidth);
    % Fill all rects but one
    Screen('FillRect', window, cardColors, rects(:, (1:ncards ~= cardCurrent)));
    Screen('FillRect', window, cardColorControl, rects(:, cardCurrent));
    % Show fixation cross
    imgCrossTex = Screen('MakeTexture', window, imgCross);
    tmp = CenterRectOnPointd(crossSize, rects(1, cardCurrent)+cardSize(3)/2, rects(2, cardCurrent)+cardSize(4)/2);
    tmp = reshape(tmp, 4, 1);
    Screen('DrawTexture', window, imgCrossTex, [], tmp);
    % Show frames
    Screen('FrameRect', window, frameColor, rects, frameWidth);
    Screen('Flip', window, flipTime);
    Screen('Close', imgCrossTex);
    Priority(0);

    % Display the card for a time defined by cardDisplay
    WaitSecs(cardDisplay);
    
end

%% Ask how many cards changed their color up to now
ShowCursor;
nControlAnswers     = 4;
controlAnswers      = round(abs(nCardsShown-nControlAnswers):nCardsShown+nControlAnswers);
controlAnswers      = controlAnswers(controlAnswers~=nCardsShown & controlAnswers~=0);
controlAnswers      = Shuffle([nCardsShown randsample(controlAnswers, 3, 0)]);

controlCardTextSize = 40;
controlCardHeigth   = 100;
controlCardWidth    = controlCardHeigth * (4/3);
controlRects        = zeros(4, nControlAnswers);
yOffset             = 50;

for cc = 1 : nControlAnswers
    controlRects(:, cc) = CenterRectOnPointd([0 0 controlCardWidth controlCardHeigth], cfg_window.center(1), cc*(controlCardHeigth+20)+yOffset);
end
Screen('TextSize', window, 20);               % set text size

Priority(MaxPriority(window));
Screen('FillRect', window, cardColors, controlRects);
Screen('FrameRect', window, frameColor, controlRects, frameWidth);
DrawFormattedText(window, 'Wie viele Karten wurden dunkler?', 'center', yOffset, textDefColor);
Screen('TextSize', window, controlCardTextSize);
for cc = 1 : nControlAnswers
    DrawFormattedText(window, num2str(controlAnswers(cc)), 'center', ...
        (controlRects(4, cc)-(controlCardHeigth/2)-(controlCardTextSize*0.8)), textDefColor);
end
Screen('Flip', window, flipTime);
Priority(0);

mouseOnCard = zeros(nControlAnswers,1);
while ~(sum(mouseOnCard)==1)
    % Runs until a mouse button is pressed
    MousePress      = 0; % initializes flag to indicate no response
    while    ( MousePress==0 ) 
        [x, y, buttons]     = GetMouse();   % wait for a key-press
        % stop loop if the first mouse button is pressed
        if buttons(1)
            MousePress      = buttons(1); % sets to 1 if a button was pressed
            WaitSecs(.01);                % put in small interval to allow other system events
        end
    end

    for cc = 1 : nControlAnswers
        mouseOnCard(cc) = IsInRect(x, y, controlRects(:,cc));
    end
end
mouseOnCard        = find(mouseOnCard);
controlCardCorrect = find(controlAnswers == nCardsShown);

Screen('TextSize', window, 20);               % set text size

Priority(MaxPriority(window));
Screen('FillRect', window, cardColors, controlRects);
Screen('FrameRect', window, frameColor, controlRects, frameWidth);
DrawFormattedText(window, 'Wie viele Karten wurden dunkler?', 'center', yOffset, textDefColor);
Screen('TextSize', window, controlCardTextSize);
if mouseOnCard == controlCardCorrect
    % Correct
    controlCardInds = find(1:nControlAnswers ~= controlCardCorrect);
    for cc = 1 : nControlAnswers-1
    DrawFormattedText(window, num2str(controlAnswers(controlCardInds(cc))), 'center', ...
        (controlRects(4, controlCardInds(cc))-(controlCardHeigth/2)-(controlCardTextSize*0.8)), textDefColor);
    end
    Screen('TextStyle', window, 1);
    DrawFormattedText(window, num2str(controlAnswers(controlCardCorrect)), 'center', ...
        (controlRects(4, controlCardCorrect)-(controlCardHeigth/2)-(controlCardTextSize*0.8)), textColorCorrect);
    DrawFormattedText(window, 'Richtig', controlRects(1,1)+controlTextMargin, (controlRects(4, controlCardCorrect)-(controlCardHeigth/2)-(controlCardTextSize*0.8)), textColorCorrect);
else
    % Incorrect 
    controlCardInds = find((1:nControlAnswers ~= controlCardCorrect) & (1:nControlAnswers ~= mouseOnCard));
    for cc = 1 : nControlAnswers-2
    DrawFormattedText(window, num2str(controlAnswers(controlCardInds(cc))), 'center', ...
        (controlRects(4, controlCardInds(cc))-(controlCardHeigth/2)-(controlCardTextSize*0.8)), textDefColor);
    end
    Screen('TextStyle', window, 1);
    DrawFormattedText(window, num2str(controlAnswers(controlCardCorrect)), 'center', ...
        (controlRects(4, controlCardCorrect)-(controlCardHeigth/2)-(controlCardTextSize*0.8)), textColorCorrect);
    DrawFormattedText(window, num2str(controlAnswers(mouseOnCard)), 'center', ...
        (controlRects(4, mouseOnCard)-(controlCardHeigth/2)-(controlCardTextSize*0.8)), textColorIncorrect);
%     DrawFormattedText(window, 'Richtig', controlRects(1,1)+controlTextMargin, (controlRects(4, controlCardCorrect)-(controlCardHeigth/2)-(controlCardTextSize*0.8)), textColorCorrect);
    DrawFormattedText(window, 'Falsch', controlRects(1,1)+controlTextMargin, (controlRects(4, mouseOnCard)-(controlCardHeigth/2)-(controlCardTextSize*0.8)), textColorIncorrect);
end
Screen('Flip', window, flipTime);
Priority(0);
WaitSecs(controlFeedbackDisplay);

Screen('TextStyle', window, 0);

%% Save session data
SessionTime         = cell(length(cardShown),1);
SessionTime(:)      = {sessTime};
isinterf = (cfg_dlgs.sesstype==3)+1;    % check if interference

run                 = cell(length(cardShown),1);
run(:)              = {iControlRun};
correct             = zeros(length(cardShown),1);
correct(:)          = controlAnswers(controlCardCorrect) - controlAnswers(mouseOnCard) + 1 ;
correct(correct~=1) = 0; % set others incorrect
imageShown          = cell(length(cardShown),1);
imageClicked        = cell(length(cardShown),1);
imageShown(:)       = {nCardsShown};
imageClicked(:)     = {controlAnswers(mouseOnCard)};
coordsShown         = cell(length(cardShown), 1);
for iCard = 1: length(cardShown)
    coordsShown{iCard}      = mt_cards1Dto2D(cardShown(iCard), ncards_x, ncards_y);
end
coordsClicked       = coordsShown;
% save cards shown, cards clicked, mouse click x/y coordinates, reaction time
performance         = table(SessionTime, TrialTime, run, correct, imageShown, imageClicked,  mouseData, coordsShown, coordsClicked);

mt_saveTable(dirRoot, performance)

end