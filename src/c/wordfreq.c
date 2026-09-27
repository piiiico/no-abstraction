#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef struct { char *w; size_t len; long cnt; } E;
static char buf[1<<24]; static E *tab; static size_t cap=1<<20, nd; static E **dist;
static int cmp(const void *a, const void *b){
  const E *x=*(E*const*)a, *y=*(E*const*)b;
  if(x->cnt!=y->cnt) return x->cnt>y->cnt ? -1 : 1;
  size_t m = x->len<y->len ? x->len : y->len; int c=memcmp(x->w,y->w,m);
  if(c) return c; return x->len<y->len ? -1 : x->len>y->len;
}
int main(void){
  size_t n=fread(buf,1,sizeof buf,stdin);
  tab=calloc(cap,sizeof(E)); dist=malloc(cap*sizeof(E*));
  for(size_t i=0;i<n;){
    unsigned c=buf[i]|32;
    if(c-'a'>25u){ i++; continue; }
    size_t s=i; unsigned long long h=1469598103934665603ULL;
    while(i<n && ((unsigned)(buf[i]|32))-'a'<=25u){ buf[i]|=32; h=(h^(unsigned char)buf[i])*1099511628211ULL; i++; }
    size_t len=i-s, k=h&(cap-1);
    for(;;){
      E *e=&tab[k];
      if(!e->len){ e->w=buf+s; e->len=len; e->cnt=1; dist[nd++]=e; break; }
      if(e->len==len && !memcmp(e->w,buf+s,len)){ e->cnt++; break; }
      k=(k+1)&(cap-1);
    }
  }
  qsort(dist,nd,sizeof *dist,cmp);
  for(size_t i=0;i<nd && i<10;i++){ printf("%ld ",dist[i]->cnt); fwrite(dist[i]->w,1,dist[i]->len,stdout); putchar('\n'); }
  return 0;
}
