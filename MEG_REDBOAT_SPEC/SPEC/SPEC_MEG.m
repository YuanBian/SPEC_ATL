function SPEC_MEG()
subj_ID = 'FED_MEG_20200212a';
subj_num = '1';

%% Make sure inputs are valid
%subj_ID is a string

assert(ischar(subj_ID), 'subj_ID must be a string');

listFolderPath = [pwd '/subject_lists/'];
% materials_filenames = dir(strcat(pwd,'/subject_lists/subject',subj_ID,'_*'));

%% Make sure we don't accidentally overwrite a data file
DATA_DIR = fullfile(pwd, 'data');
fileToSave = strcat('SPEC_subject', subj_ID, '_*');
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
BLANK_DUR2 = 0.5;
QUESTION_DUR = 3;%3
FIXATION_DUR = 0.25;
INSTRUCT_DUR = 600;
TRIAL_DUR = FIXATION_DUR+BLANK_DUR1+WORD_DUR+BLANK_DUR2+QUESTION_DUR;%5
BREAK_DUR = 60;
PROJ_DELAY = 0.026;

%% set up materials
TRIALS_PER_RUN = 48; % TRIALS_PER_RUN = 48;
NUM_RUN = 4;%4 runs: COMP_1W, COMP_2W, LIST_1W, LIST_2W
NUM_PRACTICE = 4; % number of practice trials

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
% Screen('FillRect',wPtr,backgroundColor);
Screen('FillRect',wPtr,backgroundColor);
%DrawFormattedText(wPtr,'test')
PTBhelper('stimText',wPtr,'Loading experiment\n\n(Don''t start yet!)', 30);

%Keyboard
keyboardInfo = PTBhelper('getKeyboardIndex');
kbIdx = keyboardInfo{1};
escapeKey = keyboardInfo{2};
keyNames = KbName('KeyNames');

% read all lists for this subject in a sorted order
sortedFiles = read_list(listFolderPath, subj_num);

% set up experiment images
ques_stims = {NUM_RUN, TRIALS_PER_RUN};
noun_stims = cell(NUM_RUN, TRIALS_PER_RUN);
trigger_idx = cell(NUM_RUN, TRIALS_PER_RUN);
ISIs = cell(NUM_RUN, TRIALS_PER_RUN);
correct_answers = cell(NUM_RUN, TRIALS_PER_RUN);

% for runIndex = 1:NUM_RUN
%     runFile = sortedFiles{runIndex};
%     run = readtable(runFile);
%     for trialIndex = 1:TRIALS_PER_RUN
%        % attach nouns
%        ques_stims{runIndex, trialIndex} = run.Question{trialIndex};
%        % attach questions
%        noun_stims{runIndex, trialIndex} = run.Noun{trialIndex};
%        % attach ISIs
%        ISIs{runIndex,trialIndex} = run.ISI(trialIndex)/1000;
%        % attach triggers
%        trigger_idx{runIndex,trialIndex} = decide_trigger(run.Condition{trialIndex});
%        % attach correct answers
%        correct_answers{runIndex,trialIndex} = run.Answer(trialIndex);
%     end
% end

% results
resultsHdr = {'TrialOnset', 'PairNumber', 'Condition', 'Noun','Category','Question', 'QuestionIndex', 'Answer', 'ISI', 'Accuracy', 'RT'};

%results is the table that will hold all of the data we want to save
results = cell(TRIALS_PER_RUN, length(resultsHdr));
results = cell2table(results, 'VariableNames', resultsHdr);

% make practice trials
RestrictKeysForKbCheck([]);

escapeKey = 'Escape';
enableKeys = [KbName('1'), KbName('1!'), KbName('2'), KbName('2@'), KbName(escapeKey)];
RestrictKeysForKbCheck(enableKeys);

% Present the experiment
% RestrictKeysForKbCheck([]);
% enableKeys = [KbName('1'), KbName('1!'), KbName('2'), KbName('2@'), KbName(escapeKey)];

% Wait indefinitely until trigger
% PTBhelper('stimText',wPtr,'Waiting for trigger...',sentFontSize);
% PTBhelper('waitFor','TRIGGER',kbIdx,escapeKey);

RestrictKeysForKbCheck(enableKeys);

%% initialize trigger [new stim comp]
%comment this when simulating presentation locally
% p.usetrigs = 1;
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


runOnset = GetSecs; %remains the same
onset = runOnset;   %updates for each trial

%Present each run
try
    for runIndex = 1:NUM_RUN
        % get file name
%         fileName = strsplit(sortedFiles(runIndex), '/');
%         fileName = fileName(length(fileName));
%         fileToSave = strcat(pwd, '/data/SPEC_', fileName);
        if runIndex ==1
            PTBhelper('stimText', wPtr, ['Please get ready.\n\n'...
                    'As you were instructed by the experimenter, for all trials, \n press the LEFT key to answer YES,\n and the RIGHT to answer NO.\n\n'...
                    'The experiment will consist of four ''runs'' with each run lasting ~4.5 minutes.\n\n'...
                    'And remember: if you must blink, please blink during the question or between trials,\n not while you are reading the words.\n\n'...
                    'When you are ready to start the first run, please press any key.\n\n'], instructFontSize);        
            PTBhelper('waitUntil',GetSecs+INSTRUCT_DUR,kbIdx,escapeKey);
            WaitSecs(2);
        else
        	PTBhelper('stimText', wPtr, ['Press any key to start the experiment.'], instructFontSize);
            PTBhelper('waitUntil',GetSecs+INSTRUCT_DUR,kbIdx,escapeKey);
            WaitSecs(2);
        end
        
        ques_stims = cell(TRIALS_PER_RUN,1);
        noun_stims = cell(TRIALS_PER_RUN,1);
        trigger_idx = cell(TRIALS_PER_RUN,1);
        ISIs = cell(TRIALS_PER_RUN,1);
        correct_answers = cell(TRIALS_PER_RUN,1);
        for trialIndex = 1:TRIALS_PER_RUN
            runFile = sortedFiles{runIndex};
            run = readtable(runFile);
            % attach nouns
            ques_stims{trialIndex} = run.Question{trialIndex};
            % attach questions
            noun_stims{trialIndex} = run.Noun{trialIndex};
            % attach ISIs
            ISIs{trialIndex} = run.ISI(trialIndex)/1000;
            % attach triggers
            trigger_idx{trialIndex} = decide_trigger(run.Condition{trialIndex});
            % attach correct answers
            correct_answers{trialIndex} = run.Answer(trialIndex);

        end
        % wait 2 sec before starting the trial
        %blank screen (2 sec)
        Screen('FillRect',wPtr,backgroundColor);
        WaitSecs(2);
        % actual trial onset
        onset = GetSecs;
        %Show each trial
        for trialIndex=1:TRIALS_PER_RUN
            
            ISI = ISIs{trialIndex};
            
            %Get the trial end time
            trialEndTime = onset + TRIAL_DUR;

            %fixation (duration 250ms)
            PTBhelper('stimText', wPtr, '+', fixFontSize);
            %SEND TRIGGER
            WaitSecs(0.026);
            %uncomment this in real exp
            %send_trigger(p, trigger_idx{trialIndex},0.004);
            WaitSecs(FIXATION_DUR-PROJ_DELAY);

            %blank screen (250ms)
            %Screen('FillRect',wPtr,backgroundColor);
            Screen('FillRect',wPtr,backgroundColor);
            Screen(wPtr, 'Flip');
            WaitSecs(BLANK_DUR1);

            %word (1000ms)
            PTBhelper('stimText', wPtr, noun_stims{trialIndex}, fixFontSize);
            %WaitSecs(WORD_DUR);
            %SEND TRIGGER
            WaitSecs(0.026);
            %uncomment this in real exp
            %send_trigger(p, trigger_idx{trialIndex},0.004);
            WaitSecs(WORD_DUR-PROJ_DELAY);
            
            %blank screen (500ms)
            %Screen('FillRect',wPtr,backgroundColor);
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
            %Screen('FillRect',wPtr,backgroundColor);
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
        % wait 2 sec before starting the trial
        WaitSecs(2);
        %fill in the rest of the data
        run = readtable(runFile);
        results.Noun = noun_stims(1:TRIALS_PER_RUN);%reshape(noun_stims(runIndex, :),TRIALS_PER_RUN,1);
        results.Question = ques_stims(1:TRIALS_PER_RUN);%reshape(ques_stims(runIndex, :),TRIALS_PER_RUN,1);
        results.PairNumber = run.PairNumber(1:TRIALS_PER_RUN);
        results.Condition = run.Condition(1:TRIALS_PER_RUN);
        results.Category = run.Category(1:TRIALS_PER_RUN);
        results.QuestionIndex = run.QuestionIndex(1:TRIALS_PER_RUN);
        results.Answer = cellstr(num2str(run.Answer(1:TRIALS_PER_RUN)));
        results.ISI = run.ISI(1:TRIALS_PER_RUN);
        %Calculate the accuracies
        results.Accuracy = grade_results(results);

        fileName = strsplit(runFile, '/');
        fileName = fileName{length(fileName)};
        fileToSave = [pwd, '/data/SPEC_MEG_' subj_ID '_' fileName];
        writetable(results, fileToSave);
        %results = [];
        disp(strcat('Subj', subj_ID, ' finished; data for this run saved to ', fileToSave))
       
    end
    
catch errorInfo                
    %Save all data
    %writetable(results, fileToSave);

    Screen('CloseAll');
    ShowCursor;
    fprintf('%s%s\n', 'error message: ', errorInfo.message)
end

%Restore the old level.
Screen('Preference','SuppressAllWarnings',oldEnableFlag);


% identify the subject runs, sort them in order
% read each file, and identify the condition, words, image, and ISI

function [sortedList] = read_list(folderPath, subj_num)
    filenames = {};
    files = dir([folderPath '/subject' subj_num '_*']);
    for K = 1 : length(files)
        filenames = [filenames, [folderPath files(K).name]];
    end
    sortedList = sort(filenames);
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

function [trigger] = decide_trigger(condition)
    trigger = '';
    if strcmp(condition, 'High')
        trigger = 1;
    elseif strcmp(condition, 'Low')
        trigger = 2;
    end
end

end