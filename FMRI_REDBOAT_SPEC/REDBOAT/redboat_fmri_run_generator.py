import pandas as pd
import numpy as np
import glob
import math
import itertools 
import random
import os
# current working directory
cwd = os.getcwd()

listmods = ['Cup','Boat','Lamp','Plane','Cross','House']
consonants = ['Xkq','Qxsw','Mtpv','Rjdnv','Wvcnz','Zbxlv']
extraIdx = np.random.choice(6,1,replace=False) # 24 + 1
listmods1 = listmods * 4
listmods1.append(listmods[extraIdx[0]])
np.random.permutation(listmods1)

# Helper function
def remove_item(l, item): 
    t = l.copy()
    if item in t:
        t.remove(item)
    return(t)

def select_by_length(l, item):
    t = l.copy()
    return([cur_item for cur_item in t if len(cur_item)==len(item)])

def orient():
    return(str(np.random.choice([1,2,3])))

def randomize_match_trials():
    # distribute the number of matching trials in each condition (e.g. COMP_1W)
    # there are 50 match trials and 50 mismatch trials in each condition
    # there must be at least 2 matching trials in each 5-trial block
    # there are 20 blocks in each condition in total
    # divide 50 into 20 sets, where there can't be more than 3 in each set
    while True:
        match_num = [random.choice([0,1,2]) for i in range(20)]
        if sum(match_num)==10:
            return([match_num[i]+2 for i in range(len(match_num))])

def upper(l):
    return([x.upper() for x in l])

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
################################################################################################################

def create_materials(subjn):
    # raw materials 
    HEAD = ["Disc", "Plane", "Bag", "Lock", "Cane", "Hand", \
             "Key", "Shoe", "Bone", "Square", "Bell", "Boat", \
             "Bow", "Car", "Cross", "Cup", "Flag", "Fork", \
             "Heart", "Lamp", "Leaf", "Note", "Star", "Tree", "House"]

    MODIFIER = ["Red", "Blue", "Pink", "Black", "Green", "Brown"]

    LIST_MOD = ["Cup", "Boat", "Lamp", "Plane", "Cross", "House"]
    
    CONS_STR = ["Xkq", "Qxsw", "Mtpv", "Rjdnw", "Wvcnz", "Zbxlv"]

   # common head for every subject
    head = [item for item in HEAD for _ in range(4)]
    modifier = []
    list_mod = []
    cons_str1 = []
    cons_str2 = []
    match = []
    list_match = []
    mismatch_type = []
    mismatch_all = [1]*16+[2]*16+[3]*18
    image_comp_1w = []
    image_comp_2w = []
    image_list_1w = []
    image_list_2w = []
    for cur_head in HEAD:
        # make copy of the original list so we dont accidently modify them
        LIST_MOD_ = LIST_MOD.copy()
        MODIFIER_ = MODIFIER.copy()
        CONS_STR1_ = CONS_STR.copy()
        CONS_STR2_ = CONS_STR.copy()
        # exclude items
        if cur_head in LIST_MOD:
            LIST_MOD_.remove(cur_head)
            MODIFIER_.remove(random.sample(select_by_length(MODIFIER_, cur_head), 1)[0])
            CONS_STR1_.remove(random.sample(select_by_length(CONS_STR1_, cur_head), 1)[0])
            CONS_STR2_.remove(random.sample(select_by_length(CONS_STR2_, cur_head), 1)[0])
        for i in range(4):
            # choose MODIFIER
            chosen_mod = random.sample(MODIFIER_, 1)[0]
            MODIFIER_.remove(chosen_mod)
            modifier.append(chosen_mod)
            # choose list mod
            chosen_list_mod = random.sample(select_by_length(remove_item(LIST_MOD_, cur_head), chosen_mod), 1)[0]
            LIST_MOD_.remove(chosen_list_mod)
            list_mod.append(chosen_list_mod)
            # choose cons_str1
            chosen_cons_str1 = random.sample(select_by_length(CONS_STR1_, chosen_mod), 1)[0]
            CONS_STR1_.remove(chosen_cons_str1)
            cons_str1.append(chosen_cons_str1)
            # choose cons_str2
            chosen_cons_str2 = random.sample(select_by_length(CONS_STR2_, chosen_mod), 1)[0]
            CONS_STR2_.remove(chosen_cons_str2)
            cons_str2.append(chosen_cons_str2)
            # assign match type
            if i in [0, 1]:
                match.append("match")
                mismatch_type.append(0)
                if i == 0:
                    list_match.append(1)
                else:
                    list_match.append(2)
            else:
                match.append("mismatch")
                list_match.append(0)
                chosen_mismatch = np.random.choice(mismatch_all)
                mismatch_type.append(chosen_mismatch)
                mismatch_all.remove(chosen_mismatch)
            # assign image
            # when the description matches the image
            if match[-1]=="match":
                # image for COMP_1W
                comp_1w_color = np.random.choice(MODIFIER)
                image_comp_1w.append(comp_1w_color+cur_head+"_"+orient()+".jpg")
                # image for COMP_2W
                image_comp_2w.append(modifier[-1]+cur_head+"_"+orient()+".jpg")
                # image for LIST_1W
                list_1w_color = np.random.choice(MODIFIER)
                image_list_1w.append(list_1w_color+cur_head+"_"+orient()+".jpg")
                # image for LIST_2W
                # match the first noun
                list_2w_color = np.random.choice(MODIFIER)
                if list_match[-1]==1:
                    image_list_2w.append(list_2w_color+list_mod[-1]+"_"+orient()+".jpg")
                # match the head noun
                elif list_match[-1]==2:
                    image_list_2w.append(list_2w_color+cur_head+"_"+orient()+".jpg")
            # mismatch image
            elif match[-1]=="mismatch":
                # image for COMP_1W
                mismatch_head = np.random.choice(remove_item(HEAD,cur_head))
                comp_1w_color = np.random.choice(MODIFIER)
                image_comp_1w.append(comp_1w_color+mismatch_head+"_"+orient()+".jpg")
                # image for COMP_2W
                # match the mod
                if mismatch_type[-1]==1:
                    mismatch_head = np.random.choice(remove_item(HEAD,cur_head))
                    image_comp_2w.append(modifier[-1]+mismatch_head+"_"+orient()+".jpg")
                # match the head noun
                elif mismatch_type[-1]==2:
                    comp_2w_color = np.random.choice(MODIFIER)
                    image_comp_2w.append(comp_2w_color+cur_head+"_"+orient()+".jpg")
                # match none
                elif mismatch_type[-1]==3:
                    mismatch_head = np.random.choice(remove_item(HEAD,cur_head))
                    comp_2w_color = np.random.choice(MODIFIER)
                    image_comp_2w.append(comp_2w_color+mismatch_head+"_"+orient()+".jpg")
                # image for LIST_1W
                mismatch_head = np.random.choice(remove_item(HEAD,cur_head))
                list_1w_color = np.random.choice(MODIFIER)
                image_list_1w.append(list_1w_color+mismatch_head+"_"+orient()+".jpg")
                # image for LIST_2W
                mismatch_head = np.random.choice(remove_item(remove_item(HEAD,cur_head), list_mod[-1]))
                list_2w_color = np.random.choice(MODIFIER)
                image_list_2w.append(list_2w_color+mismatch_head+"_"+orient()+".jpg")
    # create csv files 
    materials = pd.DataFrame({"Modifier_COMP":upper(modifier), "Consonant_COMP":upper(cons_str1), "Consonant_LIST":upper(cons_str2), "Modifier_LIST":upper(list_mod), "Head":upper(head), \
                      "Match":match, "Mismatch_Type":mismatch_type, "List_Match":list_match, "Image_COMP_1W":image_comp_1w, "Image_COMP_2W":image_comp_2w, \
                      "Image_LIST_1W":image_list_1w, "Image_LIST_2W":image_list_2w},\
            columns = ["Consonant_COMP", "Modifier_COMP", "Consonant_LIST", "Modifier_LIST", "Head", "Match", "Mismatch_Type", "List_Match", \
                      "Image_COMP_1W", "Image_COMP_2W", "Image_LIST_1W", "Image_LIST_2W"])
    materials.to_csv(cwd+"/subject_materials/subject"+str(subjn)+"_materials.csv")

# create 24 subject materials
for i in range(1,25):
    create_materials(i)

################################################################################################################

# creating pregenerated condition orders
# one of the order will be used twice
ORDERS = [["FIX", "COMP_1W", "COMP_2W", "LIST_1W", "LIST_2W", "FIX", "COMP_2W", "LIST_2W", "COMP_1W", "LIST_1W", "FIX", "LIST_1W", "COMP_1W", "LIST_2W", "COMP_2W", "FIX", "LIST_2W", "LIST_1W", "COMP_2W", "COMP_1W", "FIX"],\
["FIX", "COMP_2W", "LIST_1W", "LIST_2W", "COMP_1W", "FIX", "LIST_1W", "COMP_1W", "COMP_2W", "LIST_2W", "FIX", "LIST_2W", "COMP_2W", "COMP_1W", "LIST_1W", "FIX", "COMP_1W", "LIST_2W", "LIST_1W", "COMP_2W", "FIX"],\
["FIX", "LIST_1W", "LIST_2W", "COMP_1W", "COMP_2W", "FIX", "LIST_2W", "COMP_2W", "LIST_1W", "COMP_1W", "FIX", "COMP_1W", "LIST_1W", "COMP_2W", "LIST_2W", "FIX", "COMP_2W", "COMP_1W", "LIST_2W", "LIST_1W", "FIX"],\
["FIX", "LIST_2W", "COMP_1W", "COMP_2W", "LIST_1W", "FIX", "COMP_1W", "LIST_1W", "LIST_2W", "COMP_2W", "FIX", "COMP_2W", "LIST_2W", "LIST_1W", "COMP_1W", "FIX", "LIST_1W", "COMP_2W", "COMP_1W", "LIST_2W", "FIX"]]

################################################################################################################
# assign values to the condition order
def create_redboat_fmri_run(subjn, condition_idx):
    # better use a 
    material_name = cwd+"/subject_materials/subject"+str(subjn)+"_materials.csv"
    material_COMP_1W_ = pd.read_csv(material_name)
    material_COMP_2W_ = pd.read_csv(material_name)
    material_LIST_1W_ = pd.read_csv(material_name)
    material_LIST_2W_ = pd.read_csv(material_name)

    restart = True
    while restart:
        material_COMP_1W = material_COMP_1W_.copy()
        material_COMP_2W = material_COMP_2W_.copy()
        material_LIST_1W = material_LIST_1W_.copy()
        material_LIST_2W = material_LIST_2W_.copy()
        match_COMP_1W = randomize_match_trials()
        match_COMP_2W = randomize_match_trials()
        match_LIST_1W = randomize_match_trials()
        match_LIST_2W = randomize_match_trials()
        run_n = 1
        for idx in condition_idx:
            condition_order = ORDERS[idx-1]
            # create run dataframe to append values to
            run = pd.DataFrame({"Word_1st":[],"Word_2nd":[],"Condition":[],"Match":[],\
                "Mismatch_Type":[],"Image":[]}, \
         columns=["Word_1st","Word_2nd","Condition","Match", "Mismatch_Type","Image"])
            for condition in condition_order:
                # each block contains 5 trials
                if condition == "FIX":
                    block = pd.DataFrame({"Word_1st":["NA"],"Word_2nd":["NA"],"Condition":condition,"Match":["NA"],\
                    "Mismatch_Type":["NA"],"Image":["NA"]})
                elif condition == "COMP_1W":
                    match_num = match_COMP_1W.pop(0)
                    mismatch_num = 5-match_num
                    match_trials = material_COMP_1W[material_COMP_1W.Match=="match"].sample(match_num)
                    mismatch_trials = material_COMP_1W[material_COMP_1W.Match=="mismatch"].sample(mismatch_num)
                    trials = match_trials.append(mismatch_trials).sample(frac=1)
                    block = pd.DataFrame({"Word_1st":trials["Consonant_COMP"],"Word_2nd":trials["Head"],"Condition":condition,"Match":trials["Match"],\
                    "Mismatch_Type":trials["Mismatch_Type"],"Image":trials["Image_COMP_1W"]})
                    material_COMP_1W = material_COMP_1W.drop(trials.index)
                elif condition == "COMP_2W":
                    match_num = match_COMP_2W.pop(0)
                    mismatch_num = 5-match_num
                    match_trials = material_COMP_2W[material_COMP_2W.Match=="match"].sample(match_num)
                    mismatch_trials = material_COMP_2W[material_COMP_2W.Match=="mismatch"].sample(mismatch_num)
                    trials = match_trials.append(mismatch_trials).sample(frac=1)
                    block = pd.DataFrame({"Word_1st":trials["Modifier_COMP"],"Word_2nd":trials["Head"],"Condition":condition,"Match":trials["Match"],\
                    "Mismatch_Type":trials["Mismatch_Type"],"Image":trials["Image_COMP_2W"]})
                    material_COMP_2W = material_COMP_2W.drop(trials.index)
                elif condition == "LIST_1W":
                    match_num = match_LIST_1W.pop(0)
                    mismatch_num = 5-match_num
                    match_trials = material_LIST_1W[material_LIST_1W.Match=="match"].sample(match_num)
                    mismatch_trials = material_LIST_1W[material_LIST_1W.Match=="mismatch"].sample(mismatch_num)
                    trials = match_trials.append(mismatch_trials).sample(frac=1)
                    block = pd.DataFrame({"Word_1st":trials["Consonant_LIST"],"Word_2nd":trials["Head"],"Condition":condition,"Match":trials["Match"],\
                    "Mismatch_Type":trials["Mismatch_Type"],"Image":trials["Image_LIST_1W"]})
                    material_LIST_1W = material_LIST_1W.drop(trials.index)
                elif condition == "LIST_2W":
                    match_num = match_LIST_2W.pop(0)
                    mismatch_num = 5-match_num
                    match_trials = material_LIST_2W[material_LIST_2W.Match=="match"].sample(match_num)
                    mismatch_trials = material_LIST_2W[material_LIST_2W.Match=="mismatch"].sample(mismatch_num)
                    trials = match_trials.append(mismatch_trials).sample(frac=1)
                    block = pd.DataFrame({"Word_1st":trials["Modifier_LIST"],"Word_2nd":trials["Head"],"Condition":condition,"Match":trials["Match"],\
                    "Mismatch_Type":trials["Mismatch_Type"],"Image":trials["Image_LIST_2W"]})
                    material_LIST_2W = material_LIST_2W.drop(trials.index)
                run = run.append(block)
            restart = check_consecutive_items(run["Match"].values, 4)
            if restart==False:
                run = run.reset_index(drop=True)
                run.to_csv(cwd+"/subject_lists/subject"+str(subjn)+"_"+"run"+str(run_n)+"_order"+str(idx)+".csv")
                run_n = run_n +1
            else:
                break

# create subject runs
orders_idx = [1, 2, 3, 4]
repeated_order = orders_idx*6
# balance the condition order
all_orders = list(itertools.permutations(orders_idx))
for i in range(len(all_orders)):
    all_orders[i] = list(all_orders[i][:])+[repeated_order[i]]

for subjn, order in zip(list(range(1, 25)), all_orders):
    create_redboat_fmri_run(subjn, order)
################################################################################################################


