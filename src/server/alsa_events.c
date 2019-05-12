#include <stdio.h>
#include <stdbool.h>
#include <alsa/asoundlib.h>

#include "helpers.h"

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

    // we wait here for an event
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

long int check_vol(snd_mixer_elem_t *elem, const long int old_vol)
{
    long int volume;
    snd_mixer_selem_get_playback_volume(elem, 0, &volume);
    if (volume != old_vol) {
        fprintf(stdout, "volume %ld\n", volume);
    }
    return volume;
}

int check_switch(snd_mixer_elem_t *elem, const int old_switch)
{
    int new_switch;
    snd_mixer_selem_get_playback_switch(elem, 0, &new_switch);
    if (new_switch != old_switch) {
        fprintf(stdout, "switch %d\n", new_switch);
        fflush(stdout);
    }
    return new_switch;
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
    long volume = -1;
    int switch_state = -1;
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

    // initialize the values
    snd_mixer_selem_get_playback_volume_range(elem, &pmin, &pmax);
    fprintf(stdout, "pmin %ld\n", pmin);
    fprintf(stdout, "pmax %ld\n", pmax);
    volume = check_vol(elem, volume);
    switch_state = check_switch(elem, switch_state);
    fprintf(stdout, "----\n");
    fflush(stdout);

    snd_mixer_close(handle);

    ctl = open_ctl(card);

    while (true) {
        if (check_event(ctl)) {
            handle = get_handle(device);
            elem = get_elem(handle, mixer);
            volume = check_vol(elem, volume);
            switch_state = check_switch(elem, switch_state);
            fflush(stdout);
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
