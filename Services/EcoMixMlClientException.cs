using System;
using EcomixIA.Models.Dtos;

namespace EcomixIA.Services
{
    /// <summary>
    /// Excepción tipada para fallos controlados en la comunicación con el microservicio de inferencia Azure ML.
    /// </summary>
    public class EcoMixMlClientException : Exception
    {
        public int StatusCode { get; }
        public ProblemDetailsDto ProblemDetails { get; }

        public EcoMixMlClientException(string message, int statusCode = 500, ProblemDetailsDto problemDetails = null, Exception inner = null)
            : base(message, inner)
        {
            StatusCode = statusCode;
            ProblemDetails = problemDetails;
        }
    }
}
