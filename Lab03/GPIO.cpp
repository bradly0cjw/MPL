#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <iostream>

using namespace std;
const int LED1_GPIO = 396;
const int LED2_GPIO = 397;
const int LED3_GPIO = 254;
const int LED4_GPIO = 389;

int gpio_export(unsigned int gpio)
{
	int fd, len;
	char buf[64];

	fd = open("/sys/class/gpio/export", O_WRONLY);
	if (fd < 0)
	{
		perror("gpio/export");
		return fd;
	}
	len = snprintf(buf, sizeof(buf), "%d", gpio);
	write(fd, buf, len);
	close(fd);

	return 0;
}
int gpio_unexport(unsigned int gpio)
{
	int fd, len;
	char buf[64];

	fd = open("/sys/class/gpio/unexport", O_WRONLY);
	if (fd < 0)
	{
		perror("gpio/export");
		return fd;
	}
	len = snprintf(buf, sizeof(buf), "%d", gpio);
	write(fd, buf, len);
	close(fd);

	return 0;
}
int gpio_set_dir(unsigned int gpio, string dirStatus)
{
	int fd;
	char buf[64];
	snprintf(buf, sizeof(buf), "/sys/class/gpio/gpio%d/direction", gpio);
	fd = open(buf, O_WRONLY);

	if (fd < 0)
	{

		perror("gpio/direction");

		return fd;
	}

	if (dirStatus == "out")
	{
		write(fd, "out", 4);
	}

	else
	{
		write(fd, "in", 3);
	}

	close(fd);

	return 0;
}

int gpio_set_value(unsigned int gpio, int value)
{
	int fd;
	char buf[64];
	snprintf(buf, sizeof(buf), "/sys/class/gpio/gpio%d/value", gpio);
	fd = open(buf, O_WRONLY);

	if (fd < 0)
	{

		perror("gpio/set-value");

		return fd;
	}

	if (value == 0)
	{
		write(fd, "0", 2);
	}
	else
	{
		write(fd, "1", 2);
	}

	close(fd);

	return 0;
}
int main(int arc, char *argv[])
{
	int gpio_number, gpio_number2, num;
	cout << argv[1];
	if (strcmp(argv[1], "LED1") == 0)
	{
		cout << "ok";
		gpio_number = LED1_GPIO;
	}
	else if (strcmp(argv[1], "LED2") == 0)
	{
		gpio_number = LED2_GPIO;
	}
	else if (strcmp(argv[1], "LED3") == 0)
	{
		gpio_number = LED3_GPIO;
	}
	else if (strcmp(argv[1], "LED4") == 0)
	{
		gpio_number = LED4_GPIO;
	}
	else if (strcmp(argv[1], "Mode_Shine") == 0)
	{
		for (int i = 0; i < atoi(argv[2]) * 2; i++)
		{
			if (i % 2 == 0)
			{
				gpio_export(LED1_GPIO);
				gpio_set_dir(LED1_GPIO, "out");
				gpio_set_value(LED1_GPIO, 1);
				gpio_export(LED2_GPIO);
				gpio_set_dir(LED2_GPIO, "out");
				gpio_set_value(LED2_GPIO, 1);
			}
			else
			{
				gpio_export(LED4_GPIO);
				gpio_set_dir(LED4_GPIO, "out");
				gpio_set_value(LED4_GPIO, 1);
				gpio_export(LED3_GPIO);
				gpio_set_dir(LED3_GPIO, "out");
				gpio_set_value(LED3_GPIO, 1);
			}
			// cout<<gpio ;

			usleep(300000);
			if (i % 2 == 0)
			{
				gpio_set_value(LED1_GPIO, 0);
				gpio_unexport(LED1_GPIO);
				gpio_set_value(LED2_GPIO, 0);
				gpio_unexport(LED2_GPIO);
				usleep(300000);
				continue;
			}
			else
			{
				gpio_set_value(LED4_GPIO, 0);
				gpio_unexport(LED4_GPIO);
				gpio_set_value(LED3_GPIO, 0);
				gpio_unexport(LED3_GPIO);

				usleep(300000);
				continue;
			}
		}
		return 0;
	}
	if (strcmp(argv[2], "on") == 0)
	{
		gpio_export(gpio_number);
		gpio_set_dir(gpio_number, "out");
		gpio_set_value(gpio_number, 1);
	}
	else if (strcmp(argv[2], "off") == 0)
	{
		gpio_set_value(gpio_number, 0);
	}
}
