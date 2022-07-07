% subj_num = '1';
% run_num = '1';
%cd /Users/yuanbian/Documents/Spec_ATL/Redboat_Replication/FMRI_PRES;
%pwd = '/Users/yuanbian/Documents/Spec_ATL/Redboat_Replication/FMRI_PRES';
function REDBOAT_FMRI(subj_ID, subj_num,run_num)
%% Make sure inputs are valid
%subj_num is a string

assert(ischar(subj_num), 'subj_num must be a string');

assert(ischar(subj_ID), 'subj_ID must be a string');
 
assert(ischar(run_num), 'run must be a string');

listFolderPath = [pwd '/subject_lists/'];
% materials_filenames = dir(strcat(pwd,'/subject_lists/subject',subj_num,'_*'));

%% Make sure we don't accidentally overwrite a data file
DATA_DIR = fullfile(pwd, 'data');
fileToSave = ['REDBOAT_subject' subj_ID '_*'];
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
backgroundColor = [170 170 170]; % background color
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
TRIALS_PER_RUN = 85; % TRIALS_PER_RUN = 100;
NUM_PRACTICE = 8;

%% set up screen and keyboard
screenNum = max(Screen('Screens'));  %Highest screen number is most likely correct display
windowInfo = PTBhelper('initialize', screenNum);

%UNCOMMENT FOR REAL EXPT
wPtr = windowInfo{1}; %pointer to window on screen that's being referenced
rect = windowInfo{2}; %dimensions of the window
winWidth = rect(3);
winHeight = rect(4);

text_size = 40;
text_font = 'Helvetica'; %'Times New Roman';
Screen('TextSize', wPtr, text_size);
Screen('TextFont', wPtr, text_font);
%[expwindow, rect] = Screen('OpenWindow',screenNum, 1, rect);

rect = rect/2;
disp(rect)
oldEnableFlag = windowInfo{4};
%HideCursor;
%Screen('FillRect',wPtr,backgroundColor); 
Screen('FillRect',wPtr,backgroundColor);             
Screen(wPtr, 'Flip');
PTBhelper('stimText',wPtr,'Loading experiment\n\n(Don''t start yet!)', 30);

%Keyboard
keyboardInfo = PTBhelper('getKeyboardIndex');
kbIdx = keyboardInfo{1};
escapeKey = keyboardInfo{2};
keyNames = KbName('KeyNames');

% read all lists for this subject in a sorted order
runFile = read_list(listFolderPath, subj_num, run_num);

% change the path of materials and results if it's practice
if run_num == '0' 
    TRIALS_PER_RUN = NUM_PRACTICE;
    runFile = [pwd '/practice_materials.csv'];
end

% results
resultsHdr = {'TrialOnset','Word_1st', 'Word_2nd', 'Condition', 'Match', 'Mismatch_Type', 'Image', 'Accuracy', 'RT', 'Dur'};

%results is the table that will hold all of the data we want to save
results = cell(TRIALS_PER_RUN, length(resultsHdr));
results = cell2table(results, 'VariableNames', resultsHdr);

% Present the experiment
RestrictKeysForKbCheck([]);
enableKeys = [KbName('1'), KbName('1!'), KbName('2'), KbName('2@'), KbName(escapeKey)];

if run_num=='0'
% Wait indefinitely until trigger
PTBhelper('stimText',wPtr,'Waiting for trigger...',sentFontSize);
PTBhelper('waitFor','TRIGGER',kbIdx,escapeKey);
end

RestrictKeysForKbCheck(enableKeys);

if run_num=='0'
    PTBhelper('stimText', wPtr, ['Welcome to the words+images experiment.\n\n'...
    'You will now have a chance to practice.\n\n'...
    'Remember: press LEFT for MATCH, and RIGHT for NON-MATCH.\n\n'...
    'Press any key to try a few practice trials.'], instructFontSize);
    PTBhelper('waitUntil',GetSecs+INSTRUCT_DUR,kbIdx,escapeKey);
    WaitSecs(2);
else
    PTBhelper('stimText', wPtr, ['Press any key to start the experiment.'], instructFontSize);
    PTBhelper('waitUntil',GetSecs+INSTRUCT_DUR,kbIdx,escapeKey);
    WaitSecs(2);
end

runOnset = GetSecs; %remains the same
onset = runOnset;   %updates for each trial

%Present each block
try
    %%%%
    wrd_stims = cell(TRIALS_PER_RUN, 2);
    trigger_idx = cell(TRIALS_PER_RUN,1);
    correct_answers = cell(TRIALS_PER_RUN, 1);
    img_stims = cell(TRIALS_PER_RUN, 1);
    run = readtable(runFile);
    for trialIndex = 1:TRIALS_PER_RUN
       if strcmp(run.Condition{trialIndex}, 'FIX')
           % attach images
           img_stims{trialIndex} = 'NA';
           % attach words
           wrd_stims{trialIndex, 1} = 'NA';
           wrd_stims{trialIndex, 2} = 'NA';
           % attach correct answers
           correct_answers{trialIndex} = 'NA';
       else
           % attach images
           img_file = [pwd '/Pics/' run.Image{trialIndex}];
           image = imread(img_file);
           img_stims{trialIndex} = Screen('MakeTexture', wPtr, double(image));
           % attach words
           wrd_stims{trialIndex, 1} = run.Word_1st{trialIndex};
           wrd_stims{trialIndex, 2} = run.Word_2nd{trialIndex};
           % attach correct answers
           correct_answers{trialIndex} = run.Match(trialIndex);
       end
    end
    
    WaitSecs(2);
    % actual trial onset
    onset = GetSecs;

    %Show each trial
    for trialIndex=1:TRIALS_PER_RUN
        if strcmp(run.Condition{trialIndex}, 'FIX')
            trialEndTime = onset + LONG_FIXATION_DUR;
            %fixation (duration 12s)
            PTBhelper('stimText', wPtr, '+', fixFontSize);
            WaitSecs(LONG_FIXATION_DUR);
            onset = trialEndTime;
            results.TrialOnset{trialIndex} =  GetSecs-onset;
            results.Response{trialIndex} = '';
            results.RT{trialIndex} = '';
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
            Screen('FillRect',wPtr,backgroundColor);             
            Screen(wPtr, 'Flip');
            WaitSecs(BLANK_DUR);

            %word1 (300ms)
            PTBhelper('stimText', wPtr, wrd_stims{trialIndex,1}, fixFontSize);
            WaitSecs(WORD_DUR);

            %blank screen (300ms)
            Screen('FillRect',wPtr,backgroundColor);             
            Screen(wPtr, 'Flip');
            WaitSecs(BLANK_DUR);

            %word2 (300ms)
            PTBhelper('stimText', wPtr, wrd_stims{trialIndex,2}, fixFontSize);
            WaitSecs(WORD_DUR);

            %blank screen (300ms)
            Screen('FillRect',wPtr,backgroundColor);             
            Screen(wPtr, 'Flip');
            WaitSecs(BLANK_DUR);

            %target shape (max 2,200ms)
            PTBhelper('stimImage', wPtr, trialIndex, img_stims);

            %request keyboard response from subject
            %need to revise this function
            record_resp  = PTBhelper('waitUntil',trialEndTime,kbIdx,escapeKey);
            remain_time = trialEndTime-GetSecs;
            
            %blank screen 
            Screen('FillRect',wPtr,backgroundColor);             
            Screen(wPtr, 'Flip');
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
    run = readtable(runFile);
    %fill in the rest of the data
    results.Word_1st = reshape(wrd_stims(:, 1),TRIALS_PER_RUN,1);
    results.Word_2nd = reshape(wrd_stims(:, 2),TRIALS_PER_RUN,1);
    results.Condition = run.Condition(1:TRIALS_PER_RUN);
    results.Match = run.Match(1:TRIALS_PER_RUN);
    results.Mismatch_Type = run.Mismatch_Type(1:TRIALS_PER_RUN);
    results.Image = run.Image(1:TRIALS_PER_RUN);
    %Calculate the accuracies
    results.Accuracy = grade_results(results);
    %Save all data
    fileName = strsplit(runFile, '/');
    fileName = fileName(length(fileName));
    fileName = fileName{1};
    if run_num == '0'
        fileToSave = [pwd '/data/REDBOAT_FMRI_' subj_ID '_subject' subj_num '_practice.csv'];
    else
        fileToSave = [pwd '/data/REDBOAT_FMRI_' subj_ID '_' fileName];
    end
    writetable(results, fileToSave);
    disp(strcat('Subj', subj_num, ' finished; data for this run saved to ', fileToSave))

    % end of run instruction
    PTBhelper('stimText', wPtr, ['The current run is now over.\n\n'...
        'Please take a short break and wait for the next run!'], instructFontSize);
    PTBhelper('waitUntil',GetSecs+BREAK_DUR,kbIdx,escapeKey);
    
    Screen('closeAll');
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

function [filename] = read_list(folderPath, subj_num, run_num)
    filename = dir([folderPath '/subject' subj_num '_run' run_num '_order*']);
    filename = [folderPath filename.name];
end

function [response] = decode_key(key)
    response = '';
    if strcmp(int2str(key), '1')
        response = 'match';
    elseif strcmp(int2str(key), '2')
        response = 'mismatch';
    end
end

function [accuracy] = grade_results(results)
    accuracy = int8(cellfun(@strcmp,results.Response, results.Match));
end

end