cd /Users/yuanbian/Downloads/Spec_ATL/Spec/MEG_PRES;
subjID = '1';

pwd = '/Users/yuanbian/Downloads/Spec_ATL/Spec';

%% Make sure inputs are valid
%subjID is a string

assert(ischar(subjID), 'subjID must be a string');

listFolderPath = [pwd '/subject_lists/'];
% materials_filenames = dir(strcat(pwd,"/subject_lists/subject",subjID,"_*"));

%% Make sure we don't accidentally overwrite a data file
DATA_DIR = fullfile(pwd, 'data');
fileToSave = strcat('SPEC_subject', subjID, '_*');
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
instructFontSize = 30;  %instructions screen before each block
helpFontSize = 20;      %instructions that appear during each trial
fixFontSize = 40;       %fixation cross
bg_color = [10 10 10]; % background color
fg_color = [255 255 255]; % text color


%% set up presentation duration parameters
WORD_DUR = 0.3;
BLANK_DUR = 0.3;
QUESTION_DUR = 2.2;
FIXATION_DUR = 0.3;
INSTRUCT_DUR = 600;
TRIAL_DUR = 4.2;
BREAK_DUR = 60;

%% set up materials
TRIALS_PER_BLOCK = 48; % TRIALS_PER_BLOCK = 100;
NUM_BLOCK = 4;%4 blocks: COMP_1W, COMP_2W, LIST_1W, LIST_2W

%% set up presentation instruction for each tasks
SPEC_INSTRUCTION = ['In each block, you will first see a word appearing on the screen for a very short time. \n'...
'Then you will answer a YES/NO question based on the word you see.\n'...
'You only have 2.2 second to respond after the image is shown.\n'];

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
sortedFiles = read_list(listFolderPath, subjID);

% set up experiment images
ques_stims = {};
noun_stims = cell(NUM_BLOCK, TRIALS_PER_BLOCK);
trigger_idx = cell(NUM_BLOCK, TRIALS_PER_BLOCK);
ISIs = cell(NUM_BLOCK, TRIALS_PER_BLOCK);
correct_answers = cell(NUM_BLOCK, TRIALS_PER_BLOCK);

for blockIndex = 1:NUM_BLOCK
    blockFile = sortedFiles(blockIndex);
    block = readtable(blockFile);
    for trialIndex = 1:TRIALS_PER_BLOCK
       % attach nouns
       ques_stims{blockIndex, trialIndex} = block.Noun{trialIndex};
       % attach questions
       noun_stims{blockIndex, trialIndex} = block.Question{trialIndex};
       % attach ISIs
       ISIs{blockIndex,trialIndex} = block.ISI(trialIndex)/1000;
       % attach triggers
       trigger_idx{blockIndex,trialIndex} = decide_trigger(block.Condition{trialIndex});
       % attach correct answers
       correct_answers{blockIndex,trialIndex} = block.Match(trialIndex);
    end
end

% results
resultsHdr = {'TrialOnset', "PairNumber", "Condition","Noun","Category","Question", "QuestionIndex", "Answer", "ISI", 'Accuracy', 'RT'};

%results is the table that will hold all of the data we want to save
results = cell(TRIALS_PER_BLOCK, length(resultsHdr));
results = cell2table(results, 'VariableNames', resultsHdr);

%opening instructions 
PTBhelper('stimText', wPtr, ['Welcome to our experiment!\n ' ...
    'Please press any button to read through these instructions!'], instructFontSize);
PTBhelper('waitUntil',GetSecs+INSTRUCT_DUR,kbIdx,escapeKey);
WaitSecs(1);
PTBhelper('stimText', wPtr, ['There will be 4 blocks and they have the same kind of task.'], instructFontSize);
PTBhelper('waitUntil',GetSecs+INSTRUCT_DUR,kbIdx,escapeKey);
WaitSecs(1);
PTBhelper('stimText', wPtr, ['In each block, you will first see a word appearing on the screen for a very short time. \n'...
'Then you will answer a YES/NO question based on the word you see.\n'...
'You only have 2.2 second to respond after the image is shown.\n'], instructFontSize);
PTBhelper('waitUntil',GetSecs+INSTRUCT_DUR,kbIdx,escapeKey);
WaitSecs(1);
PTBhelper('stimText', wPtr, ['When the "+" is shown, it indicates the start of the trial.\n\n'...
    'On each trial, press the LEFT button to respond YES and the RIGHT button to respond NO'], instructFontSize);
PTBhelper('waitUntil',GetSecs+INSTRUCT_DUR,kbIdx,escapeKey);
WaitSecs(1);


% Present the experiment
RestrictKeysForKbCheck([]);
enableKeys = [KbName('1'), KbName('1!'), KbName('2'), KbName('2@'), KbName(escapeKey)];

%% initialize trigger [new stim comp]
% comment this when simulating presentation locally
%     p.usetrigs = 0;
%     if(p.usetrigs)
%         try
%             p.di = DaqDeviceIndex;
%             DaqDConfigPort(p.di,0,0);
%             DaqDOut(p.di,0,0);%clear trig
%         catch
%             disp('Error: USB-1208FS device not connected');
%             return;
%         end
%     else
%         p.di = 0;
%     end

RestrictKeysForKbCheck(enableKeys);

runOnset = GetSecs; %remains the same
onset = runOnset;   %updates for each trial

%Present each block
try
    for blockIndex = 1:NUM_BLOCK
        % get file name
        fileName = strsplit(sortedFiles(blockIndex), '/');
        fileName = fileName(length(fileName));
        fileToSave = strcat(pwd, "/data/REDBOAT_", fileName);
        
        blockFile = sortedFiles(blockIndex);

        % show instruction
        PTBhelper('stimText', wPtr, SPEC_INSTRUCTION, instructFontSize);
        instructEndTime = onset + INSTRUCT_DUR;
        PTBhelper('waitUntil',instructEndTime,kbIdx,escapeKey);
        % actual trial onset
        onset = GetSecs;

        %Show each trial
        for trialIndex=1:TRIALS_PER_BLOCK

            %fixation (duration 300ms)
            %blank screen (300ms)
            %word (300ms)
            %blank screen (300ms)
            %question (max 3,000ms)

            %SEND TRIGGER
            %WaitSecs(0.026);
            %uncomment this in real exp
            %send_trigger(p, trigger_idx{blockIndex, trialIndex},0.004);

            ISI = ISIs{blockIndex, trialIndex};
            
            %Get the trial end time
            trialEndTime = onset + TRIAL_DUR;

            %fixation (duration 300ms)
            PTBhelper('stimText', wPtr, '+', fixFontSize);
            WaitSecs(FIXATION_DUR);

            %blank screen (300ms)
            PTBhelper('stimImage',wPtr,'WHITE');
            WaitSecs(BLANK_DUR);

            %word1 (300ms)
            PTBhelper('stimText', wPtr, noun_stims{blockIndex, trialIndex}, fixFontSize);
            WaitSecs(WORD_DUR);

            %blank screen (300ms)
            PTBhelper('stimImage',wPtr,'WHITE');
            WaitSecs(BLANK_DUR);

            %question (max 2,200ms)
            PTBhelper('stimText', wPtr, ques_stims{blockIndex, trialIndex}, fixFontSize);
            
            %request keyboard response from subject
            record_resp  = PTBhelper('waitUntil',trialEndTime,kbIdx,escapeKey); 
            %record_resp  = PTBhelper('waitFor',GetSecs+2,kbIdx,escapeKey); 
            remain_time = trialEndTime-GetSecs;

            %blank screen (300ms)
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
        %fill in the rest of the data
        blockFile = sortedFiles(blockIndex);
        block = readtable(blockFile);
        results.Noun = reshape(noun_stims(blockIndex, :, 1),TRIALS_PER_BLOCK);
        results.Question = reshape(ques_stims(blockIndex, :, 2),TRIALS_PER_BLOCK);
        results.PairNumber = block.PairNumber(1:TRIALS_PER_BLOCK);
        results.Condition = block.Condition(1:TRIALS_PER_BLOCK);
        results.Category = block.Category(1:TRIALS_PER_BLOCK);
        results.QuestionIndex = block.QuestionIndex(1:TRIALS_PER_BLOCK);
        results.Answer = block.ISI(1:TRIALS_PER_BLOCK);
        results.ISI = block.ISI(1:TRIALS_PER_BLOCK);
        %Calculate the accuracies
        results.Accuracy = grade_results(results);
        
        %Remove used stimuli
%         wrd_stims(blockIndex, :, :) = [];
%         img_stims(blockIndex, :) = [];
%         block = [];
        %Save all data
        writetable(results, fileToSave);
        %results = [];
        disp(strcat('Subj', subjID, ' finished; data for this run saved to ', fileToSave))
        
        %interblock instructions
        % get the name of the next block
        if blockIndex<4
            PTBhelper('stimText', wPtr, ['Please take a short break (1 minute).\n'...
                'Press the left button to continue.'], instructFontSize);
            PTBhelper('waitUntil',GetSecs+BREAK_DUR,kbIdx,escapeKey);
            WaitSecs(1);
        elseif blockIndex==4
            PTBhelper('stimText', wPtr, ['The experiment is now over. Thank you for your participation!\n'...
                'Please lay still until the experimenter opens the door!'], instructFontSize);
            PTBhelper('waitUntil',GetSecs+BREAK_DUR,kbIdx,escapeKey);
        end
    end
    
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

function [sortedList] = read_list(folderPath, subjID)
    filenames = [];
    files = dir(strcat(folderPath,"/subject", subjID,"_*"));
    for K = 1 : length(files)
        filenames = [filenames; [folderPath files(K).name]];
    end
    sortedList = sort(string(filenames));
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
    accuracy = [string(results.Response)]== [string(results.Answer)];
end

function [trigger] = decide_trigger(condition)
    trigger = '';
    if strcmp(condition, 'High')
        trigger = 1;
    elseif strcmp(condition, 'Low')
        trigger = 2;
    end
end
