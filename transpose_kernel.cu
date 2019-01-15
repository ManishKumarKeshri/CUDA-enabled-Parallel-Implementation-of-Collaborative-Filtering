#include<stdio.h>

#define TILE_DIM 32

__global__ void transpose(float *odata, const float *idata,
int width, int height)
{
__shared__ float tile[TILE_DIM][TILE_DIM+1];
int x = blockIdx.x * TILE_DIM + threadIdx.x;
int y = blockIdx.y * TILE_DIM + threadIdx.y;

if (x < width && y < height)
{ tile[threadIdx.y][threadIdx.x] = idata[y*width + x]; }
__syncthreads();

x = blockIdx.y * TILE_DIM + threadIdx.x; // transpose block offset
y = blockIdx.x * TILE_DIM + threadIdx.y;
if (y < width && x < height)
{ odata[y*height + x] = tile[threadIdx.x][threadIdx.y]; }
}
