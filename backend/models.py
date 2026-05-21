from sqlalchemy import Column, String, Integer, DateTime
from database import Base
from datetime import datetime


class Usuario(Base):
    __tablename__ = "usuarios"
    usuario  = Column(String, primary_key=True, index=True)
    clave    = Column(String, nullable=False)
    rol      = Column(String, default="Operador")


class Maquina(Base):
    __tablename__ = "maquinas"
    nombre               = Column(String, primary_key=True, index=True)
    contador             = Column(Integer, default=0)
    limite_mantenimiento = Column(Integer, default=50000)


class StockItem(Base):
    __tablename__ = "stock"
    item     = Column(String, primary_key=True, index=True)
    cantidad = Column(Integer, default=0)
    minimo   = Column(Integer, default=2)


class LogEntry(Base):
    __tablename__ = "log"
    id          = Column(Integer, primary_key=True, autoincrement=True)
    fecha       = Column(String, default=lambda: datetime.now().strftime("%d/%m/%Y %H:%M"))
    maquina     = Column(String, nullable=False)
    insumo      = Column(String, nullable=False)
    contador    = Column(Integer, default=0)
    rendimiento = Column(Integer, default=0)
    nota        = Column(String, default="")
    usuario     = Column(String, default="")
