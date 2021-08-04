/*
This do-file: Replication Table 3 - Panel A - Sun and Abraham 2020.
The HRS_long.dta is obtained from the Replication Kit for 
Dobkin, Carlos, Amy Finkelstein, Raymond Kluender, and Matthew J. Notowidigdo, 
“The Economic Consequences of Hospital Admissions,” 
American Economic Review, February 2018, 108 (2), 308–52.
All variables follow their definitions.
*/
use  "/116186-V1/Replication-Kit/HRS/Data/HRS_long.dta", clear
set matsize 800
set more off

/* 
	Preliminaries
*/
drop if wave < 7 // keep a balanced sample for wave 7-11
bys hhidpn: gen N = _N
keep if N == 5

bys hhidpn: egen flag = min(evt_time)
drop if flag >= 0 & flag != . // drop those first hospitalization happened before or during wave 7
drop if flag == . 
drop flag

*Cohort variable
bys hhidpn: egen wave_hosp_copy = min(wave_hosp) // fill in the wave of index hosp within an hhidpn
replace wave_hosp = wave_hosp_copy
drop wave_hosp_copy

keep if ever_hospitalized // keep a sample of individuals who were ever hospitalized wave 8-11
* Generate calendar and event time and cohort dummies
xi i.wave
tab evt_time, gen(evt_time_)
tab wave_hosp, gen(wave_hosp_)

keep if age_hosp <= 59

* Gen control variable
gen last_cohort = (wave_hosp==11)


*Two-way fixed effects  - Column 1
reghdfe oop_spend  evt_time_2-evt_time_3 evt_time_5-evt_time_8 _Iwave_*  if ever_hospitalized    , absorb(hhidpn) cluster(hhidpn)


 /* IW - Column 2*/ 
 eventstudyinteract oop_spend  evt_time_2 evt_time_3 evt_time_5 evt_time_6 evt_time_7 if ever_hospitalized & wave < 11, cohort(wave_hosp) control_cohort(last_cohort)  absorb(hhidpn i.wave) vce(cluster hhidpn)

   matrix C = e(b_iw)
   mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
   matrix C = C \ A
   matrix list C
   coefplot matrix(C[1]), se(C[2])


  * We can look at the share of cohorts underlying the IW estimates for each relative time.
        matrix list e(ff_w)

    *We can look at the cohort-specific treatment effect estimates for each relative time.  Column 3, 4 and 5.
        matrix list e(b_interact)

   /*  We can check that the IW estimates are weighted averages of the
    cohort-specific dynamic effect estimate , weighted by the corresponding
    cohort share estimates.  */
       matrix list e(b_iw)
    *which is the weighted average of cohort-specific treatment effect
    *estimates, with weights corresponding to the cohort share estimates:
        matrix delta = e(b_interact)
        matrix weight = e(ff_w)
        matrix nu = delta[1...,1]'*weight[1...,1]
         matrix list nu





