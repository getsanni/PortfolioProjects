-- select sum(total_deaths ) ,continent
-- from producto.coviddeaths
-- where continent is not Null
-- group by continent
-- order by continent desc

-- select data that would be used

select location, date, total_cases,new_cases,new_deaths, total_deaths, population
from producto.coviddeaths
where continent is not Null
order by 1,2

-- looking at the Total cases vs Total deaths
-- shows the likelyhood of dying if you contract covid in your country

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from producto.coviddeaths
where  continent is not Null
order by 1,2

-- Look at Total cases vs Population
select location, date, total_cases, population, (total_cases/population)*100 as DeathPercentage
from producto.coviddeaths
where where continent is not Null
order by 1,2

-- looking at countries at contries with highest infection rate compared to population

select location, population,MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationinfected
from producto.coviddeaths
where continent is not Null
Group by location,population
order by PercentPopulationinfected desc

-- showing the countries with the highest death count per population
SELECT location,
       Max(cast(total_deaths AS signed))
       AS TotalDeathCount
FROM   producto.coviddeaths
where continent is not Null
GROUP  BY location
ORDER  BY TotalDeathCount DESC 
-- it shows that the usa had the highest number of covid deaths
-- Now Let's break this down by continents

SELECT continent,
       Max(cast(total_deaths AS signed))
       AS TotalDeathCount
FROM   producto.coviddeaths
where continent is not Null
GROUP  BY continent
ORDER  BY TotalDeathCount DESC 
-- We can see from the result that the highest continent that recorded the most death is North America and the least was oceania

SELECT continent,
       Max(cast(total_deaths AS signed))
       AS TotalDeathCount
FROM   producto.coviddeaths
where continent is not Null
GROUP  BY continent
ORDER  BY TotalDeathCount DESC 

-- GLOBAL NUMBERS dividing sum of new deaths by sum of new cases to get the desired result

select
	date,
	SUM(new_cases) as TotalCases,
	SUM(cast(new_deaths as signed)) as TotalDeaths,
    SUM(cast(new_deaths as signed))/SUM(new_cases) * 100 as DeathPercentage

		from
			producto.coviddeaths
		where
			continent is not Null
		Group 
             by date
		order by
			1,
			2
            -- The above query shows how many toal new cases were recorded per day versus the total deaths recorded  daiily across the world
            
 select
	SUM(new_cases) as TotalCases,
	SUM(cast(new_deaths as signed)) as TotalDeaths,
	SUM(cast(new_deaths as signed))/SUM(new_cases) * 100 as DeathPercentage
		from
			producto.coviddeaths
		where
			continent is not Null
	-- 	Group by
	-- 		date
		order by
			1,
			2
  -- The above query shows the total amount of cases and deaths recoreded up on till the recent date we have in our dataset as well as the percentage of death from new cases recorded
 
 -- Below we are going to join the other table (covidvaccination) on covid deaths on location and date to further analyse the data
  Select *
  From producto.covidDeaths dea
  Join producto.covidvaccinations vac
       on dea.location = vac.location
       and dea.date = vac.date
       
-- Looking at the total population vs vaccinations   
Select
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations
From
	producto.covidDeaths dea
	Join producto.covidvaccinations vac on dea.location = vac.location
	and dea.date = vac.date 
where
	dea.continent is not Null    
Order by 2,3    

-- Moving forward we need to determine the sum of new vaccination and partition by location to create some form of rolling count
Select
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
    SUM(cast(vac.new_vaccinations as signed))  OVER (partition by dea.location) as TotalVaccination
From
	producto.covidDeaths dea
	Join producto.covidvaccinations vac 
    on dea.location = vac.location
	and dea.date = vac.date 
where
	dea.continent is not Null    
Order by 2,3   

-- Alternative method to achieve the same result above (using the convert function instead of cast)
Select
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
    SUM(convert(vac.new_vaccinations,signed ))  OVER (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
From
	producto.covidDeaths dea
	Join producto.covidvaccinations vac 
    on dea.location = vac.location
	and dea.date = vac.date 
where
	dea.continent is not Null  
Order by 2,3   
  
  -- need to find the total number in a country are vaccinated
  -- USING CTE 
  
  With PopvsVac (
	continent,
	location,
	Date,
	Population,
	new_vaccinations,
	RollingPeopleVaccinated
) as (
	Select
		dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations,
		SUM(convert(vac.new_vaccinations, signed)) OVER (
			partition by dea.location
			order by
				dea.location,
				dea.date
		) as RollingPeopleVaccinated
	From
		producto.covidDeaths dea
		Join producto.covidvaccinations vac on dea.location = vac.location
		and dea.date = vac.date
	where
		dea.continent is not Null
-- 	Order by
-- 		2,
-- 		3
)
Select *,(RollingPeopleVaccinated/population)*100
From PopvsVac

-- TEMP TABLE 

Drop temporary table if exists  PercentPopulationVaccinated
Create temporary table PercentPopulationVaccinated 
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	RollingPeopleVaccinated numeric
);
INSERT INTO PercentPopulationVaccinated 
Select
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(convert(vac.new_vaccinations, signed)) OVER (
		partition by dea.location
		order by
			dea.location,
			dea.date
	) as RollingPeopleVaccinated
From
	producto.covidDeaths dea
	Join producto.covidvaccinations vac on dea.location = vac.location
	and dea.date = vac.date
where
	dea.continent is not Null;

Select
	*,(RollingPeopleVaccinated/population)*100
From PercentPopulationVaccinated 

-- Creating views to store data for later visualisations
USE `producto`;
CREATE  OR REPLACE VIEW `PopvsVac` AS
Select
		dea.continent,
		dea.location,
		dea.date,
		dea.population,popvsvacpopvsvac
		vac.new_vaccinations,
		SUM(convert(vac.new_vaccinations, signed)) OVER (
			partition by dea.location
			order by
				dea.location,
				dea.date
		) as RollingPeopleVaccinated
	From
		producto.covidDeaths dea
		Join producto.covidvaccinations vac on dea.location = vac.location
		and dea.date = vac.date
	where
		dea.continent is not Null;
        
        select *
        from producto.popvsvac