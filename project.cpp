#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include<unordered_map>
#include<vector>
#include<cuda.h>
#include<ctime>
#include<stdio.h>
#include <algorithm>
#include<cmath>
#include <queue>
using namespace std;
#define ROWS 629
#define COLS 9000

//unordered_map<int, unordered_map<int, float>> rating_map;
vector<vector<float>> rating_map(ROWS, vector<float>(COLS, 0.0));
vector<float> avg_rating(ROWS);
vector<string> movie_map(COLS);
vector<vector<float>> similarity_matrix(ROWS, vector<float>(ROWS));
//char* fileName = "D:/APP_Project/ml-20m/ml-20m/ratings_small.csv";
char fileName[] = "./ratings_small.csv";
//unordered_map<int, vector<movie_rate>> cache;

bool read_movietitle(string filename) {
	fstream movie_title_file(filename, ios::in);
	if (!movie_title_file.is_open())
		return false;
	int id_int;
	string ID, title, genre;
  getline(movie_title_file, ID, ',');
  getline(movie_title_file, title, ',');
  getline(movie_title_file, genre);
	while(getline(movie_title_file, ID, ',')){
		getline(movie_title_file, title, ',');
		getline(movie_title_file, genre);
		id_int = stoi(ID);
		if(id_int>=COLS)
			continue;
		movie_map[id_int] = title + " ("+ genre + ")";
	}
	movie_title_file.close();
	return true;
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
					if(user>=ROWS || item>=COLS)
						continue;
					rating_map[user-1][item-1] = score;
    	}
    	while(!feof(fp));
}


// bool read_rating(string filename) {
// 	fstream rating_file(filename, ios::in);
// 		if (!rating_file.is_open())
// 			return false;
//
// 		int user_id, movie_id,rating;
// 		string movie_id_str, user_id_str, rating_str;
//     getline(rating_file, movie_id_str, ',');
//     getline(rating_file, user_id_str, ',');
//     getline(rating_file, rating_str);
// 		while (getline(rating_file, movie_id_str, ',')) {
// 			getline(rating_file, user_id_str, ',');
// 			getline(rating_file, rating_str);
// 			user_id = stoi(user_id_str);
// 			movie_id = stoi(movie_id_str);
// 			rating=stof(rating_str);
// 			if(user_id>=ROWS || movie_id>=COLS)
// 				continue;
//       rating_map[user_id][movie_id]=rating;
// 	}
// 	rating_file.close();
// 	return true;
// }

void user_rating_avg(){
	float sum, temp;
	int mv_count;
	for(int user = 0; user<ROWS; user++){
		sum = 0.0;
		mv_count = 0;
		for(int mv = 0; mv<COLS; mv++){
			temp = rating_map[user][mv];
			if(temp!=0.0)
				mv_count++;
			sum += temp;
		}
		if(mv_count!=0)
			avg_rating[user] = sum/(float)mv_count;
		else
			avg_rating[user] = 0.0;
		//cout<<avg_rating[user]<<" ";
	}
}


void movie_recommendation(int active_user, int K){
	priority_queue<pair<float,int>, vector<pair<float, int>>, greater<pair<float, int>>> pq;
	for(int mv=0;mv<COLS;mv++){
		if(rating_map[active_user][mv]==0.0){
			float pred_rating = 0.0;
			for(int user = 0;user<ROWS;user++){
				pred_rating += similarity_matrix[active_user][user]*(rating_map[user][mv]-avg_rating[user]);
			}
			pq.push(make_pair(pred_rating,mv));
			if(pq.size()>K)
				pq.pop();
		}
	}
	cout<<"\n"<<K <<" recommended movies for user : "<<active_user<<"\n";
	while(!pq.empty()){
		cout<<movie_map[pq.top().second]<<"\n";
		pq.pop();
	}
}

void bulid_similarity_matrix(){
	float numerator, sigmA, sigmB;
		for(int i=0;i<ROWS;i++){
			for(int j=0;j<ROWS;j++){
					numerator = 0.0; sigmA = 0.0, sigmB = 0.0;
					for(int k=0;k<COLS;k++){
							if(rating_map[i][k]!=0.0 && rating_map[j][k]!=0.0){
								numerator += (rating_map[i][k]-avg_rating[i]) * (rating_map[j][k]-avg_rating[j]);
							}
							if(rating_map[i][k]!=0.0)
								sigmA += pow(rating_map[i][k]-avg_rating[i],2);
							if(rating_map[j][k]!=0.0)
								sigmB += pow(rating_map[j][k]-avg_rating[j],2);
					}
					float denominator = sqrt(sigmA * sigmB);
					//cout<<numerator<<" "<<sqrt(sigmA)<<" "<<sqrt(sigmB)<<endl;
					if(denominator!=0.0)
						similarity_matrix[i][j] = numerator/denominator;
					else
						similarity_matrix[i][j] = 0.0;
			}
		}
}

int main(int argc, char ** argv) {
	/*//string movie_title_file="D:/APP_Project/ml-20m/ml-20m/movies.csv";
	string rating_file="./ratings_small.csv";
	if(argc==3){
		movie_title_file=argv[1];
		rating_file=argv[2];
	}else{
		cout<<"File name not given. Trying to read file from executable location.\n";
	}
	//cout<< "Reading file \""<<movie_title_file<<"\" ...\n";
	//if(read_movietitle(movie_title_file)==false){
	//	cout << movie_title_file<<" not found!\n";
	//	return 1;
	//}
	cout<< "Reading file \""<<rating_file<<"\" ...\n";
	 if(read_rating(rating_file)==false){
	 	cout << rating_file<<" not found!\n";
	 	return 1;
	}*/
	std::clock_t  start,stop;
        start = std::clock();
	readCSV();
	double duration = ( std::clock() - start ) / (double) CLOCKS_PER_SEC;
        printf("Time taken to load csv = %lf seconds\n\n",duration);
	/*for(int i=0;i<10;i++){
		for(int j=0;j<10;j++)
			cout<<rating_map[i][j]<<" ";
		cout<<endl;
	}*/
	//cudaEventRecord(start);
	cout<< "Computing User average rating.... \n";
	start = std::clock();
	user_rating_avg();
	duration = ( std::clock() - start ) / (double) CLOCKS_PER_SEC;
        cout<<"time to compute average = "<<duration<<" seconds"<<endl; 
	//cudaEventRecord(stop);
        //cudaEventSynchronize(stop);
        //milliseconds = 0.0f;
        //cudaEventElapsedTime(&milliseconds,start,stop);
        

	//cudaEventRecord(start);
	cout<<"Computing similarity matrix.... \n";
	start = std::clock();
	bulid_similarity_matrix();
	duration = ( std::clock() - start ) / (double) CLOCKS_PER_SEC;
        cout<<"time to compute similarity matrix = "<<duration<<" seconds"<<endl;
	//cudaEventRecord(stop);
        //cudaEventSynchronize(stop);
        //milliseconds = 0.0f;
        //cudaEventElapsedTime(&milliseconds,start,stop);
        //printf("Time taken to compute similarity matrix = %f seconds\n\n",(float)milliseconds/1000);
	
	for(int i=0;i<10;i++){
		for(int j=0;j<10;j++){
			cout<<similarity_matrix[i][j]<<" ";
		}
		cout<<endl;
	}
	int user_id, K;
	cout<<"here";
	while(true){
		cout<<"Please Enter UserID (or enter -1 to exit): ";
		cin>>user_id;
		if(user_id>=ROWS)
			cout<<"UserID not found, Please enter valid UserID\n";
		else{
			cout<<"Please Enter Number of Recommendation: ";
			cin>>K;
			if(K>0)
				movie_recommendation(user_id, K);
			else
				cout<<"Number of recommendation must be greater than 0\n";
		}
		cout<<"\n";
	}
	return 0;
}
