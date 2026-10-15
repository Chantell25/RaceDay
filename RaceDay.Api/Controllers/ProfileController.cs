using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RaceDay.Api.Data;
using RaceDay.Api.Dtos;

namespace RaceDay.Api.Controllers;

[ApiController, Authorize, Route("api/profile")]
public class ProfileController(RaceDayDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get()
    {
        int id = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var user = await db.UserAccounts.Include(x => x.OrganiserProfile).Include(x => x.ParticipantProfile)
            .Where(x => x.UserId == id)
            .Select(x => new { x.UserId, x.FirstName, x.LastName, x.Email, x.Role,
                Organiser = x.OrganiserProfile == null ? null : x.OrganiserProfile.OrganisationName,
                ParticipantDateOfBirth = x.ParticipantProfile == null ? null : x.ParticipantProfile.DateOfBirth })
            .SingleOrDefaultAsync();
        return user is null ? NotFound() : Ok(user);
    }

    [HttpPut]
    public async Task<IActionResult> Update(ProfileUpdateRequest request)
    {
        int id = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var user = await db.UserAccounts.FindAsync(id);
        if (user is null) return NotFound();
        user.FirstName = request.FirstName.Trim(); user.LastName = request.LastName.Trim();
        await db.SaveChangesAsync();
        return Ok(new { user.UserId, user.FirstName, user.LastName, user.Email, user.Role });
    }
}
