#include <stdio.h>
#include <stdint.h>
int main(void){
  uint32_t t[256]; for(uint32_t n=0;n<256;n++){ uint32_t c=n; for(int k=0;k<8;k++) c = c&1 ? 0xEDB88320u^(c>>1) : c>>1; t[n]=c; }
  static unsigned char b[65536]; size_t r; uint32_t crc=0xFFFFFFFFu;
  while((r=fread(b,1,sizeof b,stdin))>0) for(size_t i=0;i<r;i++) crc=t[(crc^b[i])&255]^(crc>>8);
  printf("%08x\n",crc^0xFFFFFFFFu); return 0;
}
