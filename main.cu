// includes, system
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

//#include "cutil.h"

// includes, kernels
#include "vectoradd_kernel.cu"

#define MAXLINE 100000

////////////////////////////////////////////////////////////////////////////////
// declarations, forward

extern "C"
void computeGold(float*, const float*, const float*, unsigned int);

"vectoradd.cu" [dos] 212L, 6159C                              17,0-1        Top

