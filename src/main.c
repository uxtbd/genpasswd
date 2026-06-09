#include <stdio.h>
#include <sodium.h>

int main(void) {
	if (sodium_init() == -1) {
		printf("Sodium couldn't initialize, quitting.\n");
        return 1;
    }
	printf("Sodium initialized\n");
	return 0;
}
