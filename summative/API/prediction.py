import io
from pathlib import Path
from typing import Literal

import joblib
import pandas as pd
from fastapi import FastAPI, File, HTTPException, Request, UploadFile
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

from retrain import REQUIRED_COLUMNS, encode_features, retrain_model

MODEL_PATH = Path(__file__).parent / "best_model.pkl"

model = joblib.load(MODEL_PATH)

app = FastAPI(
    title="Rwanda Youth Wage Predictor",
    description="Predicts the monthly income (RWF) of employed youth aged 16-30 "
                "using NISR EICV VUP microdata.",
    version="1.0.0",
)

ALLOWED_ORIGINS = [
    "https://rwanda-youth-wage-api.onrender.com",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Accept"],
)

@app.exception_handler(RequestValidationError)
async def validation_error_handler(request: Request, exc: RequestValidationError):
    errors = [
        {
            "field": ".".join(str(part) for part in err["loc"][1:]) or "body",
            "message": err["msg"],
        }
        for err in exc.errors()
    ]
    return JSONResponse(status_code=400, content={"detail": errors})

class YouthProfile(BaseModel):
    model_config = {"extra": "forbid"}

    age: int = Field(..., ge=16, le=30, description="Age in years (youth range 16-30)")
    sex: Literal["Male", "Female"]
    area: Literal["Urban", "Rural"]
    province: Literal["City of Kigali", "Eastern", "Northern", "Southern", "Western"]
    poverty_status: Literal["Non Poor", "Moderately poor", "Severaly Poor"]
    attended_school_last_12m: bool
    consumption_quintile: Literal["Poor", "Poor/mid", "Mid", "Mid/upper", "Upper"]
    education_level: Literal["Primary", "INGOBOKA /Vocational training", "Lower secondary", "Upper secondary", "Tertiary"]

    model_config["json_schema_extra"] = {
        "example": {
            "age": 25,
            "sex": "Female",
            "area": "Urban",
            "province": "City of Kigali",
            "poverty_status": "Non Poor",
            "attended_school_last_12m": False,
            "consumption_quintile": "Upper",
            "education_level": "Upper secondary",
        }
    }

def encode(raw: pd.DataFrame) -> pd.DataFrame:
    return encode_features(raw, model.feature_names_in_)

@app.get("/")
def home():
    return {
        "message": "API is running. Go to /docs to test it.",
        "model": type(model.named_steps["model"]).__name__,
        "n_features": len(model.feature_names_in_),
    }

@app.post('/predict')
def predict(profile: YouthProfile):
    row = pd.DataFrame([{
        "s1q3y": profile.age,
        "s1q1": profile.sex,
        "ur": profile.area,
        "province": profile.province,
        "poverty": profile.poverty_status,
        "s4aq7": "Yes" if profile.attended_school_last_12m else "No",
        "quintile": profile.consumption_quintile,
        "s4aq2": profile.education_level,
    }])

    X = encode(row)
    prediction = float(model.predict(X)[0])

    return {"predicted_monthly_income_rwf": round(max(prediction, 0.0), 2)}

@app.post("/retrain")
async def retrain(file: UploadFile = File(...)):
    global model

    if not file.filename or not file.filename.lower().endswith(".csv"):
        raise HTTPException(status_code=400, detail="Please upload a .csv file.")

    try:
        new_rows = pd.read_csv(io.BytesIO(await file.read()))
    except Exception:
        raise HTTPException(status_code=400, detail="Could not read the file as CSV.")

    missing = [col for col in REQUIRED_COLUMNS if col not in new_rows.columns]
    if missing:
        raise HTTPException(status_code=400, detail=f"Missing columns: {missing}")

    try:
        new_model, stats = retrain_model(new_rows, model.feature_names_in_)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    joblib.dump(new_model, MODEL_PATH)
    model = new_model

    return {"status": "Model retrained successfully", **stats}