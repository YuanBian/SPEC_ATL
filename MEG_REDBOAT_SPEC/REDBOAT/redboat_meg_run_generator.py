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
# for i in range(1,25):
#     create_materials(i)

################################################################################################################
def create_condition_order(order_number):
    run = \
        [(1, "match", 200)]*5+[(1, "match", 300)]*5+[(1, "match", 400)]*5+[(1, "match", 500)]*5+[(1, "match", 600)]*5+\
        [(1, "mismatch", 200)]*5+[(1, "mismatch", 300)]*5+[(1, "mismatch", 400)]*5+[(1, "mismatch", 500)]*5+[(1, "mismatch", 600)]*5+\
        [(2, "match", 200)]*5+[(2, "match", 300)]*5+[(2, "match", 400)]*5+[(2, "match", 500)]*5+[(2, "match", 600)]*5+\
        [(2, "mismatch", 200)]*5+[(2, "mismatch", 300)]*5+[(2, "mismatch", 400)]*5+[(2, "mismatch", 500)]*5+[(2, "mismatch", 600)]*5
    restart = True
    while restart:
        random.shuffle(run)
        run_tmp = np.asarray(run).transpose()
        restart = check_consecutive_items(run_tmp[0], 3) or check_consecutive_items(run_tmp[1], 4)
    run_df = pd.DataFrame({"Condition":run_tmp[0], "Match":run_tmp[1], "ISI":run_tmp[2]})
    run_df.to_csv(cwd+"/condition_orders/condition_order"+str(order_number)+".csv", index=False)

# create condition orders
# for i in range(1, 9):
#     create_condition_order(i)

################################################################################################################
# assign values to the condition order
# def create_redboat_meg_run(subjn, material_order):
#     # better use a 
#     condition_order_files = random.sample(glob.glob(cwd+"/condition_orders/*"),4)
#     material_ = pd.read_csv(cwd+"/subject_materials/subject"+str(subjn)+"_materials.csv")
#     #run_n = 1
#     order_idx = 0
#     tasks = ["COMP", "LIST"]
#     for task in tasks:
#         # get run numbers 
#         run_nums_idx = 1
#         run_nums = [i for i,val in enumerate(material_order) if val==task]
#         # create lists to append values to
#         material = material_.copy()
#         # E.g. COMP_1W COMP_2W
#         # sample 50 COMP_1W, where 25 matches, 25 mismatches
#         # sample 50 COMP_2W, where 25 matches, 25 mismatches
#         COND_1W_match = material[material.Match=="match"].sample(25)
#         COND_1W_mismatch = material[material.Match=="mismatch"].sample(25)
#         list1 = COND_1W_match.append(COND_1W_mismatch)
#         list2 = material.drop(list(COND_1W_match.index)+list(COND_1W_mismatch.index))
#         COND_2W_match = material[material.Match=="match"].sample(25)
#         COND_2W_mismatch = material[material.Match=="mismatch"].sample(25)
#         list2 = list2.append(COND_1W_match.append(COND_1W_mismatch))
#         list1 = material.drop(list(COND_2W_match.index)+list(COND_2W_mismatch.index)).append(list1)
#         list1.reset_index(inplace=True)
#         list2.reset_index(inplace=True)
#         task_order_files = [condition_order_files[run_nums[0]], condition_order_files[run_nums[1]]]
#         # assign values to condition order
#         for order_file, run_material in zip(task_order_files, [list1, list2]):
#             word_1st = []
#             word_2nd = []
#             condition = []
#             mismatch = []
#             image = []
#             match = []
#             ISI = []
#             #run_material = run_material_.copy()
#             condition_order = pd.read_csv(order_file)
#             for row in range(len(condition_order)):
#                 match_image = condition_order.iloc[row]["Match"]
#                 match.append(match_image)
#                 item = run_material[run_material.Match==match_image].sample()
#                 run_material = run_material.drop(item.index)
#                 # attach mismatch type
#                 mismatch.append(item["Mismatch_Type"].values[0]) 
#                 COND_word = condition_order.iloc[row]["Condition"]
#                 # assign image, words, condition
#                 if COND_word==1:
#                     condition.append(task+"_1W")
#                     image.append(item["Image_"+task+"_1W"].values[0])
#                     word_1st.append(item["Consonant_"+task].values[0])
#                 elif COND_word==2:
#                     condition.append(task+"_2W")
#                     image.append(item["Image_"+task+"_2W"].values[0])
#                     word_1st.append(item["Modifier_"+task].values[0])
#                 word_2nd.append(item["Head"].values[0])
#                 ISI.append(condition_order.iloc[row]["ISI"])
#             run = pd.DataFrame({"Word_1st":word_1st,"Word_2nd":word_2nd,"Condition":condition,"Match":match,\
#                         "Mismatch_Type":mismatch,"Image":image,"ISI":ISI}, \
#                  columns=["Word_1st","Word_2nd","Condition","Match", "Mismatch_Type","Image","ISI"])
#             order_n = order_file.split("/")[-1][10:-4]
#             run.to_csv(cwd+"/subject_lists/subject"+str(subjn)+"_"+"run"+str(run_nums[run_nums_idx])+"_"+task+"_"+order_n+".csv")
#             run_nums_idx = run_nums_idx+1

def create_redboat_meg_run(subjn, material_order):
    # better use a 
    condition_order_files = random.sample(glob.glob(cwd+"/condition_orders/*"),4)
    material_ = pd.read_csv(cwd+"/subject_materials/subject"+str(subjn)+"_materials.csv")
    #run_n = 1
    order_idx = 0
    tasks = ["COMP", "LIST"]
    for task in tasks:
        # get run numbers 
        run_nums_idx = 0
        run_nums = [i for i,val in enumerate(material_order) if val==task]
        # create lists to append values to
        material = material_.copy()
        # E.g. COMP_1W COMP_2W
        # sample 50 COMP_1W, where 25 matches, 25 mismatches
        # sample 50 COMP_2W, where 25 matches, 25 mismatches
        # COND_1W_match = material[material.Match=="match"].sample(25)
        # COND_1W_mismatch = material[material.Match=="mismatch"].sample(25)
        # list1 = COND_1W_match.append(COND_1W_mismatch)
        # list2 = material.drop(list(COND_1W_match.index)+list(COND_1W_mismatch.index))
        # COND_2W_match = material[material.Match=="match"].sample(25)
        # COND_2W_mismatch = material[material.Match=="mismatch"].sample(25)
        # list2 = list2.append(COND_1W_match.append(COND_1W_mismatch))
        # list1 = material.drop(list(COND_2W_match.index)+list(COND_2W_mismatch.index)).append(list1)
        list_1W = material_.copy()
        list_2W = material_.copy()
        list_1W.reset_index(inplace=True)
        list_2W.reset_index(inplace=True)
        task_order_files = [condition_order_files[run_nums[0]], condition_order_files[run_nums[1]]]
        # assign values to condition order
        for order_file in task_order_files:
            word_1st = []
            word_2nd = []
            condition = []
            mismatch = []
            image = []
            match = []
            ISI = []
            #run_material = run_material_.copy()
            condition_order = pd.read_csv(order_file)
            for row in range(len(condition_order)):
                match_image = condition_order.iloc[row]["Match"]
                match.append(match_image)
                COND_word = condition_order.iloc[row]["Condition"]
                cond = ""
                item = ""
                if COND_word==1:
                    if task=="COMP":
                        cond = "Consonant_COMP"
                    else:
                        cond = "Consonant_LIST"
                    item = list_1W[list_1W.Match==match_image].sample()
                    list_1W = list_1W.drop(item.index)
                else:
                    if task=="COMP":
                        cond = "Modifier_COMP"
                    else:
                        cond = "Modifier_LIST"
                    item = list_2W[list_2W.Match==match_image].sample()
                    list_2W = list_2W.drop(item.index)
                # attach mismatch type
                mismatch.append(item["Mismatch_Type"].values[0])     
                # assign image, words, condition
                if COND_word==1:
                    condition.append(task+"_1W")
                    image.append(item["Image_"+task+"_1W"].values[0])
                    word_1st.append(item["Consonant_"+task].values[0])
                elif COND_word==2:
                    condition.append(task+"_2W")
                    image.append(item["Image_"+task+"_2W"].values[0])
                    word_1st.append(item["Modifier_"+task].values[0])
                word_2nd.append(item["Head"].values[0])
                ISI.append(condition_order.iloc[row]["ISI"])
            run = pd.DataFrame({"Word_1st":word_1st,"Word_2nd":word_2nd,"Condition":condition,"Match":match,\
                        "Mismatch_Type":mismatch,"Image":image,"ISI":ISI}, \
                 columns=["Word_1st","Word_2nd","Condition","Match", "Mismatch_Type","Image","ISI"])
            order_n = order_file.split("/")[-1][10:-4]
            run.to_csv(cwd+"/subject_lists/subject"+str(subjn)+"_"+"run"+str(run_nums[run_nums_idx]+1)+"_"+task+"_"+order_n+".csv")
            run_nums_idx = run_nums_idx+1
            #run_n = run_n +1

# create subject runs
material_order = [["COMP", "LIST", "LIST", "COMP"], ["LIST", "COMP", "COMP", "LIST"]]
# balance the condition order
all_orders = material_order*12
for subjn, order in zip(list(range(1, 25)), all_orders):
    create_redboat_meg_run(subjn, order)
################################################################################################################


