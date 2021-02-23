###  generic Python ToolKit module  ###


import math
import os
import random
import re
import sys



####=============================####
##  check the sign of some number  ##
####=============================####
def chk_sign_input(var, stype):
    valid = True

    ### this decision structure is only for number variables
    if stype == 'neg':
        if var >= 0: valid = False    # verify number is negative 
    elif stype == 'pos': 
        if var <= 0: valid = False    # verify number is positive
    elif stype == 'nneg':
        if var < 0: valid = False     # verify number is not negative
    elif stype == 'npos':
        if var > 0: valid = False     # verify number is not positive
    elif stype == '' or stype == 'none':
        pass
    else:
        print("Function Error - Invalid argument 'stype': ", stype)

    return(valid)
####++++++++++++++++++++++++++++++####
##  end function - chk_sign_input  ##
####++++++++++++++++++++++++++++++####


####===============================####
##  check an input variable by type  ##
####===============================####
def chk_valid_input(var, itype, emsg='', stype=''):
    #print("starting function:  chk_valid_input")
    valid = False                                           # set valid to False (Boolean)
    retvar = var                                            # set return var type to var
    #print("using:  var = ", "'", var, "'", sep='')
    #print("using:  emsg = ", emsg)
    #print("using:  itype = ", itype)
    #print("using:  stype = ", stype)
    if re.match(r'^[Xx]$',var): return(0, 0, 1)             # return 0 if user enters [Xx]
    if itype == 'binary':
        if re.match(r'^([Yy])(es)*|([Nn])(o|ein)*',var):    # match Yes/No/Nein
            if re.match(r'^[Yy]',var): retvar = 'Y'         # set var to Y for Yes
            if re.match(r'^[Nn]',var): retvar = 'N'         # set var to N for Nein
            valid = True;
        #print("matched binary regex:  valid = ", valid)
    elif itype == 'floater':
        if re.match(r'^-*\d+(\.\d+)*$',var):                 # match digits (maybe with decimal)
            retvar = float(var)                             # set return var type to float
            valid = chk_sign_input(retvar, stype)           # call chk_sign_input with sub_type
    elif itype == 'integer':
        if re.match(r'^-*\d+$',var):                        # match digits without decimal
            retvar = int(var)                               # set return var type to int
            valid = chk_sign_input(retvar, stype)           # call chk_sign_input with sub_type
    elif itype == 'name':
        if re.match(r'^[A-Za-z]+$',var): valid = True        # match letters only, no numbers
    elif itype == 'string':
        if re.match(r'^\w+$',var): valid = True             # match alphanumeric chars
    elif itype == 'word':
        if re.match(r'^[A-Za-z]+$|\d+$',var): valid = True        # match letters or numbers only
    elif itype == 'list':
        if var in stype: valid = True                       # if var is in the list, gogogo
    else:
        print("Function Error - Invalid argument 'itype': ", itype)

    #print("using:  valid = ", valid)
    if not valid:
        if emsg:
            print(emsg, "'", var, "'", sep='')    # only print error message if valid = false

    return(retvar, valid, 0)
####++++++++++++++++++++++++++++++####
##  end function - chk_valid_input  ##
####++++++++++++++++++++++++++++++####


###------------------------------------------###
###  read a file and return it as a list...  ###
###------------------------------------------###
def file_get(filname):
    print("Reading file: ", filname)
    Slist = []    # list for the file contents (lines)

    try:
        file_obj = open(filname, 'r')
        line = file_obj.readline()
        line = line.rstrip('\n')
        while line != '':
            num = 0
            try:
                #print("trying line: ", line)
                num = int(line)
            except ValueError:
                print("Error converting line to int: ", line)
            if num: Slist.append(num)
            line = file_obj.readline()
            line = line.rstrip('\n')
        file_obj.close()

    except IOError:
        print("Error opening file for read: ", filname)



    ### this method is way easier IMHO
    #with open(filname) as file_obj:
    #    Flist = file_obj.readlines()
    #Slist = list(map(str.strip, Flist))

    print()
    return(Slist)
###+++++++++++++++++++++++++###
###  end file_get function  ###
###+++++++++++++++++++++++++###


###------------------------------------------------###
###  read a file qwick and return it as a list...  ###
###------------------------------------------------###
def file_getlist(filname):
    print("Reading file: ", filname)
    fList = []    # list for the file contents (lines)

    ### this method is way easier IMHO
    with open(filname) as file_obj:
        fList = file_obj.readlines()
    fList = list(map(str.strip, fList))

    print()
    return(fList)
###+++++++++++++++++++++++++++++###
###  end file_getlist function  ###
###+++++++++++++++++++++++++++++###


###-------------------------------###
###  write a file from a list...  ###
###-------------------------------###
def file_put(filname, Flist):
    print("Writing file: ", filname)
    #Flist = []    # list for the file contents (lines)

    try:
        file_obj = open(filname, 'w')
        for item in Flist:
            try:
                #print("trying item: ", item)
                snum = str(item)
            except ValueError:
                print("Error converting line to int: ", line)
            file_obj.write(snum + '\n')
        file_obj.close()

    except IOError:
        print("Error opening file for write: ", filname)

    print('')
    return(1)
###+++++++++++++++++++++++++###
###  end file_put function  ###
###+++++++++++++++++++++++++###


###-------------------------------###
###  get the days of the week...  ###
###-------------------------------###
def get_daysofweek(dlength='short', dtype='full'):
    Longdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
    Shortdays = []
    dList = []
    for day in Longdays:
        Shortdays.append(day[0:3])
    if dlength == 'long':
        dList = Longdays
    else:
        dList = Shortdays
    if dtype == 'bus':
        dList = dList[1:6]

    return(dList)
###+++++++++++++++++++++++++++++++###
###  end get_daysofweek function  ###
###+++++++++++++++++++++++++++++++###


###--------------------------------------###
###  get the total&average of a list...  ###
###--------------------------------------###
def get_List_totavg(iList):
    (total, average) = (0, 0)
    count = len(iList)
    if count == 0:
        print("Error:  Empty list passed to get_List_totavg.")
    else:
        for amt in iList:
            total += amt
        average = total / count

    return(total, average)
###++++++++++++++++++++++++++++++++###
###  end get_List_totavg function  ###
###++++++++++++++++++++++++++++++++###


###---------------------------------###
###  get the months of the year...  ###
###-----------------------------  --###
def get_monsofyear(dlength='short'):
    # define a dictionary for #days in each month
    (mList, Mon_days) = ([], {})
    nDays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    Longmons = ['January', 'February', 'March', 'April', 'May', 'June', \
       'July', 'August', 'September', 'October', 'November', 'December']
    if dlength == 'long':
        mList = Longmons
    elif dlength == 'short':
        for mon in Longmons:
            mList.append(mon[0:3])
    else:
        print("Error: Invalid arg dlength: ", dlength, "in function get_monofyear.")
    for i in range(12):
        Mon_days[mList[i]] = nDays[i]

    return(Mon_days)
###+++++++++++++++++++++++++++++++###
###  end get_monsofyear function  ###
###+++++++++++++++++++++++++++++++###


###---------------------------------------###
###  get standard input from the user...  ###
###---------------------------------------###
def get_user_input(itype='posint'):
    # set function parameters for get_valid_input (in ToolKit.py)...
    (var, prompt, emsg, stype) = ('', '', '', '')
    if itype == 'amount':
        prompt = "Enter the amount:  "
        itype = 'floater'
        stype = 'pos'
        emsg = "Error:  Must enter a positive amount, not:  "
    elif itype == 'integer':
        prompt = "Enter an integer:  "
        itype = 'integer'
        emsg = "Error:  Must enter an integer, not:  "
    elif itype == 'floater':
        prompt = "Enter a number:  "
        itype = 'floater'
        emsg = "Error:  Must enter a number, not:  "
    elif itype == 'posint':
        prompt = "Enter a positive integer:  "
        itype = 'integer'
        stype = 'pos'
        emsg = "Error:  Must enter a positive integer, not:  "
    else:
        print("Function Error in get_user_input - invalid argument 'itype': ", itype)
        return(0)


    # use function get_valid_input to get the user input...
    (var, done) = get_valid_input(itype, prompt, emsg, stype)

    return(var)
###+++++++++++++++++++++++++++++++###
###  end get_user_input function  ###
###+++++++++++++++++++++++++++++++###


###------------------------------------------------###
###  get a list input of amounts from the user...  ###
###------------------------------------------------###
def get_user_input_Amounts(dList, itype='posint', stype='nneg'):
    Amounts = []
    # set function parameters for get_valid_input (in ToolKit.py)...
    emsg = "Error:  Must enter a positive amount, not:  "
    for day in dList:
        prompt = "Enter the sales amount for " + day + ":  "
        # use function get_valid_input to get the user input...
        (var, done) = get_valid_input(itype, prompt, emsg, stype)
        if done: break
        Amounts.append(var)

    return(Amounts)
###+++++++++++++++++++++++++++++++++++++++###
###  end get_user_input_Amounts function  ###
###+++++++++++++++++++++++++++++++++++++++###


###-------------------------------------###
###  get a list input from the user...  ###
###-------------------------------------###
def get_user_input_List(prompt, emsg, itype='posint', stype='nneg'):
    (done, iList) = (0, [])
    while (done != 1):        # begin loop to check a single variable input
        # use function get_valid_input to get the user input...
        (var, done) = get_valid_input(itype, prompt, emsg, stype)
        if done: break
        iList.append(var)

    return(iList)
###++++++++++++++++++++++++++++++++++++###
###  end get_user_input_List function  ###
###++++++++++++++++++++++++++++++++++++###


####==================================####
##  get a valid input variable by type  ##
####==================================####
def get_valid_input(itype, prompt='Enter: ', emsg='', stype=''):
    (valid, done) = (0, 0)
    while (valid != True):     # begin loop to check a single variable input
        var = input(prompt)    # get input variable from user with prompt message
        # call function to check if input variable is valid using arguments
        (var, valid, done) = chk_valid_input(var, itype, emsg, stype)
        #vtype = type(var)
        #print('vtype is', vtype, "valid = ", valid)
        print()
        if done: break

    return(var, done)
####++++++++++++++++++++++++++++++####
##  end function - get_valid_input  ##
####++++++++++++++++++++++++++++++####


###-----------------------------------###
###  determine if number is prime...  ###
###-----------------------------------###
def is_prime(number):
    prime = False                          # more numbers are not prime than are
    if number == 1: return(prime)          # 1 cannot be a prime number
    if number == 2: return(True)           # 2 is a prime number
    if number % 2 == 0: return(prime)      # all other even numbers are not prime
    # only need to go to square root + 1 to find factors
    #print("da sqrt:  ", f'{math.sqrt(number):>6.4f}')
    #print("use int:  ", int(math.sqrt(number)) + 1)
    #print("use ceil: ", math.ceil(math.sqrt(number)))
    for i in range(3, math.ceil(math.sqrt(number)), 2):
        if number % i == 0: return(prime)  # i is a factor of number, so not prime
    return(True)                           # no factors found, so number is prime
###+++++++++++++++++++++++++###
###  end is_prime function  ###
###+++++++++++++++++++++++++###




###  end-of-file  ###
