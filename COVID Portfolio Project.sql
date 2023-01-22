Select *
From PortfolioProject..['Covid Deaths$']
-- content and location contradition (Asia vs Asia)
Where continent is not null  
order by 3,4

--Select *
--From PortfolioProject..CovidVaccinations$
--order by 3,4

--Select Data that we are going to be using 

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..['Covid Deaths$']
Where continent is not null
order by 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..['Covid Deaths$']
Where location like '%states%'
and continent is not null
order by 1,2


-- Looking at Total Cases vs Population
-- Shows what percentage of populaation got covid 

Select Location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..['Covid Deaths$']
Where continent is not null
--Where location like '%states%'
order by 1,2


Select Location, date, population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..['Covid Deaths$']
--Where location like '%states%'
and continent is not null
order by 1,2

--Msg 8120, Level 16, State 1, Line 33
--Column 'PortfolioProject..'Covid Deaths$'.location' is invalid in the select list because it is not contained in either an aggregate function or the GROUP BY clause.

--Completion time: 2023-01-22T01:45:12.0902337+01:00

--Looking at Countries with Highest Inflation Rate compared to Populaion

Select Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..['Covid Deaths$']
--Where location like '%states%'
and continent is not null
Group by Location, Population
Order by PercentPopulationInfected desc


-- Showing Countries with Highest Death Count per Population 

Select Location, MAX(total_deaths) as TotalDeathCount
From PortfolioProject..['Covid Deaths$']
Where location like '%states%'
and continent is not null
Group by Location
Order by TotalDeathCount desc

--when there is an inssue with data type (e.g. total deaths) we do>>>

Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..['Covid Deaths$']
Where continent is not null
--Where location like '%states%'
Group by Location
Order by TotalDeathCount desc


-- LET'S BREAK THINGS DOWN BY CONTINENT


Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..['Covid Deaths$']
Where continent is not null
--Where location like '%states%'
Group by continent
Order by TotalDeathCount desc

--numbers as correct by Location but not by Continent


-- Showing continents with the highest death per population

Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..['Covid Deaths$']
Where continent is not null
--Where location like '%states%'
Group by continent
Order by TotalDeathCount desc



-- GLOBAL NUMBERS 

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..['Covid Deaths$']
--Where location like '%states%'
Where continent is not null
--Group by date
order by 1,2



Select * 
From PortfolioProject..CovidVaccinations$

-- To join both tables >>> ('dea' and 'vac' are little aliases)
Select * 
From PortfolioProject..['Covid Deaths$'] dea
join PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date


-- Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated -- to add up number of new vaccinations everyday but only for each location, then order that by date and location
--, (RollingPeopleVaccinated/population)*100 {becasue we just created the column. To fix that, see below examples}
From PortfolioProject..['Covid Deaths$'] dea
join PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- USE CTE 

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..['Covid Deaths$'] dea
join PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
Select *, (RollingPeopleVaccinated/population)*100
From PopvsVac



--TEMP TABLE  - to create temporart table ('Popvsvac')
Drop table if exists #PercentPopulationVaccinated  -- when using alterations for instance
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric, 
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated -- 'Bigint' was used here instead of 'int' for conversion to fix the issue 
From PortfolioProject..['Covid Deaths$'] dea
join PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
-- where dea.continent is not null
--order by 2,3
Select *, (RollingPeopleVaccinated/population)*100
From #PercentPopulationVaccinated



--Creating view to store data for later visualizations 

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated -- 'Bigint' was used here instead of 'int' for conversion to fix the issue 
From PortfolioProject..['Covid Deaths$'] dea
join PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select *
From PercentPopulationVaccinated