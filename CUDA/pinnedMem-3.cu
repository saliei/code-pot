#include <stdio.h>

//convience func for checking runtime CUDA errors
inline
cudaError_t checkCuda(cudaError_t result)
{
#if defined (DEBUG) || defined (_DEBUG)
	if(result != cudaSuccess)
	{
		fprintf(stderr, "CUDA Runtime Error: %s\n", cudaGetErrorString(result));
		assert(result == cudaSuccess);
	}
#endif
	return result;
}

void profileCopy(float* h_a, float* h_b, float* d, unsigned int n, char* descr)
{
	unsigned int bytes = n * sizeof(float);
	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	cudaEventRecord(start, 0);
	cudaMemcpy(d, h_a, bytes, cudaMemcpyHostToDevice);
	cudaEventRecord(stop, 0);
	cudaEventSynchronize(stop);
	float milSecs;
	cudaEventElapsedTime(&milSecs, start, stop);
	printf("%s Transfers:\n", descr);
	printf("  Host to Device Bandwidth[GB/s]: %f\n", 1e-6*bytes/milSecs);

	cudaEventRecord(start, 0);
	cudaMemcpy(h_b, d, bytes, cudaMemcpyDeviceToHost);
	cudaEventRecord(stop. 0);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&milSecs, start, stop);
	printf("  Device to Host Bandwidth[GB/s]: %f\n", 1e-6*bytes/milSecs);

	unsigned int i;
	for(i = 0; i < n; ++i)
		if(h_a[i] - h_b[i] > 0.0)
		{
			fprintf(stderr, "%s Transfer Failure Error.\n", descr);
			break;
		}

	cudaEventDestroy(start);
	cudaEventDestroy(stop);
}

int main(int argc, char** argv)
{
	unsigned int numElem = 4*1024*1024;
	unsigned int byteSize = numElem * sizeof(float);
	float *h_aPageable, *h_bPageable;
	float *h_aPinned, *h_bPinned;

	h_aPageable = (float*)malloc(byteSize);
	h_bPageable = (float*)malloc(byteSize);
	checkCuda(cudaMallocHost((void**)&h_aPinned, byteSize));
	checkCuda(cudaMallocHost((void**)&h_bPinned, byteSize));
	cudaMalloc((void**)&d, byteSize);

	profileCopy(h_aPageable, h_aPageable, d, numElem, "Pageable");
	profileCopy(h_aPinned, h_bPinned, d, numElem, "Pinned");

}