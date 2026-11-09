# Estrategia de Preparación y Migración a Azure SQL Database — EcoMix IA

**Proyecto:** EcoMix IA — Sistema Inteligente de Dosificación y Optimización de Mezclas de Concreto Ecológico  
**Fase:** Fase 2 — Identidad, RBAC y Consolidación de Base de Datos  
**Fecha:** 9 de noviembre de 2026  
**Entorno Local:** Microsoft SQL Server LocalDB `(localdb)\MSSQLLocalDB`  
**Base de Datos Local:** `EcomixIA`  
**Entorno Destino:** Azure SQL Database (PaaS) / Azure App Service (Windows)  
**Presupuesto Máximo (D-06):** US$ 20.00 acumulado (Consumo en esta sesión: US$ 0.00)  

---

## 1. Respaldo Local de Seguridad y Verificación Criptográfica

Previo a cualquier consolidación del esquema, se generó un respaldo completo independiente de la base de datos `EcomixIA` fuera del repositorio Git:

| Parámetro | Detalle Técnico |
| :--- | :--- |
| **Ruta del archivo:** | `C:\Users\Admin\Desktop\Respaldos_EcoMixIA\Fase_02\EcomixIA_F2_Consolidacion_20261109_122028.bak` |
| **Fecha y hora:** | 2026-11-09 12:20:28 |
| **Tamaño en disco:** | 3,561,984 bytes (3.40 MB) |
| **Algoritmo de Hash:** | SHA-256 |
| **Checksum SHA-256:** | `B6AFF31C0C00F9A55FA554E7117B3A721CDDFC1680A939BA68188B3776ADAE3A` |
| **Verificación de Integridad:** | `RESTORE VERIFYONLY WITH CHECKSUM`: **100% Válido y Verificado** |
| **Integridad Física:** | `DBCC CHECKDB ('EcomixIA')`: **0 errores de asignación, 0 errores de consistencia** |

### Respaldos anteriores preservados:
- **Línea Base Fase 0:** `C:\Users\Admin\Desktop\Respaldos_EcoMixIA\Fase_00\EcomixIA_F0_20261109_004220.bak` (SHA-256: `80736A0DF13CB5EC5A9858592DDA65C6D4BA9E675E76C24C58D110DCF3FC2766`).
- **Línea Base Pre-F2:** `C:\Users\Admin\Desktop\Respaldos_EcoMixIA\Fase_02\EcomixIA_PreF2_Migration.bak` (SHA-256: `0DF06701C26ABB6360D98D824196F33B34266931492E3F87B1C33752421F9B54`).

---

## 2. Estado Actual del Esquema Consolidado Local

La base de datos `EcomixIA` integra armónicamente dos contextos de Entity Framework 6 que comparten la misma base de datos, diferenciados por su `ContextKey` en `dbo.__MigrationHistory`:

```
EcomixIA (Base de Datos)
├── Contexto de Negocio: EcomixIA.Models.EcomixContext (202611082237174_InitialCreate)
│   ├── dbo.Materials (10 filas)
│   ├── dbo.Mezclas (8 filas)
│   └── dbo.MezclaComponentes (32 filas)
└── Contexto de Identidad: EcomixIA.Models.ApplicationDbContext (202611091550114_IdentityInitialCreate)
    ├── dbo.AspNetRoles (0 filas)
    ├── dbo.AspNetUsers (0 filas)
    ├── dbo.AspNetUserRoles (0 filas)
    ├── dbo.AspNetUserClaims (0 filas)
    └── dbo.AspNetUserLogins (0 filas)
```

### Inventario de Tablas y Filas (LocalDB):

| Tabla | Tipo de Objeto | Registros | Clave Primaria (PK) | Claves Foráneas (FK) |
| :--- | :---: | :---: | :--- | :--- |
| `dbo.Materials` | Negocio | 10 | `PK_dbo.Materials` (Clustered) | Ninguna |
| `dbo.Mezclas` | Negocio | 8 | `PK_dbo.Mezclas` (Clustered) | Ninguna |
| `dbo.MezclaComponentes` | Negocio | 32 | `PK_dbo.MezclaComponentes` (Clustered) | `FK_Materials`, `FK_Mezclas` |
| `dbo.AspNetRoles` | Identidad | 0 | `PK_dbo.AspNetRoles` (Clustered) | Ninguna |
| `dbo.AspNetUsers` | Identidad | 0 | `PK_dbo.AspNetUsers` (Clustered) | Ninguna |
| `dbo.AspNetUserRoles` | Identidad | 0 | `PK_dbo.AspNetUserRoles` (Clustered) | `FK_AspNetRoles`, `FK_AspNetUsers` |
| `dbo.AspNetUserClaims` | Identidad | 0 | `PK_dbo.AspNetUserClaims` (Clustered) | `FK_AspNetUsers` |
| `dbo.AspNetUserLogins` | Identidad | 0 | `PK_dbo.AspNetUserLogins` (Clustered) | `FK_AspNetUsers` |
| `dbo.__MigrationHistory` | Sistema EF6 | 2 | `PK_dbo.__MigrationHistory` (Clustered) | Ninguna |

---

## 3. Evaluación de Compatibilidad con Azure SQL Database

Se realizó una auditoría de compatibilidad DDL/DML entre el esquema local y los requisitos técnicos de Azure SQL Database (PaaS):

1. **Índices Clustered Obligatorios:**  
   *Requisito Azure SQL:* Las tablas en Azure SQL Database requieren un índice Clustered (típicamente en la clave primaria) para permitir replicación geográfica y niveles de servicio estándar.  
   *Estado:* **100% Compatible.** Las 9 tablas tienen claves primarias agrupadas (`CLUSTERED PRIMARY KEY`).
2. **Tipos de Datos Utilizados:**  
   *Tipos en uso:* `INT`, `NVARCHAR(128)`, `NVARCHAR(256)`, `NVARCHAR(MAX)`, `BIT`, `DATETIME`, `DECIMAL(18,2)`.  
   *Estado:* **100% Compatible.** Todos son tipos ANSI/T-SQL nativos totalmente admitidos en Azure SQL Database.
3. **Acciones Referenciales en Cascada:**  
   Las tablas `dbo.AspNetUserRoles`, `dbo.AspNetUserClaims` y `dbo.AspNetUserLogins` utilizan `ON DELETE CASCADE` hacia `dbo.AspNetUsers` y `dbo.AspNetRoles`.  
   *Estado:* **100% Compatible.** No existen ciclos de cascada múltiple prohibidos por el motor relacional.
4. **Historial de Migraciones EF6 (`dbo.__MigrationHistory`):**  
   Entity Framework 6.5.1 utiliza la estructura binaria comprimida en `__MigrationHistory`. Es plenamente compatible con Azure SQL Database siempre que se use el proveedor `System.Data.SqlClient` o `Microsoft.Data.SqlClient`.
5. **Diferencia Fundamental con SQL Server On-Premise:**  
   > [!IMPORTANT]
   > **Azure SQL Database NO admite `RESTORE DATABASE` desde archivos `.bak` tradicionales de disco.**
   > Para trasladar una base de datos local a Azure SQL se debe emplear un paquete **BACPAC** (mediante SqlPackage / SSMS), un archivo **DACPAC** (solo esquema) o un **script SQL DDL/DML transaccional**, nunca un archivo `.bak`.

---

## 4. Estrategia Reproducible de Despliegue en Azure SQL Database

Para el momento en que se autorice la creación del recurso en la nube, se establecen dos vías técnicas aprobadas:

### Opción A: Despliegue mediante Paquete DACPAC / SqlPackage (Recomendada para CI/CD)
1. Extraer el esquema consolidado en un archivo `.dacpac`:
   ```powershell
   SqlPackage.exe /Action:Extract /SourceServerName:"(localdb)\MSSQLLocalDB" /SourceDatabaseName:"EcomixIA" /TargetFile:"docs\EcomixIA_Consolidado.dacpac"
   ```
2. Publicar el DACPAC hacia la base Azure SQL Database recién creada:
   ```powershell
   SqlPackage.exe /Action:Publish /SourceFile:"docs\EcomixIA_Consolidado.dacpac" /TargetServerName:"<servidor>.database.windows.net" /TargetDatabaseName:"ecomix-sql-db" /TargetUser:"<admin-user>" /TargetPassword:"<admin-password>"
   ```
3. Cargar los datos semilla mediante script DML transaccional.

### Opción B: Script SQL Idempotente Transaccional (Aprobado y Documentado)
Se ha generado el script DDL de creación de tablas Identity en [`docs/IdentityInitialCreate_Generated.sql`](file:///c:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/IdentityInitialCreate_Generated.sql).  
Para una base de datos limpia en Azure SQL:
1. Ejecutar el script DDL del modelo de negocio (`Materials`, `Mezclas`, `MezclaComponentes`).
2. Insertar los 10 materiales y las 8 mezclas patrón.
3. Ejecutar el script [`docs/IdentityInitialCreate_Generated.sql`](file:///c:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/IdentityInitialCreate_Generated.sql).
4. Insertar los registros de historial en `dbo.__MigrationHistory` para que EF6 reconozca ambos contextos.

---

## 5. Tratamiento de Datos Semilla y Seguridad

Para garantizar la integridad y confidencialidad en el traslado:

1. **Datos de Negocio a Migrar:**
   - 10 materiales sostenibles en `dbo.Materials` (Cementos, Escorias, Cenizas, Aditivos, Agregados).
   - 8 mezclas experimentales patrón en `dbo.Mezclas`.
   - 32 componentes dosificados en `dbo.MezclaComponentes`.
2. **Roles de Seguridad:**
   - Creación controlada del rol inicial `Registrado` en `dbo.AspNetRoles`.
   - No crear administradores genéricos ni contraseñas por defecto.
3. **Cero Migración de Credenciales de Prueba:**
   - **No se migrarán usuarios ni hashes de prueba** de la base secundaria `EcomixIA_F2_Migration_Test` hacia Azure SQL.
   - Las cuentas de producción deberán registrarse a través del flujo formal con dominios autorizados (`@upt.pe`, `@virtual.upt.pe`) y confirmación de correo.
4. **Transición del Servicio de Correo Transaccional:**
   - `SimulatedEmailService` almacena correos en `App_Data/EmailOutbox/`. **Su uso está terminantemente prohibido en producción.**
   - Para Azure App Service se implementará una clase `AzureSendGridEmailSender` o `AzureCommunicationServicesSender` que implemente `ITransactionalEmailSender`, cuyas credenciales y API Keys provendrán de Azure Key Vault / App Settings, sin figurar en código ni en `Web.config`.

---

## 6. Configuración de Conexión en Azure App Service (Windows)

Para asegurar que las credenciales de Azure SQL Database nunca se almacenen en `Web.config` ni se confirmen en Git:

1. **En el repositorio Git (`Web.config`):**  
   Se mantiene la cadena de conexión local hacia LocalDB para el desarrollo del equipo.
2. **En Azure Portal / Azure CLI:**  
   Se inyecta la cadena en la configuración de la aplicación:
   - **Ruta:** `Azure Portal -> App Services -> <tu-app-service> -> Configuration -> Connection strings`
   - **Nombre:** `DefaultConnection`
   - **Tipo:** `SQLAzure`
   - **Valor:**
     ```
     Server=tcp:<tu-servidor>.database.windows.net,1433;Initial Catalog=ecomix-sql-db;Persist Security Info=False;User ID=<usuario>;Password=<contraseña>;MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;
     ```
   *Efecto de Azure:* El motor de Azure App Service intercepta en memoria `ConfigurationManager.ConnectionStrings["DefaultConnection"]`, sobrescribiendo transparentemente el valor local sin requerir modificar ningún archivo de código.

---

## 7. Análisis de Costos y Restricciones FinOps (D-06)

* **Presupuesto Máximo Autorizado:** **US$ 20.00 acumulado**.
* **Consumo en la presente sesión:** **US$ 0.00** (cero recursos facturables creados).

### Elegibilidad del Azure SQL Database Free Tier:
Microsoft Azure ofrece una capa gratuita de por vida (*Free Offer*) para Azure SQL Database bajo las siguientes condiciones:
* **Modelo:** General Purpose — Serverless (Compute Tier).
* **Capacidad Gratuita:** Hasta **32 GB de almacenamiento** y **100,000 vCore-segundos por mes** gratis.
* **Auto-Pausa:** Configurada tras 60 minutos de inactividad para evitar consumo residual de cómputo.
* **Compatibilidad:** La base de datos de EcoMix IA ocupa menos de 20 MB y tiene cargas académicas de baja concurrencia, por lo que **califica holgadamente dentro del Azure SQL Free Tier con costo proyectado de US$ 0.00 / mes**.

> [!CAUTION]
> **Condición de Bloqueo FinOps:**
> Aunque la oferta gratuita existe, **queda prohibido aprovisionar el servidor o la base de datos en Azure** hasta conciliar el consumo histórico de la suscripción y recibir autorización expresa del usuario.
