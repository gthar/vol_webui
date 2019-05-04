#include <alsa/asoundlib.h>
#include <stdbool.h>

snd_ctl_t * open_ctl(char * card_name)
{
    int err;
    snd_ctl_t *ctl;

    err = snd_ctl_open(&ctl, card_name, SND_CTL_READONLY);
    if (err < 0) {
        fprintf(stderr, "Cannot open ctl %s\n", card_name);
        exit(err);
    }
    err = snd_ctl_subscribe_events(ctl, 1);
    if (err < 0) {
        fprintf(stderr, "Cannot open subscribe events to ctl %s\n", card_name);
        snd_ctl_close(ctl);
        exit(err);
    }
    return ctl;
}

bool check_event (snd_ctl_t * ctl)
{
    int err;
    snd_ctl_event_t *event;
    struct pollfd fd;
    unsigned int mask;
    unsigned short revents;

    snd_ctl_poll_descriptors(ctl, &fd, 1);

    err = poll(&fd, 1, -1);
    if (err <= 0)
        exit(err);

    snd_ctl_poll_descriptors_revents(ctl, &fd, 1, &revents);
    if (revents & POLLIN) {

        snd_ctl_event_alloca(&event);
        err = snd_ctl_read(ctl, event);
        if (err < 0)
            exit(err);

        if (snd_ctl_event_get_type(event) != SND_CTL_EVENT_ELEM)
            return false;

        mask = snd_ctl_event_elem_get_mask(event);
        if (!(mask & SND_CTL_EVENT_MASK_VALUE))
            return false;

        return true;

    }
    return false;
}

int main(int argc, char *argv[])
{
    snd_ctl_t *ctl;

    if (argc < 2) {
        printf("arguments: card (i.e., hw:0)\n");
        return 1;
    }

    ctl = open_ctl(argv[1]);
    while (true) {
        if (check_event(ctl)) {
            fprintf(stdout, "valueChanged\n");
            fflush(stdout);
        }
    }
    return 0;
}
