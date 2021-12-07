
-- Wyswietlenie zestawu danych

SELECT * from [dbo].['Life Expectancy Data$']
;


--  W projekcie skupi� si� na kolumnach: Country, Year, Status, Life_exptectancy
-- Sprawdzenie czy nie ma tam warto�ci null

SELECT * from [dbo].['Life Expectancy Data$']
where Status is NULL OR Year is NULL OR Status is NULL OR Life_expectancy IS NULL
;
-- mamy 10 warto�ci NULL dla Life_expectancy,

-- usuniecie rekord�w, kt�re zawieraj� puste pola

Delete from [dbo].['Life Expectancy Data$']
where Life_expectancy is NULL;


-- To jest tabela na kt�rej b�de bazowa�

SELECT Country, Year, Status, Life_expectancy
from [dbo].['Life Expectancy Data$']
;


-- Uzycie funkcji agregujacej Max do wyznaczenia najwiekszej i najmniejszej wartosci Life_expectancy i pogrupowaniu wed�ug statusu

SELECT status,MAX (life_expectancy) as max_life_expectancy, MIN(life_expectancy) as min_life_expectancy
from [dbo].['Life Expectancy Data$']
Group by status
;


--Uzycie partycji do wyznaczenia maksymalnej warto�ci life_expectancy i obliczeniu ilo�ci kraji posiadaj�cych ten wynik, zapytanie wskazuje te� nazwy kraj�w spe�niajace te warunki

SELECT status, MAX( Life_expectancy) over (partition by status) as max_life_expectancy , year,country, COUNT(country) over (partition by year) as partition_number_of_countries_by_year
from [dbo].['Life Expectancy Data$']
Where Life_expectancy=
	(SELECT MAX(life_expectancy)
	from [dbo].['Life Expectancy Data$']
	)
order by Year ASC
;

--Uzycie partycji do wyznaczenia minimalnej warto�ci life_expectancy  i obliczeniu ilo�ci kraji posiadaj�cych ten wynik, zapytanie wskazuje te� nazwy kraj�w spe�niajace te warunki

SELECT status, MIN( Life_expectancy) over (partition by status) as max_life_expectancy , year,country, COUNT(country) over (partition by year) as partition_number_of_countries_by_year
from [dbo].['Life Expectancy Data$']
Where Life_expectancy=
	(SELECT MIN(life_expectancy)
	from [dbo].['Life Expectancy Data$']
	)
order by Year ASC
;



-- przes�anie kolejnego zestawu danych, tabela z rankingiem wskazniku szczecia dla poszczegolnych kraji 

SELECT * from [dbo].['2015$'];


-- w projekcie b�d� wykorzystywane 2 kolumny: country, Happiness_rank
-- Sprawdzenie czy nie ma tam warto�ci NULL

SELECT Country, Happiness_Rank from [dbo].['2015$']
WHERE Country IS NULL OR Happiness_Rank is NULL
;

-- uporz�dkowanie danych

SELECT Country, Happiness_Rank
from [dbo].['2015$']
order by Happiness_Rank;


-- T-SQL
-- Wy�wietlenie pierwszych 5 kraji z rankigu szcz�scia

DECLARE @intCounter as INT = 1;
Declare @country2 as nvarchar(255);
WHILE @intCounter <= 5
BEGIN
SET @country2 = (SELECT country from  [dbo].['2015$'] where Happiness_Rank=@intCounter);
PRINT @country2;
SET @IntCounter = @IntCounter + 1;
END;




-- ��czenie 2 baz danych, Sumowanie ranking�w szcz�scia i oczekiwanej d�ugo�ci zycia


-- tworz� now� tymczasow� Tabele  

DROP Table #Ranking; 
Create Table #Ranking
(
Country nvarchar(255),
Life_expectancy float,
Happiness_Rank float
)


-- Za�adowanie warto�ci do nowo utworzonej tymczasowej tabeli

INSERT INTO #Ranking
SELECT  a.country,convert(float,Life_expectancy), convert(float,Happiness_Rank)
from [dbo].['2015$'] a
inner join [dbo].['Life Expectancy Data$'] b
		On a.country=b.country
where year=2015
;


SELECT * from #Ranking;


-- Po po��czeniu tabel, utworzenie ranking�w jeszcze raz za pomoc� Row_number()

Select country,Life_expectancy,Happiness_rank,ROW_NUMBER() OVER(ORDER BY Life_expectancy DESC),ROW_NUMBER() OVER(ORDER BY Happiness_rank ASC) from #Ranking
;


-- Tworz� now� tabel� tymczasow� w kt�rej b�d� sumowa� rankingi

DROP Table #Ranking_Sum;
Create Table #Ranking_Sum
(
Country nvarchar(255),
Life_expectancy float,
Happiness_Ranking int,
Life_expectancy_Ranking int,
)


-- Za�adowanie warto�ci do nowo utworzonej tymczasowej tabeli

INSERT INTo #Ranking_Sum
Select country,Life_expectancy,ROW_NUMBER() OVER(ORDER BY Happiness_rank ASC),ROW_NUMBER() OVER(ORDER BY Life_expectancy DESC) from #Ranking
;


-- Utworzenie nowego aliasu informuj�cego o numerze w rankingu, kt�ry jest sum� rankingu Life_expectancy i Happiness Ranking w 2015 roku
-- Uporz�dkowanie danych wed�ugo nowego aliasu (rosn�co) , dzieki temu aliasowi mamy informacje o krajach o najwy�szym wska�niku Life expectancy i Happiness Rank 
-- W 2015 roku krajewm o najwy�szym wska�niku Life expectancy i Happiness Rank by�a Dania

SELECT  Country,Happiness_Ranking,Life_expectancy_Ranking, (Happiness_Ranking+Life_expectancy_Ranking) as Sum_of_Rankings from #Ranking_Sum
order by Sum_of_Rankings;


-- Usuni�cie ewentualnych powtarzajacych si� warto�ci w kolumnie country przy pomocy CTE

;WITH Cez 	
AS
(
   SELECT Country, ROW_NUMBER() OVER (PARTITION BY Country 
                                       ORDER BY ( SELECT 0)) RN                                
         FROM #Ranking_Sum
)      
DELETE FROM Cez
WHERE  RN > 1


-- Za�adowanie wyniku do nowo utworzenej tabeli 

/*Truncate table Sum_of_rankings;*/

Insert into Sum_of_rankings
SELECT  Country,Happiness_Ranking,Life_expectancy_Ranking, (Happiness_Ranking+Life_expectancy_Ranking) from #Ranking_Sum
;

Select * from Sum_of_rankings
order by Sum_Of_rankings
;


-- Utworzenie widoku dla powsta�ej tabeli wynikowej

Create View Sum_of_ranings as
Select * from Sum_of_rankings
;



-- T-SQL
-- Wy�wietlenie nazwy kraju ktory uzyska� najwy�szym wsp�czynnik szcz�scia i najd�u�sz� oczekiwan� d�ugo�� �ycia w 2015 roku

Declare @first varchar(255);
Set @first =(
Select country 
from Sum_of_ranings
where 
Life_expectancy_Ranking+Happiness_Ranking=  (SELECT Min(Life_expectancy_Ranking+Happiness_Ranking) from Sum_of_ranings)
);
print @first;

