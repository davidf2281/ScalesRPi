
/* CREDIT: Adapted from https://github.com/doceme/py-spidev/blob/master/spidev_module.c */

#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <linux/spi/spidev.h>
#include <linux/types.h>
#include <sys/ioctl.h>
#include <linux/ioctl.h>

#define SPIDEV_MAXPATH 4096

#define BLOCK_SIZE_CONTROL_FILE "/sys/module/spidev/parameters/bufsiz"
// The xfwr3 function attempts to use large blocks if /sys/module/spidev/parameters/bufsiz setting allows it.
// However where we cannot get a value from that file, we fall back to this safe default.
#define XFER3_DEFAULT_BLOCK_SIZE SPIDEV_MAXPATH
// Largest block size for xfer3 - even if /sys/module/spidev/parameters/bufsiz allows bigger
// blocks, we won't go above this value. As I understand, DMA is not used for anything bigger so why bother.
#define XFER3_MAX_BLOCK_SIZE 65535

// Maximum block size for xfer3
// Initialised once by get_xfer3_block_size
uint32_t xfer3_block_size = 0;

// Read maximum block size from the /sys/module/spidev/parameters/bufsiz
// In case of any problems reading the number, we fall back to XFER3_DEFAULT_BLOCK_SIZE.
// If number is read ok but it exceeds the XFER3_MAX_BLOCK_SIZE, it will be capped to that value.
// The value is read and cached on the first invocation. Following invocations just return the cached one.
uint32_t get_xfer3_block_size(void) {
	int value;

	// If value was already initialised, just use it
	if (xfer3_block_size != 0) {
		return xfer3_block_size;
	}

	// Start with the default
	xfer3_block_size = XFER3_DEFAULT_BLOCK_SIZE;

	FILE *file = fopen(BLOCK_SIZE_CONTROL_FILE,"r");
	if (file != NULL) {
		if (fscanf(file, "%d", &value) == 1 && value > 0) {
			if (value <= XFER3_MAX_BLOCK_SIZE) {
				xfer3_block_size = value;
			} else {
				xfer3_block_size = XFER3_MAX_BLOCK_SIZE;
			}
		}
		fclose(file);
	}

	return xfer3_block_size;
}
