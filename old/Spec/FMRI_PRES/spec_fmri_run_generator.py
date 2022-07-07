import pandas as pd
import numpy as np
import glob
import math
import itertools 
import random
import os
import sys
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
L1_S1 = L1[(L1.PairNumber%4==1) | (L1.PairNumber%4==2)].sort_values(by=["PairNumber", "Condition"])
L1_S2 = L1[(L1.PairNumber%4==3) | (L1.PairNumber%4==0)].sort_values(by=["PairNumber", "Condition"])
L2_S1 = L2[(L2.PairNumber%4==1) | (L2.PairNumber%4==2)].sort_values(by=["PairNumber", "Condition"])
L2_S2 = L2[(L2.PairNumber%4==3) | (L2.PairNumber%4==0)].sort_values(by=["PairNumber", "Condition"])
L1_S1.to_csv(cwd+"/sublists/L1-S1.csv", index=False)
L1_S2.to_csv(cwd+"/sublists/L1-S2.csv", index=False)
L2_S1.to_csv(cwd+"/sublists/L2-S1.csv", index=False)
L2_S2.to_csv(cwd+"/sublists/L2-S2.csv", index=False)
########################################################################################################
def check_consecutive_items(v, num):
    ret = False
    c = 1
    for i in range(0, len(v)-1):
        if v[i] == v[i+1]:
            c = c+1
            if c > num:
                ret = True
                break
        else:
            c = 1
    return ret

########################################################################################################
def create_spec_condition_order(order_number):
    run = [("High", 1, 200), ("High", 1, 300),("High", 1, 400),("High", 1, 500), ("High", 1, 600),("High", 1, 700),\
           ("High", 0, 200), ("High", 0, 300),("High", 0, 400),("High", 0, 500), ("High", 0, 600),("High", 0, 700)]*2+\
           [("Low", 1, 200), ("Low", 1, 300),("Low", 1, 400),("Low", 1, 500), ("Low", 1, 600),("Low", 1, 700),\
           ("Low", 0, 200), ("Low", 0, 300),("Low", 0, 400),("Low", 0, 500), ("Low", 0, 600),("Low", 0, 700)]*2
    restart = True
    while restart:
        random.shuffle(run)
        run_tmp = np.asarray(run).transpose()
        restart = check_consecutive_items(run_tmp[0], 3) or check_consecutive_items(run_tmp[1], 4)
    run_df = pd.DataFrame({"Condition":run_tmp[0], "Answer":run_tmp[1], "ISI":run_tmp[2]})
    run_df.to_csv(cwd+"/condition_orders/condition_order"+str(order_number)+".csv", index=False)

# def create_spec_condition_order(subjn):
#     run = [("High", 1, 200), ("High", 1, 300),("High", 1, 400),("High", 1, 500), ("High", 1, 600),("High", 1, 700),\
#            ("High", 0, 200), ("High", 0, 300),("High", 0, 400),("High", 0, 500), ("High", 0, 600),("High", 0, 700)]*2+\
#            [("Low", 1, 200), ("Low", 1, 300),("Low", 1, 400),("Low", 1, 500), ("Low", 1, 600),("Low", 1, 700),\
#            ("Low", 0, 200), ("Low", 0, 300),("Low", 0, 400),("Low", 0, 500), ("Low", 0, 600),("Low", 0, 700)]*2
#     # a dirty but quick way to generate the random lists
#     # "reshuffle then filter" is way too slow for generating all unique items (or practically impossible)
#     # restart = True
#     # while restart:
#     #     restart = False
#     #     idx = np.asarray(list(range(48)))
#     #     run_rnd = []
#     #     # choose x random trials as the initial x trials
#     #     initials_idx = np.random.choice(idx, 3, replace=False)
#     #     idx = idx[idx!= initials_idx[0]]
#     #     idx = idx[idx!= initials_idx[1]]
#     #     idx = idx[idx!= initials_idx[2]]
#     #     run_rnd.append(run[initials_idx[0]])
#     #     run_rnd.append(run[initials_idx[1]])
#     #     run_rnd.append(run[initials_idx[2]])
#     #     for i in range(3, 48): # the number here means how many consecutive trials are allowed
#     #         # if the previous three items are the same, choose the other condition
#     #         if run_rnd[i-1][0]==run_rnd[i-2][0] and run_rnd[i-1][0]==run_rnd[i-3][0]: 
#     #             if run_rnd[i-1][0] =="High":
#     #                 choosable = idx[idx>23]
#     #                 if len(choosable)==0:
#     #                     restart = True
#     #                     break
#     #                 else:
#     #                     chosen_idx = np.random.choice(choosable)
#     #                     run_rnd.append(run[chosen_idx])
#     #                     idx = idx[idx!=chosen_idx]
#     #             else:
#     #                 choosable = idx[idx<=23]
#     #                 if len(choosable)==0:
#     #                     restart = True
#     #                     break
#     #                 else:
#     #                     chosen_idx = np.random.choice(choosable)
#     #                     run_rnd.append(run[chosen_idx])
#     #                     idx = idx[idx!=chosen_idx]
#     #         else:
#     #             chosen_idx = np.random.choice(idx)
#     #             run_rnd.append(run[chosen_idx])
#     #             idx = idx[idx!=chosen_idx]
#     #     restart = check_consecutive_items(run_rnd, 4)
#     restart = True
#     while restart:
#         random.shuffle(run)
#         run_tmp = np.asarray(run).transpose()
#         restart = check_consecutive_items(run_tmp[0], 3) and check_consecutive_items(run_tmp[1], 4)
#     run_df = pd.DataFrame({"Condition":run_tmp[0], "Answer":run_tmp[1], "ISI":run_tmp[2]})
#     #run_rnd = np.asarray(run_rnd).transpose()
#     #run_df = pd.DataFrame({"Condition":run_rnd[0], "Answer":run_rnd[1], "ISI":run_rnd[2]})
#     run_df.to_csv(cwd+"/condition_orders/condition_order"+str(subjn)+".csv", index=False)

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
        subject_run = pd.DataFrame({"PairNumber":[], "Condition":[],"Noun":[],"Category":[],"Question":[], "QuestionIndex":[], "Answer":[], "ISI":[]}, \
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
        # iterate
        restart = True
        while restart:
            restart = False
            try:
                run_unordered = pd.DataFrame({"PairNumber":[], "Condition":[],"Noun":[],"Category":[],"Question":[], "QuestionIndex":[], "Answer":[]})
                for condition in ["High", "Low"]:
                    question_list = sublist_.copy()
                    sublist = sublist_.copy()
                    # the space for questions and answers
                    questions_all = [0,1,2,3,4,5,6,7]
                    #np.random.shuffle(questions_all)
                    Yes_total = 12
                    No_total = 12
                    for q_index in questions_all: 
                        #print(q_index)
                        condition_materials = sublist[sublist.Condition==condition]
                        max_Yes = list(condition_materials.iloc[:, q_index+7]).count(1)
                        #print(list(condition_materials.iloc[:, q_index+7]))
                        Yes_num = min(random.choice(list(range(max_Yes))), random.choice(list(range(1,4))))
                        No_num = 3-Yes_num
                        if q_index ==7:
                            Yes_num = Yes_total
                            No_num = No_total
                            # print("Yes num:"+str(Yes_num))
                            # print("No num:"+str(No_num))
                        else:
                            Yes_total = Yes_total-Yes_num
                            No_total = No_total-No_num
                        Yes_trials = condition_materials[condition_materials.iloc[:, q_index+7]==1].sample(Yes_num)
                        Yes_trials["Answer"] = 1
                        No_trials = condition_materials[condition_materials.iloc[:, q_index+7]==0].sample(No_num)
                        No_trials["Answer"] = 0
                        all_trials = Yes_trials.append(No_trials)
                        all_trials["QuestionIndex"] = q_index
                        all_trials["Question"] = sublist.columns[q_index+7]
                        #trials = pd.DataFrame({"PairNumber":all_trials["PairNumber"], "Condition":all_trials[],"Noun":all_trials[],"Category":all_trials[],"Question":all_trials[], "QuestionIndex":all_trials[], "Answer":[], "ISI":[]})
                        run_unordered = pd.concat([run_unordered, all_trials], join='inner', ignore_index=True)
            except:
                restart = True
        # assign items to condition order
        restart = True
        run_unordered_ = run_unordered
        while restart:
            run_unordered = run_unordered_
            run_ordered = pd.DataFrame({"PairNumber":[], "Condition":[],"Noun":[],"Category":[],"Question":[], "QuestionIndex":[], "Answer":[]})
            for row in range(len(condition_order)):
                condition = condition_order.iloc[row]["Condition"]
                answer = condition_order.iloc[row]["Answer"]
                chosen_item = run_unordered[(run_unordered.Condition==condition) & (run_unordered.Answer==answer)].sample()
                chosen_idx = list(chosen_item.index)
                # append all values
                run_ordered = run_ordered.append(chosen_item) 
                run_unordered = run_unordered[~run_unordered.index.isin(chosen_idx)] # remove already sampled items
        # check if there is more than 2 same questions in a row
            restart = check_consecutive_items(run_ordered["QuestionIndex"], 3)
        # name the csv output
        #print(run_ordered)
        order_name = order_file.split("/")[-1][10:-4]
        sublist_name = sublist_file.split("/")[-1][0:5]
        run_ordered["ISI"] = 4000
        run_ordered.Answer = run_ordered.Answer.astype(int)
        run_ordered.QuestionIndex = run_ordered.QuestionIndex.astype(int)
        run_ordered.PairNumber = run_ordered.PairNumber.astype(int)
        run_ordered = run_ordered.reset_index()
        column_order=["PairNumber", "Condition","Noun","Category","Question", "QuestionIndex", "Answer", "ISI"]
        run_ordered[column_order].to_csv(cwd+"/subject_lists/subject"+str(subjn)+"_"+"run"+str(run_n)+"_"+order_name+"_"+sublist_name+".csv", index=False)
        run_n = run_n+1

material_order = ["L1-S1", "L1-S2", "L2-S1", "L2-S2"]
all_orders = list(itertools.permutations(material_order))
for subjn, order in zip(list(range(1, 25)), all_orders):
    create_spec_runs(subjn, order)
