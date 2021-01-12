#include <stdio.h>
#include <limits.h>

int main(void)
{
    int a;
    if (&a > 100000)
    {
        printf("First path\n");
    }
    else
    {
        printf("Second path\n");
    }
    return 0;
}