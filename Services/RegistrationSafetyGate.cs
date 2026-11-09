using System;
using System.Configuration;
using System.Data.SqlClient;
using EcomixIA.Models;

namespace EcomixIA.Services
{
    public interface IRegistrationSafetyGate
    {
        bool IsRegistrationAllowed(ApplicationDbContext dbContext, out string denialReason);
    }

    public class RegistrationSafetyGate : IRegistrationSafetyGate
    {
        public const string SettingKey = "EcoMix:EnableRegistrationTesting";
        public const string AllowLocalMainDbKey = "EcoMix:AllowLocalMainDbRegistration";
        public const string MainDatabaseName = "EcomixIA";
        public const string AuthorizedTestDatabaseName = "EcomixIA_F2_Migration_Test";

        public bool IsRegistrationAllowed(ApplicationDbContext dbContext, out string denialReason)
        {
            // 1. Condición de activación explícita: Debe estar encendida en la configuración del servidor
            string enabledSetting = ConfigurationManager.AppSettings[SettingKey];
            if (!string.Equals(enabledSetting, "true", StringComparison.OrdinalIgnoreCase))
            {
                denialReason = "El registro de cuentas está deshabilitado en este entorno. Por motivos de seguridad perimetral, la creación de usuarios solo se activa en entornos de desarrollo autorizados.";
                return false;
            }

            // 2. Verificación de la Base de Datos SQL Real de destino
            if (dbContext == null || dbContext.Database == null || dbContext.Database.Connection == null)
            {
                denialReason = "Error de seguridad: No se pudo verificar la conexión a la base de datos de destino.";
                return false;
            }

            string connStr = dbContext.Database.Connection.ConnectionString;
            if (string.IsNullOrWhiteSpace(connStr))
            {
                denialReason = "Error de seguridad: Cadena de conexión vacía o no disponible.";
                return false;
            }

            string initialCatalog = string.Empty;
            string dataSource = string.Empty;
            try
            {
                var builder = new SqlConnectionStringBuilder(connStr);
                initialCatalog = builder.InitialCatalog;
                dataSource = builder.DataSource;
            }
            catch (Exception ex)
            {
                denialReason = $"Error al analizar la cadena de conexión: {ex.Message}";
                return false;
            }

            // 3. Verificación de servidor local de desarrollo (Prohibición estricta de servidores remotos/nube)
            bool isLocalServer = string.IsNullOrWhiteSpace(dataSource) ||
                                 dataSource.StartsWith("(localdb)", StringComparison.OrdinalIgnoreCase) ||
                                 dataSource.StartsWith(".\\", StringComparison.OrdinalIgnoreCase) ||
                                 dataSource.Equals("localhost", StringComparison.OrdinalIgnoreCase) ||
                                 dataSource.Equals("127.0.0.1", StringComparison.OrdinalIgnoreCase) ||
                                 dataSource.Equals("(local)", StringComparison.OrdinalIgnoreCase);

            if (!isLocalServer)
            {
                denialReason = "Bloqueo de Seguridad Safety Gate: El registro está terminantemente prohibido contra servidores de bases de datos remotos o en la nube.";
                return false;
            }

            // 4. Tratamiento para la base principal 'EcomixIA'
            if (string.Equals(initialCatalog, MainDatabaseName, StringComparison.OrdinalIgnoreCase))
            {
                string allowMainDb = ConfigurationManager.AppSettings[AllowLocalMainDbKey];
                if (!string.Equals(allowMainDb, "true", StringComparison.OrdinalIgnoreCase))
                {
                    denialReason = "Bloqueo de Seguridad Safety Gate: El registro sobre la base local principal 'EcomixIA' requiere autorización explícita mediante la directiva '" + AllowLocalMainDbKey + "'.";
                    return false;
                }

                denialReason = null;
                return true;
            }

            // 5. Tratamiento para la base secundaria de ensayo autorizada o bases que terminen en _Test
            bool isAuthorizedTestDb = string.Equals(initialCatalog, AuthorizedTestDatabaseName, StringComparison.OrdinalIgnoreCase) ||
                                      initialCatalog.EndsWith("_Test", StringComparison.OrdinalIgnoreCase);

            if (!isAuthorizedTestDb)
            {
                denialReason = $"Bloqueo de Seguridad: La base de datos '{initialCatalog}' no está autorizada para registro de cuentas.";
                return false;
            }

            denialReason = null;
            return true;
        }
    }
}
