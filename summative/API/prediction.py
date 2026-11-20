from fastapi import FastAPI

app = FastAPI(
    title="Rwanda Youth Wage Predictor",
    description="Predicts the monthly income (RWF) of employed youth aged 16-30 "
                "using NISR EICV VUP microdata.",
    version="1.0.0",
)

@app.get('/')
def home():
    return {'message": "API is running. Go to /docs to test it.'}