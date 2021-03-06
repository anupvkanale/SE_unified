#include "mex.h"
#include "SE_fgg.h"
#include "fgg_thrd.h"

void SE_FGG_MEX_params(SE_FGG_params*, const mxArray*, int);

#define X   prhs[0] 
#define Q   prhs[1] 
#define OPT prhs[2]

#define H_OUT plhs[0]  // Output

#ifndef VERBOSE
#define VERBOSE 0
#endif

static inline
int get_idx0(const double x[3],
	     const SE_FGG_params* params)
{
    // unpack params
    const int p = params->P;
    const int p_half = params->P_half;
    const double h = params->h;
    
    int idx;
    int idx_from[3];

    // compute index range and centering
    if(is_odd(p))
    {
	for(int j=0; j<3; j++)
	{
	    idx = (int) round(x[j]/h);
	    idx_from[j] = idx - p_half;
	}
    }
    else
    {
	for(int j=0; j<3; j++)
	{
	    idx = (int) floor(x[j]/h);
	    idx_from[j] = idx - (p_half-1);
	}
    }


    return __IDX3_RMAJ(idx_from[0]+p_half, 
		       idx_from[1]+p_half, 
		       idx_from[2]+p_half, 
		       params->npdims[1], params->npdims[2]);
}


void mexFunction(int nlhs,       mxArray *plhs[],
		 int nrhs, const mxArray *prhs[] )
{
    const int N = mxGetM(X);
    double* restrict x = mxGetPr(X);
    double* restrict q = mxGetPr(Q);

    // pack parameters
    SE_FGG_params params;
    SE_FGG_MEX_params(&params, OPT, N);

    // scratch arrays
    SE_FGG_work work;
    SE_FGG_allocate_workspace(&work, &params,true,true);
    
    // allocate output array
    H_OUT = mxCreateNumericArray(3, params.dims, mxDOUBLE_CLASS, mxREAL);
    double* H_per = mxGetPr(H_OUT);
    SE_fp_set_zero(H_per, SE_prod3(params.dims));

    // coordinates and charges
    const SE_state st = {.x = x,  .q = q};

    if(VERBOSE)
	mexPrintf("[SE%s FG(G) THRD] N=%d, P=%d\n",PER_STR,N,params.P);

    // now do the work
    SE_FGG_base_gaussian(&work, &params);

    for(int n=0; n < N; n++)
    {	
	double xn[3];
	xn[0] = x[n]; 
	xn[1] = x[n+N]; 
	xn[2] = x[n+2*N];
	work.idx[n] = get_idx0(xn, &params);
    }
    

#if FGG_THRD
#pragma omp parallel
#else
#warning "Threading must be activated with -DFGG_THRD"
#endif
    {
	SE_FGG_grid(&work, &st, &params);
    }

#ifdef THREE_PERIODIC
    SE_FGG_wrap_fcn(H_per, &work, &params);
#endif    

#ifdef TWO_PERIODIC
    SE2P_FGG_wrap_fcn(H_per, &work, &params);
#endif    
    
    // done
    SE_FGG_free_workspace(&work);
}
