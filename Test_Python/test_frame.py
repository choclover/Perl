#!/usr/bin/env python

#coding:gb2312

import os,time,sys,datetime

from threading import Thread, Event



count = 0

def get_log_filename():

    global count

    count+=1

    return 'log_1_%02d.txt' % count

    



#define the child thread class

class testit(Thread):

    def __init__ (self,x):

        Thread.__init__(self)

        self.x = x

        self.line = 'no ret'

        self.log_file = get_log_filename()

        self.file_handle = file(self.log_file,'w')

        self._stopevent = Event()

        

    def run(self):

        #run external script with parameter!

        ext_call = os.popen("./multi_connect "+self.x,"r")

        while True:

            self.line = ext_call.readline()

            if not self.line: break

            self.file_handle.write(self.line)

            #self.file_handle.flush()

            print self.x, '=>', self.line,

        self._stopevent.wait(1)

        self.file_handle.close()    

    def join(self, timeout = None):

        """ Stop the thread. """

        self._stopevent.set()

                   

n = 0

def run_test():

    global n

    runlist = []

    #generate different parameters

    for i in range(1,6):

       x = 'perf_client1_1_%d 10.0.5.0/24' % i

       #generate child thread

       th = testit(x)

       runlist.append(th)

    for j in range(1,6):

       x = 'perf_client1_2_%d 10.0.8.0/24' % j

       #generate child thread

       th = testit(x)

       runlist.append(th)

    #start all threads    

    for th in runlist:

       th.start()

       n += 1 

    #wait for all child threads exits

    for th in runlist:

       th.join()

       #print "Status from ",th.x,"is ",th.line



print 'Test begin time:', time.strftime('%m/%d %H:%M:%S ')

t1 = datetime.datetime.now()

#execute test       

run_test()

df_time = datetime.datetime.now() - t1

print 'Test end time:',  time.strftime('%m/%d %H:%M:%S ')

print 'Loops:', n, ' time cost:', df_time



multi_connect:
#!/home/users/lqiao/software/expect-5.43/expect -f

#set timeout 30



set client_id [lindex $argv 0] 

set address [lindex $argv 1]



spawn ssh -l  root 10.0.7.219

sleep 10

expect "root@10.0.7.219's password:"

sleep 10

send "policies\r"

sleep 10

set timeout 30

expect "~]#"

sleep 10

send "/opt/camiant/platform/bin/diamcli\r"

sleep 10

expect "Diameter>"

sleep 10

send "test perf rx -hostname=10.0.7.131 -realm=test.example.com -remoteidentity=topmpe.test.example.com  -identity=$client_id -numclients=1 -transactions=1000 -cycles=0 -addressrange=$address -disconnect=true -verbose=on -modifies=1 -duration=7200 -output=/root/$client_id -timeout=5000\r"

sleep 10

expect "Diameter>"

sleep 10

send "exit\r"

sleep 10

expect "~]#"

sleep 10

send "exit\r"

#sleep 10



interact



