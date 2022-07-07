% cd /Users/yuanbian/Downloads/Spec_ATL/Spec/FMRI_PRES;
% subj_ID = '1';
% subj_num = '1';
% run_num = '1';
% pwd = '/Users/yuanbian/Downloads/Spec_ATL/Spec/FMRI_PRES';

function FMRI_SPEC(subj_ID, subj_num, run_num)
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
bg_color = [10 10 10]; % background color
fg_color = [255 255 255]; % text color


%% set up presentation duration parameters
WORD_DUR = 1;
BLANK_DUR1 = 0.25;
BLANK_DUR2 = 4.5;
QUESTION_DUR = 3;
FIXATION_DUR = 0.25;
INSTRUCT_DUR = 600;
ISI = 4;
TRIAL_DUR = WORD_DUR+BLANK_DUR1+QUESTION_DUR+BLANK_DUR2+FIXATION_DUR;
BREAK_DUR = 60;

%% set up materials
TRIALS_PER_RUN = 5; % TRIALS_PER_RUN = 48;
NUM_PRACTICE = 4; % number of practice trials

%% set up presentation instruction for each tasks
SPEC_INSTRUCTION = ['Instruction Reminder: \nYou will first see a word appearing on the screen for a very short time. \n'...
'Then you will answer a YES/NO question based on the word you see.\n'...
'You only have 3 second to respond after the question is shown.\n\n'...
'Press left button to START.'];

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

% read all lists for this subject in a sorted order
runFile = read_list(listFolderPath, subj_num, run_num);

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


% results
resultsHdr = {'TrialOnset', 'PairNumber', 'Condition', 'Noun','Category','Question', 'QuestionIndex', 'Answer', 'ISI', 'Accuracy', 'RT'};

%results is the table that will hold all of the data we want to save
results = cell(4, length(resultsHdr));
results = cell2table(results, 'VariableNames', resultsHdr);

%opening instructions 
PTBhelper('stimText', wPtr, ['Welcome to the words+questions experiment.\n\n'], instructFontSize);
PTBhelper('waitUntil',GetSecs+INSTRUCT_DUR,kbIdx,escapeKey);
WaitSecs(2);
PTBhelper('stimText', wPtr, ['There will be 4 runs in total and they have the same kind of task.'], instructFontSize);
PTBhelper('waitUntil',GetSecs+INSTRUCT_DUR,kbIdx,escapeKey);
WaitSecs(1);
PTBhelper('stimText', wPtr, ['In each run, you will first see a word appearing on the screen for a very short time. \n'...
'Then you will answer a YES/NO question based on the word you see.\n'...
'You only have 3 second to respond after the question is shown.\n\n'...
'After you input your answer, the screen will turn blank.'], instructFontSize);
PTBhelper('waitUntil',GetSecs+INSTRUCT_DUR,kbIdx,escapeKey);
WaitSecs(1);
PTBhelper('stimText', wPtr, ['When the '+' is shown, it indicates the start of the trial.\n\n'...
    'On each trial, press the LEFT button to respond YES and the RIGHT button to respond NO\n\n'], instructFontSize);
PTBhelper('waitUntil',GetSecs+INSTRUCT_DUR,kbIdx,escapeKey);
WaitSecs(1);
PTBhelper('stimText', wPtr, ['You will now have a chance to practice.\n\n'...
    'Remember: press LEFT for YES, and RIGHT for NO.\n\n A reminder about the answer key will appear with each question.\n\n'...
    'Press the LEFT key to try a few practice trials.'], instructFontSize);
PTBhelper('waitUntil',GetSecs+INSTRUCT_DUR,kbIdx,escapeKey);
WaitSecs(2);


% make practice trials
RestrictKeysForKbCheck([]);
enableKeys = [KbName('1'), KbName('1!'), KbName('2'), KbName('2@'), KbName(escapeKey)];
RestrictKeysForKbCheck(enableKeys);
% results
practice_resultsHdr = {'TrialOnset', 'Noun','Question', 'Answer', 'ISI', 'Accuracy', 'RT'};
%results is the table that will hold all of the data we want to save
practice_results = cell(4, length(practice_resultsHdr));
practice_results = cell2table(practice_results, 'VariableNames', practice_resultsHdr);

PRACTICE_WORDS = {'professor', 'hair', 'faucet', 'oatmeal'};
PRACTICE_QUESTIONS = {'Is it alive?', 'Does it make sounds?', 'Can you find it in the wild?', 'Can you eat or drink it?'};
PRACTICE_ANSWERS = {1,0,0,1};
% actual trial onset
onset = GetSecs;
runOnset = onset;
practiceToSave = [pwd '/data/SPEC_' 'subject' subj_ID '_practice.csv'];
for trialIndex=1:NUM_PRACTICE
    ISI = 4;
    
    %fixation (duration 250ms)
    %blank screen (250ms)
    %word (1000ms)
    %blank screen (500ms)
    %question (max 3,000ms)
        
    %Get the trial end time
    trialEndTime = onset + TRIAL_DUR;

    %fixation (duration 250ms)
    PTBhelper('stimText', wPtr, '+', fixFontSize);
    WaitSecs(FIXATION_DUR);

    %blank screen (250ms)
    PTBhelper('stimImage',wPtr,'WHITE');
    WaitSecs(BLANK_DUR1);

    %word (1000ms)
    PTBhelper('stimText', wPtr, PRACTICE_WORDS{trialIndex}, fixFontSize);
    WaitSecs(WORD_DUR);

    %blank screen (500ms)
    PTBhelper('stimImage',wPtr,'WHITE');
    WaitSecs(BLANK_DUR2);

    %question (max 3,000ms)
    PTBhelper('stimText', wPtr, PRACTICE_QUESTIONS{trialIndex}, fixFontSize);

    %request keyboard response from subject
    record_resp  = PTBhelper('waitUntil',trialEndTime,kbIdx,escapeKey); 
    %record_resp  = PTBhelper('waitFor',GetSecs+2,kbIdx,escapeKey); 
    remain_time = trialEndTime-GetSecs;

    %ISI screen (4s)
    PTBhelper('stimImage',wPtr,'WHITE');
    WaitSecs(remain_time+ISI);

    %show blank screen if subject answer before the end of
    %target. 

    %Save data
    %results.TrialOnset(trialIndex) = onset - runOnset;
    key = record_resp{1};
    rt = record_resp{2};
    practice_results.TrialOnset{trialIndex} = onset - runOnset;
    practice_results.Response{trialIndex} = decode_key(key);
    practice_results.RT{trialIndex} = rt;
    % check if their response is correct
    practice_results.Accuracy{trialIndex} = PRACTICE_ANSWERS{trialIndex}==decode_key(key);
    onset = trialEndTime+ISI;
    if mod(trialIndex, 2)==0 
        PTBhelper('stimText', wPtr, 'A short break. Please blink as needed.\n\n Press the LEFT key to continue.', fixFontSize);
        PTBhelper('waitUntil',onset+BREAK_DUR,kbIdx,escapeKey); 
        onset = onset+BREAK_DUR;
    end
end
% write practice response to files
practice_results.ISI = {ISI*1000;ISI*1000;ISI*1000;ISI*1000};
practice_results.Answer = reshape(PRACTICE_ANSWERS,4,1);
practice_results.Noun = reshape(PRACTICE_WORDS,4,1);
practice_results.Question = reshape(PRACTICE_QUESTIONS,4,1);
writetable(practice_results, practiceToSave);

PTBhelper('stimText', wPtr, ['That''s it for practice!\n\n'...
    'Please blink a few times now. \n\nRemember: we ask you to try not to blink during the experiment.\n\n'...
    'When you are ready, press the LEFT key to start.\n\n'], instructFontSize);
PTBhelper('waitUntil',GetSecs+INSTRUCT_DUR,kbIdx,escapeKey);
WaitSecs(1);

% practice trials end

% Present the experiment
RestrictKeysForKbCheck([]);
enableKeys = [KbName('1'), KbName('1!'), KbName('2'), KbName('2@'), KbName(escapeKey)];

if run_num=='0'
% Wait indefinitely until trigger
PTBhelper('stimText',wPtr,'Waiting for trigger...',sentFontSize);
PTBhelper('waitFor','TRIGGER',kbIdx,escapeKey);
end

RestrictKeysForKbCheck(enableKeys);

runOnset = GetSecs; %remains the same
onset = runOnset;   %updates for each trial

%Present each run
try

    %Show each trial
    for trialIndex=1:TRIALS_PER_RUN

        %fixation (duration 250ms)
        %blank screen (250ms)
        %word (1000ms)
        %blank screen (500ms)
        %question (max 3,000ms)
        %ISI (trial dependent)

        %SEND TRIGGER
        %WaitSecs(0.026);
        %uncomment this in real exp

        ISI = ISIs{trialIndex};

        %Get the trial end time
        trialEndTime = onset + TRIAL_DUR;

        %fixation (duration 250ms)
        PTBhelper('stimText', wPtr, '+', fixFontSize);
        WaitSecs(FIXATION_DUR);

        %blank screen (250ms)
        PTBhelper('stimImage',wPtr,'WHITE');
        WaitSecs(BLANK_DUR1);

        %word (1000ms)
        PTBhelper('stimText', wPtr, noun_stims{trialIndex}, fixFontSize);
        WaitSecs(WORD_DUR);

        %blank screen (500ms)
        PTBhelper('stimImage',wPtr,'WHITE');
        WaitSecs(BLANK_DUR2);

        %question (max 3,000ms)
        PTBhelper('stimText', wPtr, ques_stims{trialIndex}, fixFontSize);

        %request keyboard response from subject
        record_resp  = PTBhelper('waitUntil',trialEndTime,kbIdx,escapeKey); 
        %record_resp  = PTBhelper('waitFor',GetSecs+2,kbIdx,escapeKey); 
        remain_time = trialEndTime-GetSecs;

        %ISI screen (200-700ms)
        PTBhelper('stimImage',wPtr,'WHITE');
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
    % wait 2 sec before starting the trial
    WaitSecs(2);
    %fill in the rest of the data
    run = readtable(runFile);
    results.Noun = reshape(noun_stims,TRIALS_PER_RUN,1);
    results.Question = reshape(ques_stims,TRIALS_PER_RUN,1);
    results.PairNumber = run.PairNumber(1:TRIALS_PER_RUN);
    results.Condition = run.Condition(1:TRIALS_PER_RUN);
    results.Category = run.Category(1:TRIALS_PER_RUN);
    results.QuestionIndex = run.QuestionIndex(1:TRIALS_PER_RUN);
    results.Answer = run.Answer(1:TRIALS_PER_RUN);
    results.ISI = run.ISI(1:TRIALS_PER_RUN);
    %Calculate the accuracies
    results.Accuracy = grade_results(results);

    %Save all data
    fileName = strsplit(runFile, '/');
    fileName = fileName(length(fileName));
    fileToSave = [pwd '/data/REDBOAT_FMRI_' fileName];
    writetable(results, fileToSave);
    %results = [];
    disp(strcat('Subj', subj_ID, ' finished; data for this run saved to ', fileToSave))

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


% identify the subject runs, sort them in order
% read each file, and identify the condition, words, image, and ISI

function [filename] = read_list(folderPath, subj_num, run_num)
    filename = dir([folderPath '/subject' subj_num '_run' run_num '_order*']);
    filename = [folderPath filename.name];
end

function [response] = decode_key(key)
    response = '';
    if strcmp(string(key), '1')
        response = 1;
    elseif strcmp(string(key), '2')
        response = 0;
    end
end

function [accuracy] = grade_results(results)
    accuracy = int8(cellfun(@strcmp,results.Response, results.Answer));
end

end
