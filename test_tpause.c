#include <stdio.h>
#include <signal.h>
#include <x86gprintrin.h>
#include <immintrin.h>

#define cpu_relax() asm volatile ("rep; nop")

int main(void)
{
	unsigned long long start, end;
	for (int i = 0; i < 10; i++) {
		start = __rdtsc();
		// cpu_relax();
		_tpause(0, start+100);
		end = __rdtsc();
		printf("%lld\n", end - start);
	}
}

