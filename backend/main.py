from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import jwt
import os

from database import get_db, engine
import models, schemas, crud

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="PowerPrints OS API", version="2.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

SECRET_KEY = os.getenv("SECRET_KEY", "powerprints_secret_2024")
ALGORITHM  = "HS256"
TOKEN_EXP  = 24  # horas

security = HTTPBearer()

# ── AUTH ─────────────────────────────────────────────────────────────────────

def crear_token(data: dict):
    payload = data.copy()
    payload["exp"] = datetime.utcnow() + timedelta(hours=TOKEN_EXP)
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

def verificar_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expirado")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Token inválido")

def solo_admin(token=Depends(verificar_token)):
    if token.get("rol") != "Admin":
        raise HTTPException(status_code=403, detail="Se requiere rol Admin")
    return token

# ── ENDPOINTS AUTH ────────────────────────────────────────────────────────────

@app.post("/login", response_model=schemas.LoginResponse)
def login(body: schemas.LoginRequest, db: Session = Depends(get_db)):
    user = crud.autenticar_usuario(db, body.usuario, body.clave)
    if not user:
        raise HTTPException(status_code=401, detail="Credenciales incorrectas")
    token = crear_token({"sub": user.usuario, "rol": user.rol})
    return {"token": token, "usuario": user.usuario, "rol": user.rol}

@app.get("/me")
def me(token=Depends(verificar_token)):
    return {"usuario": token["sub"], "rol": token["rol"]}

# ── MÁQUINAS ─────────────────────────────────────────────────────────────────

@app.get("/maquinas", response_model=list[schemas.Maquina])
def listar_maquinas(db: Session = Depends(get_db), token=Depends(verificar_token)):
    return crud.get_maquinas(db)

@app.post("/maquinas", response_model=schemas.Maquina)
def crear_maquina(body: schemas.MaquinaCreate, db: Session = Depends(get_db), token=Depends(solo_admin)):
    return crud.crear_maquina(db, body)

@app.put("/maquinas/{nombre}", response_model=schemas.Maquina)
def editar_maquina(nombre: str, body: schemas.MaquinaUpdate, db: Session = Depends(get_db), token=Depends(solo_admin)):
    m = crud.actualizar_maquina(db, nombre, body)
    if not m:
        raise HTTPException(status_code=404, detail="Máquina no encontrada")
    return m

@app.delete("/maquinas/{nombre}")
def borrar_maquina(nombre: str, db: Session = Depends(get_db), token=Depends(solo_admin)):
    crud.eliminar_maquina(db, nombre)
    return {"ok": True}

# ── STOCK ─────────────────────────────────────────────────────────────────────

@app.get("/stock", response_model=list[schemas.StockItem])
def listar_stock(db: Session = Depends(get_db), token=Depends(verificar_token)):
    return crud.get_stock(db)

@app.post("/stock", response_model=schemas.StockItem)
def crear_stock(body: schemas.StockCreate, db: Session = Depends(get_db), token=Depends(solo_admin)):
    return crud.crear_stock(db, body)

@app.put("/stock/{item}", response_model=schemas.StockItem)
def editar_stock(item: str, body: schemas.StockUpdate, db: Session = Depends(get_db), token=Depends(solo_admin)):
    s = crud.actualizar_stock(db, item, body)
    if not s:
        raise HTTPException(status_code=404, detail="Item no encontrado")
    return s

@app.delete("/stock/{item}")
def borrar_stock(item: str, db: Session = Depends(get_db), token=Depends(solo_admin)):
    crud.eliminar_stock(db, item)
    return {"ok": True}

# ── LOG ───────────────────────────────────────────────────────────────────────

@app.get("/log", response_model=list[schemas.LogEntry])
def listar_log(buscar: str = "", db: Session = Depends(get_db), token=Depends(verificar_token)):
    return crud.get_log(db, buscar)

@app.post("/log", response_model=schemas.LogEntry)
def registrar_log(body: schemas.LogCreate, db: Session = Depends(get_db), token=Depends(verificar_token)):
    return crud.crear_log(db, body, token["sub"])

@app.delete("/log/{id}")
def borrar_log(id: int, db: Session = Depends(get_db), token=Depends(solo_admin)):
    crud.eliminar_log(db, id)
    return {"ok": True}

@app.delete("/log")
def vaciar_log(db: Session = Depends(get_db), token=Depends(solo_admin)):
    crud.vaciar_log(db)
    return {"ok": True}

# ── USUARIOS ──────────────────────────────────────────────────────────────────

@app.get("/usuarios", response_model=list[schemas.UsuarioPublico])
def listar_usuarios(db: Session = Depends(get_db)):
    return crud.get_usuarios(db)

@app.post("/usuarios", response_model=schemas.UsuarioPublico)
def crear_usuario(body: schemas.UsuarioCreate, db: Session = Depends(get_db), token=Depends(solo_admin)):
    return crud.crear_usuario(db, body)

@app.delete("/usuarios/{usuario}")
def borrar_usuario(usuario: str, db: Session = Depends(get_db), token=Depends(solo_admin)):
    if usuario == "admin":
        raise HTTPException(status_code=400, detail="No se puede borrar al admin")
    crud.eliminar_usuario(db, usuario)
    return {"ok": True}
