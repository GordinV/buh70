alter table eelarve.eelarve add COLUMN summa_kassa NUMERIC(14,2) not null default 0;

update eelarve.eelarve set summa_kassa = summa;

alter table eelarve.taotlus1 add COLUMN summa_kassa NUMERIC(14,2) not null default 0;

update eelarve.taotlus1 set summa_kassa = summa;
