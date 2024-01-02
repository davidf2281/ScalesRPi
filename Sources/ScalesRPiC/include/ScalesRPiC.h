

#ifndef SCALESRPIC_H__
#define SCALESRPIC_H__

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



struct bme280_uncomp_data
{
    /*! Un-compensated pressure */
    uint32_t pressure;

    /*! Un-compensated temperature */
    uint32_t temperature;

    /*! Un-compensated humidity */
    uint32_t humidity;
};

struct bme280_calib_data
{
    /*! Calibration coefficient for the temperature sensor */
    uint16_t dig_t1;

    /*! Calibration coefficient for the temperature sensor */
    int16_t dig_t2;

    /*! Calibration coefficient for the temperature sensor */
    int16_t dig_t3;

    /*! Calibration coefficient for the pressure sensor */
    uint16_t dig_p1;

    /*! Calibration coefficient for the pressure sensor */
    int16_t dig_p2;

    /*! Calibration coefficient for the pressure sensor */
    int16_t dig_p3;

    /*! Calibration coefficient for the pressure sensor */
    int16_t dig_p4;

    /*! Calibration coefficient for the pressure sensor */
    int16_t dig_p5;

    /*! Calibration coefficient for the pressure sensor */
    int16_t dig_p6;

    /*! Calibration coefficient for the pressure sensor */
    int16_t dig_p7;

    /*! Calibration coefficient for the pressure sensor */
    int16_t dig_p8;

    /*! Calibration coefficient for the pressure sensor */
    int16_t dig_p9;

    /*! Calibration coefficient for the humidity sensor */
    uint8_t dig_h1;

    /*! Calibration coefficient for the humidity sensor */
    int16_t dig_h2;

    /*! Calibration coefficient for the humidity sensor */
    uint8_t dig_h3;

    /*! Calibration coefficient for the humidity sensor */
    int16_t dig_h4;

    /*! Calibration coefficient for the humidity sensor */
    int16_t dig_h5;

    /*! Calibration coefficient for the humidity sensor */
    int8_t dig_h6;

    /*! Variable to store the intermediate temperature coefficient */
    int32_t t_fine;
};

static double compensate_temperature(const struct bme280_uncomp_data *uncomp_data, struct bme280_calib_data *calib_data) {
    double var1;
    double var2;
    double temperature;
    double temperature_min = -40;
    double temperature_max = 85;

    var1 = (((double)uncomp_data->temperature) / 16384.0 - ((double)calib_data->dig_t1) / 1024.0);
    var1 = var1 * ((double)calib_data->dig_t2);
    var2 = (((double)uncomp_data->temperature) / 131072.0 - ((double)calib_data->dig_t1) / 8192.0);
    var2 = (var2 * var2) * ((double)calib_data->dig_t3);
    calib_data->t_fine = (int32_t)(var1 + var2);
    temperature = (var1 + var2) / 5120.0;

    if (temperature < temperature_min)
    {
        temperature = temperature_min;
    }
    else if (temperature > temperature_max)
    {
        temperature = temperature_max;
    }

    return temperature;
}


#endif
