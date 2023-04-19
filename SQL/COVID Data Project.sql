SELECT *
FROM [COVID Data Project]..CovidDeaths
ORDER BY 3, 4

-- Select Data that we are going to be using
-- Needed to clear out NULL data that was not a duplicate

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [COVID Data Project]..CovidDeaths
WHERE total_cases IS NOT NULL
ORDER BY location ,date


-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying after contracting COVID-19, based on country location and grouped by date

SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100.0, 2) AS death_percentage
FROM [COVID Data Project]..CovidDeaths
WHERE total_cases IS NOT NULL AND location LIKE '%states%'
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got COVID

SELECT location, date, population, total_cases, ROUND((total_cases/population)*100.0, 2) AS percent_contracted
FROM [COVID Data Project]..CovidDeaths
WHERE total_cases IS NOT NULL 
--AND location LIKE '%states%' - can be changed for location
ORDER BY location, date

-- Looking at Countries with Hghest Infection Rate compared to Population

SELECT location, population, max(total_cases) AS max_infection_count, ROUND(max(total_cases/population)*100.0, 2) AS percent_contracted
FROM [COVID Data Project]..CovidDeaths
WHERE total_cases IS NOT NULL
GROUP BY location, population
ORDER BY percent_contracted DESC

-- Showing Countries with Highest Death Count per Population

SELECT location, population, MAX(CAST(total_deaths as int)) AS total_death_count, ROUND(max(CAST(total_deaths as int)/population)*100.0, 2) AS percent_died
FROM [COVID Data Project]..CovidDeaths
WHERE total_cases IS NOT NULL AND continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_died DESC

-- Showing Continents with Highest Death Count per Population

SELECT continent, MAX(CAST(total_deaths as int)) AS total_death_count
FROM [COVID Data Project]..CovidDeaths
WHERE total_cases IS NOT NULL AND continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC

-- GLOBAL NUMBERS

--Showing total cases globally by day
SELECT date, sum(new_cases) AS total_cases ,sum(cast(new_deaths as int)) AS total_deaths, round(sum(cast(new_deaths as int))/sum(new_cases)*100.0,2) AS death_percentage
FROM [COVID Data Project]..CovidDeaths
WHERE total_cases IS NOT NULL AND continent IS NOT NULL
-- WHERE location LIKE '%states%'
GROUP BY date
ORDER BY 1,2

--Showing total cases globally
SELECT sum(new_cases) AS total_cases ,sum(cast(new_deaths as int)) AS total_deaths, round(sum(cast(new_deaths as int))/sum(new_cases)*100.0,2) AS death_percentage
FROM [COVID Data Project]..CovidDeaths
WHERE total_cases IS NOT NULL AND continent IS NOT NULL
-- WHERE location LIKE '%states%'
ORDER BY 1,2


-- COVID VACCINATIONS

--Looking at Total Population vs New Vaccinations Globally Per Day

SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations
	,SUM(CAST(vacc.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccs_count
	--,(rolling_vaccs_count/dea.population)*100.0
FROM [COVID Data Project]..CovidDeaths dea
JOIN [COVID Data Project]..CovidVaccinations vacc
	ON dea.location = vacc.location
	AND dea.date = vacc.date
WHERE dea.total_cases IS NOT NULL AND dea.continent IS NOT NULL
ORDER BY 2,3


-- USE CTE: Use rolling vacc count and add percentage

WITH pop_vs_vacc (continent, location, date, population, new_vaccinations, rolling_vaccs_count)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations
	,SUM(CAST(vacc.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccs_count
FROM [COVID Data Project]..CovidDeaths dea
JOIN [COVID Data Project]..CovidVaccinations vacc
	ON dea.location = vacc.location
	AND dea.date = vacc.date
WHERE dea.total_cases IS NOT NULL AND dea.continent IS NOT NULL 
--AND dea.location = 'Canada'
--ORDER BY 2,3
)
SELECT *, round((rolling_vaccs_count/population)*100.0,2) AS rolling_vacc_percent
FROM pop_vs_vacc

-- TEMP TABLE
DROP TABLE IF exists #Percent_Population_Vaccinated
CREATE TABLE #Percent_Population_Vaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
rolling_vaccs_count numeric
)

INSERT INTO #Percent_Population_Vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations
	,SUM(CAST(vacc.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccs_count
	--,(rolling_vaccs_count/dea.population)*100.0
FROM [COVID Data Project]..CovidDeaths dea
JOIN [COVID Data Project]..CovidVaccinations vacc
	ON dea.location = vacc.location
	AND dea.date = vacc.date
--WHERE dea.total_cases IS NOT NULL 
--AND dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, round((rolling_vaccs_count/population)*100.0,2) AS rolling_vacc_percent
FROM #Percent_Population_Vaccinated


-- Creating View to store data for later visualizations

CREATE View Percent_Population_Vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations
	,SUM(CAST(vacc.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccs_count
	--,(rolling_vaccs_count/dea.population)*100.0
FROM [COVID Data Project]..CovidDeaths dea
JOIN [COVID Data Project]..CovidVaccinations vacc
	ON dea.location = vacc.location
	AND dea.date = vacc.date
WHERE dea.total_cases IS NOT NULL AND dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *
FROM Percent_Population_Vaccinated