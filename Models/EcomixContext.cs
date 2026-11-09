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
    }
}
