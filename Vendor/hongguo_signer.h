#ifndef HONGGUO_SIGNER_H
#define HONGGUO_SIGNER_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

char *hongguo_sign(const char *request_json);
void hongguo_free_string(char *value);
int32_t hongguo_decrypt_file(
    const char *spade_a_b64,
    const char *input_path,
    const char *output_path,
    int32_t flag
);

#ifdef __cplusplus
}
#endif

#endif
