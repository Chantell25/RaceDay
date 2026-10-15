# RaceDay — Part 2: RESTful API Development.

**Module:** PROG6212 Programming 2B
**Continuation of:** RaceDay Part 1 (ERD, endpoint plan and `RaceDayDB.sql`)  
**Technology:** C#, ASP.NET Core Web API, Entity Framework Core 8, SQL Server, Swagger, xUnit, GitHub Actions.

## Important schema continuity
This project maps to the seven Part 1 SQL Server tables: `UserAccount`, `OrganiserProfile`, `ParticipantProfile`, `Event`, `Category`, `Enrollment`, and `Result`. The API uses those existing names and keys; it does not introduce a separate `AppUser`/`EventCategory` database model. Use the exact Part 1 SQL script at `docs/RaceDayDB.sql`.

## Open and run correctly in Visual Studio (important)

Open **`RaceDay.sln`** from the extracted folder. In Solution Explorer, right-click **`RaceDay.Api` → Set as Startup Project** (it should become bold), then press **F5** or the green Run button. Swagger should open at `https://localhost:7157/swagger`. If it does not, enter that URL in your browser.

You do not run each `.cs` class separately: controllers, models, DTOs and services are parts of the API and are called by the application when needed. **RaceDay.Api is the runnable application; RaceDay.Tests is run through Test Explorer or `RUN-TESTS.bat`.** You can use `RUN-RACEDAY.bat` to restore, build and start the API from Windows. See `VISUAL-STUDIO-START-HERE.txt` for simple steps.

## What is included
- Account registration for Organiser or Participant roles.
- Cookie-based login, current-user endpoint, logout, and profile operations.
- PBKDF2 password hashing; plaintext passwords are never stored.
- Public event browsing and event detail/category listing.
- Organiser-only event and category management with ownership checks.
- Participant-only enrolment, personal enrolment list, and cancellation.
- Organiser-only event enrolment list and result create/update/delete.
- Participant-only personal result history.
- Swagger/OpenAPI in Development.
- Unit tests for password hashing and verification.
- GitHub Actions workflow for build and tests.

## Prerequisites
- .NET 8 SDK
- SQL Server / SQL Server Express / LocalDB
- Visual Studio 2022 or another .NET IDE
- Git and a GitHub repository

## Database setup
1. Open `docs/RaceDayDB.sql` in SQL Server Management Studio.
2. Run the Part 1 script against your development SQL Server. **Warning:** the Part 1 script drops and recreates the seven tables; back up any data first.
3. Update `RaceDay.Api/appsettings.json` connection string to your SQL Server instance.
4. Do not use the Part 1 sample `DEMO_HASH_*` values to log in. They are illustrative seed values, not usable password hashes. Register real accounts through the API.

## Run locally
From the repository root:

```bash
dotnet restore RaceDay.Api/RaceDay.Api.csproj
dotnet build RaceDay.Api/RaceDay.Api.csproj
dotnet test RaceDay.Tests/RaceDay.Tests.csproj
dotnet run --project RaceDay.Api/RaceDay.Api.csproj
```

Open the HTTPS URL printed by `dotnet run`, then add `/swagger`.

The cookie is marked Secure, so use the HTTPS launch URL. In production, protect cookie-authenticated state-changing requests with anti-forgery controls and configure HTTPS, secrets, logging and deployment settings appropriately.

## Endpoint overview
| Method | Route | Access | Purpose |
|---|---|---|---|
| POST | `/api/auth/register` | Public | Register either role |
| POST | `/api/auth/login` | Public | Authenticate and issue session cookie |
| GET | `/api/auth/me` | Authenticated | Current account details |
| POST | `/api/auth/logout` | Authenticated | End session |
| GET / PUT | `/api/profile` | Authenticated | View/update basic profile |
| GET | `/api/events` | Public | Browse/filter events |
| GET | `/api/events/{id}` | Public | Event details and categories |
| POST / PUT / DELETE | `/api/events` and `/api/events/{id}` | Organiser | Event CRUD with ownership validation |
| GET / POST | `/api/events/{eventId}/categories` | Public GET / Organiser POST | View/add categories |
| PUT / DELETE | `/api/categories/{id}` | Organiser | Update/delete own event category |
| POST | `/api/enrolments/{eventId}` | Participant | Enrol in a category |
| GET | `/api/enrolments/mine` | Participant | Own enrolments |
| DELETE | `/api/enrolments/{id}` | Participant | Cancel own enrolment |
| GET | `/api/events/{eventId}/enrolments` | Organiser | View enrolments for own event |
| POST | `/api/events/{eventId}/results/{enrollmentId}` | Organiser | Record result for own event |
| PUT / DELETE | `/api/results/{id}` | Organiser | Update/delete result for own event |
| GET | `/api/results/mine` | Participant | Own results |

## Part 1 to Part 2 mapping
- `UserAccount.UserId` is the account identity in the authenticated claims.
- The matching `OrganiserProfile` or `ParticipantProfile` is created at registration.
- `RaceEvent.OrganiserId` is resolved from the signed-in organiser; clients cannot choose another organiser ID.
- `Enrollment` references a participant, event and category. The API verifies that the category belongs to the selected event.
- `Result.EnrollmentId` is unique, matching the one-result-per-enrolment design.

## Testing and evidence still required from the student
- Run the SQL script in your own SQL Server environment.
- Run `dotnet build` and `dotnet test`; confirm all tests pass in your environment.
- Test both roles in Swagger and capture evidence of forbidden cross-role requests.
- Push to your own lecturer-provided GitHub repository with at least 20 meaningful commits. Do not fabricate commits.
- Confirm GitHub Actions produces a green build and add a real screenshot to this README.
- Record and upload your own-voice demonstration video; add its unlisted link here.
- Complete the student name and student number fields required by your submission portal.

## Final pre-submission verification checklist

- [ ] Compare `docs/RaceDayDB.sql` and `docs/RaceDay_ERD.png` with the approved Part 1 submission before running the script.
- [ ] Back up any existing `RaceDayDB` before executing the SQL file because it drops/recreates tables.
- [ ] Verify SQL Server contains exactly the seven core tables: `UserAccount`, `OrganiserProfile`, `ParticipantProfile`, `Event`, `Category`, `Enrollment`, `Result`.
- [ ] Confirm `Enrollment(EventId, CategoryId)` references `Category(EventId, CategoryId)` and `Result.EnrollmentId` is unique.
- [ ] Verify the connection string matches the SQL Server instance on the machine running the API.
- [ ] Run `dotnet restore`, `dotnet build`, and `dotnet test`; record the actual results (do not claim success unless commands pass).
- [ ] In Swagger, test public access, valid login, invalid login, inactive-account rejection, organiser-only operations, participant-only operations, ownership checks, capacity checks and duplicate enrolment/result conflicts.
- [ ] Test the organiser dashboard routes: `GET /api/organiser/events` and `GET /api/organiser/events/{id}/summary`.
- [ ] Push to your own GitHub repository, make at least 20 meaningful commits, and confirm the Actions workflow passes on GitHub.
- [ ] Add a genuine screenshot of the green workflow and your unlisted demonstration video link to this README before submission.

**Important:** This archive is a project starter/continuation, not a guarantee of a particular mark. The .NET SDK and SQL Server environment must be available to compile, execute and verify it. Your lecturer's rubric and approved Part 1 artefacts remain the final authority.
