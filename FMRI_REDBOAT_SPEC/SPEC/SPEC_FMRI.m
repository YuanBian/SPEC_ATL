% subj_ID is a string like FED2019XXXX
% subj_num is the number assigned to the current subject, which determine
% the materials they receive (the materials are pre-generated for each number)
% so if the last subject is '7', you should put '8' for the next subject
% run_num is run number

% example: SPEC_FMRI('FED20191119a', '1', '1')
%subj_ID = 'FED2019';subj_num = '1';run_num = '1';
function SPEC_FMRI(subj_ID, subj_num, run_num)
%% Make sure inputs are valid
%subj_ID is a string

assert(ischar(subj_ID), 'subj_ID must be a string');

assert(ischar(subj_num), 'subj_num must be a string');

assert(ischar(run_num), 'run must be a string');

listFolderPath = [pwd '/subject_lists/'];
% materials_filenames = dir(strcat(pwd,'/subject_lists/subject',subj_ID,'_*'));

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
WORD_DUR = 1;
BLANK_DUR1 = 0.25;
BLANK_DUR2 = 4.5;% 4.5
QUESTION_DUR = 3;
FIXATION_DUR = 0.25;
INSTRUCT_DUR = 600;
ISI = 4;%4
TRIAL_DUR = WORD_DUR+BLANK_DUR1+QUESTION_DUR+BLANK_DUR2+FIXATION_DUR;
BREAK_DUR = 60;


TRIALS_PER_RUN = 48; % TRIALS_PER_RUN = 48;
NUM_PRACTICE = 4; % number of practice trials

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
Screen('FillRect',wPtr,backgroundColor);             
Screen(wPtr, 'Flip');
PTBhelper('stimText',wPtr,'Loading experiment\n\n(Don''t start yet!)', 30);

%Keyboard
keyboardInfo = PTBhelper('getKeyboardIndex');
kbIdx = keyboardInfo{1};
escapeKey = keyboardInfo{2};
keyNames = KbName('KeyNames');

escapeKey = 'Escape';
RestrictKeysForKbCheck([]);
enableKeys = [KbName('1'), KbName('1!'), KbName('2'), KbName('2@'), KbName(escapeKey)];

% RestrictKeysForKbCheck(enableKeys);

% prepare instructions and lists for practice or actual runs 
if run_num=='0'
    TRIALS_PER_RUN = NUM_PRACTICE;
    runFile = [pwd '/practice_materials.csv'];
    
    PTBhelper('stimText', wPtr, ['Welcome to the words+questions experiment.\n\n'...
    'You will now have a chance to practice.\n\n'...
    'Remember: press LEFT for YES, and RIGHT for NO.\n\n'...
    'Press any key to try a few practice trials.'], instructFontSize);
    PTBhelper('waitUntil',GetSecs+INSTRUCT_DUR,kbIdx,escapeKey);
    WaitSecs(2);
else
    runFile = read_list(listFolderPath, subj_num, run_num);
end

% results
resultsHdr = {'TrialOnset', 'PairNumber', 'Condition', 'Noun','Category','Question', 'QuestionIndex', 'Answer', 'ISI', 'Accuracy', 'RT'};

%results is the table that will hold all of the data we want to save
results = cell(TRIALS_PER_RUN, length(resultsHdr));
results = cell2table(results, 'VariableNames', resultsHdr);

% set up experiment materials
ques_stims = cell(1,TRIALS_PER_RUN);
noun_stims = cell(1,TRIALS_PER_RUN);
ISIs = cell(1, TRIALS_PER_RUN);
correct_answers = cell(1, TRIALS_PER_RUN);

% read experiment materials
run = readtable(runFile);
for trialIndex = 1:TRIALS_PER_RUN
   % attach nouns
   ques_stims{trialIndex} = run.Question{trialIndex};
   % attach questions
   noun_stims{trialIndex} = run.Noun{trialIndex};
   % attach ISIs
   ISIs{trialIndex} = run.ISI(trialIndex)/1000;
   % attach correct answers
   correct_answers{trialIndex} = run.Answer(trialIndex);
end

%Present each run
try    
    if run_num~='0'
    % Wait indefinitely until trigger
    PTBhelper('stimText',wPtr,'Waiting for trigger...',sentFontSize);
    PTBhelper('waitFor','TRIGGER',kbIdx,escapeKey);
    end
    RestrictKeysForKbCheck(enableKeys);
    runOnset = GetSecs; %remains the same
    Screen('FillRect',wPtr,backgroundColor);
    Screen(wPtr, 'Flip');
    WaitSecs(4);
    onset = GetSecs;   %updates for each trial

    %Show each trial
    for trialIndex=1:TRIALS_PER_RUN

        ISI = ISIs{trialIndex};

        %Get the trial end time
        trialEndTime = onset + TRIAL_DUR;

        %fixation (duration 250ms)
        PTBhelper('stimText', wPtr, '+', fixFontSize);
        WaitSecs(FIXATION_DUR);

        %blank screen (250ms)
        Screen('FillRect',wPtr,backgroundColor);
        Screen(wPtr, 'Flip');
        WaitSecs(BLANK_DUR1);

        %word (1000ms)
        PTBhelper('stimText', wPtr, noun_stims{trialIndex}, fixFontSize);
        WaitSecs(WORD_DUR);

        %blank screen (500ms)
        Screen('FillRect',wPtr,backgroundColor);
        Screen(wPtr, 'Flip');
        WaitSecs(BLANK_DUR2);

        %question (max 3,000ms)
        PTBhelper('stimText', wPtr, ques_stims{trialIndex}, fixFontSize);

        %request keyboard response from subject
        record_resp  = PTBhelper('waitUntil',trialEndTime,kbIdx,escapeKey); 
        %record_resp  = PTBhelper('waitFor',GetSecs+2,kbIdx,escapeKey); 
        remain_time = trialEndTime-GetSecs;

        %ISI screen (200-700ms)
        Screen('FillRect',wPtr,backgroundColor);
        Screen(wPtr, 'Flip');
        WaitSecs(remain_time+ISI);

        %show blank screen if subject answer before the end of
        %target. 

        %Save data
        %results.TrialOnset(trialIndex) = onset - runOnset;
        key = record_resp{1};
        rt = record_resp{2};
        results.TrialOnset{trialIndex} = onset - runOnset;
        results.Response{trialIndex} = decode_key(key); 
        results.RT{trialIndex} = rt;
        onset = trialEndTime+ISI;
    end
    WaitSecs(2);
    %fill in the rest of the data
    run = readtable(runFile);
    results.Noun = reshape(noun_stims,TRIALS_PER_RUN,1);
    results.Question = reshape(ques_stims,TRIALS_PER_RUN,1);
    results.PairNumber = run.PairNumber(1:TRIALS_PER_RUN);
    results.Condition = run.Condition(1:TRIALS_PER_RUN);
    results.Category = run.Category(1:TRIALS_PER_RUN);
    results.QuestionIndex = run.QuestionIndex(1:TRIALS_PER_RUN);
    results.Answer = cellstr(num2str(run.Answer(1:TRIALS_PER_RUN)));
    results.ISI = run.ISI(1:TRIALS_PER_RUN);
    %Calculate the accuracies
    results.Accuracy = grade_results(results);

    %Save all data
    fileName = strsplit(runFile, '/');
    fileName = fileName{length(fileName)};
    if run_num == '0'
        fileToSave = [pwd '/data/SPEC_FMRI_' subj_ID '_subject' subj_num '_practice.csv'];
    else
        fileToSave = [pwd '/data/SPEC_FMRI_' subj_ID '_' fileName];
    end
    writetable(results, fileToSave);
    %results = [];
    disp(strcat('Subj', subj_ID, ' finished; data for this run saved to ', fileToSave))

    % end of run instruction
%     PTBhelper('stimText', wPtr, ['The current run is now over.\n\n'...
%         'Please take a short break and wait for the next run!'], instructFontSize);
%     PTBhelper('waitUntil',GetSecs+BREAK_DUR,kbIdx,escapeKey);
%     
    Screen('CloseAll');
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


% identify the subject runs, sort them in order
% read each file, and identify the condition, words, image, and ISI

function [filename] = read_list(folderPath, subj_num, run_num)
    filename = dir([folderPath '/subject' subj_num '_run' run_num '_order*']);
    filename = [folderPath filename.name];
end

function [response] = decode_key(key)
    response = '';
    if strcmp(int2str(key), '1')
        response = '1';
    elseif strcmp(int2str(key), '2')
        response = '0';
    end
end

function [accuracy] = grade_results(results)
    accuracy = int8(cellfun(@strcmp,results.Response, results.Answer));
end

end
