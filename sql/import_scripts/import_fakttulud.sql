delete from libs.library where library = 'TULUKONTOD';

insert into libs.library (rekvid, kood, nimetus, library)
  SELECT distinct 63, kood, nimetus, library
  FROM remote_library l
  WHERE l.library = 'TULUKONTOD';


