#include <stdio.h>
int main(void){
  static unsigned char b[65536]; size_t r; unsigned long long L=0,W=0,B=0; int in=0;
  while((r=fread(b,1,sizeof b,stdin))>0){
    B+=r;
    for(size_t i=0;i<r;i++){ unsigned c=b[i];
      if(c=='\n') L++;
      if(c==' '||(c>=9&&c<=13)) in=0; else if(!in){ in=1; W++; } }
  }
  printf("%llu %llu %llu\n",L,W,B); return 0;
}
