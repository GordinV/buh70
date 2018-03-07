DROP TYPE IF EXISTS DOK_VALUUTA CASCADE ;

CREATE TYPE DOK_VALUUTA AS ENUM (
  'journal1', --1
  'arv1', -- 2
  'arv', --3
  'mk1', --4
  'avans2', --5
  'tuhi6', --6
  'tuhi7', --7
  'eelarve', --8
  'tuhi9', --9
  'korder1', --10
  'korder2', --11
  'palk_oper', -- 12,
  'pv_oper', -- 13
  'tuhi14',
  'tuhi15',
  'tuhi16',
  'nomenklatuur', -- 17
  'pv_kaart', --18
  'tooleping', --19
  'palk_kaart', -- 20
  'arvtasu', --21
  'leping2', --22
  'tuhi23',
  'toiming', --24
  'luba1', --25
  'palk_config' --26
);

/*
select array_position((enum_range(NULL :: DOK_VALUUTA)), 'nomenklatuur')
array_position(a_dokvaluuta, 'journal1')
 */