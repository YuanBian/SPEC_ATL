
% initialization script

%clear previous variables
clc;
Screen('CloseAll')

%get subject name
subjID = input('Name of subject: ','s');

%initialize button responses
KbName('UnifyKeyNames');
escapeKey = KbName('ESCAPE');

%check Java
warning off
PsychJavaTrouble;
warning on

%initialize functions
dummy=GetSecs;  % Force GetSecs and WaitSecs into memory to avoid latency later on:
WaitSecs(0.1);

%OpenGL support
AssertOpenGL;

%set screen
screens=Screen('Screens');
screenNumber=max(screens);
screenNumber = 1;

% Open a double buffered window and draw a white (or other) background to front and back buffers
[p.whandle, p.wRect]=Screen('OpenWindow',screenNumber, 0,[],32,2); %fullsize
white=WhiteIndex(screenNumber); % returns as default the mean white value of screen
p.background_color= 128;
%p.background_color = 0;
Screen('FillRect',p.whandle,p.background_color ); %black screen
Screen('Flip', p.whandle);
 
% set Text properties (all Screen functions must be called after screen)
Screen('TextSize', p.whandle, p.text_size);
Screen('TextFont', p.whandle, p.text_font);
Screen('TextStyle',p.whandle,32);

% set priority - also set after Screen init
priorityLevel=MaxPriority(p.whandle);
Priority(priorityLevel);

%center of screen
p.xCenter = p.wRect(3)/2;
p.yCenter = p.wRect(4)/2;

%screen refresh rate
p.refreshRate= Screen('GetFlipInterval', p.whandle);
p.flashDuration=80*p.refreshRate;

%initialize triggers

p.usetrigs = 1;
if(p.usetrigs)
    p.di = DaqDeviceIndex;
    DaqDConfigPort(p.di,0,0);
    DaqDOut(p.di,0,0); %clear trig
else
    p.di=0;
end
