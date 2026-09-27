#include <stdio.h>
static unsigned char in[1<<24]; static char out[(1<<24)/3*4+8];
static const char *A="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
int main(void){
  size_t n=fread(in,1,sizeof in,stdin), i=0, o=0;
  for(; i+3<=n; i+=3){ unsigned w=in[i]<<16|in[i+1]<<8|in[i+2];
    out[o++]=A[w>>18&63]; out[o++]=A[w>>12&63]; out[o++]=A[w>>6&63]; out[o++]=A[w&63]; }
  if(n-i==1){ unsigned w=in[i]<<16; out[o++]=A[w>>18&63]; out[o++]=A[w>>12&63]; out[o++]='='; out[o++]='='; }
  else if(n-i==2){ unsigned w=in[i]<<16|in[i+1]<<8; out[o++]=A[w>>18&63]; out[o++]=A[w>>12&63]; out[o++]=A[w>>6&63]; out[o++]='='; }
  out[o++]='\n'; fwrite(out,1,o,stdout); return 0;
}
