#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "mikbug.h"

int main(int argc, char **argv)
{
    const char *out_path = (argc > 1) ? argv[1] : "mikbug.bin";
    const size_t image_size = sizeof(sbc6800_binary);

    if (image_size != 65536) {
        fprintf(stderr, "error: image size is %zu bytes (expected 65536)\n", image_size);
        return 1;
    }

    FILE *fp = fopen(out_path, "wb");
    if (!fp) {
        fprintf(stderr, "error: cannot open '%s': %s\n", out_path, strerror(errno));
        return 1;
    }

    size_t written = fwrite(sbc6800_binary, 1, image_size, fp);
    if (written != image_size) {
        fprintf(
            stderr,
            "error: short write to '%s': wrote %zu of %zu bytes\n",
            out_path,
            written,
            image_size
        );
        fclose(fp);
        return 1;
    }

    if (fclose(fp) != 0) {
        fprintf(stderr, "error: failed to close '%s': %s\n", out_path, strerror(errno));
        return 1;
    }

    printf("wrote %zu bytes to %s\n", image_size, out_path);
    return 0;
}
