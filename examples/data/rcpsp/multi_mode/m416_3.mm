************************************************************************
file with basedata            : cm416_.bas
initial value random generator: 1644555694
************************************************************************
projects                      :  1
jobs (incl. supersource/sink ):  18
horizon                       :  137
RESOURCES
  - renewable                 :  2   R
  - nonrenewable              :  2   N
  - doubly constrained        :  0   D
************************************************************************
PROJECT INFORMATION:
pronr.  #jobs rel.date duedate tardcost  MPM-Time
    1     16      0       18        0       18
************************************************************************
PRECEDENCE RELATIONS:
jobnr.    #modes  #successors   successors
   1        1          3           2   3   4
   2        4          2           7  13
   3        4          3           6   9  12
   4        4          3           5   6   7
   5        4          2           8  16
   6        4          2          10  13
   7        4          3           9  14  17
   8        4          3           9  12  13
   9        4          1          15
  10        4          2          11  14
  11        4          1          16
  12        4          2          15  17
  13        4          1          17
  14        4          2          15  16
  15        4          1          18
  16        4          1          18
  17        4          1          18
  18        1          0        
************************************************************************
REQUESTS/DURATIONS:
jobnr. mode duration  R 1  R 2  N 1  N 2
------------------------------------------------------------------------
  1      1     0       0    0    0    0
  2      1     2       5    2    0    5
         2     2       4    3    0    6
         3     2       4    3    5    0
         4     6       1    2    4    0
  3      1     1       8    7    9    0
         2     3       8    6    0    8
         3     4       5    6    0    6
         4     5       5    5    8    0
  4      1     4       9    5    5    0
         2     5       9    5    0    4
         3     7       7    4    4    0
         4    10       6    4    4    0
  5      1     4       6    9    0    6
         2     6       4    7    0    6
         3     7       4    6    0    5
         4     9       2    5    1    0
  6      1     1       5    3    0    5
         2     2       4    3    0    4
         3     7       4    2    0    4
         4     9       3    2    0    4
  7      1     2       8    8    0    7
         2     3       6    7   10    0
         3     6       2    7    8    0
         4     6       2    6    9    0
  8      1     2       7    8   10    0
         2     4       7    8    5    0
         3     7       7    7    0    8
         4    10       6    7    0    3
  9      1     1       5    9    0    9
         2     7       5    8    0    4
         3     9       5    8    0    1
         4    10       5    7    8    0
 10      1     1       6   10    0   10
         2     4       6    9    0   10
         3     7       5    6    0    9
         4     9       4    5    0    9
 11      1     4       8    9    6    0
         2     6       6    7    5    0
         3     6       6    7    0    7
         4     8       2    5    5    0
 12      1     1       8    4    0    8
         2     4       8    4    3    0
         3     6       8    3    0    6
         4     8       7    3    0    1
 13      1     3       4   10    0    6
         2     6       3    8    2    0
         3    10       3    5    2    0
         4    10       2    5    0    6
 14      1     6       8    5    0    9
         2     8       8    5    0    6
         3     9       6    4    0    6
         4    10       6    4    0    3
 15      1     4       3    7    0    8
         2     5       3    7    9    0
         3     7       3    7    2    0
         4    10       2    6    0    7
 16      1     6       6    9    0    6
         2     8       6    8    0    6
         3    10       6    6    0    5
         4    10       6    7    7    0
 17      1     4       5    6    0    9
         2     5       5    5    4    0
         3     6       4    3    0    6
         4     7       4    2    0    5
 18      1     0       0    0    0    0
************************************************************************
RESOURCEAVAILABILITIES:
  R 1  R 2  N 1  N 2
   25   28   40   66
************************************************************************
