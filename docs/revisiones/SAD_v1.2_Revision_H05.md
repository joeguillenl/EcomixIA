# Documento de Arquitectura de Software (SAD) — Versión 1.2 (Revisión H05)

**Proyecto:** EcoMix IA — Sistema Inteligente de Dosificación y Simulación de Concreto Ecológico  
**Versión Base:** SAD v1.1 (Octubre 2026)  
**Versión de Revisión:** SAD v1.2 (Noviembre 2026 — Hito H05)  
**Estado:** Aprobado para Entrega y Cierre  
**Autores:** Equipo de Arquitectura de Software y Seguridad  

---

## 1. Resumen de Actualizaciones Arquitectónicas en H05

La revisión 1.2 del SAD documenta las decisiones estructurales y los patrones de resiliencia consolidados en la fase de cierre:

1. **Patrón de Bloqueo Concurrente Híbrido (Proceso + Motor SQL):**  
   Para proteger el estado del último administrador activo ante condiciones de carrera en entornos de escalabilidad horizontal, se implementó una estrategia en dos capas: `SemaphoreSlim(1,1)` a nivel de proceso web y transacciones con aislamiento `Serializable` con bloqueo `WITH (UPDLOCK, HOLDLOCK)` a nivel de SQL Server.
2. **Canal de Revocación Inmediata de Sesiones Inhabilitadas:**  
   Integración combinada entre el filtro de autorización global `AuthorizeUserEnabledFilter` (intercepción síncrona en cada petición HTTP) y la revalidación periódica de `SecurityStamp` en la canalización OWIN Katana (`OnValidateIdentity`).
3. **Arquitectura de Auditoría Segura y Privacidad de Datos:**  
   Persistencia en tabla dedicada `dbo.AuditEvents` con retención temporal indexada de 30 días, sanitización regex en memoria antes de la escritura, y depuración física oportunista no bloqueante.
4. **Desacoplamiento Estricto de Provisión:**  
   Separación de las migraciones de esquema DDL respecto a la rutina manual de provisión administrativa (`tools/Provision-Administrator.ps1`).

---

## 2. Diagrama de Arquitectura de Componentes y Despliegue

Describe la interacción entre las capas de presentación, lógica de negocio, persistencia relacional y el microservicio de inferencia de Machine Learning.

```mermaid
flowchart TD
    subgraph Cliente ["Cliente / Navegador Web"]
        Browser["Navegador Web\n(Bootstrap 5.3.3 / Chart.js)"]
    end

    subgraph AppServer ["Servidor de Aplicación (ASP.NET MVC 5 / .NET 4.7.2)"]
        direction TB
        GlobalFilter["AuthorizeUserEnabledFilter\n(Verificación IsEnabled)"]
        
        subgraph Controllers ["Controladores MVC"]
            HomeCtrl["HomeController\n(Portada / Carrusel)"]
            AccountCtrl["AccountController\n(Auth / Tokens)"]
            MatCtrl["MaterialesController\n(Catálogo D-02)"]
            MezclasCtrl["MezclasController\n(Simulador / CRUD)"]
            DashCtrl["DashboardController\n(KPIs Personales D-04)"]
            AdminCtrl["AdminController\n(Gestión / Auditoría D-10)"]
        end

        subgraph Services ["Capa de Servicios y Seguridad"]
            AuditSvc["AuditService\n(Sanitización / Purga 30d)"]
            RateLimit["RequestRateLimiter\n(Sliding Window)"]
            EmailSvc["ITransactionalEmailSender\n(Simulated / SMTP)"]
            MlClient["EcoMixMlClientService\n(Singleton HttpClient)"]
        end
    end

    subgraph DataTier ["Capa de Datos Relacional (SQL Server LocalDB / Azure SQL)"]
        EF6["Entity Framework 6.5.1 (Code First)"]
        TableUsers["dbo.AspNetUsers\n(Identity 2 / IsEnabled)"]
        TableRoles["dbo.AspNetRoles / UserRoles"]
        TableMat["dbo.Materials"]
        TableMezclas["dbo.Mezclas"]
        TableComp["dbo.MezclaComponentes\n(Snapshots H02 / D-09)"]
        TableAudit["dbo.AuditEvents\n(IX_TimestampUtc / D-07)"]
    end

    subgraph ExternalServices ["Microservicios Externos"]
        FastAPI["Microservicio Inferencia ML (FastAPI)\nAzure Container Apps\n(VotingEnsemble / Pydantic v2)"]
    end

    Browser <--> |"HTTPS / Cookies OWIN / CSRF"| GlobalFilter
    GlobalFilter --> Controllers
    Controllers --> Services
    Services --> EF6
    EF6 --> TableUsers
    EF6 --> TableRoles
    EF6 --> TableMat
    EF6 --> TableMezclas
    EF6 --> TableComp
    EF6 --> TableAudit
    
    MlClient <--> |"HTTPS / X-API-Key / ProblemDetails"| FastAPI
```

---

## 3. Diagrama de Secuencia: Provisión Administrativa y Revocación de Sesión

Muestra la provisión manual segura del rol `Administrador` y la revocación inmediata de privilegios y sesiones activas.

```mermaid
sequenceDiagram
    autonumber
    actor Operador as Operador de Sistemas
    participant Script as Provision-Administrator.ps1
    participant DB as SQL Server (LocalDB / Azure)
    actor Admin as Administrador
    participant AdminCtrl as AdminController
    participant Filter as AuthorizeUserEnabledFilter
    participant OWIN as Pipeline OWIN Katana
    actor Usuario as Usuario Afectado

    Note over Operador, Script: 1. Provisión Administrativa Segura (D-10)
    Operador->>Script: Ejecuta script con -TargetEmail y -Force
    Script->>DB: Valida precondiciones (Existe, EmailConfirmed=1, IsEnabled=1)
    Script->>DB: Asigna RoleId de 'Administrador' en AspNetUserRoles
    Script->>DB: Actualiza SecurityStamp (Guid criptográfico)
    Script->>DB: Registra evento en AuditEvents
    Script-->>Operador: Notifica provisión exitosa con evidencia

    Note over Admin, Usuario: 2. Conmutación de Estado y Revocación Concurrente (H05-A2 / A3)
    Admin->>AdminCtrl: POST /Admin/ToggleUserStatus(userId)
    activate AdminCtrl
    AdminCtrl->>AdminCtrl: Adquiere SemaphoreSlim(1,1)
    AdminCtrl->>DB: BEGIN TRANSACTION (IsolationLevel.Serializable)
    AdminCtrl->>DB: SELECT COUNT(*) WITH (UPDLOCK, HOLDLOCK) de Admins Activos
    alt Es el último administrador activo
        AdminCtrl->>DB: ROLLBACK TRANSACTION
        AdminCtrl->>DB: Registra evento 'BlockDisableLastAdmin'
        AdminCtrl-->>Admin: Muestra alerta de operación bloqueada por seguridad
    else Hay más de un administrador
        AdminCtrl->>DB: UPDATE AspNetUsers SET IsEnabled = 0
        AdminCtrl->>DB: Regenera SecurityStamp
        AdminCtrl->>DB: COMMIT TRANSACTION
        AdminCtrl->>DB: Registra evento 'InhabilitacionUsuario'
        AdminCtrl-->>Admin: Confirma usuario inhabilitado
    end
    AdminCtrl->>AdminCtrl: Libera SemaphoreSlim
    deactivate AdminCtrl

    Note over Usuario, OWIN: 3. Intercepción y Cierre Forzoso de Sesión
    Usuario->>Filter: GET /Mezclas/Index con Cookie de sesión activa
    Filter->>DB: Consulta appUser.IsEnabled mediante UserManager
    alt Usuario.IsEnabled == false
        Filter->>OWIN: SignOut(ApplicationCookie)
        Filter-->>Usuario: HTTP 302 Redirección a /Account/Login?disabled=1
    else Usuario.IsEnabled == true
        Filter-->>Usuario: Continúa ejecución normal de la acción
    end
```

---

## 4. Estrategia de Concurrencia y Bloqueo en Servidor (H05-A2)

Para garantizar la invarianza normativa del **último administrador activo (D-10)**, `AdminController` implementa el siguiente protocolo transaccional:

```csharp
private static readonly SemaphoreSlim _adminConcurrencyLock = new SemaphoreSlim(1, 1);

// En ToggleUserStatus y ChangeUserRole:
await _adminConcurrencyLock.WaitAsync();
try
{
    using (var tx = DbContext.Database.BeginTransaction(IsolationLevel.Serializable))
    {
        int activeAdmins = await CountActiveAdministratorsLockedAsync();
        if (activeAdmins <= 1)
        {
            // Bloqueo y auditoría de seguridad
            tx.Rollback();
            return RedirectToAction("Users");
        }

        // Mutación y regeneración de SecurityStamp
        var result = await UserManager.UpdateAsync(user);
        if (!result.Succeeded) { tx.Rollback(); return Error(); }

        await UserManager.UpdateSecurityStampAsync(user.Id);
        tx.Commit();
    }
}
finally
{
    _adminConcurrencyLock.Release();
}
```

La consulta bloqueante utiliza la sintaxis:
```sql
SELECT COUNT(*) 
FROM dbo.AspNetUsers u WITH (UPDLOCK, HOLDLOCK)
INNER JOIN dbo.AspNetUserRoles ur WITH (UPDLOCK, HOLDLOCK) ON u.Id = ur.UserId
WHERE ur.RoleId = @AdminRoleId AND u.IsEnabled = 1;
```
Esto garantiza que ninguna otra transacción concurrentemente pueda evaluar o mutar roles de administrador en paralelo, eliminando condiciones de carrera tanto en una sola instancia como en entornos multi-nodo.

---

## 5. Diseño del Subsistema de Auditoría y Retención (D-07 / H05-A5)

1. **Sanitización Pre-Persistencia:**  
   `AuditService.SanitizeDetails` aplica un pipeline de expresiones regulares que reemplaza credenciales (`Password`, `Token`, `ApiKey`, `Secret`, `Bearer`), cadenas de conexión completas, rutas de disco (`[RUTA_PROTEGIDA]`) y trazas internas (`[STACK_PROTEGIDO]`).
2. **Índice de Retención Optimizado:**  
   ```sql
   CREATE NONCLUSTERED INDEX [IX_AuditEvents_TimestampUtc]
   ON [dbo].[AuditEvents] ([TimestampUtc] DESC)
   INCLUDE ([Category], [Action], [Success], [CorrelationId]);
   ```
3. **Depuración Oportunista y Manual:**  
   Las consultas administrativas (`GetActiveEvents`) activan de forma no bloqueante una purga por lotes (`DELETE TOP (500) WHERE TimestampUtc < @cutoff`) con acelerador de frecuencia (máximo 1 ejecución por hora), asegurando que el volumen de la tabla se mantenga controlado sin requerir tareas programadas en la nube.
