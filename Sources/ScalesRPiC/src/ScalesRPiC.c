
#include "ScalesRPiC.h"

// Returns temperature in DegC, resolution is 0.01 DegC. Output value of “5123” equals 51.23
// DegC.
// t_fine carries fine temperature as global value
BME280_S32_t t_fine;
BME280_S32_t BME280_compensate_T_int32(BME280_S32_t adc_T, unsigned short dig_T1, signed short dig_T2, signed short dig_T3)
{
   BME280_S32_t var1, var2, T;
   var1 = ((((adc_T>>3) - ((BME280_S32_t)dig_T1<<1))) * ((BME280_S32_t)dig_T2)) >> 11;
   var2 = (((((adc_T>>4) - ((BME280_S32_t)dig_T1)) * ((adc_T>>4) - ((BME280_S32_t)dig_T1))) >> 12) * ((BME280_S32_t)dig_T3)) >> 14;
   t_fine = var1 + var2;
   T = (t_fine * 5 + 128) >> 8;
   return T;
}
