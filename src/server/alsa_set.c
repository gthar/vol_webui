#include <stdio.h>
#include <stdbool.h>
#include <alsa/asoundlib.h>

void handle_error(const int err, const char *msg, ...)
{
    va_list args;
    if (err < 0) {
        va_start(args, msg);
        vfprintf(stderr, msg, args);
        va_end(args);
        exit(err);
    }
}

snd_mixer_elem_t * get_elem(snd_mixer_t *handle, const char *mixer_name)
{
    snd_mixer_selem_id_t *sid;
    snd_mixer_selem_id_alloca(&sid);
    snd_mixer_selem_id_set_index(sid, 0);
    snd_mixer_selem_id_set_name(sid, mixer_name);
    return snd_mixer_find_selem(handle, sid);
}

snd_mixer_t * get_handle(const char *device)
{
    snd_mixer_t *handle;
    const char *err_msg = "Error while getting the handle for device %s\n";
    handle_error(snd_mixer_open(&handle, 0), "Cannot open the handle\n");
    handle_error(snd_mixer_attach(handle, device), err_msg, device);
    handle_error(snd_mixer_selem_register(handle, NULL, NULL), err_msg, device);
    handle_error(snd_mixer_load(handle), err_msg, device);
    return handle;
}

long int check_vol(snd_mixer_elem_t *elem, const long int old_vol)
{
    long int vol;
    snd_mixer_selem_get_playback_volume(elem, 0, &vol);
    if (vol != old_vol) {
        fprintf(stdout, "vol: %ld\n", vol);
        fflush(stdout);
    }
    return vol;
}

int check_on(snd_mixer_elem_t *elem, const int old_on)
{
    int on;
    snd_mixer_selem_get_playback_switch(elem, 0, &on);
    if (on != old_on) {
        fprintf(stdout, "on: %d\n", on);
        fflush(stdout);
    }
    return on;
}

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
