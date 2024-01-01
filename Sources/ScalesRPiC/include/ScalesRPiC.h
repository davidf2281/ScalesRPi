
#include <stdint.h>
#include <stdbool.h>
typedef int32_t BME280_S32_t;

BME280_S32_t BME280_compensate_T_int32(BME280_S32_t adc_T, unsigned short dig_T1, signed short dig_T2, signed short dig_T3);
