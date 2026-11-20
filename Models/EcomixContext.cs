using System.Data.Entity;

namespace EcomixIA.Models
{
    public class EcomixContext : DbContext
    {
        public EcomixContext() : base("DefaultConnection")
        {
            Database.SetInitializer<EcomixContext>(null);
        }

        public EcomixContext(string nameOrConnectionString) : base(nameOrConnectionString)
        {
            Database.SetInitializer<EcomixContext>(null);
        }

        public DbSet<Material> Materiales { get; set; }
        public DbSet<Mezcla> Mezclas { get; set; }
        public DbSet<MezclaComponente> Componentes { get; set; }

        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Mapeo explícito de precisión (18,6) para evitar truncamiento por defecto de EF6 a (18,2) (D-09)
            modelBuilder.Entity<MezclaComponente>()
                .Property(c => c.CostoPorKgGuardado)
                .HasPrecision(18, 6);

            modelBuilder.Entity<MezclaComponente>()
                .Property(c => c.Co2PorKgGuardado)
                .HasPrecision(18, 6);

            modelBuilder.Entity<MezclaComponente>()
                .Property(c => c.OrigenSnapshot)
                .HasMaxLength(24);
        }
    }
}
