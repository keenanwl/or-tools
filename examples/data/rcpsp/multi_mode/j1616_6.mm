************************************************************************
file with basedata            : md208_.bas
initial value random generator: 1210888507
************************************************************************
projects                      :  1
jobs (incl. supersource/sink ):  18
horizon                       :  112
RESOURCES
  - renewable                 :  2   R
  - nonrenewable              :  2   N
  - doubly constrained        :  0   D
************************************************************************
PROJECT INFORMATION:
pronr.  #jobs rel.date duedate tardcost  MPM-Time
    1     16      0       22        7       22
************************************************************************
PRECEDENCE RELATIONS:
jobnr.    #modes  #successors   successors
   1        1          3           2   3   4
   2        3          3          14  15  17
   3        3          3           5  10  15
   4        3          3           8   9  13
   5        3          3           6   7   8
   6        3          2          11  12
   7        3          3          12  13  17
   8        3          2          11  14
   9        3          1          12
  10        3          3          11  13  14
  11        3          1          17
  12        3          1          16
  13        3          1          16
  14        3          1          16
  15        3          1          18
  16        3          1          18
  17        3          1          18
  18        1          0        
************************************************************************
REQUESTS/DURATIONS:
jobnr. mode duration  R 1  R 2  N 1  N 2
------------------------------------------------------------------------
  1      1     0       0    0    0    0
  2      1     3       9    6    9    0
         2     5       6    5    0    7
         3     7       5    3    4    0
  3      1     3       6    7    0    9
         2     4       6    6    8    0
         3     4       6    7    0    4
  4      1     3       8    9    7    0
         2     3       8    8    0    4
         3     7       8    8    0    3
  5      1     2       9    2    0    9
         2     4       9    1    0    6
         3     4       8    1    6    0
  6      1     8       3    3    0    1
         2     8       4    3    5    0
         3    10       3    1    3    0
  7      1     1       4   10    3    0
         2     2       3   10    0    5
         3    10       2    9    0    5
  8      1     2       3    2    0    9
         2     4       3    2    0    4
         3     7       2    2   10    0
  9      1     1       8    9    0    7
         2     1       8    5    0    9
         3    10       8    3    6    0
 10      1     2      10    6    0    6
         2     4       9    6    0    3
         3     6       6    5    0    3
 11      1     3       6    3    0    4
         2     3       5    6    9    0
         3     3       5    4    0    1
 12      1     1       9    6    9    0
         2     5       6    3    7    0
         3     5       7    4    6    0
 13      1     1      10    6    6    0
         2     5       7    5    5    0
         3     7       5    5    5    0
 14      1     4       7    8    4    0
         2     6       6    8    3    0
         3     7       5    6    0    3
 15      1     2       8    6    0    8
         2     4       8    5    0    5
         3     8       8    5    1    0
 16      1     6       8    5    0    3
         2     9       5    4    7    0
         3    10       3    3    3    0
 17      1     6       8    5    7    0
         2     7       8    4    0    8
         3     7       8    3    6    0
 18      1     0       0    0    0    0
************************************************************************
RESOURCEAVAILABILITIES:
  R 1  R 2  N 1  N 2
   35   23   54   44
************************************************************************
