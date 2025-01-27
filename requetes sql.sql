select *
from FIDVALSAC.VENTLV
where EAADLV = 24
order by emmdlv desc;
select *
from FIDVALSAC.KCOENT
where numerolivraison = 75034725
;
select *
from FIDVALSAC.KCOLIG
where numerolivraison = 75034725;
select *
from FIDVALSAC.KCOCUM
where codeclient = 'C006897'
;
select *
from FIDVALSAC.VRESTK;

select *
from FIDVALSAC.vparam
where XCORAC = 'MOISCL';


-- Fichier des blocages
delete
from FIDVALSAC.KCOF10;
delete
from FIDVALSAC.KCOENT
where numerolivraison = 75034725;
delete
from FIDVALSAC.KCOLIG
where numerolivraison = 75034725;
delete
from FIDVALSAC.KCOCUM
where codeclient = 'C006897';


select  SUBSTR(Xlipar, 1, 45)
from FIDVALSAC.VPARAM
where xcorac ='ZDSC01' ;

