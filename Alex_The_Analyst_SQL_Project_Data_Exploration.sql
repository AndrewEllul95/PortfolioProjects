SELECT *
FROM [Project Portfolio]..Covid_Deaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT *
--FROM [Project Portfolio]..Covid_Vaccinations
--ORDER BY 3,4

-- Select the data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [Project Portfolio]..Covid_Deaths
WHERE continent IS NOT NULL
ORDER BY location, date

-- Exploring difference between Total Cases & Total Deaths in Malta
-- The below query resulted in an error

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM [Project Portfolio]..Covid_Deaths
WHERE continent IS NOT NULL
ORDER BY location, date

-- Resolved error using  CAST as FLOAT data type as per below

SELECT
  location,
  date,
  total_cases,
  total_deaths,
  (CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT)) * 100 AS death_percentage
FROM [Project Portfolio]..Covid_Deaths
WHERE location LIKE '%malta%'
AND continent IS NOT NULL
ORDER BY location, date

-- Expanded on the above using additional operators such as CONCAT, COALESCE AND ROUND
-- The below query now shows the likelihood of a person in Malta dying after contracting covid-19.

SELECT
  location,
  date,
  total_cases,
  total_deaths,
  CONCAT(COALESCE(CAST(ROUND((CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT)) * 100, 2) AS DECIMAL(10,2)), 0), '%') AS death_percentage
FROM [Project Portfolio]..Covid_Deaths
WHERE location LIKE '%malta%'
AND continent IS NOT NULL
ORDER BY location, date


-- Looking at Total Cases vs Population
-- Show what % of population has contracted covid-19 in Malta

SELECT
  location,
  date,
  population,
  total_cases,
  CONCAT(COALESCE(CAST(ROUND((CAST(total_cases AS FLOAT) / CAST(population AS FLOAT)) * 100, 2) AS DECIMAL(10,2)), 0), '%') AS percent_population_infected
FROM [Project Portfolio]..Covid_Deaths
WHERE location LIKE '%malta%'
AND continent IS NOT NULL
ORDER BY location, date

-- Looking at countries with infection rate >= 60% per population

SELECT
  location,
  population,
  MAX(total_cases) AS highest_infection_count,
  MAX((total_cases / population)) * 100 AS percent_population_infected
FROM [Project Portfolio]..Covid_Deaths
WHERE continent IS NOT NULL
-- WHERE location = 'Malta'
GROUP BY location, population
HAVING MAX((total_cases / population)) * 100 >= 60.00
ORDER BY percent_population_infected DESC


-- Looking at countries with highest death count per population

SELECT
  location,
  MAX(CAST(total_deaths as int)) AS total_death_count
FROM [Project Portfolio]..Covid_Deaths
WHERE continent IS NOT NULL
-- WHERE location = 'Malta'
GROUP BY location
ORDER BY total_death_count DESC


-- LET'S BREAK THINGS DOWN BY CONTINENT
-- Showing the continents with highest death count

SELECT
  continent,
  MAX(CAST(total_deaths as int)) AS total_death_count
FROM [Project Portfolio]..Covid_Deaths
WHERE continent IS NOT NULL
-- WHERE location = 'Malta'
GROUP BY continent
ORDER BY total_death_count DESC


-- Global Death Percentage by date
-- Used NULLIF to resolve a divide by zero error

SELECT
  date,
  SUM(new_cases) AS total_cases,
  SUM(new_deaths) AS total_deaths,
  SUM(new_deaths) / NULLIF(SUM(new_cases), 0) * 100 AS death_percentage 
FROM [Project Portfolio]..Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date, total_cases;


-- Global Death Percentage (total)
-- Used NULLIF to resolve a divide by zero error

SELECT
  SUM(new_cases) AS total_cases,
  SUM(new_deaths) AS total_deaths,
  SUM(new_deaths) / NULLIF(SUM(new_cases), 0) * 100 AS death_percentage 
FROM [Project Portfolio]..Covid_Deaths
WHERE continent IS NOT NULL
ORDER BY total_cases, total_deaths;


-- Looking at Total Population vs Vaccinations
-- Casted as bigint because the value being converted or operated was too large to fit into the int data type.

SELECT	  dea.continent
		, dea.location
		, dea.date
		, dea.population
		, vac.new_vaccinations
		, SUM(CAST(vac.new_vaccinations AS bigint)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
		--, (rolling_people_vaccinated/population)*100
FROM [Project Portfolio]..Covid_Deaths AS dea
INNER JOIN [Project Portfolio]..Covid_Vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;


--USE CTE

WITH popvsvac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT	  dea.continent
		, dea.location
		, dea.date
		, dea.population
		, vac.new_vaccinations
		, SUM(CAST(vac.new_vaccinations AS bigint)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
		--, (rolling_people_vaccinated/population)*100
FROM [Project Portfolio]..Covid_Deaths AS dea
INNER JOIN [Project Portfolio]..Covid_Vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY dea.location, dea.date
)

SELECT *, (rolling_people_vaccinated/population)*100
FROM popvsvac


-- USE TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
rolling_people_vaccinated  numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT	  dea.continent
		, dea.location
		, dea.date
		, dea.population
		, vac.new_vaccinations
		, SUM(CAST(vac.new_vaccinations AS bigint)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
		--, (rolling_people_vaccinated/population)*100
FROM [Project Portfolio]..Covid_Deaths AS dea
INNER JOIN [Project Portfolio]..Covid_Vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
-- WHERE dea.continent IS NOT NULL
-- ORDER BY dea.location, dea.date

SELECT *, (rolling_people_vaccinated/population)*100
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS

SELECT	  dea.continent
		, dea.location
		, dea.date
		, dea.population
		, vac.new_vaccinations
		, SUM(CAST(vac.new_vaccinations AS bigint)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
		--, (rolling_people_vaccinated/population)*100
FROM [Project Portfolio]..Covid_Deaths AS dea
INNER JOIN [Project Portfolio]..Covid_Vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY dea.location, dea.date

SELECT *
FROM PercentPopulationVaccinated;