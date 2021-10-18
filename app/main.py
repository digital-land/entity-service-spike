from app.datastore import datastore
from fastapi import FastAPI, HTTPException

app = FastAPI()

datastore.connect()


@app.get("/search")
def read_entity(slug: str):
    entity_id = datastore.lookup(slug)
    if not entity_id:
        raise HTTPException(status_code=404, detail="Entity not found")
    return entity_id


@app.get("/health")
def health():
    return "OK"
