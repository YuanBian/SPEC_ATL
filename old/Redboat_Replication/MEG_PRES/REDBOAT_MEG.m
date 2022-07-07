%cd /Users/yuanbian/Documents/Spec_ATL/Redboat_Replication/MEG_PRES;
subjID = '1';
practice_mode = '1';
pwd = '/Users/yuanbian/Documents/Spec_ATL/Redboat_Replication/MEG_PRES';

%% Make sure inputs are valid
%subjID is a string

assert(ischar(subjID), 'subjID must be a string');

listFolderPath = [pwd '/subject_lists/'];
% materials_filenames = dir(strcat(pwd,"/subject_lists/subject",subjID,"_*"));

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
instructFontSize = 30;  %instructions screen before each block
helpFontSize = 20;      %instructions that appear during each trial
fixFontSize = 40;       %fixation cross
backgroundColor = [170 170 170]; % background color
fg_color = [255 255 255]; % text color


%% set up presentation duration parameters
WORD_DUR = 0.3;
BLANK_DUR = 0.3;
TARGET_DUR = 2.2;
FIXATION_DUR = 0.3;
INSTRUCT_DUR = 600;
TRIAL_DUR = 4;
BREAK_DUR = 2;
PROJ_DELAY = 0.026;
INF = 1000000;
%% set up materials
TRIALS_PER_BLOCK = 5; % TRIALS_PER_BLOCK = 100;
NUM_PRACTICE = 8;%4 blocks: COMP_1W, COMP_2W, LIST_1W, LIST_2W
NUM_BLOCK = 4;

%% set up screen and keyboard
screenNum = max(Screen('Screens'));  %Highest screen number is most likely correct display
windowInfo = PTBhelper('initialize', screenNum);
keyboardInfo = PTBhelper('getKeyboardIndex');
kbIdx = keyboardInfo{1};
escapeKey = keyboardInfo{2};
keyNames = KbName('KeyNames');

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
% PTBhelper('stimImage',wPtr,'WHITE');
Screen('FillRect',wPtr,backgroundColor);
PTBhelper('stimText',wPtr,'Loading experiment\n\n(Don''t start yet!)', 30);

% the parameters of practice trials
TRIALS_PER_BLOCK = 8;
sortedFiles = [strcat(pwd, "/practice_materials.csv")];

% results for practice
resultsHdr = {'TrialOnset','Word_1st', 'Word_2nd', 'Condition', 'Match', 'Mismatch_Type', 'Image', 'ISI', 'Accuracy', 'RT', 'Dur'};

%results is the table that will hold all of the data we want to save
results = cell(TRIALS_PER_BLOCK, length(resultsHdr));
results = cell2table(results, 'VariableNames', resultsHdr);

% Present the practice
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

PTBhelper('stimText', wPtr, ['Welcome to the words+images experiment.\n\n'...
'You will now have a chance to practice.\n\n'...
'Remember: press LEFT for MATCH, and RIGHT for NON-MATCH.\n\n'...
'Press any key to try a few practice trials.'], instructFontSize);
PTBhelper('waitUntil',GetSecs+INSTRUCT_DUR,kbIdx,escapeKey);
WaitSecs(2);

runOnset = GetSecs; %remains the same
onset = runOnset;   %updates for each trial

%Present each block
try
    NUM_BLOCK = 1;
    for blockIndex = 1:NUM_BLOCK
        %%%%
        wrd_stims = cell(NUM_PRACTICE, 2);
        trigger_idx = cell(NUM_PRACTICE, 1);
        ISIs = cell(NUM_PRACTICE, 1);
        correct_answers = cell(NUM_PRACTICE, 1);
        blockFile = sortedFiles(blockIndex);
        block = readtable(blockFile);
        block_img_stims = cell(NUM_PRACTICE, 1);

        for trialIndex = 1:NUM_PRACTICE
           % attach images
           img_file = [pwd '/Pics/' block.Image{trialIndex}];
           image = imread(img_file);
           block_img_stims{trialIndex} = Screen('MakeTexture', wPtr, double(image));
           %img_stims{blockIndex,trialIndex} = Screen('MakeTexture', wPtr, double(image));
           % attach words
           wrd_stims{trialIndex, 1} = block.Word_1st{trialIndex};
           wrd_stims{trialIndex, 2} = block.Word_2nd{trialIndex};
           % attach ISIs
           ISIs{trialIndex} = block.ISI(trialIndex)/1000;
           % attach triggers
           trigger_idx{trialIndex} = decide_trigger(block.Condition{trialIndex});
           % attach correct answers
           correct_answers{trialIndex} = block.Match(trialIndex);
        end
        
        %PTBhelper('stimImage',wPtr,'WHITE');
        WaitSecs(2);
        % actual trial onset
        onset = GetSecs;
        
        %Show each trial
        for trialIndex=1:NUM_PRACTICE

            %fixation (duration 300ms)
            %blank screen (300ms)
            %word1 (300ms)
            %blank screen (300ms)
            %word2 (300ms)
            %blank screen (300ms)
            %target shape (max 2,200ms)
            %ISI (trial dependent)
            
            ISI = ISIs{trialIndex};
            
            %Get the trial end time
            trialEndTime = onset + TRIAL_DUR;

            %fixation (duration 300ms)
            PTBhelper('stimText', wPtr, '+', fixFontSize);
            
            %SEND TRIGGER
            WaitSecs(PROJ_DELAY);
            %uncomment this in real exp
            %send_trigger(p, trigger_idx{trialIndex},0.004);
            WaitSecs(FIXATION_DUR-PROJ_DELAY);
            
            %blank screen (300ms)
            %PTBhelper('stimImage',wPtr,'WHITE');
            Screen('FillRect',wPtr,backgroundColor);
            Screen(wPtr, 'Flip');
            WaitSecs(BLANK_DUR);

            %word1 (300ms)
            PTBhelper('stimText', wPtr, wrd_stims{trialIndex,1}, sentFontSize);
            WaitSecs(WORD_DUR);

            %blank screen (300ms)
            %PTBhelper('stimImage',wPtr,'WHITE');
            Screen('FillRect',wPtr,backgroundColor);
            Screen(wPtr, 'Flip');
            WaitSecs(BLANK_DUR);

            %word2 (300ms)
            PTBhelper('stimText', wPtr, wrd_stims{trialIndex,2}, sentFontSize);
            WaitSecs(WORD_DUR);

            %blank screen (300ms)
            %PTBhelper('stimImage',wPtr,'WHITE');
            Screen('FillRect',wPtr,backgroundColor);
            Screen(wPtr, 'Flip');
            WaitSecs(BLANK_DUR);

            %target shape (max 2,200ms)
            PTBhelper('stimImage', wPtr, trialIndex, block_img_stims);
            
            %request keyboard response from subject
            %need to revise this function
            record_resp  = PTBhelper('waitUntil',trialEndTime,kbIdx,escapeKey); 
            %record_resp  = PTBhelper('waitFor',GetSecs+2,kbIdx,escapeKey); 
            remain_time = trialEndTime-GetSecs;

            %blank screen (300ms)
            %PTBhelper('stimImage',wPtr,'WHITE');
            Screen('FillRect',wPtr,backgroundColor);
            Screen(wPtr, 'Flip');
            WaitSecs(remain_time+ISI);
            
            %show blank screen if subject answer before the end of
            %target. 

            %Save data
            key = record_resp{1};
            rt = record_resp{2};
            results.TrialOnset{trialIndex} = onset - runOnset;
            results.Response{trialIndex} = decode_key(key);
            results.RT{trialIndex} = rt;
            results.Dur{trialIndex} = GetSecs-onset;
            onset = trialEndTime+ISI;
        end
        
        %fill in the rest of the data
        results.Word_1st = reshape(wrd_stims(:, 1),NUM_PRACTICE,1);
        results.Word_2nd = reshape(wrd_stims(:, 2),NUM_PRACTICE,1);
        results.Condition = block.Condition(1:NUM_PRACTICE);
        results.Match = block.Match(1:NUM_PRACTICE);
        results.Mismatch_Type = block.Mismatch_Type(1:NUM_PRACTICE);
        results.Image = block.Image(1:NUM_PRACTICE);
        results.ISI = block.ISI(1:NUM_PRACTICE);
        %Calculate the accuracies
        results.Accuracy = grade_results(results);
        
        %Remove used stimuli
%         wrd_stims(blockIndex, :, :) = [];
%         img_stims(blockIndex, :) = [];
%         block = [];
        %Save all data
        fileName = strsplit(sortedFiles(blockIndex), '/');
        fileName = fileName(length(fileName));
        fileToSave = strcat(pwd, "/data/REDBOAT_MEG_subject", subjID, "_",fileName);
        writetable(results, fileToSave);
        %results = [];
        disp(strcat('Subj', subjID, ' finished; data for this run saved to ', fileToSave))
        
        %interblock instructions
        PTBhelper('stimText', wPtr, ['The practice session is over.\n\n When you are ready to do the experiment, please press any key.'], instructFontSize);
        PTBhelper('waitUntil',GetSecs+INF,kbIdx,escapeKey);             
    end
    
    ShowCursor;

catch errorInfo                
    %Save all data
    writetable(results, fileToSave);

    Screen('CloseAll');
    ShowCursor;
    fprintf('%s%s\n', 'error message: ', errorInfo.message)
end

% END OF PRACTICE
%%%%%%%%%%%%%%%%
TRIALS_PER_BLOCK = 100;
NUM_BLOCK = 4;
% read all lists for this subject in a sorted order
sortedFiles = read_list(listFolderPath, subjID);

% results
resultsHdr = {'TrialOnset','Word_1st', 'Word_2nd', 'Condition', 'Match', 'Mismatch_Type', 'Image', 'ISI', 'Accuracy', 'RT', 'Dur'};

%results is the table that will hold all of the data we want to save
results = cell(TRIALS_PER_BLOCK, length(resultsHdr));
results = cell2table(results, 'VariableNames', resultsHdr);

PTBhelper('stimText', wPtr, ['Please get ready.\n\n'...
'As you were instructed by the experimenter, for all trials, \n press the LEFT key when the image matches the word(s),\n and the RIGHT key when the image does not match.\n\n'...
'The experiment will consist of four "runs" with each run lasting ~7.5 minutes.\n\n'...
'And remember: if you must blink, please blink during the image or between trials,\n not while you are reading the words.\n\n'...
'When you are ready to start the first run, please press any key.\n\n'], instructFontSize);
PTBhelper('waitUntil',GetSecs+INSTRUCT_DUR,kbIdx,escapeKey);
WaitSecs(1);

runOnset = GetSecs; %remains the same
onset = runOnset;   %updates for each trial

%Present each block
try
    for blockIndex = 1:NUM_BLOCK
        %%%%
        wrd_stims = cell(TRIALS_PER_BLOCK, 2);
        trigger_idx = cell(TRIALS_PER_BLOCK, 1);
        ISIs = cell(TRIALS_PER_BLOCK, 1);
        correct_answers = cell(TRIALS_PER_BLOCK, 1);
        blockFile = sortedFiles(blockIndex);
        block = readtable(blockFile);
        block_img_stims = cell(TRIALS_PER_BLOCK, 1);
        for trialIndex = 1:TRIALS_PER_BLOCK
           % attach images
           img_file = [pwd '/Pics/' block.Image{trialIndex}];
           image = imread(img_file);
           block_img_stims{trialIndex} = Screen('MakeTexture', wPtr, double(image));
           %img_stims{blockIndex,trialIndex} = Screen('MakeTexture', wPtr, double(image));
           % attach words
           wrd_stims{trialIndex, 1} = block.Word_1st{trialIndex};
           wrd_stims{trialIndex, 2} = block.Word_2nd{trialIndex};
           % attach ISIs
           ISIs{trialIndex} = block.ISI(trialIndex)/1000;
           % attach triggers
           trigger_idx{trialIndex} = decide_trigger(block.Condition{trialIndex});
           % attach correct answers
           correct_answers{trialIndex} = block.Match(trialIndex);
        end

        %PTBhelper('stimImage',wPtr,'WHITE');
        WaitSecs(2);
        % actual trial onset
        onset = GetSecs;
        
        %Show each trial
        for trialIndex=1:TRIALS_PER_BLOCK

            %fixation (duration 300ms)
            %blank screen (300ms)
            %word1 (300ms)
            %blank screen (300ms)
            %word2 (300ms)
            %blank screen (300ms)
            %target shape (max 2,200ms)
            %ISI (trial dependent)
            
            ISI = ISIs{trialIndex};
            
            %Get the trial end time
            trialEndTime = onset + TRIAL_DUR;

            %fixation (duration 300ms)
            PTBhelper('stimText', wPtr, '+', fixFontSize);
            
            %SEND TRIGGER
            WaitSecs(PROJ_DELAY);
            %uncomment this in real exp
            %send_trigger(p, trigger_idx{trialIndex},0.004);
            WaitSecs(FIXATION_DUR-PROJ_DELAY);
            
            %blank screen (300ms)
            %PTBhelper('stimImage',wPtr,'WHITE');
            Screen('FillRect',wPtr,backgroundColor);
            Screen(wPtr, 'Flip');
            WaitSecs(BLANK_DUR);

            %word1 (300ms)
            PTBhelper('stimText', wPtr, wrd_stims{trialIndex,1}, sentFontSize);
            WaitSecs(WORD_DUR);

            %blank screen (300ms)
            %PTBhelper('stimImage',wPtr,'WHITE');
            Screen('FillRect',wPtr,backgroundColor);
            Screen(wPtr, 'Flip');
            WaitSecs(BLANK_DUR);

            %word2 (300ms)
            PTBhelper('stimText', wPtr, wrd_stims{trialIndex,2}, sentFontSize);
            WaitSecs(WORD_DUR);

            %blank screen (300ms)
            %PTBhelper('stimImage',wPtr,'WHITE');
            Screen('FillRect',wPtr,backgroundColor);
            Screen(wPtr, 'Flip');
            WaitSecs(BLANK_DUR);

            %target shape (max 2,200ms)
            PTBhelper('stimImage', wPtr, trialIndex, block_img_stims);
            
            %request keyboard response from subject
            %need to revise this function
            record_resp  = PTBhelper('waitUntil',trialEndTime,kbIdx,escapeKey); 
            %record_resp  = PTBhelper('waitFor',GetSecs+2,kbIdx,escapeKey); 
            remain_time = trialEndTime-GetSecs;

            %blank screen (300ms)
            %PTBhelper('stimImage',wPtr,'WHITE');
            Screen('FillRect',wPtr,backgroundColor);
            Screen(wPtr, 'Flip');
            WaitSecs(remain_time+ISI);
            
            %show blank screen if subject answer before the end of
            %target. 

            %Save data
            key = record_resp{1};
            rt = record_resp{2};
            results.TrialOnset{trialIndex} = onset - runOnset;
            results.Response{trialIndex} = decode_key(key);
            results.RT{trialIndex} = rt;
            results.Dur{trialIndex} = GetSecs-onset;
            onset = trialEndTime+ISI;
        end
        
        %fill in the rest of the data
        results.Word_1st = reshape(wrd_stims(:, 1),TRIALS_PER_BLOCK,1);
        results.Word_2nd = reshape(wrd_stims(:, 2),TRIALS_PER_BLOCK,1);
        results.Condition = block.Condition(1:TRIALS_PER_BLOCK);
        results.Match = block.Match(1:TRIALS_PER_BLOCK);
        results.Mismatch_Type = block.Mismatch_Type(1:TRIALS_PER_BLOCK);
        results.Image = block.Image(1:TRIALS_PER_BLOCK);
        results.ISI = block.ISI(1:TRIALS_PER_BLOCK);
        %Calculate the accuracies
        results.Accuracy = grade_results(results);
        
        %Remove used stimuli
%         wrd_stims(blockIndex, :, :) = [];
%         img_stims(blockIndex, :) = [];
%         block = [];
        %Save all data
        fileName = strsplit(sortedFiles(blockIndex), '/');
        fileName = fileName(length(fileName));
        fileToSave = strcat(pwd, "/data/REDBOAT_MEG_", fileName);
        writetable(results, fileToSave);
        %results = [];
        disp(strcat('Subj', subjID, ' finished; data for this run saved to ', fileToSave))
        
        %interblock instructions
        % get the name of the next block
        if blockIndex<NUM_BLOCK
            PTBhelper('stimText', wPtr, ['Please take a little break. When you are ready to start the next run, please press any key.'], instructFontSize);
            PTBhelper('waitUntil',GetSecs+INF,kbIdx,escapeKey); 
        elseif blockIndex==NUM_BLOCK
            PTBhelper('stimText', wPtr, ['The experiment is now over. Thank you for your participation!\n\n'...
                'Please lay still until the experimenter opens the door!'], instructFontSize);
            PTBhelper('waitUntil',GetSecs+INF,kbIdx,escapeKey);
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

%%%%%%%%%%%%%%%%%%%%%%%%
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
        response = 'match';
    elseif strcmp(string(key), '2')
        response = 'mismatch';
    end
end

function [accuracy] = grade_results(results)
    accuracy = [string(results.Response)]== [string(results.Match)];
end

function [trigger] = decide_trigger(condition)
    trigger = '';
    if strcmp(condition, 'COMP_1W')
        trigger = 1;
    elseif strcmp(condition, 'COMP_2W')
        trigger = 2;
    elseif strcmp(condition, 'LIST_1W')
        trigger = 3;
    elseif strcmp(condition, 'LIST_2W')
        trigger = 4;
    end
end
