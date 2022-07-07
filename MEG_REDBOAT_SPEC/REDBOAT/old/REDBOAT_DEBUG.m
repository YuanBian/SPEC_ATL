cd /Users/yuanbian/Downloads/Spec_ATL/Redboat_Replication/MEG_PRES;
subjID = '1';

pwd = '/Users/yuanbian/Downloads/Spec_ATL/Redboat_Replication/MEG_PRES';

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
bg_color = [10 10 10]; % background color
fg_color = [255 255 255]; % text color


%% set up presentation duration parameters
WORD_DUR = 0.3;
BLANK_DUR = 0.3;
TARGET_DUR = 2.2;
FIXATION_DUR = 0.3;
INSTRUCT_DUR = 2;
TRIAL_DUR = 4;
BREAK_DUR = 2;
PROJ_DELAY = 0.026;
%% set up materials
TRIALS_PER_BLOCK = 10; % TRIALS_PER_BLOCK = 100;
NUM_BLOCK = 4;%4 blocks: COMP_1W, COMP_2W, LIST_1W, LIST_2W

%% set up presentation instruction for each tasks
COMP_INSTRUCTION = ['This is a PHRASE block.\n'...
'If the picture matches ALL of the REAL words, press the LEFT button.\n'...
'If the picture does not match all of the REAL words, press the RIGHT button.'];
LIST_INSTRUCTION = ['This is a LIST block.\n'...
'If the picture matches ANY of the REAL words, press the LEFT button.\n'...
'If the picture does not match any of the REAL words, press the RIGHT button.'];

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
img_stims = {};
wrd_stims = cell(NUM_BLOCK, TRIALS_PER_BLOCK, 2);
trigger_idx = cell(NUM_BLOCK, TRIALS_PER_BLOCK);
ISIs = cell(NUM_BLOCK, TRIALS_PER_BLOCK);
correct_answers = cell(NUM_BLOCK, TRIALS_PER_BLOCK);

for blockIndex = 1:NUM_BLOCK
    blockFile = sortedFiles(blockIndex);
    block = readtable(blockFile);
    block_img_stims = cell(1, TRIALS_PER_BLOCK);
    for trialIndex = 1:TRIALS_PER_BLOCK
       % attach images
       img_file = [pwd '/Pics/' block.Image{trialIndex}];
       image = imread(img_file);
       block_img_stims{trialIndex} = Screen('MakeTexture', wPtr, double(image));
       %img_stims{blockIndex,trialIndex} = Screen('MakeTexture', wPtr, double(image));
       % attach words
       wrd_stims{blockIndex, trialIndex, 1} = block.Word_1st{trialIndex};
       wrd_stims{blockIndex, trialIndex, 2} = block.Word_2nd{trialIndex};
       % attach ISIs
       ISIs{blockIndex,trialIndex} = block.ISI(trialIndex)/1000;
       % attach triggers
       trigger_idx{blockIndex,trialIndex} = decide_trigger(block.Condition{trialIndex});
       % attach correct answers
       correct_answers{blockIndex,trialIndex} = block.Match(trialIndex);
    end
    img_stims{blockIndex} = block_img_stims;
end

% results
resultsHdr = {'TrialOnset','Word_1st', 'Word_2nd', 'Condition', 'Match', 'Mismatch_Type', 'Image', 'ISI', 'Accuracy', 'RT', 'Dur'};

%results is the table that will hold all of the data we want to save
results = cell(TRIALS_PER_BLOCK, length(resultsHdr));
results = cell2table(results, 'VariableNames', resultsHdr);

%opening instructions 
PTBhelper('stimText', wPtr, ['Welcome to our experiment!\n ' ...
    'Please press any button to read through these instructions!'], instructFontSize);
PTBhelper('waitUntil',GetSecs+INSTRUCT_DUR,kbIdx,escapeKey);
WaitSecs(1);
PTBhelper('stimText', wPtr,['Throughout this experiment, you will read words appearing one by one on the screen and\n'...
    ' then judge whether those words match or mismatch a picture\n that appears on the screen.\n'...
    'You only have 2.2 second to respond after the image is shown.\n'...
    'After you input your response, the image will disappear.\n'], instructFontSize);
PTBhelper('waitUntil',GetSecs+INSTRUCT_DUR,kbIdx,escapeKey);
WaitSecs(1);
PTBhelper('stimText', wPtr, ['There will be 2 types of blocks.'], instructFontSize);
PTBhelper('waitUntil',GetSecs+INSTRUCT_DUR,kbIdx,escapeKey);
WaitSecs(1);
PTBhelper('stimText', wPtr, ['In LIST blocks, you will see either a list of words (CUP, BOAT),\n or a non-word and a word (xwk, BOAT).\n'...
    'If the picture matches ANY of the words, press the LEFT button. \nIf the picture does not match any of the words, press the RIGHT button.\n\n'...
    'The words and images appear one by one on the screen very quickly. Please pay attention to them.'], instructFontSize);
PTBhelper('waitUntil',GetSecs+INSTRUCT_DUR,kbIdx,escapeKey);
WaitSecs(1);
PTBhelper('stimText', wPtr, ['In PHRASE blocks, you will see either a phrase (RED BOAT), or \n'...
'a non-word and then a word (xwk BOAT).\n'...
'If the picture matches ALL of the REAL words, press the LEFT button.\n'...
'If the pictures does not match all of the REAL words, press the RIGHT button.\n\n'...
'The words and images appear one by one on the screen very quickly. Please pay attention to them.'], instructFontSize);
PTBhelper('waitUntil',GetSecs+INSTRUCT_DUR,kbIdx,escapeKey);
WaitSecs(1);
PTBhelper('stimText', wPtr, ['When the "+" is shown, it indicates the start of the trial.\n\n'...
    'On each trial, press the LEFT button to respond MATCH and the RIGHT button to respond NO MATCH'], instructFontSize);
PTBhelper('waitUntil',GetSecs+INSTRUCT_DUR,kbIdx,escapeKey);
WaitSecs(1);


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

%Present each block
try
    for blockIndex = 1:NUM_BLOCK
        %%%%
        blockFile = sortedFiles(blockIndex);
        block = readtable(blockFile);
        block_img_stims = cell(1, TRIALS_PER_BLOCK);
        for trialIndex = 1:TRIALS_PER_BLOCK
           % attach images
           img_file = [pwd '/Pics/' block.Image{trialIndex}];
           image = imread(img_file);
           block_img_stims{trialIndex} = Screen('MakeTexture', wPtr, double(image));
           %img_stims{blockIndex,trialIndex} = Screen('MakeTexture', wPtr, double(image));
           % attach words
           wrd_stims{blockIndex, trialIndex, 1} = block.Word_1st{trialIndex};
           wrd_stims{blockIndex, trialIndex, 2} = block.Word_2nd{trialIndex};
           % attach ISIs
           ISIs{blockIndex,trialIndex} = block.ISI(trialIndex)/1000;
           % attach triggers
           trigger_idx{blockIndex,trialIndex} = decide_trigger(block.Condition{trialIndex});
           % attach correct answers
           correct_answers{blockIndex,trialIndex} = block.Match(trialIndex);
        end
        img_stims{blockIndex} = block_img_stims;
        %%%%
        blockFile = sortedFiles(blockIndex);
        INSTRUCTION = "";
        % show task-dependent instruction
        if contains(blockFile, "_COMP_")
            INSTRUCTION = COMP_INSTRUCTION;
        elseif contains(blockFile, "_LIST_")
            INSTRUCTION = LIST_INSTRUCTION;
        end
        
        % show instruction
        PTBhelper('stimText', wPtr, INSTRUCTION, instructFontSize);
        instructEndTime = onset + INSTRUCT_DUR;
        PTBhelper('waitUntil',instructEndTime,kbIdx,escapeKey);
        block_img_stims = img_stims{blockIndex};
        
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
            
            ISI = ISIs{blockIndex, trialIndex};
            
            %Get the trial end time
            trialEndTime = onset + TRIAL_DUR;

            %fixation (duration 300ms)
            PTBhelper('stimText', wPtr, '+', fixFontSize);
            
            %SEND TRIGGER
            WaitSecs(PROJ_DELAY);
            %uncomment this in real exp
            send_trigger(p, trigger_idx{blockIndex, trialIndex},0.004);
            WaitSecs(FIXATION_DUR-PROJ_DELAY);
            
            %blank screen (300ms)
            PTBhelper('stimImage',wPtr,'WHITE');
            WaitSecs(BLANK_DUR);

            %word1 (300ms)
            PTBhelper('stimText', wPtr, wrd_stims{blockIndex, trialIndex,1}, fixFontSize);
            WaitSecs(WORD_DUR);

            %blank screen (300ms)
            PTBhelper('stimImage',wPtr,'WHITE');
            WaitSecs(BLANK_DUR);

            %word2 (300ms)
            PTBhelper('stimText', wPtr, wrd_stims{blockIndex, trialIndex,2}, fixFontSize);
            WaitSecs(WORD_DUR);

            %blank screen (300ms)
            PTBhelper('stimImage',wPtr,'WHITE');
            WaitSecs(BLANK_DUR);

            %target shape (max 2,200ms)
            PTBhelper('stimImage', wPtr, trialIndex, block_img_stims);
            
            %request keyboard response from subject
            %need to revise this function
            record_resp  = PTBhelper('waitUntil',trialEndTime,kbIdx,escapeKey); 
            %record_resp  = PTBhelper('waitFor',GetSecs+2,kbIdx,escapeKey); 
            remain_time = trialEndTime-GetSecs;

            %blank screen (300ms)
            PTBhelper('stimImage',wPtr,'WHITE');
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
        block = readtable(blockFile);
        results.Word_1st = reshape(wrd_stims(blockIndex, :, 1),TRIALS_PER_BLOCK,1);
        results.Word_2nd = reshape(wrd_stims(blockIndex, :, 2),TRIALS_PER_BLOCK,1);
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
        fileToSave = strcat(pwd, "/data/REDBOAT_", fileName);
        writetable(results, fileToSave);
        %results = [];
        disp(strcat('Subj', subjID, ' finished; data for this run saved to ', fileToSave))
        
        %interblock instructions
        % get the name of the next block
        if blockIndex<4
            if contains(sortedFiles(blockIndex+1), "_COMP_")
                nextBlock = 'PHRASE';
            elseif contains(sortedFiles(blockIndex+1), "_LIST_")
                nextBlock = 'LIST';
            end
            PTBhelper('stimText', wPtr, ['Please take a short break (1 minute).\n'...
                'The next block is a ' nextBlock ' block. \nPress the left button to continue.'], instructFontSize);
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
