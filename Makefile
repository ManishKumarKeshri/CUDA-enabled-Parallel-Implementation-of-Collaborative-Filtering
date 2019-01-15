NVCC        = nvcc

NVCC_FLAGS  = -I/usr/local/cuda/include -gencode=arch=compute_60,code=\"sm_60\"
ifdef dbg
	NVCC_FLAGS  += -g -G
else
	NVCC_FLAGS  += -O2
endif

LD_FLAGS    = -lcudart -L/usr/local/cuda/lib64
EXE	        = collaborativeFiltering
OBJ	        = collaborativeFiltering.o

default: $(EXE)

collaborativeFiltering.o: collaborativeFiltering.cu dataReader.c getAverageAndNorm.cu calculateSimilarityMatrix.cu
	$(NVCC) -c -o $@ collaborativeFiltering.cu $(NVCC_FLAGS) 

#dataReader.o: dataReader.c 
#	$(NVCC) -c -o $@ dataReader.c $(NVCC_FLAGS)

#getAverageAndNorm.o: getAverageAndNorm.cu
	#$(NVCC) -c -o $@ getAverageAndNorm.cu $(NVCC_FLAGS) 

$(EXE): $(OBJ)
	$(NVCC) $(OBJ) -o $(EXE) $(LD_FLAGS) $(NVCC_FLAGS)

clean:
	rm -rf *.o $(EXE)
