using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;

namespace EcomixIA.Services
{
    /// <summary>
    /// Limitador de solicitudes en memoria con comprobación y asignación atómica de intentos (Sliding Window).
    /// NOTA ARQUITECTÓNICA (D-03 / H04-A):
    /// Esta implementación reside en memoria de proceso (In-Memory). En un despliegue multi-instancia
    /// (ej. Azure App Service con autoescalado o múltiples contenedores en Azure Container Apps),
    /// debe sustituirse por un adaptador distribuido respaldado en Redis Cache o SQL Server
    /// implementando la misma interfaz IRequestRateLimiter para compartir contadores entre nodos.
    /// </summary>
    public class RequestRateLimiter : IRequestRateLimiter
    {
        private static readonly ConcurrentDictionary<string, List<DateTime>> _attempts =
            new ConcurrentDictionary<string, List<DateTime>>(StringComparer.OrdinalIgnoreCase);

        private static DateTime _lastPruneUtc = DateTime.UtcNow;
        private static readonly object _pruneLock = new object();

        public bool TryAcquire(string key, int maxRequests, TimeSpan window, out TimeSpan retryAfter)
        {
            if (string.IsNullOrWhiteSpace(key))
            {
                retryAfter = TimeSpan.Zero;
                return true;
            }

            MaybePruneOpportunistic();

            var now = DateTime.UtcNow;
            var cutoff = now - window;

            var list = _attempts.GetOrAdd(key, _ => new List<DateTime>());
            lock (list)
            {
                list.RemoveAll(t => t < cutoff);
                if (list.Count >= maxRequests)
                {
                    var oldestInWindow = list[0];
                    retryAfter = (oldestInWindow + window) - now;
                    if (retryAfter < TimeSpan.Zero)
                    {
                        retryAfter = TimeSpan.FromSeconds(1);
                    }
                    return false;
                }

                // Registro atómico del intento dentro de la ventana
                list.Add(now);
                retryAfter = TimeSpan.Zero;
                return true;
            }
        }

        public bool IsAllowed(string key, int maxRequests, TimeSpan window, out TimeSpan retryAfter)
        {
            if (string.IsNullOrWhiteSpace(key))
            {
                retryAfter = TimeSpan.Zero;
                return true;
            }

            var now = DateTime.UtcNow;
            var cutoff = now - window;

            if (!_attempts.TryGetValue(key, out var list))
            {
                retryAfter = TimeSpan.Zero;
                return true;
            }

            lock (list)
            {
                list.RemoveAll(t => t < cutoff);
                if (list.Count >= maxRequests)
                {
                    var oldestInWindow = list[0];
                    retryAfter = (oldestInWindow + window) - now;
                    if (retryAfter < TimeSpan.Zero)
                    {
                        retryAfter = TimeSpan.FromSeconds(1);
                    }
                    return false;
                }

                retryAfter = TimeSpan.Zero;
                return true;
            }
        }

        public void RecordAttempt(string key, TimeSpan window)
        {
            if (string.IsNullOrWhiteSpace(key)) return;

            var now = DateTime.UtcNow;
            var cutoff = now - window;

            var list = _attempts.GetOrAdd(key, _ => new List<DateTime>());
            lock (list)
            {
                list.RemoveAll(t => t < cutoff);
                list.Add(now);
            }
        }

        public void Reset(string key)
        {
            if (string.IsNullOrWhiteSpace(key)) return;
            _attempts.TryRemove(key, out _);
        }

        public void PruneExpired()
        {
            var now = DateTime.UtcNow;
            var keysToRemove = new List<string>();

            foreach (var kvp in _attempts)
            {
                lock (kvp.Value)
                {
                    // Remover elementos con más de 1 hora de antigüedad
                    kvp.Value.RemoveAll(t => (now - t).TotalMinutes > 60);
                    if (kvp.Value.Count == 0)
                    {
                        keysToRemove.Add(kvp.Key);
                    }
                }
            }

            foreach (var k in keysToRemove)
            {
                _attempts.TryRemove(k, out _);
            }
        }

        private void MaybePruneOpportunistic()
        {
            if ((DateTime.UtcNow - _lastPruneUtc).TotalMinutes > 10 || _attempts.Count > 300)
            {
                lock (_pruneLock)
                {
                    if ((DateTime.UtcNow - _lastPruneUtc).TotalMinutes > 10 || _attempts.Count > 300)
                    {
                        PruneExpired();
                        _lastPruneUtc = DateTime.UtcNow;
                    }
                }
            }
        }
    }
}
