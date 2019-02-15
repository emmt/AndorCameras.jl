/*
 * Look on the usb bus for:
 * 136e:0014 Andor Technology Ltd. Zyla 5.5 sCMOS camera
 * and specifically reset that device
 *
 * Nota:   0x136e = 4974  and  0x0014 = 20
 * Nota2:  compile with -lusb
 *
 * Copyright (c), 11/02/2019 Bernard Gelly.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <usb.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <errno.h>
#include <linux/usbdevice_fs.h>

int main(int argc, char* argv[])
{
    struct usb_bus *bus;
    struct usb_device *dev;
    char filename[64] = "/dev/bus/usb/";
    int fd;
    int rc;

    usb_init();
    usb_find_busses();
    usb_find_devices();
    for (bus = usb_busses; bus; bus = bus->next) {
        for (dev = bus->devices; dev; dev = dev->next) {
            if ((dev->descriptor.idVendor == 4974) &&
                (dev->descriptor.idProduct == 20)) {
                strcat(strcat(strcat(filename, bus->dirname), "/"),
                       dev->filename);
                fprintf(stdout, "Found Andor Zyla camera on %s\n", filename);
                fd = open(filename, O_WRONLY);
                if (fd == -1) {
                    fprintf(stderr, "%s: Error opening device %s (%s)\n",
                            argv[0], filename, strerror(errno));
                    return EXIT_FAILURE;
                }
                fprintf(stdout, "Resetting: %s ...", filename);
                fflush(stdout);
                rc = ioctl(fd, USBDEVFS_RESET, 0);
                if (rc < 0) {
                    fprintf(stdout, "\n");
                    fprintf(stderr, "%s: Error resetting USB device %s (%s)\n",
                            argv[0], filename, strerror(errno));
                    return EXIT_FAILURE;
                }
                fprintf(stdout, " Ok\n");
                if (close(fd) == -1) {
                    fprintf(stderr, "%s: Error closing device %s (%s)\n",
                            argv[0], filename, strerror(errno));
                    return EXIT_FAILURE;
                }
                return EXIT_SUCCESS;
            }
        }
    }
    fprintf(stderr, "%s: No Andor Zyla cameras found on USB bus.\n", argv[0]);
    return EXIT_FAILURE;
}
