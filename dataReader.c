#include<stdio.h>
//TODO: Modify for larger dataset. For small dataset, actual no. of rows were greater than what was specified in the MovieLens website

#define ROWS 629
#define COLS 9000

char fileName[] = "./ratings_small.csv";
float ratings[ROWS][COLS];
float avg_rating[ROWS];
float similarity_matrix[ROWS][ROWS];;


void readDat(){
	int user, item;
        float score;
        long ts;
        FILE *fp;
        fp = fopen(fileName, "r");
        fscanf(fp, "%*[^\n]\n", NULL);
        do
    	{
        	fscanf(fp,"%d::%d::%f::%ld\n", &user, &item, &score, &ts);
                ratings[user - 1][item - 1] = score;
    	}
    	while(!feof(fp));

}

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
	if(item>=COLS||user>=ROWS)	
	continue;
		ratings[user - 1][item - 1] = score;
    }
    while(!feof(fp));
}

//Serial implementation of average for each user
void serial_mean(){
	int row,col;
	for(row=0;row<ROWS;row++){
		avg_rating[row] = 0.0;
		int count = 0; 
		for(col=0;col<COLS;col++){
			if(ratings[row][col]!=0.0)
			{
				count++;
				avg_rating[row] += ratings[row][col];
			}
		}
		if(count!=0)
		avg_rating[row] = (float)avg_rating[row]/count;
		else
		avg_rating[row] = 0.0f;
	}
}

void build_similarity_matrix(){
        float numerator, sigmA, sigmB;
        int i,j,k;
                for(i=0;i<ROWS;i++){
                        for(j=i;j<ROWS;j++){
                                        numerator = 0.0; sigmA = 0.0, sigmB = 0.0;
                                        for(k=0;k<COLS;k++){
                                                        if(ratings[i][k]!=0.0 && ratings[j][k]!=0.0){
                                                                numerator += (ratings[i][k]-avg_rating[i]) * (ratings[j][k]-avg_rating[j]);
                                                        }
                                                        if(ratings[i][k]!=0.0)
                                                                sigmA += pow(ratings[i][k]-avg_rating[i],2);
                                                        if(ratings[j][k]!=0.0)
                                                                sigmB += pow(ratings[j][k]-avg_rating[j],2);
                                        }
                                        float denominator = sqrt(sigmA * sigmB);
                                        if(denominator!=0.0)
                                                similarity_matrix[i][j] = numerator/denominator;                                                                                                                                                  else                                                                                                                                                                                                          similarity_matrix[i][j] = 0.0;
					//similarity_matrix[j][i] = similarity_matrix[i][j];
                                      }
                        }
}


//serial implementation of computing Ri-R_mean
void compute_difference()
{
	int row,col;
	for(row=0;row<ROWS;row++){
		for(col=0;col<COLS;col++){
			if(ratings[row][col]!=0.0)
				ratings[row][col] = ratings[row][col]-avg_rating[row];
		}
	}
}
