# EcoMix IA — Guía de Configuración e Inicialización de Base de Datos

Esta carpeta contiene los scripts SQL oficiales para generar y poblar la base de datos `EcomixIA` en cualquier computadora nueva (desarrollo local, servidor de pruebas o Azure SQL Database).

---

## 📁 Archivos Disponibles

| Archivo | Tipo | Descripción |
| :--- | :--- | :--- |
| **`EcomixIA_Full_Setup.sql`** | **Todo-en-Uno (Recomendado)** | Ejecuta el esquema completo (DDL) y la carga de datos iniciales (DML) de manera atómica e idempotente. |
| **`01_Schema_EcomixIA.sql`** | DDL (Solo Esquema) | Crea la base de datos `EcomixIA`, las 9 tablas de aplicación/identidad, claves primarias, foráneas, índices (`IX_Mezclas_OwnerUserId`, etc.) e historial EF6. |
| **`02_SeedData_EcomixIA.sql`** | DML (Solo Datos) | Carga los 10 materiales de referencia, roles, cuentas de demostración, mezclas legadas, mezclas privadas, 46 componentes y el historial de migraciones EF6. |

---

## 🚀 Método 1: Ejecutar desde SQL Server Management Studio (SSMS)

1. Abre **SQL Server Management Studio (SSMS)**.
2. Conéctate a tu instancia de SQL Server (por ejemplo: `(localdb)\MSSQLLocalDB`, `.\SQLEXPRESS` o tu servidor local).
3. Ve a **Archivo > Abrir > Archivo...** y selecciona:
   `database\EcomixIA_Full_Setup.sql`
4. Haz clic en **Ejecutar** (o presiona `F5`).
5. En la pestaña **Mensajes** verás la confirmación de creación de tablas e inserción de datos sin ningún error.

---

## ⚡ Método 2: Ejecutar por Línea de Comandos (`sqlcmd` o PowerShell)

Abre **PowerShell** o **CMD** en la raíz del repositorio y ejecuta:

### En SQL Server LocalDB (Predeterminado en Visual Studio):
```powershell
sqlcmd -S "(localdb)\MSSQLLocalDB" -i "database\EcomixIA_Full_Setup.sql"
```

### En SQL Server Express:
```powershell
sqlcmd -S ".\SQLEXPRESS" -i "database\EcomixIA_Full_Setup.sql"
```

### En SQL Server Instancia Predeterminada:
```powershell
sqlcmd -S "localhost" -i "database\EcomixIA_Full_Setup.sql"
```

---

## ⚙️ Configuración en `Web.config`

En el proyecto ASP.NET MVC, abre `Web.config` y verifica la cadena de conexión en la sección `<connectionStrings>`:

```xml
<connectionStrings>
  <!-- Para SQL Server LocalDB (Visual Studio) -->
  <add name="EcomixContext" 
       connectionString="Data Source=(localdb)\MSSQLLocalDB;Initial Catalog=EcomixIA;Integrated Security=True;MultipleActiveResultSets=True;" 
       providerName="System.Data.SqlClient" />
</connectionStrings>
```

> **Nota para SQL Server Express:** Si tu computadora usa SQL Server Express en lugar de LocalDB, cambia `Data Source=(localdb)\MSSQLLocalDB` por `Data Source=.\SQLEXPRESS`.

---

## 👤 Cuentas de Demostración Preconfiguradas

El script inicializa automáticamente usuarios funcionales con correos confirmados y rol `Registrado`:

| Correo | Rol | Mezclas Privadas Visibles | Estado |
| :--- | :--- | :--- | :--- |
| **`joamedina@upt.pe`** | `Registrado` | 3 mezclas privadas guardadas | Confirmado y Listo |
| **`joamedina2@upt.pe`** | `Registrado` | 0 mezclas (cuenta limpia para pruebas) | Confirmado y Listo |

*(Contraseña establecida al registrarse en el sistema).*

---

## 🛡️ Idempotencia y Seguridad

- **Seguridad de re-ejecución:** Todos los scripts utilizan cláusulas `IF NOT EXISTS` e `IF OBJECT_ID(...) IS NULL`. Puedes ejecutarlos múltiples veces sin riesgo de duplicar datos ni corromper tablas existentes.
- **Historial EF6 sincronizado:** El script registra automáticamente las entradas en `__MigrationHistory` (`InitialCreate` e `IdentityInitialCreate`), permitiendo que Entity Framework 6 reconozca el modelo sin disparar errores de migración pendiente.
