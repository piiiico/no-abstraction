#include <stdio.h>
#include <string.h>
static long keys[1000], vals[1000], stamp[1000];
int main(void){
  int cap, cnt=0; long clock=0; char op[8]; long k,v;
  if(scanf("%d",&cap)!=1) return 0;
  while(scanf("%7s %ld",op,&k)==2){
    int j=0; while(j<cnt && keys[j]!=k) j++;
    clock++;
    if(op[0]=='g'){
      if(j<cnt){ stamp[j]=clock; printf("%ld\n",vals[j]); } else puts("-1");
    } else {
      scanf("%ld",&v);
      if(j==cnt){
        if(cnt<cap) cnt++;
        else { j=0; for(int s=1;s<cnt;s++) if(stamp[s]<stamp[j]) j=s; }
        keys[j]=k;
      }
      vals[j]=v; stamp[j]=clock;
    }
  }
  return 0;
}
