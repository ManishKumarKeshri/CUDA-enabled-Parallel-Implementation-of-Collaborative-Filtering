#include <stdio.h>

#define TILE_WIDTH 16

//calculate similarity matrix using global memory
__global__ void calculateSimilarityMatrixGlobal(float *M,float *P,int width,int height,float *avgArray,float *norm_val) 
{
	//thread indices and block indices
        int tx = threadIdx.x;
        int ty = threadIdx.y;
        int bx = blockIdx.x;
        int by = blockIdx.y;

        //row and column indices of element of P being calculated
        int row = by * blockDim.y + ty;
        int column = bx * blockDim.x  + tx;

	float val = 0.0;
	float num,denom; 
	for(int i=0;i<width;i++)
	{
		if(row<height && column<height && M[row*width+i]>0.0f && M[column*width+i]>0.0f)
			val += (M[row*width+i]-avgArray[row])*(M[column*width+i]-avgArray[column]);
			
	}
	if(row<height && column<height && norm_val[row]>0.0f && norm_val[column]>0.0f)
		denom = (float)sqrt(norm_val[row])*sqrt(norm_val[column]);
	if(row<height && column< height)
	{	
		if(denom>0.0f)
			P[row*height+column] = val/denom;
		else
			P[row*height+column] = 0.0f;
	}
}


// Matrix multiplication kernel thread specification
__global__ void calculateSimilarityMatrixNoTranspose(float *M,float *N,float *P,int width, int height,float *avgArray, float* norm_val)
{

  //variables declared in shared memory
        __shared__ float Ms[TILE_WIDTH][TILE_WIDTH];
        __shared__ float Ns[TILE_WIDTH][TILE_WIDTH];
        //thread indices and block indices
        int tx = threadIdx.x;
        int ty = threadIdx.y;
        int bx = blockIdx.x;
        int by = blockIdx.y;

        //row and column indices of element of P being calculated
        int row = by * TILE_WIDTH + ty;
        int column = bx * TILE_WIDTH + tx;

        float p_Val = 0;
        float numer, denom;

        // compute target element value
        for(int i=0;i<ceilf(width/(float)TILE_WIDTH);i++){

                if(row < height && (i*TILE_WIDTH + tx)<width)
                        Ms[ty][tx] = M[row*width + i*TILE_WIDTH + tx];
                else
                        Ms[ty][tx] = 0.0;

                //if(i*TILE_WIDTH+threadIdx.y <height && column<width)
                //        Ns[threadIdx.y][threadIdx.x] = N[(i*TILE_WIDTH+threadIdx.y)*width+column];
                //else
                //        Ns[threadIdx.y][threadIdx.x] = 0.0;


                //ensure that all values of the tile is available
                __syncthreads();

                for(int j=0;j<TILE_WIDTH;j++){
                        if(row < height && column < height && Ms[ty][j] > 0.0f && Ns[j][tx] > 0.0f){
                                p_Val += (Ms[ty][j]-avgArray[row]) * (Ns[j][tx]-avgArray[column]);
                                //p_Val += (Ms[ty][j]) * (Ms[tx][j]);
                        }
                }
                __syncthreads();

                if(column < height && row < height && norm_val[row] > 0.0f && norm_val[column] > 0.0f){
                        denom = (float) sqrt(norm_val[row]) * sqrt(norm_val[column]);
                }
                //ensure that all values of the tile are used
                __syncthreads();
        }

        //check the boundary condition
        if(row < height && column < height)
        {
                if(denom>0.0f)
                        P[row*height+column] = p_Val/denom;
                else
                        P[row*height+column] = 0.0f;
        }

}





// Matrix multiplication kernel thread specification
__global__ void calculateSimilarityMatrix(float *M,float *N,float *P,int width, int height,float *avgArray, float* norm_val)
{

  //variables declared in shared memory
        __shared__ float Ms[TILE_WIDTH][TILE_WIDTH];
	__shared__ float Ns[TILE_WIDTH][TILE_WIDTH];
        //thread indices and block indices
        int tx = threadIdx.x;
        int ty = threadIdx.y;
        int bx = blockIdx.x;
        int by = blockIdx.y;

        //row and column indices of element of P being calculated
        int row = by * TILE_WIDTH + ty;
        int column = bx * TILE_WIDTH + tx;

        float p_Val = 0;
        float numer, denom;

        // compute target element value
        for(int i=0;i<ceilf(width/(float)TILE_WIDTH);i++){
               
                if(row < height && (i*TILE_WIDTH + tx)<width)
                        Ms[ty][tx] = M[row*width + i*TILE_WIDTH + tx];
                else
                        Ms[ty][tx] = 0.0;
		
		if(i*TILE_WIDTH+threadIdx.y <width && column<height)
                        Ns[threadIdx.y][threadIdx.x] = N[(i*TILE_WIDTH+threadIdx.y)*height+column];
                else
                        Ns[threadIdx.y][threadIdx.x] = 0.0;


                //ensure that all values of the tile is available
                __syncthreads();

                for(int j=0;j<TILE_WIDTH;j++){
                        if(row < height && column < height && Ms[ty][j] > 0.0f && Ns[j][tx] > 0.0f){
                                p_Val += (Ms[ty][j]-avgArray[row]) * (Ns[j][tx]-avgArray[column]);
                                //p_Val += (Ms[ty][j]) * (Ms[tx][j]);
                        }
                }
		__syncthreads();

                if(column < height && row < height && norm_val[row] > 0.0f && norm_val[column] > 0.0f){
                        denom = (float) sqrt(norm_val[row]) * sqrt(norm_val[column]);
                }
                //ensure that all values of the tile are used
                __syncthreads();
        }

        //check the boundary condition
        if(row < height && column < height)
	{
		if(denom>0.0f)
               		P[row*height+column] = p_Val/denom;
		else
			P[row*height+column] = 0.0f;
	}

}
