#include<stdio.h>
//#include "getAvgAndNorm.cu"

//TODO: Modify for larger dataset. For small dataset, actual no. of rows were greater than what was specified in the MovieLens website

#define ROWS 629
#define COLS 9000

char fileName[] = "./ratings_small.csv";
float ratings[ROWS][COLS];
float avg[ROWS];
float average[ROWS];
float norm_val[ROWS];
void readCSV(){
        int user, item;
        float score;
        long ts;
        FILE *fp;
        fp = fopen(fileName, "r");
        fscanf(fp, "%*[^\n]\n", NULL);
        do
				{
                fscanf(fp,"%d,%d,%f,%ld\n", &user, &item, &score, &ts);
                ratings[user][item] = score;
        }
	while(!feof(fp));
}

void serial_mean(){
        int row,col;
        for(row=0;row<ROWS;row++){
                average[row] = 0.0;
                int count = 0;
                for(col=0;col<COLS;col++){
                        if(ratings[row][col]!=0.0)
                        {
                                count++;
                                average[row] += ratings[row][col];
                        }
                }
                average[row] = (float)average[row]/count;
        }
}

//serial implementation of computing Ri-R_mean
int compare()
{
        int row,col;
        for(row=0;row<ROWS;row++){
               if(fabs(average[row] - avg[row]) > 0.5)
                        return 0;
        }
        return 1;
}
__global__ void GetAverageAndNorm(float *R, int N, float *avg, float *norm){
        int tid = blockIdx.x*blockDim.x + threadIdx.x, countNonZero = 0.0f;
        float sum = 0, avgThread;
        for(int i = 0; i < N; i++){
                if (R[tid * N + i] > 0.0f) {
                        sum += R[tid * N + i];
                        countNonZero++;
                }
        }
        avgThread = (float) sum/countNonZero;
        avg[tid] = avgThread;
	sum = 0;
        for(int i = 0;  i < N; i++){
                if (R[tid * N + i] != 0) {
                        float t = R[tid * N + i] - avgThread;
                        sum += t*t;
                }
        }
	norm[tid] = sum;
}

int main(){
       	float *d_ratings, *d_avg, *d_norm;
        readCSV();
                             
        cudaMalloc((void**)&d_ratings, ROWS * COLS * sizeof(float));
        cudaMalloc((void**)&d_avg, ROWS * sizeof(float));
        cudaMalloc((void**)&d_norm, ROWS * sizeof(float));
        cudaMemcpy(d_ratings, ratings, ROWS * COLS * sizeof(float), cudaMemcpyHostToDevice);
        GetAverageAndNorm<<<1, ROWS>>>(d_ratings, COLS, d_avg, d_norm);
        cudaMemcpy(avg, d_avg, ROWS * sizeof(float), cudaMemcpyDeviceToHost);
        cudaMemcpy(norm_val, d_norm, ROWS * sizeof(float), cudaMemcpyDeviceToHost);

        for(int i = 0; i < ROWS; i++){
		printf("%f ", avg[i]);
        } 
        for(int i = 0; i < ROWS; i++){
		printf("%f ", norm_val[i]);
        } 
        serial_mean();  
        printf("\n\n\n\n\n RESULT = %d", compare()); 


}
