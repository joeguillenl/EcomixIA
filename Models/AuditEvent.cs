using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace EcomixIA.Models
{
    [Table("AuditEvents")]
    public class AuditEvent
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public long Id { get; set; }

        [StringLength(128)]
        public string UserId { get; set; }

        [StringLength(256)]
        public string ActorEmail { get; set; }

        [Required]
        [StringLength(64)]
        public string Category { get; set; }

        [Required]
        [StringLength(64)]
        public string Action { get; set; }

        public bool Success { get; set; }

        public string Details { get; set; }

        [StringLength(45)]
        public string IpAddress { get; set; }

        [StringLength(64)]
        public string CorrelationId { get; set; }

        [Required]
        public DateTime TimestampUtc { get; set; }
    }
}
