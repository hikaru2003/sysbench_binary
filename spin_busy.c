#include <stdio.h>
#include <signal.h>

static int stopped = 0;
unsigned long long count = 0;

void sigint_handler() {
	stopped = 1;
	fprintf(stderr, "count: %lld\n", count);
}

int main(void)
{
	signal(SIGINT, sigint_handler);
	for (;;) {
		if (stopped)
			break;
		count++;
	}
}
