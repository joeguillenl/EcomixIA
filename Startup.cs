using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(EcomixIA.Startup))]
namespace EcomixIA
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            ConfigureAuth(app);
        }
    }
}
