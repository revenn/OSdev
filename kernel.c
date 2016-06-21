void _start(void* kernel_location) {
  unsigned long long addr = (unsigned long long) kernel_location;
  char* textvram = (char*)0xb8000;

  for(int i = 0; i < 16; i++) {
    textvram[i * 2] = "0123456789ABCDF"[(addr >> 60) & 0xf];
    addr <<= 4;
  }

  //*(long long*)0xb8000 = 0x4242424242424242LL;

  for(;;);
}
// long long oznacza ze mamy zmienna 64bitowa
