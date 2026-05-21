from pydantic import BaseModel
from typing import Optional


# ── AUTH ──────────────────────────────────────────────────────────────────────
class LoginRequest(BaseModel):
    usuario: str
    clave:   str

class LoginResponse(BaseModel):
    token:   str
    usuario: str
    rol:     str


# ── USUARIOS ──────────────────────────────────────────────────────────────────
class UsuarioCreate(BaseModel):
    usuario: str
    clave:   str
    rol:     str = "Operador"

class UsuarioPublico(BaseModel):
    usuario: str
    rol:     str
    class Config: from_attributes = True


# ── MÁQUINAS ──────────────────────────────────────────────────────────────────
class MaquinaCreate(BaseModel):
    nombre:               str
    contador:             int = 0
    limite_mantenimiento: int = 50000

class MaquinaUpdate(BaseModel):
    contador:             Optional[int] = None
    limite_mantenimiento: Optional[int] = None

class Maquina(BaseModel):
    nombre:               str
    contador:             int
    limite_mantenimiento: int
    class Config: from_attributes = True


# ── STOCK ─────────────────────────────────────────────────────────────────────
class StockCreate(BaseModel):
    item:     str
    cantidad: int = 0
    minimo:   int = 2

class StockUpdate(BaseModel):
    cantidad: Optional[int] = None
    minimo:   Optional[int] = None

class StockItem(BaseModel):
    item:     str
    cantidad: int
    minimo:   int
    class Config: from_attributes = True


# ── LOG ───────────────────────────────────────────────────────────────────────
class LogCreate(BaseModel):
    maquina:  str
    insumo:   str
    contador: int
    nota:     str = ""

class LogEntry(BaseModel):
    id:          int
    fecha:       str
    maquina:     str
    insumo:      str
    contador:    int
    rendimiento: int
    nota:        str
    usuario:     str
    class Config: from_attributes = True
