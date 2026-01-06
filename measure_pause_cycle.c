#include <stdio.h>
#include <signal.h>
#include <x86gprintrin.h>

#define cpu_relax() asm volatile ("rep; nop")

int main(void)
{
	unsigned long long start, end;
	for (int i = 0; i < 10; i++) {
		start = __rdtsc();
		cpu_relax();
		end = __rdtsc();
		printf("%lld\n", end - start);
	}
}
