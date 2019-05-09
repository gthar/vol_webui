#include <stdio.h>
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
