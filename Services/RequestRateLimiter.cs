using System;
using System.Collections.Concurrent;
using System.Collections.Generic;

namespace EcomixIA.Services
{
    public class RequestRateLimiter : IRequestRateLimiter
    {
        private static readonly ConcurrentDictionary<string, List<DateTime>> _attempts =
            new ConcurrentDictionary<string, List<DateTime>>(StringComparer.OrdinalIgnoreCase);

        public bool IsAllowed(string key, int maxRequests, TimeSpan window, out TimeSpan retryAfter)
        {
            if (string.IsNullOrWhiteSpace(key))
            {
                retryAfter = TimeSpan.Zero;
                return true;
            }

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
    }
}
