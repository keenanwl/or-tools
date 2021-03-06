************************************************************************
file with basedata            : md177_.bas
initial value random generator: 19626
************************************************************************
projects                      :  1
jobs (incl. supersource/sink ):  16
horizon                       :  116
RESOURCES
  - renewable                 :  2   R
  - nonrenewable              :  2   N
  - doubly constrained        :  0   D
************************************************************************
PROJECT INFORMATION:
pronr.  #jobs rel.date duedate tardcost  MPM-Time
    1     14      0       19        7       19
************************************************************************
PRECEDENCE RELATIONS:
jobnr.    #modes  #successors   successors
   1        1          3           2   3   4
   2        3          3           6   7   9
   3        3          2           7   8
   4        3          3           5   7  13
   5        3          2          14  15
   6        3          3          12  13  14
   7        3          2          10  12
   8        3          2          10  11
   9        3          1          11
  10        3          1          15
  11        3          3          12  13  14
  12        3          1          15
  13        3          1          16
  14        3          1          16
  15        3          1          16
  16        1          0        
************************************************************************
REQUESTS/DURATIONS:
jobnr. mode duration  R 1  R 2  N 1  N 2
------------------------------------------------------------------------
  1      1     0       0    0    0    0
  2      1     3       6    0    6    5
         2     4       0    5    6    5
         3     9       0    5    5    2
  3      1     1       0    6    6    6
         2     6       3    0    6    6
         3     6       0    6    6    5
  4      1     1       0    9    4   10
         2     9       0    9    3   10
         3    10       0    8    1    9
  5      1     6       8    0    5   10
         2     7       3    0    4   10
         3     9       0    2    3   10
  6      1     6       4    0    9    6
         2     8       3    0    7    3
         3     9       2    0    5    3
  7      1     5       0    3    9    3
         2     6       6    0    5    3
         3     9       0    2    3    2
  8      1     6       0   10    7   10
         2     9       0    9    7    6
         3    10       0    9    7    5
  9      1     2       6    0    9    5
         2     4       0    6    7    4
         3    10       1    0    7    3
 10      1     2      10    0   10    2
         2     4       0    9    6    2
         3     6       0    7    3    2
 11      1     4       0   10    8    8
         2     6       1    0    6    5
         3     8       0   10    6    5
 12      1     1       0    7    5    3
         2     3       0    6    3    3
         3     3       5    0    5    3
 13      1     4       5    0    8   10
         2     6       0    7    5    5
         3    10       0    3    2    3
 14      1     4       0   10    9    2
         2     5       8    0    9    2
         3     9       0    9    9    2
 15      1     7       6    0    8    5
         2     8       0    5    7    5
         3     8       2    0    7    4
 16      1     0       0    0    0    0
************************************************************************
RESOURCEAVAILABILITIES:
  R 1  R 2  N 1  N 2
    7   15   94   78
************************************************************************
