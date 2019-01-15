#include<stdio.h>
#include "getAverageAndNorm.cu"
#include "dataReader.c"
#include "calculateSimilarityMatrix.cu"
#include "transpose_kernel.cu"

float avg[ROWS];
float norm_val[ROWS];
float sim[ROWS*ROWS];
float global_sim[ROWS*ROWS];
// float transpose[COLS][ROWS];

int isSimilarityCorrect(){
	printf("%d\t%d\n",ROWS,COLS);
        for(int i = 0; i < ROWS; i++){
                for(int j = i; j < ROWS; j++){
			float temp = similarity_matrix[i][j];
                        if(abs(sim[i*ROWS+j] - temp) > 0.01){
                                printf("(%d, %d): GPU=%f CPU=%f\n", i, j, sim[i*ROWS+j], similarity_matrix[i*ROWS+j]);
                                return 0;
                        }
                }
        }
        return 1;
}

int isAverageCorrect(){
        for(int i = 0; i < ROWS; i++){
                if(fabs(avg[i] - avg_rating[i]) > 0.00001){
                        printf("(%d): GPU=%f CPU=%f\n", i, avg[i], avg_rating[i]);
                        return 0;
                }
        }
        return 1;
}

// void transposeMatrix(){
//         for(int i = 0; i < ROWS; i++){
//                 for(int j = 0; j < COLS; j++){
//                         transpose[j][i] = ratings[i][j];
//                 }
//         }
// }

int main(){
        float *d_ratings, *d_avg, *d_norm, *d_sim, *d_transpose, *d_sim_global;
        dim3 dimGrid(ROWS/TILE_WIDTH + 1, ROWS/TILE_WIDTH + 1, 1);
        dim3 dimBlock(TILE_WIDTH, TILE_WIDTH, 1);
	cudaEvent_t start,stop;
        cudaEventCreate(&start);
        cudaEventCreate(&stop);
	printf("Loading CSV data.........\n");
        cudaEventRecord(start);
        readCSV();
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        float milliseconds = 0.0f;
        cudaEventElapsedTime(&milliseconds,start,stop);
        printf("Time taken to load csv = %f seconds\n\n",(float)milliseconds/1000);
	printf("Executing serial code\n");
	printf("Computing average serial code\n");
	cudaEventRecord(start);
	serial_mean();
	cudaEventRecord(stop);
	cudaEventSynchronize(stop);
        milliseconds = 0.0f;
        cudaEventElapsedTime(&milliseconds,start,stop);
        printf("Time taken for computing average serial implementation = %f seconds\n\n",(float)milliseconds/1000);

	printf("computing serial similarity matrix\n\n");
	cudaEventRecord(start);
	build_similarity_matrix();
	cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        milliseconds = 0.0f;
        cudaEventElapsedTime(&milliseconds,start,stop);
        printf("Time taken for Similarity matrix serial implementation = %f seconds\n\n",(float)milliseconds/1000);
        printf("Allocating device memory and copy data\n");
        cudaEventRecord(start);
        cudaMalloc((void**)&d_ratings, ROWS * COLS * sizeof(float));
        cudaMalloc((void**)&d_avg, ROWS * sizeof(float));
        cudaMalloc((void**)&d_norm, ROWS * sizeof(float));
        cudaMalloc((void**)&d_sim, ROWS * ROWS * sizeof(float));
	cudaMalloc((void**)&d_transpose, ROWS * COLS * sizeof(float));
        cudaMemcpy(d_ratings, ratings, ROWS * COLS * sizeof(float), cudaMemcpyHostToDevice);


        //transpose kernel being called
        // Matrix out = AllocateMatrix(4, 6, 1);
//     Matrix d_out = AllocateDeviceMatrix(out);
//     CopyToDeviceMatrix(d_out, out);


        cudaMemcpy(sim, d_sim, ROWS * ROWS * sizeof(float), cudaMemcpyDeviceToHost);
	//transpose<<<transGrid, transBlock>>>(d_transpose, d_ratings, COLS, ROWS);
        float trans_blocks_x = COLS/TILE_DIM+1;
        float trans_blocks_y = ROWS/TILE_DIM+1;

        dim3 transGrid(trans_blocks_x, trans_blocks_y);
        dim3 transBlock(TILE_DIM, TILE_DIM);

	//transpose<<<transGrid, transBlock>>>(d_transpose, d_ratings, COLS, ROWS);
        cudaEventRecord(stop);
        cudaDeviceSynchronize();
        cudaEventSynchronize(stop);
        milliseconds = 0.0f;
        cudaEventElapsedTime(&milliseconds,start,stop);
        printf("Time taken for allocating device memory and loading data = %f seconds\n\n",(float)milliseconds/1000);

        cudaMalloc((void**)&d_sim_global, ROWS * ROWS * sizeof(float));
	
	printf("Computing transpose.....\n");
	cudaEventRecord(start);
	transpose<<<transGrid, transBlock>>>(d_transpose, d_ratings, COLS, ROWS);
	cudaDeviceSynchronize();
	cudaEventRecord(stop);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&milliseconds,start,stop);
	printf("Time taken to compute transpose = %f seconds\n\n",(float)milliseconds/1000);	

        printf("Getting Average and Norm.....\n");
        cudaEventRecord(start);
	GetAverageAndNorm<<<1, ROWS>>>(d_transpose, ROWS, COLS, d_avg, d_norm);
        cudaDeviceSynchronize();
	cudaEventRecord(stop);
	cudaDeviceSynchronize();
	cudaEventSynchronize(stop);
        cudaMemcpy(avg, d_avg, ROWS * sizeof(float), cudaMemcpyDeviceToHost);
	milliseconds = 0.0f;
	cudaEventElapsedTime(&milliseconds,start,stop);
	printf("Time taken for computing average and norm = %f seconds\n\n",(float)milliseconds/1000);

	printf("Computing Similarity matrix using tiling\n");
	cudaEventRecord(start);
        calculateSimilarityMatrix<<<dimGrid, dimBlock>>>(d_ratings,d_transpose,d_sim,COLS, ROWS, d_avg, d_norm);
        cudaMemcpy(sim, d_sim, ROWS * ROWS * sizeof(float), cudaMemcpyDeviceToHost);
	cudaEventRecord(stop);
	milliseconds = 0.0f;
	cudaDeviceSynchronize();
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&milliseconds,start,stop);
        printf("Execution time for Tiled parallel version similarity matrix computation: %f  seconds\n\n",(float)milliseconds/1000);

	printf("Computing Similarity Matrix using Global Memory\n");
        cudaEventRecord(start);
	calculateSimilarityMatrixGlobal<<<dimGrid, dimBlock>>>(d_ratings, d_sim_global, COLS, ROWS, d_avg, d_norm);
        cudaMemcpy(global_sim, d_sim_global, ROWS * ROWS * sizeof(float), cudaMemcpyDeviceToHost);
        cudaEventRecord(stop);
        milliseconds = 0.0f;
	cudaDeviceSynchronize();
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&milliseconds,start,stop);
        printf("Execution time for global memory version similarity matrix computation : %f  seconds\n\n",(float)milliseconds/1000);
        printf("Average values are %s\n", isAverageCorrect()? "correct" : "incorrect");
        printf("Similarity values are %s\n", isSimilarityCorrect()? "correct" : "incorrect");

}
