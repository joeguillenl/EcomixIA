using System.Data.Entity.Migrations;
using EcomixIA.Models;

namespace EcomixIA.Migrations.Identity
{
    internal sealed class Configuration : DbMigrationsConfiguration<ApplicationDbContext>
    {
        public Configuration()
        {
            AutomaticMigrationsEnabled = false;
            AutomaticMigrationDataLossAllowed = false;
            ContextKey = "EcomixIA.Models.ApplicationDbContext";
            MigrationsDirectory = @"Migrations\Identity";
        }

        protected override void Seed(ApplicationDbContext context)
        {
            // En F2.1 NO se generan datos semilla ni usuarios ni roles.
        }
    }
}
