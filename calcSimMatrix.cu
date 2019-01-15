#ifndef _SIM_MATRIX_CALCULATION_
#define _SIM_MATRIX_CALCULATION_

#include <stdio.h>
#include <cuda.h>
#include <math.h>
#define TILE_WIDTH 16

__global__ naiveSimMatrix(float **R,float **S, float * avgArray, int width,int numUsers){
	int tid = threadIdx.x;
	int row = blockDim.y*blockIdx.y+threadIdx.y;
	int col = blockDim.x*blockIdx.x+threadIdx.y;
	float val = 0.0;
	for(int i=0;i<width;i++) {
		val += (R[row*width+i]-avgArray[row])*(R[col*width+i]-avgArray[col]);
		sigmaA += R[row*width+i]*R[row*width+i];
		sigmaB += R[col*width+i]*R[col*width+i];
	}
	float denom = sqrt(sigmaA*sigmaB)
	S[row*width+col] = val;
}

__global__ void calcSimMatrix(float *R,float *S,float *aveArray,int width)
{
  int bx = blockIdx.x; //get x and y coordinates of block
	int by = blockIdx.y;
	int tx = threadIdx.x; //get x and y coordinates of thread
	int ty = threadIdx.y;

  if(by>bx) // skip the calculation of results below diagonal
    return;

  __shared__ float ATile[TILE_WIDTH][TILE_WIDTH];
	__shared__ float BTile[TILE_WIDTH][TILE_WIDTH];
  __shared__ float AAverage[TILE_WIDTH];
	__shared__ float BAverage[TILE_WIDTH];

  if(ty==0){
    // Prasanth's function to load average values of ATile into AAverage
  }
  if(ty==1){
    //same here to load average values of BTile into BAverage
  }
  int row = by * TILE_WIDTH + ty; // get row and col in S
  int col = bx * TILE_WIDTH + tx;

  float dotproduct = 0, sigmA = 0, sigmB = 0, pearson_correlation;
  if(row<TILE_WIDTH && col<TILE_WIDTH){ // check the bounds
    for(int i=0;i<ceilf(width/(float)TILE_WIDTH);i++){ // loop all the elements in the row
      ATile[tx][ty] = R[row * width + i * TILE_WIDTH + tx] - AAverage[ty];
      BTile[tx][ty] = R[col + (i * TILE_WIDTH + ty) * width] - BAverage[ty];

      __syncthreads();

      for(int k=0;k<TILE_WIDTH; k++){
        dotproduct += ATile[ty][k] * BTile[tx][k];
        sigmA += ATile[ty][k] * ATile[ty][k];
        sigmB += BTile[tx][k] * BTile[tx][k];
      }

      __syncthreads();
    }
    pearson_correlation = dotproduct / sqrt(sigmA * sigmB);
    S[row * width + col] = pearson_correlation;
  }
}

#endif
