using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace PetstoreAppService.Controllers;

[Route("api/v3/pets")]
[ApiController]
public class PetsController : ControllerBase
{
    // -------------------------------------------------------------------------
    // In-Memory Relational Tables
    // -------------------------------------------------------------------------

    // Table: Categories
    private static readonly List<Category> Categories = new()
    {
        new Category { Id = 1, Name = "Dogs" },
        new Category { Id = 2, Name = "Cats" },
        new Category { Id = 3, Name = "Birds" }
    };

    // Table: Tags
    private static readonly List<Tag> Tags = new()
    {
        new Tag { Id = 1, Name = "vaccinated"  },
        new Tag { Id = 2, Name = "friendly"    },
        new Tag { Id = 3, Name = "trained"     },
        new Tag { Id = 4, Name = "indoor"      }
    };

    // Table: Pets  (FK: CategoryId → Categories.Id)
    private static readonly List<PetRow> PetRows = new()
    {
        new PetRow { Id = 1, Name = "Buddy", CategoryId = 1, Status = "available" },
        new PetRow { Id = 2, Name = "Max",   CategoryId = 1, Status = "pending"   },
        new PetRow { Id = 3, Name = "Bella", CategoryId = 2, Status = "sold"      }
    };

    // Table: PetPhotoUrls  (FK: PetId → Pets.Id)
    private static readonly List<PetPhotoUrl> PetPhotoUrls = new()
    {
        new PetPhotoUrl { PetId = 1, Url = "https://example.com/photos/buddy1.jpg" },
        new PetPhotoUrl { PetId = 1, Url = "https://example.com/photos/buddy2.jpg" },
        new PetPhotoUrl { PetId = 2, Url = "https://example.com/photos/max1.jpg"   },
        new PetPhotoUrl { PetId = 3, Url = "https://example.com/photos/bella1.jpg" }
    };

    // Table: PetTags  (Junction/Bridge table — FK: PetId → Pets.Id, TagId → Tags.Id)
    private static readonly List<PetTag> PetTags = new()
    {
        new PetTag { PetId = 1, TagId = 1 },   // Buddy  → vaccinated
        new PetTag { PetId = 1, TagId = 2 },   // Buddy  → friendly
        new PetTag { PetId = 2, TagId = 3 },   // Max    → trained
        new PetTag { PetId = 3, TagId = 2 },   // Bella  → friendly
        new PetTag { PetId = 3, TagId = 4 }    // Bella  → indoor
    };

    // -------------------------------------------------------------------------
    // GET /api/v3/pet/{petId}
    // Joins PetRows → Categories, PetPhotoUrls, PetTags → Tags
    // -------------------------------------------------------------------------
    [HttpGet("{petId}")]
    public IActionResult GetPetById(int petId)
    {
        var petRow = PetRows.FirstOrDefault(p => p.Id == petId);
        if (petRow == null)
            return NotFound(new { code = 404, message = $"Pet with ID {petId} not found." });

        // JOIN: Pets → Categories
        var category = Categories.FirstOrDefault(c => c.Id == petRow.CategoryId);

        // JOIN: Pets → PetPhotoUrls
        var photoUrls = PetPhotoUrls
            .Where(p => p.PetId == petId)
            .Select(p => p.Url)
            .ToList();

        // JOIN: Pets → PetTags → Tags
        var tags = PetTags
            .Where(pt => pt.PetId == petId)
            .Join(Tags,
                  pt => pt.TagId,
                  tag => tag.Id,
                  (pt, tag) => new { tag.Id, tag.Name })
            .ToList<object>();

        var result = new
        {
            petRow.Id,
            petRow.Name,
            Category = category is null ? null : new { category.Id, category.Name },
            PhotoUrls = photoUrls,
            Tags = tags,
            petRow.Status
        };

        return Ok(result);
    }

    // GET /api/v3/pet
    [HttpGet]
    public IActionResult GetAllPets() => Ok(PetRows);
}

// -------------------------------------------------------------------------
// Row / Entity Models (mirror the relational table columns)
// -------------------------------------------------------------------------

public record Category
{
    public int Id { get; init; }
    public string Name { get; init; } = string.Empty;
}

public record Tag
{
    public int Id { get; init; }
    public string Name { get; init; } = string.Empty;
}

public record PetRow
{
    public int Id { get; init; }
    public string Name { get; init; } = string.Empty;
    public int CategoryId { get; init; }   // FK → Categories.Id
    public string Status { get; init; } = string.Empty;
}

public record PetPhotoUrl
{
    public int PetId { get; init; }         // FK → Pets.Id
    public string Url { get; init; } = string.Empty;
}

public record PetTag
{
    public int PetId { get; init; }            // FK → Pets.Id
    public int TagId { get; init; }            // FK → Tags.Id
}
