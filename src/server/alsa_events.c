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

snd_ctl_t * open_ctl(const char *card_name)
{
    int err;
    snd_ctl_t *ctl;

    err = snd_ctl_open(&ctl, card_name, SND_CTL_READONLY);
    handle_error(err, "Cannot open card %s\n", card_name);
    err = snd_ctl_subscribe_events(ctl, 1);
    handle_error(err, "Cannot open subscribe events to ctl %s\n", card_name);

    return ctl;
}

bool check_event (snd_ctl_t *ctl)
{
    snd_ctl_event_t *event;
    struct pollfd fd;
    unsigned int mask;
    unsigned short revents;

    snd_ctl_poll_descriptors(ctl, &fd, 1);

    handle_error(poll(&fd, 1, -1), "Polling error\n");

    snd_ctl_poll_descriptors_revents(ctl, &fd, 1, &revents);
    if (revents & POLLIN) {

        snd_ctl_event_alloca(&event);
        handle_error(snd_ctl_read(ctl, event), "snd ctl read error\n");

        if (snd_ctl_event_get_type(event) != SND_CTL_EVENT_ELEM)
            return false;

        mask = snd_ctl_event_elem_get_mask(event);
        if (!(mask & SND_CTL_EVENT_MASK_VALUE))
            return false;

        return true;

    }
    return false;
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
        fprintf(stdout, "vol %ld\n", vol);
        fflush(stdout);
    }
    return vol;
}

int check_on(snd_mixer_elem_t *elem, const int old_on)
{
    int on;
    snd_mixer_selem_get_playback_switch(elem, 0, &on);
    if (on != old_on) {
        fprintf(stdout, "on %d\n", on);
        fflush(stdout);
    }
    return on;
}

void usage ()
{
    printf("arguments: card device mixer\n");
    printf("* card (i.e., hw:0)\n");
    printf("* device (i.e., default)\n");
    printf("* mixer (i.e., Master)\n");
}

int monitor(const char *card, const char *device, const char *mixer)
{
    long vol = -1;
    int on = -1;
    long pmin, pmax;

    snd_ctl_t *ctl;
    snd_mixer_elem_t *elem;
    snd_mixer_t *handle;

    handle = get_handle(device);
    elem = get_elem(handle, mixer);

    if (!elem) {
        snd_mixer_close(handle);
        fprintf(stderr, "Cannot find mixer %s\n", mixer);
        exit(-1);
    }

    snd_mixer_selem_get_playback_volume_range(elem, &pmin, &pmax);
    fprintf(stdout, "pmin %ld\n", pmin);
    fflush(stdout);
    fprintf(stdout, "pmax %ld\n", pmax);
    fflush(stdout);

    vol = check_vol(elem, vol);
    on = check_on(elem, on);

    snd_mixer_close(handle);

    ctl = open_ctl(card);

    while (true) {
        if (check_event(ctl)) {
            handle = get_handle(device);
            elem = get_elem(handle, mixer);
            vol = check_vol(elem, vol);
            on = check_on(elem, on);
            snd_mixer_close(handle);
        }
    }

    return 0;
}


int main(int argc, const char *argv[])
{
    if (argc < 2) {
        usage();
        return 1;
    }

    monitor(argv[1], argv[2], argv[3]);
}
