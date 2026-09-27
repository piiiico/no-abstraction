#include <stdio.h>
#include <stdint.h>
int main(void){
  long long a,b;
  while(scanf("%lld %lld",&a,&b)==2){
    if(b==0){ puts("div0"); continue; }
    if(a==INT64_MIN && b==-1){ puts("overflow"); continue; }
    long long q=a/b, r=a%b;
    if(r!=0 && ((r<0)!=(b<0))){ q--; r+=b; }
    printf("%lld %lld\n",q,r);
  }
  return 0;
}
