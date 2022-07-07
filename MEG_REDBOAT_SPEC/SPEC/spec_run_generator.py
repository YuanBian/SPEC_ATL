import pandas as pd
import numpy as np
import glob
import math
import itertools 
import random
import os
cwd = os.getcwd()

spec_raw = pd.read_csv(cwd+"/SPEC_questions_FINAL.csv")

# split into sublists L1-S1, L1-S2, L2-S1, L2-S2
# each list has *fixed* words. But words are paired with different questions for different subjects
# The 192 words will be divided into 2 experimental lists (96 trials each): 
# list 1 will contain high-spec words in odd-numbered pairs, and low-spec words in even-numbered pairs; 
# list 2 - the opposite.
L1 = spec_raw[((spec_raw.PairNumber%2==1) & (spec_raw.Condition=="High")) |\
         ((spec_raw.PairNumber%2==0) & (spec_raw.Condition=="Low"))]
L2 = spec_raw[((spec_raw.PairNumber%2==1) & (spec_raw.Condition=="Low")) |\
         ((spec_raw.PairNumber%2==0) & (spec_raw.Condition=="High"))]
L1_S1 = L1[(L1.PairNumber%4==1) | (L1.PairNumber%4==2)]
L1_S2 = L1[(L1.PairNumber%4==0) | (L1.PairNumber%4==3)]
L2_S1 = L2[(L2.PairNumber%4==1) | (L2.PairNumber%4==2)]
L2_S2 = L2[(L2.PairNumber%4==0) | (L2.PairNumber%4==3)]
L1_S1.to_csv(cwd+"/sublists/L1-S1.csv", index=False)
L1_S2.to_csv(cwd+"/sublists/L1-S2.csv", index=False)
L2_S1.to_csv(cwd+"/sublists/L2-S1.csv", index=False)
L2_S2.to_csv(cwd+"/sublists/L2-S2.csv", index=False)
########################################################################################################
def check_consecutive_question(qlist):
    ret = False
    qs = qlist["QuestionIndex"].values
    for i in range(0, len(qs)-2):
        if qs[i] == qs[i+1] and qs[i] == qs[i+2]:
            ret = True
    return ret


########################################################################################################
def create_spec_condition_order(subjn):
    run = [("High", 1, 200), ("High", 1, 300),("High", 1, 400),("High", 1, 500), ("High", 1, 600),("High", 1, 700),\
           ("High", 0, 200), ("High", 0, 300),("High", 0, 400),("High", 0, 500), ("High", 0, 600),("High", 0, 700)]*2+\
           [("Low", 1, 200), ("Low", 1, 300),("Low", 1, 400),("Low", 1, 500), ("Low", 1, 600),("Low", 1, 700),\
           ("Low", 0, 200), ("Low", 0, 300),("Low", 0, 400),("Low", 0, 500), ("Low", 0, 600),("Low", 0, 700)]*2
    # a dirty but quick way to generate the random lists
    # "reshuffle then filter" is way too slow for generating all unique items (or practically impossible)
    restart = True
    while restart:
        restart = False
        idx = np.asarray(list(range(48)))
        run_rnd = []
        # choose x random trials as the initial x trials
        initials_idx = np.random.choice(idx, 3, replace=False)
        idx = idx[idx!= initials_idx[0]]
        idx = idx[idx!= initials_idx[1]]
        idx = idx[idx!= initials_idx[2]]
        run_rnd.append(run[initials_idx[0]])
        run_rnd.append(run[initials_idx[1]])
        run_rnd.append(run[initials_idx[2]])
        for i in range(3, 48): # the number here means how many consecutive trials are allowed
            # if the previous three items are the same, choose the other condition
            if run_rnd[i-1][0]==run_rnd[i-2][0] and run_rnd[i-1][0]==run_rnd[i-3][0]: 
                if run_rnd[i-1][0] =="High":
                    choosable = idx[idx>23]
                    if len(choosable)==0:
                        restart = True
                        break
                    else:
                        chosen_idx = np.random.choice(choosable)
                        run_rnd.append(run[chosen_idx])
                        idx = idx[idx!=chosen_idx]
                else:
                    choosable = idx[idx<=23]
                    if len(choosable)==0:
                        restart = True
                        break
                    else:
                        chosen_idx = np.random.choice(choosable)
                        run_rnd.append(run[chosen_idx])
                        idx = idx[idx!=chosen_idx]
            else:
                chosen_idx = np.random.choice(idx)
                run_rnd.append(run[chosen_idx])
                idx = idx[idx!=chosen_idx]
    run_rnd = np.asarray(run_rnd).transpose()
    run_df = pd.DataFrame({"Condition":run_rnd[0], "Answer":run_rnd[1], "ISI":run_rnd[2]})
    run_df.to_csv(cwd+"/condition_orders/condition_order"+str(subjn)+".csv", index=False)

# create condition orders
for i in range(1, 9):
    create_spec_condition_order(i)

########################################################################################################
def create_spec_runs(subjn, material_order):
    condition_orders_files = random.sample(glob.glob(cwd+"/condition_orders/*"),4)
    sublists_files = [ cwd+"/sublists/"+order+".csv" for order in material_order]
    run_n = 1
    for order_file, sublist_file in zip(condition_orders_files, sublists_files):
        ISI = []
        subject_run_ = pd.DataFrame({"PairNumber":[], "Condition":[],"Noun":[],"Category":[],"Question":[], "QuestionIndex":[], "Answer":[], "ISI":[]}, \
                columns=["PairNumber", "Condition","Noun","Category","Question", "QuestionIndex", "Answer", "ISI"], dtype=np.int32)
        condition_order = pd.read_csv(order_file)
        sublist_ = pd.read_csv(sublist_file)
        sublist_.insert(4, "Question", np.nan)
        sublist_.insert(5, "QuestionIndex", np.nan)
        sublist_.insert(6, "Answer", np.nan)
        sublist = sublist_.copy()
        question_names = sublist.columns[-8:]
        # add empty columns to add values later
        # attaching questions to words
        restart = True
        while restart:
            restart = False
            question_list = sublist_.copy()
            sublist = sublist_.copy()
            # the space for questions and answers
            questions_all = [0,1,2,3,4,5,6,7]
            np.random.shuffle(questions_all)
            answers_all = [1, 0]*24
            # sample yes question
            for q_index in questions_all:
                answers = random.sample(answers_all,6)#+[1,0]
                [answers_all.remove(x) for x in answers]
                n_Yes = answers.count(1)
                n_No = answers.count(0)
                # Yes questions
                Yes_questions = question_list[question_list.iloc[:, q_index+7]==1]
                if n_Yes==0:
                    pass
                elif len(Yes_questions)<n_Yes:
                    restart = True
                    break
                else:
                    Yes_questions_index = list(Yes_questions.sample(n_Yes).index)
                    for idx in Yes_questions_index:
                        sublist.loc[idx, "Question"] = question_names[q_index]
                        sublist.loc[idx, "QuestionIndex"] = q_index
                        sublist.loc[idx, "Answer"] = 1
                    # remove the already sampled 
                    question_list = question_list.drop(Yes_questions_index)
                # No questions
                No_questions = question_list[question_list.iloc[:, q_index+7]==0]
                if n_No==0:
                    pass
                elif len(No_questions)<n_No:
                    restart = True
                    break
                else:
                    No_questions_index = list(No_questions.sample(n_No).index)
                    for idx in No_questions_index:
                        sublist.loc[idx, "Question"] = question_names[q_index]
                        sublist.loc[idx, "QuestionIndex"] = q_index
                        sublist.loc[idx, "Answer"] = 0
                    # remove the already sampled 
                    question_list = question_list.drop(No_questions_index)
                    
        # assign items to condition order
        # subject_run = subject_run_.copy()
        print("HERE")
        restart = True
        while restart:
            subject_run = subject_run_.copy()
            restart = False
            for row in range(len(condition_order)):
                condition = condition_order.iloc[row]["Condition"]
                answer = condition_order.iloc[row]["Answer"]
                chosen_item = sublist[(sublist.Condition==condition) & (sublist.Answer==answer)].sample()
                chosen_idx = list(chosen_item.index)
                # append all values
                ISI.append(condition_order.iloc[row]["ISI"])
                subject_run = subject_run.append(chosen_item.iloc[:,0:7]) 
                # check consecutive questions; if YES, restart
                sublist = sublist[~sublist.index.isin(chosen_idx)] # remove already sampled items
            restart = check_consecutive_question(sublist)
        # name the csv output
        order_name = order_file.split("/")[-1][10:-4]
        sublist_name = sublist_file.split("/")[-1][0:5]
        subject_run.ISI = ISI
        subject_run.Answer = subject_run.Answer.astype(int)
        subject_run.QuestionIndex = subject_run.QuestionIndex.astype(int)
        subject_run.PairNumber = subject_run.PairNumber.astype(int)
        subject_run = subject_run.reset_index()
        column_order=["PairNumber", "Condition","Noun","Category","Question", "QuestionIndex", "Answer", "ISI"]
        subject_run[column_order].to_csv(cwd+"/subject_lists/subject"+str(subjn)+"_"+"run"+str(run_n)+"_"+order_name+"_"+sublist_name+".csv", index=False)
        run_n = run_n+1

material_order = ["L1-S1", "L1-S2", "L2-S1", "L2-S2"]
all_orders = list(itertools.permutations(material_order))
for subjn, order in zip(list(range(1, 25)), all_orders):
    create_spec_runs(subjn, order)
