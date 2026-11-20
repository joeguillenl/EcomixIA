using System.Data.Entity;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNet.Identity;
using Microsoft.AspNet.Identity.EntityFramework;

namespace EcomixIA.Models
{
    public class ApplicationUser : IdentityUser
    {
        public bool IsEnabled { get; set; } = true;

        public async Task<ClaimsIdentity> GenerateUserIdentityAsync(UserManager<ApplicationUser> manager)
        {
            // Tenga en cuenta que el valor de authenticationType debe coincidir con el definido en CookieAuthenticationOptions.AuthenticationType
            var userIdentity = await manager.CreateIdentityAsync(this, DefaultAuthenticationTypes.ApplicationCookie);
            return userIdentity;
        }
    }

    public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
    {
        public ApplicationDbContext()
            : base("DefaultConnection", throwIfV1Schema: false)
        {
            Database.SetInitializer<ApplicationDbContext>(null);
        }

        public ApplicationDbContext(string nameOrConnectionString)
            : base(nameOrConnectionString, throwIfV1Schema: false)
        {
            Database.SetInitializer<ApplicationDbContext>(null);
        }

        public virtual DbSet<AuditEvent> AuditEvents { get; set; }

        public static ApplicationDbContext Create()
        {
            return new ApplicationDbContext();
        }

        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<ApplicationUser>()
                .Property(u => u.IsEnabled)
                .IsRequired();

            modelBuilder.Entity<AuditEvent>()
                .ToTable("AuditEvents");

            modelBuilder.Entity<AuditEvent>()
                .Property(a => a.Category)
                .IsRequired()
                .HasMaxLength(64);

            modelBuilder.Entity<AuditEvent>()
                .Property(a => a.Action)
                .IsRequired()
                .HasMaxLength(64);
        }
    }
}
