#include<stdio.h>

__global__ void GetAverageAndNorm(float *R, int cols, int rows, float *avg, float *norm){
   /* int tid = blockIdx.x*blockDim.x + threadIdx.x, countNonZero = 0;
    float sum = 0.0f, avgThread = 0.0f;
    for(int i = 0; i < cols; i++){
            if (R[tid * cols + i] > 0.0f) {
                    sum += R[tid * cols + i];
                    countNonZero++;
            }
    }
    if(countNonZero > 0)
        avgThread = (float) sum/countNonZero;
    else
        avgThread = 0.0f;
    if(tid < rows)
        avg[tid] = avgThread;
    sum = 0;
    for(int i = 0;  i < cols; i++){
        if (R[tid * cols + i] > 0.0f){
            float t = R[tid * cols + i] - avgThread;
            sum += t*t;
        }
    }
    if(tid < rows)
        norm[tid] = sum;*/
int tid = blockIdx.x*blockDim.x + threadIdx.x, countNonZero = 0;
    float sum = 0.0f, avgThread = 0.0f;
    for(int i = 0; i < rows; i++){
            if (R[i * cols + tid] > 0.0f) {
                    sum += R[i * cols + tid];
                    countNonZero++;
            }
    }
    if(countNonZero > 0)
        avgThread = (float) sum/countNonZero;
    else
        avgThread = 0.0f;
    if(tid < cols)
        avg[tid] = avgThread;
    sum = 0;
    for(int i = 0;  i < rows; i++){
        if (R[i * cols + tid] > 0.0f){
            float t = R[i * cols + tid] - avgThread;
            sum += t*t;
        }
    }
    if(tid < cols)
        norm[tid] = sum;
}