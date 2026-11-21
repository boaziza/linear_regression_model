# Youth Wage Predictor — Rwanda

## Mission

Youth unemployment and low pay are major challenges in Rwanda. This project
predicts the monthly income of employed young people (ages 16–30) from their
demographics, location and household welfare, to show where wage gaps exist
and support youth employment decisions.

And Youth employment programmes will be using to determine which place needs the most help.

## Dataset
- **Source:** National Institute of Statistics of Rwanda (NISR) — EICV Vision
  Umurenge Programme (VUP) microdata
  (`vup_s0_s1_s2_s3_s4_s6a_s6b_s6c_person.dta`)
  — [NISR Microdata Catalog](https://microdata.statistics.gov.rw/index.php/catalog/121/get_microdata)
- **Rows used:** 1,381 employed youth (ages 16–30) after cleaning
- **Target:** `monthly_income` (RWF), built from the reported wage (`s6bq9a`)
  converted to a monthly amount using its pay period (`s6bq9b`: hour, day,
  week, fortnight, month, quarter, year)
- **Features (8):**

| Column | Meaning | Type |
|---|---|---|
| `s1q3y` | Age in years | Number (16–30) |
| `s1q1` | Sex | Female / Male |
| `ur` | Residence area | Urban / Rural |
| `province` | Province | 5 provinces |
| `poverty` | Welfare category | Non poor / Moderately poor / Severely poor |
| `s4aq7` | Attended school in the last 12 months | Yes / No |
| `quintile` | Consumption quintile | Poor → Upper |
| `s4aq2` | Highest school level attended | Primary / Vocational / Lower secondary / Upper secondary / Tertiary |

## API (Swagger UI)
**Public Swagger UI — test the API here:** https://rwanda-youth-wage-api.onrender.com/docs

> The free Render instance sleeps after ~15 minutes of inactivity.
> The first request can take up to a minute while it wakes up.

## Video Demo
**YouTube:** [Watch the demo](PASTE-YOUR-YOUTUBE-LINK-HERE)

## Running the Mobile App
Requirements: [Flutter SDK](https://docs.flutter.dev/get-started/install) and an
Android emulator or Android phone with USB debugging enabled.

1. Clone the repository and open the app folder:
   ```bash
   git clone https://github.com/boaziza/linear_regression_model.git
   cd linear_regression_model/summative/FlutterApp/flutter_app
   ```
2. Install the packages:
   ```bash
   flutter pub get
   ```
3. Start an Android emulator (or connect a phone), then run the app:
   ```bash
   flutter run
   ```
4. In the app, enter an **age (16–30)**, choose **sex**, **area**, **province**,
   **poverty status**, **consumption quintile**, **highest school level**, and
   whether the person **attended school in the last 12 months**.
5. Tap **Predict**. The estimated monthly income appears in RWF. Invalid input
   (for example age 35) shows the API's error message instead.

The app calls the public Render API — the URL is set once in
`summative/FlutterApp/flutter_app/lib/services/api_service.dart` (`baseUrl`).
Run it on Android, not Chrome: the API only allows its own domain through CORS,
so a browser build of the app is blocked by design.

---

## API Details
Base URL: https://rwanda-youth-wage-api.onrender.com

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/` | Health check — confirms the model is loaded |
| `POST` | `/predict` | Returns the predicted monthly income (RWF) for one person |
| `POST` | `/retrain` | Uploads a CSV of new data, retrains the model and replaces it in memory |
| `GET` | `/docs` | Swagger UI |

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
  "consumption_quintile": "Upper",
  "education_level": "Upper secondary"
}
```
Response (`200`):
```json
{ "predicted_monthly_income_rwf": 83334.15 }
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
`s1q3y, s1q1, ur, province, poverty, s4aq7, quintile, s4aq2, monthly_income`.
The new rows are cleaned, combined with the original training data
(`summative/API/retrain_sample.csv`) and the Linear Regression pipeline is
refitted. `/predict` uses the updated model straight away, without a redeploy.
On Render's free plan the retrained model is lost when the service restarts,
and the API loads `best_model.pkl` from the repository again.

## Model
All work is in `summative/linear_regression/multivariate.ipynb`.

### Preprocessing
- Filtered the survey to people aged **16–30** with a reported wage.
- Converted every wage to a **monthly amount** using its pay period.
- One-hot encoded the categorical features (`pd.get_dummies`, `drop_first=True`),
  giving **18 model features**.
- Split **80% train / 20% test** (`random_state=42`) and standardised the
  features with `StandardScaler`, fitted on the training set only.

### Models compared (Test MSE, lower is better)
| Model | Test MSE |
|---|---|
| **Linear Regression** | **1,254,856,003.30** |
| SGD Regressor | 1,343,821,171.20 |
| Random Forest | 2,065,954,014.53 |
| Decision Tree | 10,058,771,211.89 |

**Linear Regression** had the lowest test error, so it was saved as the final
model (`StandardScaler` + `LinearRegression` in one `Pipeline`) to
`summative/API/best_model.pkl`. Its test RMSE is about **35,400 RWF**.

### Limitations
Youth incomes are heavily skewed: most earners are clustered at low incomes,
with a few very high outliers. The tree-based models overfit those outliers,
while the simpler linear model generalised better. Predictions should be read
as an average trend for similar profiles, not an exact wage for one person.

## Run the API locally (optional)
```bash
cd summative/API
uv sync
uv run uvicorn prediction:app --reload
```
Then open http://127.0.0.1:8000/docs.

## Repository Structure
```
linear_regression_model/
├── README.md
└── summative/
    ├── pyproject.toml
    ├── uv.lock
    ├── linear_regression/
    │   ├── multivariate.ipynb          # Data cleaning, EDA, training, model comparison
    │   ├── nisr_vup_demographics.csv   # Survey data converted from Stata
    │   └── Microdata/                  # Original NISR .dta file
    ├── API/
    │   ├── prediction.py               # FastAPI app: /predict, /retrain, CORS
    │   ├── retrain.py                  # Cleans new rows, combines with original data, refits
    │   ├── pyproject.toml              # API dependencies (uv)
    │   ├── uv.lock
    │   ├── requirements.txt            # Exported from uv, installed on Render
    │   ├── best_model.pkl              # Saved Pipeline (StandardScaler + LinearRegression)
    │   └── retrain_sample.csv          # Original cleaned training data / example upload
    └── FlutterApp/flutter_app/
        └── lib/
            ├── main.dart
            ├── screen/prediction_page.dart
            ├── services/api_service.dart
            └── constants/form_options.dart
```
