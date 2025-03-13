select * from FIDVALSAC.VENTLV where EAADLV = 25 order by emmdlv desc;

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