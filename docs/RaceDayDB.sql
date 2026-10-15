/* RaceDay - Part 1 SQL Server Database Script
   Module: PROG6212 Programming 2B
   Purpose: Create and seed the complete RaceDay database planned in the ERD.
*/

IF DB_ID(N'RaceDayDB') IS NULL
BEGIN
    CREATE DATABASE RaceDayDB;
END;
GO

USE RaceDayDB;
GO

/* Make the script safely re-runnable on a development database. */
IF OBJECT_ID(N'dbo.Result', N'U') IS NOT NULL DROP TABLE dbo.Result;
IF OBJECT_ID(N'dbo.Enrollment', N'U') IS NOT NULL DROP TABLE dbo.Enrollment;
IF OBJECT_ID(N'dbo.Category', N'U') IS NOT NULL DROP TABLE dbo.Category;
IF OBJECT_ID(N'dbo.Event', N'U') IS NOT NULL DROP TABLE dbo.Event;
IF OBJECT_ID(N'dbo.ParticipantProfile', N'U') IS NOT NULL DROP TABLE dbo.ParticipantProfile;
IF OBJECT_ID(N'dbo.OrganiserProfile', N'U') IS NOT NULL DROP TABLE dbo.OrganiserProfile;
IF OBJECT_ID(N'dbo.UserAccount', N'U') IS NOT NULL DROP TABLE dbo.UserAccount;
GO

CREATE TABLE dbo.UserAccount
(
    UserId INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_UserAccount PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(150) NOT NULL
        CONSTRAINT UQ_UserAccount_Email UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    Role NVARCHAR(20) NOT NULL
        CONSTRAINT CK_UserAccount_Role CHECK (Role IN (N'Organiser', N'Participant')),
    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_UserAccount_CreatedAt DEFAULT SYSUTCDATETIME(),
    IsActive BIT NOT NULL
        CONSTRAINT DF_UserAccount_IsActive DEFAULT 1
);
GO

CREATE TABLE dbo.OrganiserProfile
(
    OrganiserId INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_OrganiserProfile PRIMARY KEY,
    UserId INT NOT NULL
        CONSTRAINT UQ_OrganiserProfile_UserId UNIQUE,
    OrganisationName NVARCHAR(120) NOT NULL,
    ContactNumber NVARCHAR(30) NOT NULL,
    CONSTRAINT FK_OrganiserProfile_UserAccount
        FOREIGN KEY (UserId) REFERENCES dbo.UserAccount(UserId)
);
GO

CREATE TABLE dbo.ParticipantProfile
(
    ParticipantId INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_ParticipantProfile PRIMARY KEY,
    UserId INT NOT NULL
        CONSTRAINT UQ_ParticipantProfile_UserId UNIQUE,
    DateOfBirth DATE NULL,
    EmergencyContactName NVARCHAR(100) NULL,
    EmergencyContactNumber NVARCHAR(30) NULL,
    CONSTRAINT FK_ParticipantProfile_UserAccount
        FOREIGN KEY (UserId) REFERENCES dbo.UserAccount(UserId)
);
GO

CREATE TABLE dbo.Event
(
    EventId INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Event PRIMARY KEY,
    OrganiserId INT NOT NULL,
    EventName NVARCHAR(150) NOT NULL,
    Description NVARCHAR(500) NULL,
    EventDate DATE NOT NULL,
    Venue NVARCHAR(150) NOT NULL,
    City NVARCHAR(80) NOT NULL,
    Status NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Event_Status DEFAULT N'Planned',
    CONSTRAINT CK_Event_Status CHECK (Status IN (N'Planned', N'Open', N'Closed', N'Completed', N'Cancelled')),
    CONSTRAINT FK_Event_OrganiserProfile
        FOREIGN KEY (OrganiserId) REFERENCES dbo.OrganiserProfile(OrganiserId)
);
GO

CREATE TABLE dbo.Category
(
    CategoryId INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Category PRIMARY KEY,
    EventId INT NOT NULL,
    CategoryName NVARCHAR(100) NOT NULL,
    DistanceKm DECIMAL(6,2) NOT NULL,
    MaxParticipants INT NOT NULL,
    EntryFee DECIMAL(10,2) NOT NULL,
    CONSTRAINT UQ_Category_Event_CategoryName UNIQUE (EventId, CategoryName),
    CONSTRAINT UQ_Category_Event_CategoryId UNIQUE (EventId, CategoryId),
    CONSTRAINT CK_Category_Distance CHECK (DistanceKm > 0),
    CONSTRAINT CK_Category_MaxParticipants CHECK (MaxParticipants > 0),
    CONSTRAINT CK_Category_EntryFee CHECK (EntryFee >= 0),
    CONSTRAINT FK_Category_Event
        FOREIGN KEY (EventId) REFERENCES dbo.Event(EventId)
);
GO

CREATE TABLE dbo.Enrollment
(
    EnrollmentId INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Enrollment PRIMARY KEY,
    EventId INT NOT NULL,
    CategoryId INT NOT NULL,
    ParticipantId INT NOT NULL,
    EnrollmentDate DATETIME2(0) NOT NULL
        CONSTRAINT DF_Enrollment_EnrollmentDate DEFAULT SYSUTCDATETIME(),
    RaceNumber INT NOT NULL,
    Status NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Enrollment_Status DEFAULT N'Confirmed',
    CONSTRAINT UQ_Enrollment_RaceNumber UNIQUE (RaceNumber),
    CONSTRAINT UQ_Enrollment_Participant_Event UNIQUE (ParticipantId, EventId),
    CONSTRAINT CK_Enrollment_Status CHECK (Status IN (N'Pending', N'Confirmed', N'Cancelled', N'Completed')),
    CONSTRAINT FK_Enrollment_ParticipantProfile
        FOREIGN KEY (ParticipantId) REFERENCES dbo.ParticipantProfile(ParticipantId),
    CONSTRAINT FK_Enrollment_CategoryEvent
        FOREIGN KEY (EventId, CategoryId) REFERENCES dbo.Category(EventId, CategoryId)
);
GO

CREATE TABLE dbo.Result
(
    ResultId INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Result PRIMARY KEY,
    EnrollmentId INT NOT NULL
        CONSTRAINT UQ_Result_EnrollmentId UNIQUE,
    FinishTime TIME(0) NULL,
    Position INT NULL,
    ResultStatus NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Result_ResultStatus DEFAULT N'Pending',
    RecordedAt DATETIME2(0) NULL,
    CONSTRAINT CK_Result_Position CHECK (Position IS NULL OR Position > 0),
    CONSTRAINT CK_Result_Status CHECK (ResultStatus IN (N'Pending', N'Finished', N'DNF', N'DNS')),
    CONSTRAINT FK_Result_Enrollment
        FOREIGN KEY (EnrollmentId) REFERENCES dbo.Enrollment(EnrollmentId)
);
GO

/* -----------------------------
   Seed data: Users and profiles
   ----------------------------- */

INSERT INTO dbo.UserAccount
    (FirstName, LastName, Email, PasswordHash, Role)
VALUES
    (N'Lerato', N'Mokoena', N'lerato.organiser@raceday.example', N'DEMO_HASH_ORG_001', N'Organiser'),
    (N'Jason', N'Naidoo', N'jason.organiser@raceday.example', N'DEMO_HASH_ORG_002', N'Organiser'),
    (N'Ayanda', N'Dlamini', N'ayanda.participant@raceday.example', N'DEMO_HASH_PART_001', N'Participant'),
    (N'Kabelo', N'Molefe', N'kabelo.participant@raceday.example', N'DEMO_HASH_PART_002', N'Participant'),
    (N'Naledi', N'Pillay', N'naledi.participant@raceday.example', N'DEMO_HASH_PART_003', N'Participant'),
    (N'Tumi', N'Jacobs', N'tumi.participant@raceday.example', N'DEMO_HASH_PART_004', N'Participant');
GO

INSERT INTO dbo.OrganiserProfile
    (UserId, OrganisationName, ContactNumber)
SELECT UserId, N'RaceDay Gauteng Events', N'011-555-0101'
FROM dbo.UserAccount
WHERE Email = N'lerato.organiser@raceday.example';

INSERT INTO dbo.OrganiserProfile
    (UserId, OrganisationName, ContactNumber)
SELECT UserId, N'Coastal Active SA', N'021-555-0102'
FROM dbo.UserAccount
WHERE Email = N'jason.organiser@raceday.example';
GO

INSERT INTO dbo.ParticipantProfile
    (UserId, DateOfBirth, EmergencyContactName, EmergencyContactNumber)
SELECT UserId, '1999-04-15', N'Mpho Dlamini', N'082-555-1001'
FROM dbo.UserAccount
WHERE Email = N'ayanda.participant@raceday.example';

INSERT INTO dbo.ParticipantProfile
    (UserId, DateOfBirth, EmergencyContactName, EmergencyContactNumber)
SELECT UserId, '1997-09-22', N'Palesa Molefe', N'083-555-1002'
FROM dbo.UserAccount
WHERE Email = N'kabelo.participant@raceday.example';

INSERT INTO dbo.ParticipantProfile
    (UserId, DateOfBirth, EmergencyContactName, EmergencyContactNumber)
SELECT UserId, '2001-02-11', N'Sipho Pillay', N'084-555-1003'
FROM dbo.UserAccount
WHERE Email = N'naledi.participant@raceday.example';

INSERT INTO dbo.ParticipantProfile
    (UserId, DateOfBirth, EmergencyContactName, EmergencyContactNumber)
SELECT UserId, '1995-11-03', N'Refilwe Jacobs', N'085-555-1004'
FROM dbo.UserAccount
WHERE Email = N'tumi.participant@raceday.example';
GO

/* -----------------------------
   Seed data: three events
   ----------------------------- */

INSERT INTO dbo.Event
    (OrganiserId, EventName, Description, EventDate, Venue, City, Status)
SELECT OrganiserId,
       N'Johannesburg Spring Run',
       N'Road-running event with multiple distance categories.',
       '2026-09-20',
       N'Zoo Lake Sports Grounds',
       N'Johannesburg',
       N'Open'
FROM dbo.OrganiserProfile
WHERE OrganisationName = N'RaceDay Gauteng Events';

INSERT INTO dbo.Event
    (OrganiserId, EventName, Description, EventDate, Venue, City, Status)
SELECT OrganiserId,
       N'Cape Town Cycle Challenge',
       N'Community cycling event with road-cycling categories.',
       '2026-10-04',
       N'Green Point Urban Park',
       N'Cape Town',
       N'Open'
FROM dbo.OrganiserProfile
WHERE OrganisationName = N'Coastal Active SA';

INSERT INTO dbo.Event
    (OrganiserId, EventName, Description, EventDate, Venue, City, Status)
SELECT OrganiserId,
       N'Durban Beach Run and Walk',
       N'Beachfront running and walking event for the community.',
       '2026-10-18',
       N'Moses Mabhida Precinct',
       N'Durban',
       N'Planned'
FROM dbo.OrganiserProfile
WHERE OrganisationName = N'Coastal Active SA';
GO

/* Categories for every event */
INSERT INTO dbo.Category (EventId, CategoryName, DistanceKm, MaxParticipants, EntryFee)
SELECT EventId, N'5 KM Run', 5.00, 500, 120.00
FROM dbo.Event WHERE EventName = N'Johannesburg Spring Run';

INSERT INTO dbo.Category (EventId, CategoryName, DistanceKm, MaxParticipants, EntryFee)
SELECT EventId, N'10 KM Run', 10.00, 750, 180.00
FROM dbo.Event WHERE EventName = N'Johannesburg Spring Run';

INSERT INTO dbo.Category (EventId, CategoryName, DistanceKm, MaxParticipants, EntryFee)
SELECT EventId, N'21.1 KM Half Marathon', 21.10, 1000, 280.00
FROM dbo.Event WHERE EventName = N'Johannesburg Spring Run';

INSERT INTO dbo.Category (EventId, CategoryName, DistanceKm, MaxParticipants, EntryFee)
SELECT EventId, N'20 KM Cycle', 20.00, 500, 220.00
FROM dbo.Event WHERE EventName = N'Cape Town Cycle Challenge';

INSERT INTO dbo.Category (EventId, CategoryName, DistanceKm, MaxParticipants, EntryFee)
SELECT EventId, N'40 KM Cycle', 40.00, 750, 320.00
FROM dbo.Event WHERE EventName = N'Cape Town Cycle Challenge';

INSERT INTO dbo.Category (EventId, CategoryName, DistanceKm, MaxParticipants, EntryFee)
SELECT EventId, N'5 KM Beach Walk', 5.00, 600, 100.00
FROM dbo.Event WHERE EventName = N'Durban Beach Run and Walk';

INSERT INTO dbo.Category (EventId, CategoryName, DistanceKm, MaxParticipants, EntryFee)
SELECT EventId, N'10 KM Beach Run', 10.00, 800, 160.00
FROM dbo.Event WHERE EventName = N'Durban Beach Run and Walk';
GO

/* Sample enrolments: each participant is enrolled once per event. */
INSERT INTO dbo.Enrollment
    (EventId, CategoryId, ParticipantId, RaceNumber, Status)
SELECT e.EventId, c.CategoryId, p.ParticipantId, 1001, N'Confirmed'
FROM dbo.Event e
JOIN dbo.Category c ON c.EventId = e.EventId AND c.CategoryName = N'10 KM Run'
JOIN dbo.ParticipantProfile p ON p.UserId = (SELECT UserId FROM dbo.UserAccount WHERE Email = N'ayanda.participant@raceday.example')
WHERE e.EventName = N'Johannesburg Spring Run';

INSERT INTO dbo.Enrollment
    (EventId, CategoryId, ParticipantId, RaceNumber, Status)
SELECT e.EventId, c.CategoryId, p.ParticipantId, 1002, N'Confirmed'
FROM dbo.Event e
JOIN dbo.Category c ON c.EventId = e.EventId AND c.CategoryName = N'21.1 KM Half Marathon'
JOIN dbo.ParticipantProfile p ON p.UserId = (SELECT UserId FROM dbo.UserAccount WHERE Email = N'kabelo.participant@raceday.example')
WHERE e.EventName = N'Johannesburg Spring Run';

INSERT INTO dbo.Enrollment
    (EventId, CategoryId, ParticipantId, RaceNumber, Status)
SELECT e.EventId, c.CategoryId, p.ParticipantId, 2001, N'Confirmed'
FROM dbo.Event e
JOIN dbo.Category c ON c.EventId = e.EventId AND c.CategoryName = N'20 KM Cycle'
JOIN dbo.ParticipantProfile p ON p.UserId = (SELECT UserId FROM dbo.UserAccount WHERE Email = N'ayanda.participant@raceday.example')
WHERE e.EventName = N'Cape Town Cycle Challenge';

INSERT INTO dbo.Enrollment
    (EventId, CategoryId, ParticipantId, RaceNumber, Status)
SELECT e.EventId, c.CategoryId, p.ParticipantId, 2002, N'Confirmed'
FROM dbo.Event e
JOIN dbo.Category c ON c.EventId = e.EventId AND c.CategoryName = N'40 KM Cycle'
JOIN dbo.ParticipantProfile p ON p.UserId = (SELECT UserId FROM dbo.UserAccount WHERE Email = N'naledi.participant@raceday.example')
WHERE e.EventName = N'Cape Town Cycle Challenge';

INSERT INTO dbo.Enrollment
    (EventId, CategoryId, ParticipantId, RaceNumber, Status)
SELECT e.EventId, c.CategoryId, p.ParticipantId, 3001, N'Confirmed'
FROM dbo.Event e
JOIN dbo.Category c ON c.EventId = e.EventId AND c.CategoryName = N'5 KM Beach Walk'
JOIN dbo.ParticipantProfile p ON p.UserId = (SELECT UserId FROM dbo.UserAccount WHERE Email = N'kabelo.participant@raceday.example')
WHERE e.EventName = N'Durban Beach Run and Walk';

INSERT INTO dbo.Enrollment
    (EventId, CategoryId, ParticipantId, RaceNumber, Status)
SELECT e.EventId, c.CategoryId, p.ParticipantId, 3002, N'Confirmed'
FROM dbo.Event e
JOIN dbo.Category c ON c.EventId = e.EventId AND c.CategoryName = N'10 KM Beach Run'
JOIN dbo.ParticipantProfile p ON p.UserId = (SELECT UserId FROM dbo.UserAccount WHERE Email = N'tumi.participant@raceday.example')
WHERE e.EventName = N'Durban Beach Run and Walk';
GO

/* Sample results linked to enrolments. */
INSERT INTO dbo.Result (EnrollmentId, FinishTime, Position, ResultStatus, RecordedAt)
SELECT EnrollmentId, '00:52:34', 1, N'Finished', SYSUTCDATETIME()
FROM dbo.Enrollment WHERE RaceNumber = 1001;

INSERT INTO dbo.Result (EnrollmentId, FinishTime, Position, ResultStatus, RecordedAt)
SELECT EnrollmentId, '01:46:12', 2, N'Finished', SYSUTCDATETIME()
FROM dbo.Enrollment WHERE RaceNumber = 1002;

INSERT INTO dbo.Result (EnrollmentId, FinishTime, Position, ResultStatus, RecordedAt)
SELECT EnrollmentId, '00:58:41', 1, N'Finished', SYSUTCDATETIME()
FROM dbo.Enrollment WHERE RaceNumber = 2001;
GO

/* Verification queries for the Part 1 demonstration. */
SELECT COUNT(*) AS UserCount FROM dbo.UserAccount;
SELECT COUNT(*) AS OrganiserCount FROM dbo.OrganiserProfile;
SELECT COUNT(*) AS ParticipantCount FROM dbo.ParticipantProfile;
SELECT COUNT(*) AS EventCount FROM dbo.Event;
SELECT COUNT(*) AS CategoryCount FROM dbo.Category;
SELECT COUNT(*) AS EnrollmentCount FROM dbo.Enrollment;
SELECT COUNT(*) AS ResultCount FROM dbo.Result;

SELECT
    e.EventName,
    c.CategoryName,
    p.ParticipantId,
    u.FirstName + N' ' + u.LastName AS ParticipantName,
    en.RaceNumber,
    en.Status AS EnrollmentStatus,
    r.ResultStatus,
    r.FinishTime,
    r.Position
FROM dbo.Enrollment en
JOIN dbo.Event e ON e.EventId = en.EventId
JOIN dbo.Category c ON c.CategoryId = en.CategoryId
JOIN dbo.ParticipantProfile p ON p.ParticipantId = en.ParticipantId
JOIN dbo.UserAccount u ON u.UserId = p.UserId
LEFT JOIN dbo.Result r ON r.EnrollmentId = en.EnrollmentId
ORDER BY e.EventDate, en.RaceNumber;
GO
