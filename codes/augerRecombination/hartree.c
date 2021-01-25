#include "ar.h"

/*****************************************************************************/

void hartree(zomplex *rho,zomplex *potq,double *poth,long nGrid,fftw_plan_loc planfw,fftw_plan_loc planbw,fftw_complex *fftwpsi)
{
  long j;
  zomplex tmp;
  
  memcpy(&fftwpsi[0], &rho[0], nGrid*sizeof(fftwpsi[0]));
  fftw_execute(planfw);

  for (j = 0; j < nGrid; j++) {
    tmp.re = fftwpsi[j][0];
    tmp.im = fftwpsi[j][1];
    
    fftwpsi[j][0] = tmp.re * potq[j].re - tmp.im * potq[j].im;
    fftwpsi[j][1] = tmp.re * potq[j].im + tmp.im * potq[j].re;
  }

  fftw_execute(planbw);

  for (j = 0; j < nGrid; j++) { 
    poth[j] = fftwpsi[j][0];
  }
  
  return;
}

/*****************************************************************************/
