using System;
using System.Collections.Generic;
using System.Net.Mail;
using System.Text.RegularExpressions;

namespace EcomixIA.Services
{
    public interface IEmailDomainValidator
    {
        bool IsDomainAllowed(string email);
        string ExtractCanonicalDomain(string email);
        bool IsSyntacticallyValid(string email);
        string NormalizeEmail(string email);
    }

    public class EmailDomainValidator : IEmailDomainValidator
    {
        // Dominios canónicos explícitamente autorizados por SRS v1.2 (RF-04, RF-05)
        private static readonly HashSet<string> AllowedDomains = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "upt.pe",
            "virtual.upt.pe",
            "gmail.com"
        };

        // Regex estricto para sintaxis de correo estándar
        private static readonly Regex EmailSyntaxRegex = new Regex(
            @"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
            RegexOptions.Compiled | RegexOptions.CultureInvariant);

        public bool IsSyntacticallyValid(string email)
        {
            if (string.IsNullOrWhiteSpace(email))
            {
                return false;
            }

            string trimmed = email.Trim();

            if (!EmailSyntaxRegex.IsMatch(trimmed))
            {
                return false;
            }

            try
            {
                var addr = new MailAddress(trimmed);
                return string.Equals(addr.Address, trimmed, StringComparison.OrdinalIgnoreCase);
            }
            catch
            {
                return false;
            }
        }

        public string ExtractCanonicalDomain(string email)
        {
            if (string.IsNullOrWhiteSpace(email))
            {
                return null;
            }

            string trimmed = email.Trim();
            int atIndex = trimmed.LastIndexOf('@');
            if (atIndex <= 0 || atIndex == trimmed.Length - 1)
            {
                return null;
            }

            // Si hay más de un @, es sintaxis inválida
            if (trimmed.IndexOf('@') != atIndex)
            {
                return null;
            }

            return trimmed.Substring(atIndex + 1).ToLowerInvariant();
        }

        public bool IsDomainAllowed(string email)
        {
            if (!IsSyntacticallyValid(email))
            {
                return false;
            }

            string domain = ExtractCanonicalDomain(email);
            if (string.IsNullOrEmpty(domain))
            {
                return false;
            }

            // Comparación estricta de dominio completo (sin coincidencias parciales ni de subdominio no autorizado)
            return AllowedDomains.Contains(domain);
        }

        public string NormalizeEmail(string email)
        {
            if (string.IsNullOrWhiteSpace(email))
            {
                return string.Empty;
            }

            return email.Trim().ToLowerInvariant();
        }
    }
}
