# Youth Wage Predictor — Rwanda

## Mission

Youth unemployment and low pay are major challenges in Rwanda. This project
predicts the monthly income of employed young people (ages 16–30) from their
demographics, location and household welfare, to show where wage gaps exist
and support youth employment decisions.

## Dataset
- **Source:** National Institute of Statistics of Rwanda (NISR) — EICV Vision
  Umurenge Programme (VUP) microdata
  (`vup_s0_s1_s2_s3_s4_s6a_s6b_s6c_person.dta`)
  — [NISR Microdata Catalog](https://microdata.statistics.gov.rw/index.php/catalog/121/get_microdata)
- **Rows used:** 1,381 employed youth (ages 16–30) after cleaning
- **Target:** `monthly_income` (RWF), built from the reported wage (`s6bq9a`)
  converted to a monthly amount using its pay period (`s6bq9b`: hour, day,
  week, fortnight, month, quarter, year)
- **Features (7):**

| Column | Meaning | Type |
|---|---|---|
| `s1q3y` | Age in years | Number (16–30) |
| `s1q1` | Sex | Female / Male |
| `ur` | Residence area | Urban / Rural |
| `province` | Province | 5 provinces |
| `poverty` | Welfare category | Non poor / Moderately poor / Severely poor |
| `s4aq7` | Attended school in the last 12 months | Yes / No |
| `quintile` | Consumption quintile | Poor → Upper |