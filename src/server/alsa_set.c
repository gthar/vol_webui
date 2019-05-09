#include <stdio.h>
#include <stdbool.h>
#include <alsa/asoundlib.h>

#include "helpers.h"

void usage ()
{
    printf("arguments: device mixer param\n");
    printf("* device (i.e., default)\n");
    printf("* mixer (i.e., Master)\n");
    printf("* param (i.e., vol)\n");
    printf("* val (i.e., 5432)\n");
}

int set_val(const char *device, const char *mixer, const char *param, const char *val)
{
    int i;

    snd_mixer_elem_t *elem;
    snd_mixer_t *handle;

    handle = get_handle(device);


    elem = get_elem(handle, mixer);

    if (!elem) {
        snd_mixer_close(handle);
        fprintf(stderr, "Cannot find mixer %s\n", mixer);
        exit(-1);
    }

    for (i = 0; i <= SND_MIXER_SCHN_LAST; i++) {
        if (snd_mixer_selem_has_playback_channel(elem, i)) {
            if (strcmp(param, "vol") == 0) {
                snd_mixer_selem_set_playback_volume(elem, i, atol(val));
            }
            if (strcmp(param, "switch") == 0) {
                snd_mixer_selem_set_playback_switch(elem, i, atoi(val));
            }
        }
    }

    snd_mixer_close(handle);

    return 0;
}

int main(int argc, const char *argv[])
{
    if (argc < 5) {
        usage();
        return 1;
    }

    return set_val(argv[1], argv[2], argv[3], argv[4]);
}
