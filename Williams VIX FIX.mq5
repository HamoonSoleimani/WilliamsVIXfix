//+------------------------------------------------------------------+
//|                                       Williams VIX FIX.mq5       |
//|                              Copyright 2024, Hamoon Soleimani    |
//|                                     https://www.hamoon.net       |
//|                                  Based on Chris Moody's idea     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Hamoon Soleimani"
#property link      "https://www.hamoon.net"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 9
#property indicator_plots   5

//--- plot WVF
#property indicator_label1  "Williams Vix Fix"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrGray,clrLime,clrAqua,clrFuchsia,clrOrange
#property indicator_style1  STYLE_SOLID
#property indicator_width1  4

//--- plot Alert1
#property indicator_label2  "Alert If WVF = True"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrLime
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

//--- plot Alert2
#property indicator_label3  "Alert If WVF Was True Now False"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrAqua
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2

//--- plot Alert3
#property indicator_label4  "Alert Filtered Entry"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrFuchsia
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2

//--- plot Alert4
#property indicator_label5  "Alert Aggressive Filtered Entry"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrOrange
#property indicator_style5  STYLE_SOLID
#property indicator_width5  2

//--- input parameters
input int      pd = 22;              // LookBack Period Standard Deviation High
input int      bbl = 20;             // Bollinger Band Length
input double   mult = 2.0;           // Bollinger Band Standard Deviation Up
input int      lb = 50;              // Look Back Period Percentile High
input double   ph = 0.85;            // Highest Percentile
input bool     sbc = true;           // Show Highlight Bar if WVF WAS True and IS Now False
input bool     sbcc = false;         // Show Highlight Bar if WVF IS True
input bool     sbcFilt = true;       // Show Highlight Bar For Filtered Entry
input bool     sbcAggr = false;      // Show Highlight Bar For AGGRESSIVE Filtered Entry
input bool     sgb = false;          // Check Box To Turn Bars Gray?
input int      ltLB = 40;            // Long-Term Look Back
input int      mtLB = 14;            // Medium-Term Look Back
input int      str = 3;              // Entry Price Action Strength
input bool     swvf = true;          // Show Williams Vix Fix Histogram
input bool     sa1 = false;          // Show Alert WVF = True?
input bool     sa2 = false;          // Show Alert WVF Was True Now False?
input bool     sa3 = false;          // Show Alert WVF Filtered?
input bool     sa4 = false;          // Show Alert WVF AGGRESSIVE Filter?

//--- indicator buffers
double         WVFBuffer[];
double         WVFColors[];
double         Alert1Buffer[];
double         Alert2Buffer[];
double         Alert3Buffer[];
double         Alert4Buffer[];
double         UpperBandBuffer[];
double         RangeHighBuffer[];
double         HighestBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   // Set index buffers
   SetIndexBuffer(0, WVFBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, WVFColors, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, Alert1Buffer, INDICATOR_DATA);
   SetIndexBuffer(3, Alert2Buffer, INDICATOR_DATA);
   SetIndexBuffer(4, Alert3Buffer, INDICATOR_DATA);
   SetIndexBuffer(5, Alert4Buffer, INDICATOR_DATA);
   SetIndexBuffer(6, UpperBandBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(7, RangeHighBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(8, HighestBuffer, INDICATOR_CALCULATIONS);
   
   // Indicator digits
   IndicatorSetInteger(INDICATOR_DIGITS, 2);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   // Check for sufficient data
   if (rates_total < pd || rates_total < bbl || rates_total < lb)
      return (0);
   
   // Calculate starting point
   int start = MathMax(MathMax(pd, bbl), lb);
   if (prev_calculated > start)
      start = prev_calculated - 1;
   
   // Iterate through bars
   for (int i = start; i < rates_total; i++)
   {
      // Williams Vix Fix calculation
      int highestIdx = iHighest(NULL, 0, MODE_CLOSE, pd, i - pd + 1);
      double highestClose = close[highestIdx];
      double wvf = ((highestClose - low[i]) / highestClose) * 100;
      WVFBuffer[i] = wvf;
      
      // Bollinger Bands calculation
      double sDev = mult * StdDev(WVFBuffer, i, bbl);
      double midLine = SMA(WVFBuffer, i, bbl);
      UpperBandBuffer[i] = midLine + sDev;
      double lowerBand = midLine - sDev;
      RangeHighBuffer[i] = Highest(WVFBuffer, i, lb) * ph;
      
      // Alert conditions
      bool upRange = (low[i] > low[i - 1]) && (close[i] > high[i - 1]);
      bool upRange_Aggr = (close[i] > close[i - 1]) && (close[i] > open[i]);
      
      bool filtered = (WVFBuffer[i - 1] >= UpperBandBuffer[i - 1] || WVFBuffer[i - 1] >= RangeHighBuffer[i - 1]) && (wvf < UpperBandBuffer[i] && wvf < RangeHighBuffer[i]);
      bool filtered_Aggr = (WVFBuffer[i - 1] >= UpperBandBuffer[i - 1] || WVFBuffer[i - 1] >= RangeHighBuffer[i - 1]) && !(wvf < UpperBandBuffer[i] && wvf < RangeHighBuffer[i]);
      
      Alert1Buffer[i] = (wvf >= UpperBandBuffer[i] || wvf >= RangeHighBuffer[i]) ? 1 : 0;
      Alert2Buffer[i] = (filtered) ? 1 : 0;
      Alert3Buffer[i] = (upRange && close[i] > close[i - str] && (close[i] < close[i - ltLB] || close[i] < close[i - mtLB]) && filtered) ? 1 : 0;
      Alert4Buffer[i] = (upRange_Aggr && close[i] > close[i - str] && (close[i] < close[i - ltLB] || close[i] < close[i - mtLB]) && filtered_Aggr) ? 1 : 0;
      
      // Set WVF colors
      if (sbcAggr && Alert4Buffer[i] > 0)
         WVFColors[i] = 4; // Orange color
      else if (sbcFilt && Alert3Buffer[i] > 0)
         WVFColors[i] = 3; // Fuchsia color
      else if (sbc && Alert2Buffer[i] > 0)
         WVFColors[i] = 2; // Aqua color
      else if (sbcc && Alert1Buffer[i] > 0)
         WVFColors[i] = 1; // Lime color
      else if (sgb)
         WVFColors[i] = 0; // Gray color
      else if (wvf >= UpperBandBuffer[i] || wvf >= RangeHighBuffer[i])
         WVFColors[i] = 1; // Lime color
      else
         WVFColors[i] = 0; // Gray color
   }
   
   return (rates_total);
}

// Helper functions
double SMA(const double &array[], int pos, int period)
{
   double sum = 0.0;
   for (int i = 0; i < period; i++)
   {
      sum += array[pos - i];
   }
   return (sum / period);
}

double StdDev(const double &array[], int pos, int period)
{
   double sum = 0.0, mean, deviation = 0.0;
   for (int i = 0; i < period; i++)
   {
      sum += array[pos - i];
   }
   mean = sum / period;
   for (int i = 0; i < period; i++)
   {
      deviation += MathPow(array[pos - i] - mean, 2);
   }
   return MathSqrt(deviation / period);
}

double Highest(const double &array[], int pos, int period)
{
   double highest = array[pos];
   for (int i = 1; i < period; i++)
   {
      if (array[pos - i] > highest)
         highest = array[pos - i];
   }
   return highest;
}
