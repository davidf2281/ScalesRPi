
#include <stdint.h>

typedef int32_t BME280_S32_t;
typedef uint32_t BME280_U32_t;
typedef int64_t BME280_S64_t;

BME280_S32_t t_fine(BME280_S32_t adc_T, 
                    unsigned short dig_T1,
                    signed short dig_T2, 
                    signed short dig_T3);

BME280_S32_t BME280_compensate_T_int32(BME280_S32_t t_fine);

BME280_U32_t BME280_compensate_P_int64(BME280_S32_t adc_P,
                                       BME280_S32_t t_fine,
                                       unsigned short dig_P1,
                                       signed short dig_P2,
                                       signed short dig_P3,
                                       signed short dig_P4,
                                       signed short dig_P5,
                                       signed short dig_P6,
                                       signed short dig_P7,
                                       signed short dig_P8,
                                       signed short dig_P9);

BME280_U32_t bme280_compensate_H_int32(BME280_S32_t adc_H,
                                       BME280_S32_t t_fine,
                                       unsigned char dig_H1,
                                       signed short dig_H2,
                                       unsigned char dig_H3,
                                       signed short dig_H4,
                                       signed short dig_H5,
                                       signed char dig_H6);
