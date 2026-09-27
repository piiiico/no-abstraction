#include <stdio.h>
static char line[1<<20]; static const char *p;
static long long expr(void);
static void ws(void){ while(*p==' ') p++; }
static long long unary(void){
  ws();
  if(*p=='-'){ p++; return -unary(); }
  if(*p=='('){ p++; long long v=expr(); ws(); if(*p==')') p++; return v; }
  long long v=0; while(*p>='0'&&*p<='9') v=v*10+(*p++-'0'); return v;
}
static long long term(void){
  long long v=unary();
  for(;;){ ws(); if(*p=='*'){ p++; v*=unary(); } else if(*p=='/'){ p++; v/=unary(); } else return v; }
}
static long long expr(void){
  long long v=term();
  for(;;){ ws(); if(*p=='+'){ p++; v+=term(); } else if(*p=='-'){ p++; v-=term(); } else return v; }
}
int main(void){
  while(fgets(line,sizeof line,stdin)){
    p=line; ws(); if(*p=='\n'||*p==0) continue;
    printf("%lld\n",expr());
  }
  return 0;
}
