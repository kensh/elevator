#define N 3

byte a=5;
byte b=6;
byte c=0;
active proctype main() {
     // left shift
a=1;
     a =  a << 3-1;
     printf("left shift\n%d\n",a);

     // right shift
     a =  a >> 1;
     printf("right shift\n%d\n",a);

     // bit and
     c = a &b;
     printf("bit and\n%d\n",c);

     // bit or
     c = a | b;
     printf("bit or\n%d\n",c);


     // bit xor
     c = 5 ^ 6;
     printf("bit xor\n%d\n",c);

     // lower mask
     c = (1<<N) - 1;
     printf("lower mask\n%d\n",c);

     // bit mutex
     c = 0;
     c = c | 1;
     c = c | 2;
     printf("lower mutex\n%d\n",c & 2 == 0);

/*
struct bitmask {
    static const Type full = ~(Type(0));
    static const Type upper = ~((Type(1) << LowerBits) - 1);
    static const Type lower = (Type(1) << LowerBits) - 1;
};
*/
}
