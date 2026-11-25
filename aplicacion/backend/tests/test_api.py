from fastapi.testclient import TestClient
from app.main import app
client = TestClient(app)

def test_health():
    respuesta = client.get("/api/health")
    assert respuesta.status_code == 200
def test_crear_y_listar():
    creado = client.post("/api/items", json={"titulo": "prueba"})
    assert creado.status_code == 201
    
    lista = client.get("/api/items").json()
    assert any(item["titulo"] == "prueba" for item in lista)
    
def test_titulo_vacio():
        creado = client.post("/api/items", json={"descripcion": "prueba"})
        assert creado.status_code == 422