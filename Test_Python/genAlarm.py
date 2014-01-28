
import os
import random
s = 'alarm.put -e "%d" -s "%d" -t inetsync -i "%d" -m \'alarm.msg,%03d\';'
r = random.Random()
numAlarms = 65000
rangeLow = 1
rangeHigh = 3
for i in range(numAlarms):
  sev = r.randint(rangeLow,rangeHigh)
  t = s % (71702,sev, i, i)
  print t
  os.system(t)

