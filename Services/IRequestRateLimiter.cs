using System;

namespace EcomixIA.Services
{
    public interface IRequestRateLimiter
    {
        /// <summary>
        /// Comprueba atómicamente si la solicitud está dentro del límite y, si es así, registra el intento de inmediato.
        /// </summary>
        bool TryAcquire(string key, int maxRequests, TimeSpan window, out TimeSpan retryAfter);

        /// <summary>
        /// Comprobación de solo lectura del estado del limitador.
        /// </summary>
        bool IsAllowed(string key, int maxRequests, TimeSpan window, out TimeSpan retryAfter);

        /// <summary>
        /// Registra manualmente un intento.
        /// </summary>
        void RecordAttempt(string key, TimeSpan window);

        /// <summary>
        /// Restablece el contador para una clave específica.
        /// </summary>
        void Reset(string key);

        /// <summary>
        /// Limpia claves expiradas para prevenir el crecimiento desmedido de memoria.
        /// </summary>
        void PruneExpired();
    }
}
