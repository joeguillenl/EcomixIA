# Guía de Instalación y Despliegue en Entorno Limpio — EcoMix IA

**Proyecto:** EcoMix IA — Sistema Inteligente de Dosificación y Simulación de Concreto Ecológico  
**Versión:** 1.0 (Hito H05)  
**Fecha:** 20 de Noviembre de 2026  
**Rama de Entrega:** `feat/ecomix-fase-04-cierre-integracion`  
**Objetivo:** Instrucciones paso a paso, reproducibles y verificables para desplegar la solución en una máquina o servidor limpio desde cero.

---

## 1. Requisitos Previos del Sistema

Antes de iniciar la instalación, verifique que el equipo anfitrión cuente con el siguiente software instalado:

| Componente | Versión Mínima Requerida | Propósito |
|---|---|---|
| **Sistema Operativo** | Windows 10 / 11 / Windows Server 2019+ | Entorno de ejecución .NET Framework |
| **.NET Framework** | .NET Framework 4.7.2 Runtime y Developer Pack | Framework de ejecución de ASP.NET MVC 5 |
| **Visual Studio / Build Tools** | VS 2022 Community o Build Tools (v17+) | Compilador MSBuild y herramientas de build |
| **SQL Server** | SQL Server 2016+ o SQL Server LocalDB (`(LocalDb)\MSSQLLocalDB`) | Motor relacional de base de datos |
| **IIS Express / IIS** | IIS Express 10.0+ (incluido en VS) | Servidor web local para depuración y hosting |
| **PowerShell** | Windows PowerShell 5.1 o PowerShell 7+ | Ejecución de scripts de automatización y pruebas |
| **Git** | Git 2.30+ para Windows | Control de versiones y clonación |

---

## 2. Clonación del Repositorio y Selección de Rama

Abra una consola de PowerShell y ejecute:

```powershell
# 1. Clonar el repositorio oficial
git clone https://github.com/joeguillenl/EcomixIA.git "C:\Proyectos\EcoMixIA"
cd "C:\Proyectos\EcoMixIA"

# 2. Conmutar a la rama de cierre e integración
git checkout feat/ecomix-fase-04-cierre-integracion

# 3. Confirmar commit activo
git log -1 --oneline
```

---

## 3. Restauración de Paquetes NuGet y Compilación MSBuild

Restaure las dependencias externas y compile la solución en perfiles `Debug` y `Release`:

```powershell
# 1. Restaurar paquetes NuGet (vía MSBuild o nuget.exe)
& "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" EcomixIA.sln /t:Restore /v:m

# 2. Compilar en configuración Debug
& "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" EcomixIA.sln /p:Configuration=Debug /p:Platform="Any CPU" /v:m

# 3. Compilar en configuración Release
& "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" EcomixIA.sln /p:Configuration=Release /p:Platform="Any CPU" /v:m
```
> [!NOTE]
> Ambas compilaciones deben finalizar con **código de salida 0 (0 errores y 0 advertencias)**. Los binarios se generan en la carpeta `bin\`.

---

## 4. Configuración y Migración de Base de Datos SQL Server

La aplicación utiliza la cadena de conexión estándar `DefaultConnection` apuntando a SQL Server LocalDB.

### 4.1 Creación de la Base de Datos Inicial
Si no existe la base de datos `EcomixIA`, créela ejecutando:

```powershell
sqlcmd -S "(LocalDb)\MSSQLLocalDB" -Q "IF DB_ID('EcomixIA') IS NULL CREATE DATABASE [EcomixIA];"
```

### 4.2 Aplicación de Scripts DDL Secuenciales

Ejecute las migraciones aditivas aprobadas para provisionar el esquema de snapshots y auditoría:

```powershell
# 1. Migración H02: Snapshots históricos de precios y CO2 en MezclaComponentes
sqlcmd -S "(LocalDb)\MSSQLLocalDB" -d EcomixIA -i "Migrations\Scripts\H02_add_snapshots_to_mezclacomponentes.sql"

# 2. Migración H04: Tabla de auditoría, índices y columna IsEnabled
sqlcmd -S "(LocalDb)\MSSQLLocalDB" -d EcomixIA -i "Migrations\Scripts\H04_add_audit_and_user_enabled.sql"
```

---

## 5. Provisión Manual del Primer Administrador (Directiva D-10)

Para garantizar la seguridad del sistema, los scripts de migración **no crean cuentas administradoras predeterminadas**. Utilice la rutina de provisión asistida:

```powershell
# 1. Registrar una cuenta inicial vía interfaz web o verificar una cuenta existente
# 2. Ejecutar el script independiente de provisión
powershell -ExecutionPolicy Bypass -File "tools\Provision-Administrator.ps1" -TargetEmail "joamedina@upt.pe"
```

El script verificará:
- Que el usuario exista en `dbo.AspNetUsers`.
- Que su correo esté confirmado (`EmailConfirmed = 1`).
- Que su cuenta esté habilitada (`IsEnabled = 1`).
- Asignará el rol `Administrador` y actualizará el `SecurityStamp` registrando la evidencia en `dbo.AuditEvents`.

---

## 6. Configuración de Secretos y Conectividad ML

La integración con el microservicio ML en Azure Container Apps se parametriza en `Web.config`:

```xml
<appSettings>
  <!-- URL base del servicio de inferencia FastAPI -->
  <add key="EcoMix:ApiUrl" value="https://ca-ecomix-inference-api.salmontree-d9db53a4.chilecentral.azurecontainerapps.io" />
  
  <!-- Timeout en segundos para arranque en frío -->
  <add key="EcoMix:TimeoutSeconds" value="45" />
  
  <!-- Clave de API leída desde Web.Secrets.config o variable de entorno -->
  <add key="EcoMix:ApiKey" value="DUMMY_KEY_LOCAL" />
</appSettings>
```

Para entornos de desarrollo local o producción, configure la variable de entorno del sistema o cree un archivo `Web.Secrets.config` (ignorado por Git):

```powershell
# Configuración mediante variable de entorno del sistema
[Environment]::SetEnvironmentVariable("ECOMIX_API_KEY", "TU_CLAVE_SECRETA_AZURE", "Machine")
```

---

## 7. Ejecución de la Suite Automatizada de Pruebas

Antes de iniciar el servidor, verifique la integridad técnica de la instalación ejecutando la suite modular:

```powershell
powershell -ExecutionPolicy Bypass -File "tests\Run_All_Tests.ps1"
```

Verifique que las 6 suites reporten:
```
================================================================================
  RESUMEN EJECUTIVO CONSOLIDADO DE PRUEBAS H05
================================================================================
  [PASS] Suite 01: Unit & Domain             |  23 PASS |  0 FAIL
  [PASS] Suite 02: Integration EF6 & SQL     |   9 PASS |  0 FAIL
  [PASS] Suite 03: HTTP & Authorization      |   8 PASS |  0 FAIL
  [PASS] Suite 04: FastAPI Contract Mocks    |  10 PASS |  0 FAIL
  [PASS] Suite 05: Security & Concurrency    |   9 PASS |  0 FAIL
  [PASS] Suite 06: Full Regression H01-H04   |   7 PASS |  0 FAIL
--------------------------------------------------------------------------------
  TOTAL: 66 PASS / 0 FAIL (100% Satisfactorio)
================================================================================
```

---

## 8. Arranque de la Aplicación en IIS Express

Inicie el servidor web de desarrollo en el puerto seguro preconfigurado:

```powershell
& "C:\Program Files\IIS Express\iisexpress.exe" /path:"C:\Proyectos\EcoMixIA" /port:44357
```

Abra su navegador y acceda a:  
👉 **`https://localhost:44357/`**

La instalación se encuentra completada y lista para su uso o demostración formal.
