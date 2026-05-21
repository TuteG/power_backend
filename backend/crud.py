import hashlib
from sqlalchemy.orm import Session
import models, schemas


def hash_clave(clave: str) -> str:
    return hashlib.sha256(clave.encode()).hexdigest()


# ── USUARIOS ──────────────────────────────────────────────────────────────────
def _seed_admin(db: Session):
    if not db.query(models.Usuario).filter_by(usuario="admin").first():
        db.add(models.Usuario(usuario="admin", clave=hash_clave("1234"), rol="Admin"))
        db.commit()

def autenticar_usuario(db: Session, usuario: str, clave: str):
    _seed_admin(db)
    return db.query(models.Usuario).filter_by(
        usuario=usuario, clave=hash_clave(clave)
    ).first()

def get_usuarios(db: Session):
    _seed_admin(db)
    return db.query(models.Usuario).all()

def crear_usuario(db: Session, data: schemas.UsuarioCreate):
    u = models.Usuario(usuario=data.usuario, clave=hash_clave(data.clave), rol=data.rol)
    db.merge(u); db.commit(); db.refresh(u)
    return u

def eliminar_usuario(db: Session, usuario: str):
    db.query(models.Usuario).filter_by(usuario=usuario).delete()
    db.commit()


# ── MÁQUINAS ──────────────────────────────────────────────────────────────────
def get_maquinas(db: Session):
    return db.query(models.Maquina).all()

def crear_maquina(db: Session, data: schemas.MaquinaCreate):
    m = models.Maquina(**data.model_dump())
    db.merge(m); db.commit(); db.refresh(m)
    return m

def actualizar_maquina(db: Session, nombre: str, data: schemas.MaquinaUpdate):
    m = db.query(models.Maquina).filter_by(nombre=nombre).first()
    if not m: return None
    if data.contador             is not None: m.contador             = data.contador
    if data.limite_mantenimiento is not None: m.limite_mantenimiento = data.limite_mantenimiento
    db.commit(); db.refresh(m)
    return m

def eliminar_maquina(db: Session, nombre: str):
    db.query(models.Maquina).filter_by(nombre=nombre).delete()
    db.commit()


# ── STOCK ─────────────────────────────────────────────────────────────────────
def get_stock(db: Session):
    return db.query(models.StockItem).all()

def crear_stock(db: Session, data: schemas.StockCreate):
    s = models.StockItem(**data.model_dump())
    db.merge(s); db.commit(); db.refresh(s)
    return s

def actualizar_stock(db: Session, item: str, data: schemas.StockUpdate):
    s = db.query(models.StockItem).filter_by(item=item).first()
    if not s: return None
    if data.cantidad is not None: s.cantidad = data.cantidad
    if data.minimo   is not None: s.minimo   = data.minimo
    db.commit(); db.refresh(s)
    return s

def eliminar_stock(db: Session, item: str):
    db.query(models.StockItem).filter_by(item=item).delete()
    db.commit()


# ── LOG ───────────────────────────────────────────────────────────────────────
def get_log(db: Session, buscar: str = ""):
    q = db.query(models.LogEntry)
    if buscar:
        q = q.filter(
            models.LogEntry.maquina.ilike(f"%{buscar}%") |
            models.LogEntry.insumo.ilike(f"%{buscar}%")
        )
    return q.order_by(models.LogEntry.id.desc()).limit(60).all()

def crear_log(db: Session, data: schemas.LogCreate, usuario: str):
    # Calcular rendimiento
    prev = db.query(models.LogEntry).filter_by(
        maquina=data.maquina, insumo=data.insumo
    ).order_by(models.LogEntry.id.desc()).first()
    rend = data.contador - prev.contador if prev else 0

    # Descontar stock
    stock = db.query(models.StockItem).filter_by(item=data.insumo).first()
    if stock and stock.cantidad > 0:
        stock.cantidad -= 1

    # Actualizar contador máquina
    maquina = db.query(models.Maquina).filter_by(nombre=data.maquina).first()
    if maquina:
        maquina.contador = data.contador

    from datetime import datetime
    entry = models.LogEntry(
        fecha=datetime.now().strftime("%d/%m/%Y %H:%M"),
        maquina=data.maquina,
        insumo=data.insumo,
        contador=data.contador,
        rendimiento=rend,
        nota=data.nota,
        usuario=usuario,
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry

def eliminar_log(db: Session, id: int):
    db.query(models.LogEntry).filter_by(id=id).delete()
    db.commit()

def vaciar_log(db: Session):
    db.query(models.LogEntry).delete()
    db.commit()
