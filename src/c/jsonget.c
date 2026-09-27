#include <stdio.h>
#include <string.h>
static char b[1<<24]; static char out[1<<24];
static int hx(int c){ return c<='9'? c-'0' : (c|32)-'a'+10; }
int main(void){
  size_t n=fread(b,1,sizeof b-1,stdin), i=0; b[n]=0;
  while(i<n && b[i]!='\n') i++;
  size_t klen=i; i++;
  while(i<n && b[i]!='{') i++;
  i++;
  while(i<n){
    char c=b[i];
    if(c=='}') break;
    if(c!='"'){ i++; continue; }
    size_t ks=++i; while(b[i]!='"') i++;
    size_t kl=i-ks; i++;
    int match = kl==klen && memcmp(b,b+ks,klen)==0;
    while(b[i]!='"' && b[i]!='-' && !(b[i]>='0'&&b[i]<='9')) i++;
    size_t o=0;
    if(b[i]=='"'){
      i++;
      for(;;){ char d=b[i++];
        if(d=='"') break;
        if(d=='\\'){ d=b[i++];
          if(d=='n') d='\n'; else if(d=='t') d='\t';
          else if(d=='u'){ d=(char)(hx(b[i])<<12|hx(b[i+1])<<8|hx(b[i+2])<<4|hx(b[i+3])); i+=4; } }
        out[o++]=d; }
    } else {
      while(i<n && (b[i]=='-' || (b[i]>='0'&&b[i]<='9'))) out[o++]=b[i++];
    }
    if(match){ out[o++]='\n'; fwrite(out,1,o,stdout); return 0; }
  }
  fputs("null\n",stdout); return 0;
}
