from app.datastore import datastore
from fastapi import FastAPI, HTTPException

app = FastAPI()

datastore.connect()


@app.get("/entity")
def read_entity(alias: str):
    entity_id = datastore.lookup(alias)
    if not entity_id:
        raise HTTPException(status_code=404, detail="Entity not found")
    return entity_id


@app.get("/health")
def health():
    return "OK"
