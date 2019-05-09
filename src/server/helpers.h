void handle_error(const int err, const char *msg, ...);
snd_mixer_elem_t * get_elem(snd_mixer_t *handle, const char *mixer_name);
snd_mixer_t * get_handle(const char *device);
