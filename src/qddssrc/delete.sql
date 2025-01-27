delete
 from FIDVALSAC.KCOENT
 where numerolivraison = 75034725;

delete
 from FIDVALSAC.KCOLIG
  where numerolivraison = 75034725;

delete
 from FIDVALSAC.KCOCUM
 where CodeClient = 'C006897';

delete
 from FIDVALSAC.VRESTK;
select *
 from FIDVALSAC.VRESTK;
select *
 from FIDVALSAC.VSTOCK
 Where SCOART = '096050';

        SELECT CCOCTR,    -- Code centrale
              CCODEV,    -- Devise de commande
              CCOTAR,    -- Code tarif
              CNUCOL,    -- N° colonne tarif
              CTXREM    -- Taux de remise
       FROM FIDVALSAC.VCLIEC
       WHERE 
CCOCLI = 'C006897';


select substr(XLIPAR, 2, 1)
Into :
FROM FIDVALSAM.VPARAM
Where xcorac='AFFREM';


select *
FROM FIDVALSAC.KCOF10;

    Select Utilisateur
    From FIDVALSAC.KCOF10
    FETCH FIRST 1 ROW ONLY;

GET DIAGNOSTICS