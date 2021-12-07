
-- Wyswietlenie zestawu danych

SELECT * from [dbo].['Life Expectancy Data$']
;


--  W projekcie skupie sie na kolumnach: Country, Year, Status, Life_exptectancy
-- Sprawdzenie czy nie ma tam wartosci null

SELECT * from [dbo].['Life Expectancy Data$']
where Status is NULL OR Year is NULL OR Status is NULL OR Life_expectancy IS NULL
;
-- mamy 10 wartoœci NULL dla Life_expectancy,

-- usuniecie rekordów, które zawieraja puste pola

Delete from [dbo].['Life Expectancy Data$']
where Life_expectancy is NULL;


-- To jest tabela na ktorej bede bazowal

SELECT Country, Year, Status, Life_expectancy
from [dbo].['Life Expectancy Data$']
;


-- Uzycie funkcji agregujacej Max do wyznaczenia najwiekszej i najmniejszej wartosci Life_expectancy i pogrupowaniu wed³ug statusu

SELECT status,MAX (life_expectancy) as max_life_expectancy, MIN(life_expectancy) as min_life_expectancy
from [dbo].['Life Expectancy Data$']
Group by status
;


--Uzycie partycji do wyznaczenia maksymalnej wartosci life_expectancy i obliczeniu iloœci kraji posiadaj¹cych ten wynik, zapytanie wskazuje te¿ nazwy krajow spelniajace te warunki

SELECT status, MAX( Life_expectancy) over (partition by status) as max_life_expectancy , year,country, COUNT(country) over (partition by year) as partition_number_of_countries_by_year
from [dbo].['Life Expectancy Data$']
Where Life_expectancy=
	(SELECT MAX(life_expectancy)
	from [dbo].['Life Expectancy Data$']
	)
order by Year ASC
;

--Uzycie partycji do wyznaczenia minimalnej wartosci life_expectancy  i obliczeniu ilosci kraji posiadajacych ten wynik, zapytanie wskazuje tez nazwy krajow spelniajace te warunki

SELECT status, MIN( Life_expectancy) over (partition by status) as max_life_expectancy , year,country, COUNT(country) over (partition by year) as partition_number_of_countries_by_year
from [dbo].['Life Expectancy Data$']
Where Life_expectancy=
	(SELECT MIN(life_expectancy)
	from [dbo].['Life Expectancy Data$']
	)
order by Year ASC
;



-- przeslanie kolejnego zestawu danych, tabela z rankingiem wskazniku szczecia dla poszczegolnych kraji 

SELECT * from [dbo].['2015$'];


-- w projekcie beda wykorzystywane 2 kolumny: country, Happiness_rank
-- Sprawdzenie czy nie ma tam wartoœci NULL

SELECT Country, Happiness_Rank from [dbo].['2015$']
WHERE Country IS NULL OR Happiness_Rank is NULL
;

-- uporzadkowanie danych

SELECT Country, Happiness_Rank
from [dbo].['2015$']
order by Happiness_Rank;


-- T-SQL
-- Wyswietlenie pierwszych 5 kraji z rankigu szczescia

DECLARE @intCounter as INT = 1;
Declare @country2 as nvarchar(255);
WHILE @intCounter <= 5
BEGIN
SET @country2 = (SELECT country from  [dbo].['2015$'] where Happiness_Rank=@intCounter);
PRINT @country2;
SET @IntCounter = @IntCounter + 1;
END;




-- £aczenie 2 baz danych, Sumowanie rankingow szczêscia i oczekiwanej dlugosci zycia


-- tworze nowa tymczasowa Tabele  

DROP Table #Ranking; 
Create Table #Ranking
(
Country nvarchar(255),
Life_expectancy float,
Happiness_Rank float
)


-- Zaladowanie wartosci do nowo utworzonej tymczasowej tabeli

INSERT INTO #Ranking
SELECT  a.country,convert(float,Life_expectancy), convert(float,Happiness_Rank)
from [dbo].['2015$'] a
inner join [dbo].['Life Expectancy Data$'] b
		On a.country=b.country
where year=2015
;


SELECT * from #Ranking;


-- Po polaczeniu tabel, utworzenie rankingow jeszcze raz za pomoca Row_number()

Select country,Life_expectancy,Happiness_rank,ROW_NUMBER() OVER(ORDER BY Life_expectancy DESC),ROW_NUMBER() OVER(ORDER BY Happiness_rank ASC) from #Ranking
;


-- Tworze now¹ tabele tymczasowa w ktorej bede sumowal rankingi

DROP Table #Ranking_Sum;
Create Table #Ranking_Sum
(
Country nvarchar(255),
Life_expectancy float,
Happiness_Ranking int,
Life_expectancy_Ranking int,
)


-- Zaladowanie wartosci do nowo utworzonej tymczasowej tabeli

INSERT INTo #Ranking_Sum
Select country,Life_expectancy,ROW_NUMBER() OVER(ORDER BY Happiness_rank ASC),ROW_NUMBER() OVER(ORDER BY Life_expectancy DESC) from #Ranking
;


-- Utworzenie nowego aliasu informujacego o numerze w rankingu, ktory jest suma rankingu Life_expectancy i Happiness Ranking w 2015 roku
-- Uporzadkowanie danych wedlug nowego aliasu (rosnaco) , dzieki temu aliasowi mamy informacje o krajach o najwyzszym wskazniku Life expectancy i Happiness Rank 
-- W 2015 roku krajwm o najwyzszym wskazniku Life expectancy i Happiness Rank by³a Dania

SELECT  Country,Happiness_Ranking,Life_expectancy_Ranking, (Happiness_Ranking+Life_expectancy_Ranking) as Sum_of_Rankings from #Ranking_Sum
order by Sum_of_Rankings;


-- Usuniecie ewentualnych powtarzajacych sie wartosci w kolumnie country przy pomocy CTE

;WITH Cez 	
AS
(
   SELECT Country, ROW_NUMBER() OVER (PARTITION BY Country 
                                       ORDER BY ( SELECT 0)) RN                                
         FROM #Ranking_Sum
)      
DELETE FROM Cez
WHERE  RN > 1


-- Zaladowanie wyniku do nowo utworzenej tabeli 

/*Truncate table Sum_of_rankings;*/

Insert into Sum_of_rankings
SELECT  Country,Happiness_Ranking,Life_expectancy_Ranking, (Happiness_Ranking+Life_expectancy_Ranking) from #Ranking_Sum
;

Select * from Sum_of_rankings
order by Sum_Of_rankings
;


-- Utworzenie widoku dla powstalej tabeli wynikowej

Create View Sum_of_ranings as
Select * from Sum_of_rankings
;



-- T-SQL
-- Wyswietlenie nazwy kraju ktory uzyskal najwyzszym wspó³czynnik szczescia i najdluzsza oczekiwana dlugosc zycia w 2015 roku

Declare @first varchar(255);
Set @first =(
Select country 
from Sum_of_ranings
where 
Life_expectancy_Ranking+Happiness_Ranking=  (SELECT Min(Life_expectancy_Ranking+Happiness_Ranking) from Sum_of_ranings)
);
print @first;

