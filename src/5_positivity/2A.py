tbl_pos <- table1(~ mech_vent + rrt + vasopressor 
                  | mortality_in*has_cancer, 
                  data=df, 
                  render.missing=NULL, 
                  topclass="Rtable1-grid Rtable1-shade Rtable1-times",
                  render.categorical=render.categorical, 
                  render.strat=render.strat)

# Convert to flextable
t1flex(tbl_pos) %>% save_as_docx(path="results/table1/Table_posA.docx")