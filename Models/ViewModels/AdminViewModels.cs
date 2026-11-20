using System;
using System.Collections.Generic;
using EcomixIA.Services;

namespace EcomixIA.Models.ViewModels
{
    public class AdminUserItemViewModel
    {
        public string UserId { get; set; }
        public string Email { get; set; }
        public string UserName { get; set; }
        public List<string> Roles { get; set; } = new List<string>();
        public bool IsEnabled { get; set; }
        public bool EmailConfirmed { get; set; }
        public bool IsLockedOut { get; set; }
        public int AccessFailedCount { get; set; }
        public bool IsAdministrator => Roles.Contains("Administrador");
    }

    public class AdminUsersListViewModel
    {
        public List<AdminUserItemViewModel> Users { get; set; } = new List<AdminUserItemViewModel>();
        public string SearchEmail { get; set; }
        public int CurrentPage { get; set; } = 1;
        public int TotalPages { get; set; } = 1;
        public int TotalUsers { get; set; }
        public int PageSize { get; set; } = 10;
        public string CurrentUserId { get; set; }
    }

    public class AdminAuditListViewModel
    {
        public List<AuditEvent> Events { get; set; } = new List<AuditEvent>();
        public string Category { get; set; }
        public bool? SuccessFilter { get; set; }
        public string SearchTerm { get; set; }
        public DateTime? StartDateUtc { get; set; }
        public DateTime? EndDateUtc { get; set; }
        public DateTime RetentionCutoffUtc { get; set; }
        public int CurrentPage { get; set; } = 1;
        public int TotalPages { get; set; } = 1;
        public int TotalEvents { get; set; }
        public int PageSize { get; set; } = 20;
    }

    public class AdminDashboardViewModel
    {
        public AdminDashboardStatsDto Stats { get; set; }
        public List<AuditEvent> RecentAdminEvents { get; set; } = new List<AuditEvent>();
    }
}
