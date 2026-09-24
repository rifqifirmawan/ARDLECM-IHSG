/********************************************************************
ARDL MODEL – IHSG & MARKET FEAR
Author  : Rifqi Firmawan
Method  : ARDL Bounds Testing Approach
Data    : Time Series (Monthly)
********************************************************************/

clear all
set more off

/********************************************************************
STEP 0 : IMPORT & TIME SETTING
********************************************************************/

import excel "E:/Kuliah/Skripsi/Data Baru/Data Baru Set.xlsx", sheet("Variabel") firstrow

gen mdate = monthly(Date, "YM")
format mdate %tm
drop Date
rename mdate Date

tsset Date, monthly

/********************************************************************
STEP 1 : VARIABLE TRANSFORMATION
********************************************************************/

gen l_ihsg   = log(IHSG)
gen l_tradev = log(TRADEV)

label var l_ihsg   "Log IHSG"
label var l_tradev "Log Trading Volume"
label var FEDFUNDS "Fed Funds Rate"
label var SENTIMENT "Sentimen Pasar"
label var FOREIGN  "Foreign Net Buy"
label var BREADTH  "Market Breadth"
label var TURNOVER "Turnover"
label var MSCI "MSCI Dummy"
gen NETFOREIGN = FOREIGN / 1000000000000
/********************************************************************
STEP 2 : UNIT ROOT TEST (ADF)
********************************************************************/

* Level
dfuller l_ihsg
dfuller l_tradev
dfuller FEDFUNDS
dfuller SENTIMENT
dfuller FOREIGN
dfuller BREADTH
dfuller TURNOVER

* First Difference
dfuller D.l_ihsg
dfuller D.l_tradev
dfuller D.FEDFUNDS
dfuller D.SENTIMENT
dfuller D.FOREIGN
dfuller D.BREADTH
dfuller D.TURNOVER
/********************************************************************
STEP 3 : ESTIMASI ARDL + LR & SR & PEMILIHAN LAG (AIC)
********************************************************************/
ardl l_ihsg l_tradev FEDFUNDS SENTIMENT NETFOREIGN BREADTH TURNOVER, maxlags(4) aic exog(MSCI)  ec1
estimates store ardl_final
estat ic

/********************************************************************
STEP 4 : BOUNDS TEST FOR COINTEGRATION
********************************************************************/
estat ectest

/********************************************************************
STEP 5 : DIAGNOSTIC TESTS
********************************************************************/

* Autocorrelation
ardl l_ihsg l_tradev FEDFUNDS SENTIMENT NETFOREIGN BREADTH TURNOVER, maxlags(4) aic exog(MSCI)  ec1
predict resid, residuals
regress resid L.resid L2.resid L3.resid L4.resid



* Heteroskedasticity

estat imtest, white

* Normality

estat imtest

* Uji Stabilitas cusum dan cusumQ
ardl l_ihsg l_tradev FEDFUNDS SENTIMENT NETFOREIGN BREADTH TURNOVER, exog(MSCI) aic
estat sbcusum
cusum6 l_ihsg l_tradev FEDFUNDS SENTIMENT FOREIGN BREADTH TURNOVER

**Estimasi Model ARDL**
*-----------------------------------------------------*

ardl l_ihsg l_tradev FEDFUNDS SENTIMENT NETFOREIGN BREADTH TURNOVER, maxlags(4) aic exog(MSCIdummy) ec1

*=====================================================*
*        UJI F SIMULTAN JANGKA PANJANG                *
*=====================================================*

test L.l_tradev L.FEDFUNDS L.SENTIMENT L.NETFOREIGN L.BREADTH L.TURNOVER

display "======================================="
display "UJI F JANGKA PANJANG"
display "Bandingkan F-statistik dengan F-tabel"
display "======================================="

*=====================================================*
*         UJI F SIMULTAN JANGKA PENDEK                *
*=====================================================*

test D.l_tradev D.FEDFUNDS D.SENTIMENT D.NETFOREIGN LD.NETFOREIGN L2D.NETFOREIGN L3D.NETFOREIGN D.BREADTH LD.BREADTH L2D.BREADTH D.TURNOVER

display "======================================="
display "UJI F JANGKA PENDEK"
display "Bandingkan F-statistik dengan F-tabel"
display "======================================="

*=====================================================*
*                UJI T PARSIAL                        *
*=====================================================*

display "======================================="
display "UJI T PARSIAL"
display "Lihat nilai t-statistic masing-masing variabel"
display "Bandingkan |t-statistic| dengan t-tabel"
display "======================================="
/********************************************************************
STEP 6 : SAVE RESULTS
********************************************************************/

esttab ardl_final, b(%9.4f) se(%9.4f) star(* 0.10 ** 0.05 *** 0.01) scalars(r2 r2_a aic bic N) title("ARDL Model Estimation Results")

estimates save "ARDL_IHSG_Final", replace

* Grafik Z Score Pola Pergerakan Variabel Penelitian
* Hapus semua Z-score lama
capture drop z_*

* Buat Z-score variabel penelitian
egen z_l_ihsg      = std(l_ihsg)
egen z_l_tradev    = std(l_tradev)
egen z_FEDFUNDS    = std(FEDFUNDS)
egen z_SENTIMENT   = std(SENTIMENT)
egen z_NETFOREIGN  = std(NETFOREIGN)
egen z_BREADTH     = std(BREADTH)
egen z_TURNOVER    = std(TURNOVER)
egen z_MSCI        = std(MSCI)

* Label variabel agar legend rapi
label variable z_l_ihsg     "IHSG"
label variable z_l_tradev   "Trade Vol."
label variable z_FEDFUNDS   "Fed Funds Rate"
label variable z_SENTIMENT  "Sentiment"
label variable z_NETFOREIGN "Net Foreign"
label variable z_BREADTH    "Market Breadth"
label variable z_TURNOVER   "Turnover"
label variable z_MSCI       "MSCI"

*(tanpa MSCI jika hanya exogenous)
tsline z_l_ihsg z_l_tradev z_FEDFUNDS z_SENTIMENT z_NETFOREIGN z_BREADTH z_TURNOVER, ///
title("Pola Pergerakan Variabel Penelitian (Z-Score)") ///
ytitle("Z-Score") xtitle("Periode") ///
legend(rows(2) size(small)) ///
scheme(s2color)

*Dengan MSCI 
tsline z_l_ihsg z_l_tradev z_FEDFUNDS z_SENTIMENT z_NETFOREIGN z_BREADTH z_TURNOVER z_MSCI, ///
title("Pola Pergerakan Variabel Penelitian (Z-Score)") ///
ytitle("Z-Score") ///
xtitle("Periode") ///
legend(rows(2) size(small)) ///
scheme(s2color)

****ardl l_ihsg l_tradev FEDFUNDS SENTIMENT NETFOREIGN BREADTH TURNOVER, lags(2 1 0 0 0 0 0) exog(MSCI) ec1

