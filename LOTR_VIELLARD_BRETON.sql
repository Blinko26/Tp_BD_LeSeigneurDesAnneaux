---Partie 2

CREATE TABLE TYPE (
   nomType TEXT,
   tailleMoy FLOAT,
   imberbe BOOLEAN,
   PRIMARY KEY (nomType)
);

CREATE TABLE PERSONNE (
   nomPers TEXT NOT NULL,
   nomType TEXT,
   anNaiss SMALLINT,
   PRIMARY KEY (nomPers),
   FOREIGN KEY (nomType) REFERENCES Type(nomType)
);

CREATE TABLE LIVRE (
   numChap SMALLINT NOT NULL,
   numLivre TEXT NOT NULL,
   titre TEXT,
   PRIMARY KEY (numChap, numLivre)
);

CREATE TABLE CARACTERE (
   nomPers TEXT NOT NULL,
   traitCar TEXT NOT NULL,
   coefCar FLOAT constraint coef_constraint check(coefCar between 0 and 1),
   numChap SMALLINT NOT NULL,
   numLivre TEXT NOT NULL,
   PRIMARY KEY (nomPers, numChap, numLivre, traitCar),
   FOREIGN KEY (numChap, numLivre) REFERENCES Livre(numChap, numLivre),
   FOREIGN KEY (nomPers) REFERENCES Personne(nomPers)
);

INSERT INTO type select distinct nomType,tailleMoy,imberbe from personnages;

INSERT INTO personne select distinct nomPers, nomType, anNaiss from personnages;

INSERT INTO livre select distinct numChap,numLivre, titre from personnages;

INSERT INTO caractere select distinct nomPers,traitCar,coefCar, numChap, numLivre from personnages;

--1. Requête select
--R1
select nomPers, anNaiss, traitCar, coefCar from personnages;

EXPLAIN ANALYZE select nomPers, anNaiss, traitCar, coefCar from personnages;

--                                                 QUERY PLAN
-------------------------------------------------------------------------------------------------------------
--Seq Scan on personnages  (cost=0.00..40.91 rows=1691 width=27) (actual time=0.010..0.305 rows=1691 loops=1)
--Planning Time: 0.043 ms
--Execution Time: 0.390 ms
--(3 rows)
--La première requête est un accès séquentiel à la table personnages.

select P.nomPers, P.anNaiss, C.traitCar, C.coefCar from personne P, caractere C where P.nomPers = C.nomPers;
--    QUERY PLAN
---------------------------------------------------------------------------------------------------------------------
--Hash Join  (cost=29.35..64.72 rows=1691 width=51) (actual time=0.051..0.694 rows=1691 loops=1)
  --Hash Cond: (c.nompers = p.nompers)
  -->  Seq Scan on caractere c  (cost=0.00..30.91 rows=1691 width=25) (actual time=0.011..0.181 rows=1691 loops=1)
  -->  Hash  (cost=18.60..18.60 rows=860 width=34) (actual time=0.026..0.026 rows=50 loops=1)
      --Buckets: 1024  Batches: 1  Memory Usage: 11kB
      -->  Seq Scan on personne p  (cost=0.00..18.60 rows=860 width=34) (actual time=0.007..0.014 rows=50 loops=1)
 --Planning Time: 0.135 ms
 --Execution Time: 0.782 ms
--(8 rows)

--Cette requête d'après le plan d'éxécution est une jointure entre la table personne et caractere aveec pour condition c.nompers = p.nomPers
--Il y a ensuite un accès sequentiel sur la table caractere et personne

--==> Le coût de requete R1 sur la table personnages est plus faible que celui sur la relation normalisé mais de trop peu pour le prendre en compte.
--Width correspond à la taille d'une ligne retourné par la requête.
--On remarque que entre les deux requetes la valeur de width a presque doublé car le query selectionne toutes les valeurs des deux tables personne et caractere.
--La jointure a une valeur width assez haute en comparaison des accès séquentiels.

--R2

select numChap, numLivre, titre
from PERSONNAGES
where nomPers = 'Frodon';

--QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------
--Bitmap Heap Scan on personnages  (cost=4.37..25.16 rows=12 width=33) (actual time=0.023..0.025 rows=12 loops=1)
--  Recheck Cond: (nompers = 'Frodon'::text)
--  Heap Blocks: exact=1
--  ->  Bitmap Index Scan on personnages_pkey  (cost=0.00..4.37 rows=12 width=0) (actual time=0.015..0.015 rows=12 loops=1)
--      Index Cond: (nompers = 'Frodon'::text)
--Planning Time: 0.074 ms
--Execution Time: 0.054 ms
--(7 rows)

-- Cette requête va parcourir l'index personnages_pkey avec la condition nompers='Frodon' avant de revérifier cette condition grâce à un Heap Scan.
-- Ceci a pour effet de parcourir très peu de lignes et donc, par conséquent, d'avoir un temps d'exécution extrêmement faible.

select L.numChap, L.numLivre, L.titre
from Livre L, caractere C
where C.nomPers = 'Frodon'
AND L.numChap = C.numChap
AND L.numLivre = C.numLivre;

--QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------
--Hash Join  (cost=35.87..50.44 rows=12 width=66) (actual time=0.064..0.092 rows=12 loops=1)
--  Hash Cond: ((c.numchap = l.numchap) AND (c.numlivre = l.numlivre))
--  ->  Bitmap Heap Scan on caractere c  (cost=4.37..18.87 rows=12 width=4) (actual time=0.031..0.054 rows=12 loops=1)
--      Recheck Cond: (nompers = 'Frodon'::text)
--      Heap Blocks: exact=7
--      ->  Bitmap Index Scan on caractere_pkey  (cost=0.00..4.37 rows=12 width=0) (actual time=0.025..0.025 rows=12 loops=1)
--        Index Cond: (nompers = 'Frodon'::text)
--  ->  Hash  (cost=18.60..18.60 rows=860 width=66) (actual time=0.020..0.020 rows=22 loops=1)
--      Buckets: 1024  Batches: 1  Memory Usage: 10kB
--      ->  Seq Scan on livre l  (cost=0.00..18.60 rows=860 width=66) (actual time=0.009..0.011 rows=22 loops=1)
--Planning Time: 0.179 ms
--Execution Time: 0.152 ms
--(12 rows)

--Cette requête va effectuer un accès séquentiel sur la table Livre afin de récupérer les bons attributs.
--Dans le même temps, la requête va parcourir l'index caractere_pkey avec la condition nompers='Frodon' avant de revérifier cette condition grâce à un Heap Scan.
--Enfin, la requête va faire une jointure entre la condition de caractere et l'accès séquentiel de livre afin de retourner les bonnes lignes.

--Les différentes parties de cette requête donnent un coup plus élevée à celle-ci que celle sur Personnages. Malgré tout, le plan d'exécution est assez faible, même s'il est supérieur à l'autre requête.
--Avec l'accès séquentiel sur la table livre, la requête parcourt plus de lignes.

--R3

select count(distinct nomPers) as nombrePersonnages from personnages;

--QUERY PLAN
--------------------------------------------------------------------------------------------------------------------
-- Aggregate  (cost=45.14..45.15 rows=1 width=8) (actual time=0.911..0.911 rows=1 loops=1)
--   ->  Seq Scan on personnages  (cost=0.00..40.91 rows=1691 width=8) (actual time=0.007..0.184 rows=1691 loops=1)
-- Planning Time: 0.055 ms
-- Execution Time: 0.938 ms
--(4 rows)

-- La requête va utiliser la fonction d'agrégation count() sur l'accès séquentiel de la table personnages afin de pouvoir compter chaque nompers.
-- Celle-ci devra parcourir chaque ligne de la BDD lors de l'accès séquentiel, ce qui obligera la requête à parcourir plus de lignes et donc à avoir un coût plus important.

select count(*) as nombrePersonnages from personne;

--QUERY PLAN
--------------------------------------------------------------------------------------------------------------
-- Aggregate  (cost=20.75..20.76 rows=1 width=8) (actual time=0.036..0.036 rows=1 loops=1)
--   ->  Seq Scan on personne  (cost=0.00..18.60 rows=860 width=0) (actual time=0.020..0.024 rows=50 loops=1)
-- Planning Time: 0.057 ms
-- Execution Time: 0.066 ms
--(4 rows)

-- La requête va utiliser la fonction d'agrégation count() sur l'accès séquentiel de la table personne afin de pouvoir compter chaque nompers.
-- Le nombre de lignes à parcourir est largement inférieur à celui de la requête sur la table personnages, ce qui entraîne un coût inférieur.
-- Malgré tout, on remarque qu'il y a très peu d'écarts au niveau du temps d'exécution de chacun des deux requêtes.

--R4

select distinct p1.nomPers from personnages p1 where 1<(select count(distinct p2.numLivre) from personnages p2 where p1.nomPers = p2.nomPers);

--QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------------------------------------
--Unique  (cost=0.28..51401.45 rows=50 width=8) (actual time=0.134..50.452 rows=45 loops=1)
--  ->  Index Only Scan using personnages_pkey on personnages p1  (cost=0.28..51400.04 rows=564 width=8) (actual time=0.133..50.199 rows=1686 loops=1)
--      Filter: (1 < (SubPlan 1))
--      Rows Removed by Filter: 5
--      Heap Fetches: 1691
--      SubPlan 1
--        ->  Aggregate  (cost=30.28..30.29 rows=1 width=8) (actual time=0.028..0.029 rows=1 loops=1691)
--            ->  Bitmap Heap Scan on personnages p2  (cost=4.54..30.19 rows=34 width=2) (actual time=0.007..0.017 rows=43 loops=1691)
--                Recheck Cond: (p1.nompers = nompers)
--                Heap Blocks: exact=22665
--                ->  Bitmap Index Scan on personnages_pkey  (cost=0.00..4.53 rows=34 width=0) (actual time=0.005..0.005 rows=43 loops=1691)
--                 Index Cond: (p1.nompers = nompers)
--Planning Time: 0.132 ms
--Execution Time: 50.508 ms
--(14 rows)

-- La requête va devoir effectuer plusieurs opérations sur la base de données afin de récupérer les bons résultats.
-- Elle devra utiliser la fonction "Unique" afin de trier les différents personnages. Cela représente un coût important malgré le faible nombre de lignes à parcourir.
-- Il faut également utiliser l'index personnages_pkey afin de récupérer les personnages respectant la condition. Ce tri a pour effet de supprimer 5 lignes.
-- Enfin, la requête devra utiliser la fonction d'agrégation count() ainsi que l'index personnages_pkey pour la condition p1.nompers=nomPers sur la table personnages p2.
-- Ceci ne coûte pas très cher car le nombre de lignes parcourues est très faible.

select nomPers from caractere group by nomPers having count(distinct numlivre)>1;

--QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------
--GroupAggregate  (cost=121.58..134.89 rows=17 width=8) (actual time=1.120..1.641 rows=45 loops=1)
--    Group Key: nompers
--    Filter: (count(DISTINCT numlivre) > 1)
--    Rows Removed by Filter: 5
--    ->  Sort  (cost=121.58..125.81 rows=1691 width=10) (actual time=1.100..1.194 rows=1691 loops=1)
--          Sort Key: nompers
--          Sort Method: quicksort  Memory: 128kB
--         ->  Seq Scan on caractere  (cost=0.00..30.91 rows=1691 width=10) (actual time=0.011..0.258 rows=1691 loops=1)
--Planning Time: 0.057 ms
--Execution Time: 1.683 ms
--(10 rows)

-- Cette requête va utiliser un accès séquentiel sur la table caractère afin de parcourir chaque ligne.
-- Elle va de plus utiliser "Sort" afin de trier les différentes lignes en fonction de l'attribut nomPers.
-- Enfin, la requête va regrouper les différentes lignes en fonction de nomPers et vérifier la condition "(count(DISTINCT numlivre)>1)"
-- Le nombre de lignes à parcourir est plus grand pour cette requête mais les actions requises sur la BDD coûte moins cher, ce qui fait que le temps mis par cette requête est très nettement inférieur à celui de la précédente requête.

--R5

select distinct nomPers, nomType, anNaiss
from personnages p1
where 3=(select count(distinct p2.numLivre) from personnages p2 where p1.nomPers = p2.nomPers);

--QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------------------------------
--Unique  (cost=51263.52..51263.60 rows=8 width=16) (actual time=55.167..55.172 rows=1 loops=1)
--    ->  Sort  (cost=51263.52..51263.54 rows=8 width=16) (actual time=55.166..55.167 rows=12 loops=1)
--        Sort Key: p1.nompers, p1.nomtype, p1.annaiss
--        Sort Method: quicksort  Memory: 25kB
--        ->  Seq Scan on personnages p1  (cost=0.00..51263.40 rows=8 width=16) (actual time=0.059..55.154 rows=12 loops=1)
--            Filter: (3 = (SubPlan 1))
--            Rows Removed by Filter: 1679
--            SubPlan 1
--                ->  Aggregate  (cost=30.28..30.29 rows=1 width=8) (actual time=0.032..0.032 rows=1 loops=1691)
--                    ->  Bitmap Heap Scan on personnages p2  (cost=4.54..30.19 rows=34 width=2) (actual time=0.008..0.019 rows=43 loops=1691)
--                    Recheck Cond: (p1.nompers = nompers)
--                    Heap Blocks: exact=22665
--                    ->  Bitmap Index Scan on personnages_pkey  (cost=0.00..4.53 rows=34 width=0) (actual time=0.006..0.006 rows=43 loops=1691)
--                        Index Cond: (p1.nompers = nompers)
--Planning Time: 0.114 ms
--Execution Time: 55.215 ms
--(16 rows)

-- Cette requête va utiliser l'index personnages_pkey avec la condition p1.nompers=p2.nompers ainsi que la fonction d'agrégation count() afin de trier les lignes à renvoyer en résultat.
-- Elle va également utiliser un accès séquentiel sur la table personnages qui va être particulièrement coûteux en terme de temps, du fait que le filtre fait lors de l'accès séquentiel a permis d'éliminer 1679 lignes de la liste des potentiels résultats.
-- Enfin, la requête va trier les résultats en fonction des attributs nompers, nomtype et annaiss tout en vérifiant que chacune de ces lignes est unique.

-- La requête a un coût particulièrement important à cause de l'accès séquentiel ainsi que de sa condition, qui représente la très grande majorité de coût de cette requête.
-- Malgré tout, cette requête permet de parcourir peu de lignes.

select distinct p.nomPers, p.nomType, p.anNaiss from personne p, caractere c
where p.nomPers = c.nomPers
group by p.nomPers having count(distinct c.numlivre)=3;

--QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------------
-- Unique  (cost=178.86..178.90 rows=4 width=66) (actual time=2.216..2.217 rows=1 loops=1)
--   ->  Sort  (cost=178.86..178.87 rows=4 width=66) (actual time=2.216..2.216 rows=1 loops=1)
--         Sort Key: p.nompers, p.nomtype, p.annaiss
--         Sort Method: quicksort  Memory: 25kB
--         ->  GroupAggregate  (cost=155.39..178.82 rows=4 width=66) (actual time=1.893..2.205 rows=1 loops=1)
--               Group Key: p.nompers
--               Filter: (count(DISTINCT c.numlivre) = 3)
--               Rows Removed by Filter: 49
--               ->  Sort  (cost=155.39..159.62 rows=1691 width=68) (actual time=1.649..1.743 rows=1691 loops=1)
--                     Sort Key: p.nompers
--                     Sort Method: quicksort  Memory: 175kB
--                     ->  Hash Join  (cost=29.35..64.72 rows=1691 width=68) (actual time=0.036..0.711 rows=1691 loops=1)
--                           Hash Cond: (c.nompers = p.nompers)
--                           ->  Seq Scan on caractere c  (cost=0.00..30.91 rows=1691 width=10) (actual time=0.009..0.168 rows=1691 loops=1)
--                           ->  Hash  (cost=18.60..18.60 rows=860 width=66) (actual time=0.018..0.019 rows=50 loops=1)
--                                 Buckets: 1024  Batches: 1  Memory Usage: 11kB
--                                 ->  Seq Scan on personne p  (cost=0.00..18.60 rows=860 width=66) (actual time=0.004..0.009 rows=50 loops=1)
-- Planning Time: 0.163 ms
-- Execution Time: 2.301 ms
--(19 rows)

-- La requête va réaliser deux accès séquentiels, le premier sur la table personne et le second sur la table caractère, afin de pouvoir réaliser une jointure ayant pour condition caractère.nompers=personne.nompers
-- Celle-ci va également trier puis regrouper les résultats tout en filtrant ceux-ci grâce à la condition "(count(DISTINCT c.numlivre)=3)"
-- Enfin, elle va trier les résultats en fonction des attributs nompers, nomtype et annaiss de la table Personne tout en vérifiant que ces lignes ne se répète pas.

-- Ces différentes opérations obligent la requête à parcourir de nombreuses lignes dans la BDD, notamment lors des accès séquentiels.
-- Malgré tout, ceux-ci sont assez peu coûteux car les différentes conditions sont réalisées lors de plusieurs petites opérations.

-- Par conséquent, cette requête est nettement plus rapide que celle sur la table Personnages, malgré le fait que le Planning Time est inférieur sur cette dernière.

--3.INSERT

INSERT INTO Personne VALUES ('Baptiste','nain',1493);
INSERT INTO Caractere VALUES('Baptiste','agonisant',0.01,2,1);

INSERT INTO PERSONNAGES VALUES ('Baptiste', 'nain', 1493, 100, 'no', 'agonisant', 0.01, 2, 1, 'Le pont du destion de Gondor');

--4.UPDATE
UPDATE type set tailleMoy = 1200, imberbe = 'yes' where nomType = 'hobbit';

UPDATE PERSONNAGES set tailleMoy = 1200, imberbe = 'yes' where nomType = 'hobbit';
--5.DELETE

DELETE FROM PERSONNAGES where nompers in (select nompers from personnages where numChap = '13' AND numLivre = '3');

CREATE VIEW PersonneASuppr AS
SELECT nomPers
FROM PERSONNE
WHERE nompers in (select nomPers from Personne where nomPers in (select nomPers from caractere where numChap = '13' AND numLivre = '3');

DELETE FROM Caractere where nomPers in (select nomPers from PersonneASuppr);
delete from personne where nompers not in (select nompers from caractere);
--Partie 3

--1.

--Exemple de Lecture impropre
-- La mise à jour ne devrait pas être prise en compte.
--La valeur lue par user2 est incorrecte.
--Cette valeur est dite impropre (user2 lit des données non confirmées)

--user1
--User1 fait une modification dans la table Personne
begin;
UPDATE Personne set nomtype ='nain' where nompers='Baptiste';
--On constate que la modifictaion a été effectuée.
select * from Personne where nompers='Baptiste';
--user2
--user2 devrait voir la modification.
select * from Personne where nompers='Baptiste';
--user1
--user1 annule la modificaton sur la table Personne
ROLLBACK;

--user2 a donc lue une valeur incorrecte.

--2.
--Exemple de Perte de mise à jour
-- Il y a perte de mise à jour lorsque user2 viens écraser les modifications de user1
--user1
--On commence la transaction
begin;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
select * from type where nomType='hobbit';
--user2
--On commence la transaction
begin;
select * from type where nomType ='hobbit';
--user1
--user1 modifie la table type et valide la nouvelle valeur
UPDATE type set taillemoy= taillemoy+10 where nomtype = 'hobbit';
--user2
--user2 viens modifier la table annulant la modification précédente.
UPDATE type set taillemoy= taillemoy+30 where nomtype = 'hobbit';
select * from type where nomType ='hobbit';
--user1
COMMIT;
--user2
COMMIT;
--user1
select * from type where nomType ='hobbit';
--user2
select * from type where nomType ='hobbit';

--La modification effectuée par user1 a été écrasée par user2 qui a aussi effectué une modification sur la même table.

--3.
--Exemple de lecture non reproductible
--L'user1 lit plusieurs fois la même valeur. On s'attend donc à retrouver la même valeur.
--Or il ne retrouve pas la même valeur car entre les deux lectures la valeur a été modifiée.
--L'user1 va lire taillemoy = 90 et la deuxième fois il aura 100 même si rien ne ce passe entre ces deux moments
--là. Il y a donc un problème de lecture non reproductible.

--user1
--On démarre la transaction
begin;
select * from type where nomType='hobbit';
--user2
--User2 lit une valeur A
select * from type where nomType='hobbit';
--user1
--user1 modifie la valeur A
UPDATE type set taillemoy= taillemoy+10 where nomtype = 'hobbit';
commit;
--user2
--user2 n'ayant pas modifié la valeur A s'attend à retrouver la même
--Or la valeur A a changé.
select * from type where nomType='hobbit';


--4.
--Exemple d'interblocage
--Un interblocage correspond à un état où deux transaction attende que l'autre est finie. C'est à dire que chacune a bloqué une table nécessaire pour l'autre.
--Elles sont alors dans l'incapacité de se finir.

--user1
--user1 commence la transactions
begin;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
select * from type where nomType='hobbit';
--user2
--user2 commence la transaction
begin;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
select * from type where nomType='hobbit';
--user1
-- La table Personne est vérouillée par user1
UPDATE personne set nomtype = 'hobbit' where nompers = 'Baptiste';
--user2
UPDATE Caractere set traitCar = 'agonisant' where nompers = 'Baptiste';
--La table Personne est vérouillée.
--user1
--La table Caractere étant vérouillée user1 attend que user2 ai finis.
UPDATE Caractere set traitCar = 'Heureux' where nompers = 'Baptiste';
--user2
--La table Personne étant vérouillée user2 attend que user1 ai finis.
UPDATE personne set nomtype = 'elfe' where nompers = 'Baptiste';

--Nous sommes dans un cas d'interblocage. Les deux users attendent que l'autre ai finis.
--Ces transactions finiront jamais, il y a donc un problème.

--5.
--Pour résoudre les trois problèmes suivant Lecture Impropre, Perte de mise à jour et lecture non reproductible
--il faut faire une éxécution séquentielle. En effet exécuter les transactions l'une après l'autre afin d'éviter ces problèmes.
--interblocage(DeadLock) :
    --Il faudrait demander tout les verrous en même temps ou demander les verrous dans un ordre donné
    --En cas d'interblocage il faudrait arrêter une des deux transactions (Ce que fait déjà posgresql).

--Pour le reste simplement réaliser des transactions avec un begin et un commit / rollback suffit amplement. en effet postgresql gère déjà tout ces problèmes.
