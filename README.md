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

## API
The trained model is served by a FastAPI service hosted on Render.

- **Base URL:** https://rwanda-youth-wage-api.onrender.com
- **Swagger UI (test it here):** https://rwanda-youth-wage-api.onrender.com/docs

> The free Render instance sleeps after ~15 minutes of inactivity.
> The first request can take up to a minute while it wakes up.

### Endpoints
| Method | Path | Purpose |
|---|---|---|
| `GET` | `/` | Health check — confirms the model is loaded |
| `POST` | `/predict` | Returns the predicted monthly income (RWF) for one person |
| `POST` | `/retrain` | Uploads a CSV of new data, retrains the model and replaces it in memory |

### Example: `POST /predict`
Request body:
```json
{
  "age": 25,
  "sex": "Female",
  "area": "Urban",
  "province": "City of Kigali",
  "poverty_status": "Non Poor",
  "attended_school_last_12m": false,
  "consumption_quintile": "Upper"
}
```
Response (`200`):
```json
{ "predicted_monthly_income_rwf": 71308.5 }
```

### Validation
Inputs are validated with Pydantic: age must be **16–30**, categorical fields
only accept the listed values, and unknown fields are rejected. Invalid input
returns **`400 Bad Request`**:
```json
{ "detail": [{ "field": "age", "message": "Input should be less than or equal to 30" }] }
```

### Retraining: `POST /retrain`
Upload a CSV (multipart form, field name `file`) with the columns
`s1q3y, s1q1, ur, province, poverty, s4aq7, quintile, monthly_income`.
`summative/API/retrain_sample.csv` is a ready-made example.

## Model
All work is in `summative/linear_regression/multivariate.ipynb`.

### Preprocessing
- Filtered the survey to people aged **16–30** with a reported wage.
- Converted every wage to a **monthly amount** using its pay period.
- One-hot encoded the categorical features (`pd.get_dummies`, `drop_first=True`),
  giving **14 model features**.
- Split **80% train / 20% test** (`random_state=42`) and standardised the
  features with `StandardScaler`, fitted on the training set only.

### Models compared (Test MSE, lower is better)
| Model | Test MSE |
|---|---|
| **Linear Regression** | **1,489,493,987.70** |
| SGD Regressor | 1,537,180,358.23 |
| Random Forest | 2,333,034,006.17 |
| Decision Tree | 2,353,703,424.19 |

**Linear Regression** had the lowest test error, so it was saved as the final
model (`StandardScaler` + `LinearRegression` in one `Pipeline`) to
`summative/API/best_model.pkl`. Its test RMSE is about **38,600 RWF**.

### Limitations
Youth incomes are heavily skewed: most earners are clustered at low incomes,
with a few very high outliers. The tree-based models overfit those outliers,
while the simpler linear model generalised better. Predictions should be read
as an average trend for similar profiles, not an exact wage for one person.