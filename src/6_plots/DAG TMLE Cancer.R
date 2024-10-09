dag {
"Charlson Index" [pos="-0.825,0.311"]
"Code status at admission & discharge" [pos="-1.573,0.584"]
"Disease Severity" [pos="-1.342,-0.968"]
"Elective admission" [pos="-1.835,0.103"]
"Further comorbidities" [pos="-0.710,0.000"]
"Hospital ID" [pos="-1.548,-0.523"]
"Intervention (IMV, Vasopressors)" [exposure,pos="-1.128,-0.362"]
"Lab Values" [pos="-0.980,-0.769"]
"Lactate, glucose, sodium, potassium" [pos="-0.955,-1.119"]
"Outcomes (Mortality, 28-hospital free days)" [outcome,pos="-0.539,-0.330"]
"Source of infection" [pos="-1.813,-0.835"]
"Study year" [pos="-1.760,-0.219"]
"Vital signs" [pos="-1.890,-1.043"]
"cortisol, hemoglobin, fibrinogen, INR" [pos="-0.605,-0.966"]
"pO2, pCO2, Ph" [pos="-0.650,-0.689"]
Age [pos="-1.117,0.519"]
Comorbidities [pos="-1.060,0.023"]
Demographics [pos="-1.306,0.053"]
Ethnicity [pos="-0.972,0.502"]
OASIS [pos="-1.875,-1.256"]
Region [pos="-2.143,-0.581"]
SOFA [pos="-1.717,-1.424"]
Sex [pos="-1.290,0.527"]
Size [pos="-2.098,-0.272"]
Surgery [pos="-1.793,0.388"]
"Charlson Index" -> Comorbidities
"Code status at admission & discharge" -> Demographics
"Disease Severity" -> "Intervention (IMV, Vasopressors)"
"Elective admission" -> Demographics
"Further comorbidities" -> Comorbidities
"Hospital ID" -> "Intervention (IMV, Vasopressors)"
"Intervention (IMV, Vasopressors)" -> "Outcomes (Mortality, 28-hospital free days)"
"Lab Values" -> "Intervention (IMV, Vasopressors)"
"Lactate, glucose, sodium, potassium" -> "Lab Values"
"Source of infection" -> "Disease Severity"
"Study year" -> "Hospital ID"
"Study year" -> Demographics
"Vital signs" -> "Disease Severity"
"cortisol, hemoglobin, fibrinogen, INR" -> "Lab Values"
"pO2, pCO2, Ph" -> "Lab Values"
Age -> Demographics
Comorbidities -> Demographics
Demographics -> "Intervention (IMV, Vasopressors)"
Ethnicity -> Demographics
OASIS -> "Disease Severity"
Region -> "Hospital ID"
SOFA -> "Disease Severity"
Sex -> Demographics
Size -> "Hospital ID"
Surgery -> Demographics
}
