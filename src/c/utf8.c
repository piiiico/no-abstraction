#include <stdio.h>
static unsigned char b[1<<24];
static int valid(size_t n){
  size_t i=0;
  while(i<n){
    unsigned c=b[i]; int k; unsigned lo=0x80, hi=0xBF;
    if(c<0x80){ i++; continue; }
    if(c<0xC2) return 0;
    else if(c<0xE0) k=1;
    else if(c<0xF0){ k=2; if(c==0xE0) lo=0xA0; if(c==0xED) hi=0x9F; }
    else if(c<0xF5){ k=3; if(c==0xF0) lo=0x90; if(c==0xF4) hi=0x8F; }
    else return 0;
    if(i+k>=n) return 0;
    if(b[i+1]<lo || b[i+1]>hi) return 0;
    for(int j=2;j<=k;j++) if((b[i+j]&0xC0)!=0x80) return 0;
    i+=k+1;
  }
  return 1;
}
int main(void){ size_t n=fread(b,1,sizeof b,stdin); fputs(valid(n)?"valid\n":"invalid\n",stdout); return 0; }
