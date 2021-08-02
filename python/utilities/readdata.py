def h5filedump(filename):
    '''
    Determines variables within a hdf file so you can pring them to screen

    Parameters:
        filename:  The full path to the hdf file to open (string)
    
    r.r.b. 2021-04-14
    '''

    import subprocess
    cmd = 'h5dump -n ' + filename
    # returns output as byte string
    shell_process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    # convert to string
    subprocess_return = shell_process.stdout.read().decode('utf8').strip()
    # Human readable
    mystr = subprocess_return.split(sep='\n')
    return(mystr)
