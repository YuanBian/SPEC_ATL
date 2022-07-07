cd /Users/yuanbian/Documents/Spec_ATL/Redboat_Replication/FMRI_PRES;
subjID = '1';
pwd = '/Users/yuanbian/Documents/Spec_ATL/Redboat_Replication/FMRI_PRES';

%function Redboat_fMRI(subjID, run_num)
%% Make sure inputs are valid
%subjID is a string

assert(ischar(subjID), 'subjID must be a string');

practice_file = [pwd '/practice_materials.csv'];

%% Make sure we don't accidentally overwrite a data file
DATA_DIR = fullfile(pwd, 'data');
fileToSave = strcat('REDBOAT_subject', subjID, '_*');
fileToSave = fullfile(DATA_DIR, fileToSave);

% Error message if data file already exists.
if ~isempty(dir(fileToSave))
    str = input('The data file already exists for this subject! Overwrite? (y/n)','s');
    if ~isequal(str,'y')
        error('myfuns:REDBOAT:DataFileAlreadyExists', ...
              'The data file already exists for this subject!');
    end
end


%% Set display options
%Font sizes
sentFontSize = 40;      %stimuli sentences
instructFontSize = 30;  %instructions screen before each run
helpFontSize = 20;      %instructions that appear during each trial
fixFontSize = 40;       %fixation cross
bg_color = [10 10 10]; % background color
fg_color = [255 255 255]; % text color


%% set up presentation duration parameters
WORD_DUR = 0.3;
BLANK_DUR = 0.3;
TARGET_DUR = 2.2;
FIXATION_DUR = 0.3;
LONG_FIXATION_DUR = 12;
INSTRUCT_DUR = 600;
TRIAL_DUR = 4;
BREAK_DUR = 200;

%% set up materials
NUM_PRACTICE = 13; % NUM_PRACTICE = 100;
NUM_PRACTICE = 13;

%% set up screen and keyboard
screenNum = max(Screen('Screens'));  %Highest screen number is most likely correct display
windowInfo = PTBhelper('initialize', screenNum);

%UNCOMMENT FOR REAL EXPT
wPtr = windowInfo{1}; %pointer to window on screen that's being referenced
rect = windowInfo{2}; %dimensions of the window
winWidth = rect(3);
winHeight = rect(4);

%[expwindow, rect] = Screen('OpenWindow',screenNum, 1, rect);

rect = rect/2;
disp(rect)
oldEnableFlag = windowInfo{4};
%HideCursor;
PTBhelper('stimImage',wPtr,'WHITE');
PTBhelper('stimText',wPtr,'Loading experiment\n\n(Don''t start yet!)', 30);

%Keyboard
keyboardInfo = PTBhelper('getKeyboardIndex');
kbIdx = keyboardInfo{1};
escapeKey = keyboardInfo{2};
keyNames = KbName('KeyNames');

% results
resultsHdr = {'TrialOnset','Word_1st', 'Word_2nd', 'Condition', 'Match', 'Mismatch_Type', 'Image', 'Accuracy', 'RT', 'Dur'};

%results is the table that will hold all of the data we want to save
results = cell(NUM_PRACTICE, length(resultsHdr));
results = cell2table(results, 'VariableNames', resultsHdr);

% Present the experiment
RestrictKeysForKbCheck([]);
enableKeys = [KbName('1'), KbName('1!'), KbName('2'), KbName('2@'), KbName(escapeKey)];

%% initialize trigger [new stim comp]
% comment this when simulating presentation locally
% p.usetrigs = 0;
% if(p.usetrigs)
%     try
%         p.di = DaqDeviceIndex;
%         DaqDConfigPort(p.di,0,0);
%         DaqDOut(p.di,0,0);%clear trig
%     catch
%         disp('Error: USB-1208FS device not connected');
%         return;
%     end
% else
%     p.di = 0;
% end

RestrictKeysForKbCheck(enableKeys);

runOnset = GetSecs; %remains the same
onset = runOnset;   %updates for each trial

% results
practice_resultsHdr = {'TrialOnset', 'Noun','Question', 'Answer', 'ISI', 'Accuracy', 'RT'};
%results is the table that will hold all of the data we want to save
practice_results = cell(4, length(practice_resultsHdr));
practice_results = cell2table(practice_results, 'VariableNames', practice_resultsHdr);

% actual trial onset
onset = GetSecs;
runOnset = onset;
practiceToSave = strcat(pwd, "/data/SPEC_", "subject",subjID,"_practice.csv");
try
    %%%%
    wrd_stims = cell(NUM_PRACTICE, 2);
    trigger_idx = cell(NUM_PRACTICE);
    correct_answers = cell(NUM_PRACTICE, 1);
    img_stims = cell(1, NUM_PRACTICE);
    practice = readtable(practice_file);
    for trialIndex = 1:NUM_PRACTICE
       if practice.Condition{trialIndex}=="FIX"
           % attach images
           img_stims{trialIndex} = "";
           % attach words
           wrd_stims{trialIndex, 1} = "";
           wrd_stims{trialIndex, 2} = "";
           % attach correct answers
           correct_answers{trialIndex} = "";
       else
           % attach images
           img_file = [pwd '/Pics/' run.Image{trialIndex}];
           image = imread(img_file);
           img_stims{trialIndex} = Screen('MakeTexture', wPtr, double(image));
           % attach words
           wrd_stims{trialIndex, 1} = practice.Word_1st{trialIndex};
           wrd_stims{trialIndex, 2} = practice.Word_2nd{trialIndex};
           % attach correct answers
           correct_answers{trialIndex} = practice.Match(trialIndex);
       end
    end

    WaitSecs(2);
    % actual trial onset
    onset = GetSecs;

    %Show each trial
    for trialIndex=1:NUM_PRACTICE
        if run.Condition{trialIndex}=="FIX"
            trialEndTime = onset + LONG_FIXATION_DUR;
            %fixation (duration 12s)
            PTBhelper('stimText', wPtr, '+', fixFontSize);
            WaitSecs(LONG_FIXATION_DUR);
            onset = trialEndTime;
            key = "";
            rt = "";
            results.TrialOnset{trialIndex} =  GetSecs-onset;
            results.Response{trialIndex} = "";
            results.RT{trialIndex} = "";
            results.Dur{trialIndex} = GetSecs-onset;
            onset = trialEndTime;
        else
            %fixation (duration 300ms)
            %blank screen (300ms)
            %word1 (300ms)
            %blank screen (300ms)
            %word2 (300ms)
            %blank screen (300ms)
            %target shape (max 2,200ms)

            %Get the trial end time
            trialEndTime = onset + TRIAL_DUR;

            %fixation (duration 300ms)
            PTBhelper('stimText', wPtr, '+', fixFontSize);

            %SEND TRIGGER
            WaitSecs(FIXATION_DUR);

            %blank screen (300ms)
            PTBhelper('stimImage',wPtr,'WHITE');
            WaitSecs(BLANK_DUR);

            %word1 (300ms)
            PTBhelper('stimText', wPtr, wrd_stims{trialIndex,1}, fixFontSize);
            WaitSecs(WORD_DUR);

            %blank screen (300ms)
            PTBhelper('stimImage',wPtr,'WHITE');
            WaitSecs(BLANK_DUR);

            %word2 (300ms)
            PTBhelper('stimText', wPtr, wrd_stims{trialIndex,2}, fixFontSize);
            WaitSecs(WORD_DUR);

            %blank screen (300ms)
            PTBhelper('stimImage',wPtr,'WHITE');
            WaitSecs(BLANK_DUR);

            %target shape (max 2,200ms)
            PTBhelper('stimImage', wPtr, trialIndex, img_stims);

            %request keyboard response from subject
            %need to revise this function
            record_resp  = PTBhelper('waitUntil',trialEndTime,kbIdx,escapeKey);
            remain_time = trialEndTime-GetSecs;
            
            %blank screen 
            PTBhelper('stimImage',wPtr,'WHITE');
            WaitSecs(remain_time);

            %show blank screen if subject answer before the end of
            %target. 

            %Save data
            key = record_resp{1};
            rt = record_resp{2};
            results.TrialOnset{trialIndex} = onset - runOnset;
            results.Response{trialIndex} = decode_key(key);
            results.RT{trialIndex} = rt;
            results.Dur{trialIndex} = GetSecs-onset;
            onset = trialEndTime;
        end
    end
    %fill in the rest of the data
    results.Word_1st = reshape(wrd_stims(:, 1),NUM_PRACTICE,1);
    results.Word_2nd = reshape(wrd_stims(:, 2),NUM_PRACTICE,1);
    results.Condition = practice.Condition(1:NUM_PRACTICE);
    results.Match = practice.Match(1:NUM_PRACTICE);
    results.Mismatch_Type = practice.Mismatch_Type(1:NUM_PRACTICE);
    results.Image = run.Image(1:NUM_PRACTICE);
    %Calculate the accuracies
    results.Accuracy = grade_results(results);

    %Save all data
    fileName = strsplit(runFile, '/');
    fileName = fileName(length(fileName));
    fileToSave = strcat(pwd, "/data/REDBOAT_FMRI_", fileName);
    writetable(results, fileToSave);
    disp(strcat('Subj', subjID, ' finished; data for this run saved to ', fileToSave))

    % end of run instruction
    PTBhelper('stimText', wPtr, ['The current run is now over.\n\n'...
        'Please take a short break and wait for the next run!'], instructFontSize);
    PTBhelper('waitUntil',GetSecs+BREAK_DUR,kbIdx,escapeKey);
    
    ShowCursor;

catch errorInfo                
    %Save all data
    writetable(results, fileToSave);

    Screen('CloseAll');
    ShowCursor;
    fprintf('%s%s\n', 'error message: ', errorInfo.message)
end

%Restore the old level.
Screen('Preference','SuppressAllWarnings',oldEnableFlag);

%end
% identify the subject runs, sort them in order
% read each file, and identify the condition, words, image

function [filename] = read_list(folderPath, subjID, run_num)
    filename = dir(strcat(folderPath,"/subject", subjID,"_run",run_num, "_order*"));
    filename = [folderPath filename.name];
end

function [response] = decode_key(key)
    response = '';
    if strcmp(string(key), '1')
        response = 'match';
    elseif strcmp(string(key), '2')
        response = 'mismatch';
    end
end

function [accuracy] = grade_results(results)
    accuracy = [string(results.Response)]== [string(results.Match)];
end

