#include <stdio.h>
#include <stdint.h>
int main(void){
  unsigned long long n=0; if(scanf("%llu",&n)!=1) n=0;
  uint64_t res=0, bit=1ULL<<62;
  while(bit>n) bit>>=2;
  while(bit){ if(n>=res+bit){ n-=res+bit; res=(res>>1)+bit; } else res>>=1; bit>>=2; }
  printf("%llu\n",(unsigned long long)res);
  return 0;
}
