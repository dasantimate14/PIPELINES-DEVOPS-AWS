import os
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="API del Proyecto")

class ItemNuevo(BaseModel):
    titulo: str
    descripcion: str = ""
    
class Item(ItemNuevo):
    id: int

items: list[Item] = []

@app.get("/api/health")
def health():
    return {"status": "ok"}

@app.get("/api/version")
def version():
    return {"version": os.getenv("APP_VERSION", "local")}

@app.get("/api/items") #Lista los elementos
def items_list():
    return {"Items": items}

@app.post("/api/items", status_code=201) #Crea un elemento
def crear_item(nuevo: ItemNuevo) -> Item:
    item = Item(id=len(items) + 1, **nuevo.model_dump())
    items.append(item)
    return item