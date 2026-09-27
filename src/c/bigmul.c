#include <stdio.h>
#include <string.h>
static char a[8192], b[8192]; static unsigned long long r[16384];
int main(void){
  if(scanf("%8191s %8191s",a,b)!=2) return 0;
  int la=strlen(a), lb=strlen(b);
  for(int i=0;i<la;i++){ int x=a[la-1-i]-'0'; if(!x) continue;
    for(int j=0;j<lb;j++) r[i+j]+= (unsigned long long)x*(b[lb-1-j]-'0'); }
  unsigned long long c=0; int n=la+lb;
  for(int k=0;k<n;k++){ unsigned long long v=r[k]+c; r[k]=v%10; c=v/10; }
  int k=n-1; while(k>0 && r[k]==0) k--;
  for(;k>=0;k--) putchar('0'+(int)r[k]);
  putchar('\n'); return 0;
}
