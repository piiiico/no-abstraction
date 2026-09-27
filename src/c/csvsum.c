#include <stdio.h>
#include <stdlib.h>
static char buf[1<<24];
int main(void){
  size_t n=fread(buf,1,sizeof buf,stdin), i=0; long long sum=0;
  while(i<n && buf[i]!='\n') i++;
  if(i<n) i++;
  while(i<n){
    if(buf[i]=='\n'){ i++; continue; }
    while(i<n && buf[i]!=',') i++;
    i++;
    int neg=0; unsigned long long v=0;
    if(i<n && buf[i]=='-'){ neg=1; i++; }
    while(i<n && buf[i]>='0' && buf[i]<='9') v=v*10+(buf[i++]-'0');
    sum += neg ? -(long long)v : (long long)v;
    while(i<n && buf[i]!='\n') i++;
    if(i<n) i++;
  }
  printf("%lld\n", sum);
  return 0;
}
