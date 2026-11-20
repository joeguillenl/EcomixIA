using System;

namespace EcomixIA.Services
{
    public interface IRequestRateLimiter
    {
        bool IsAllowed(string key, int maxRequests, TimeSpan window, out TimeSpan retryAfter);
        void RecordAttempt(string key, TimeSpan window);
        void Reset(string key);
    }
}
