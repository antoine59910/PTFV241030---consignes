select * from FIDVALSAC.VENTLV where EAADLV = 25 order by emmdlv desc;34042422;

select * from FIDVALSAC.KCOENT;
select * from FIDVALSAC.KCOLIG;
select * from FIDVALSAC.KCOCUM;
select * from FIDVALSAC.VRESTK;
select * from FIDVALSAC.VMTSTK where MCODEP = 'CON' order by MNUMVT desc;
select * from FIDVALSAC.VSTOCK where SCOART LIKE 'CON00%';
select * from FIDVALSAC.KCOF10;

delete from FIDVALSAC.KCOENT;
delete from FIDVALSAC.KCOLIG;
delete from FIDVALSAC.KCOCUM;
delete from FIDVALSAC.VRESTK;
delete from FIDVALSAC.KCOF10;

-- Supprime complétement
-- drop TABLE FIDVALSAC.KCOENT;
-- drop TABLE FIDVALSAC.KCOLIG;
-- drop TABLE FIDVALSAC.KCOCUM;
-- drop TABLE FIDVALSAC.VRESTK;
-- drop TABLE FIDVALSAC.KCOF10;

Select *
FROM FIDVALSAC.VPARAM
WHERE XCORAC = 'STE';