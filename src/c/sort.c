#include <stdio.h>
#include <stdlib.h>
static long long a[300000];
static int cmp(const void*x,const void*y){ long long p=*(const long long*)x,q=*(const long long*)y; return (p>q)-(p<q); }
int main(void){
  size_t n=0; long long v;
  while(n<300000 && scanf("%lld",&v)==1) a[n++]=v;
  qsort(a,n,sizeof a[0],cmp);
  for(size_t i=0;i<n;i++) printf("%lld\n",a[i]);
  return 0;
}
