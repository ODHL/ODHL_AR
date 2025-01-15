# Sample 24AR004033-OH-VH00648-241004
Expect MASH results
```
ANI_REFSEQ      99.87   24AR004033-OH-VH00648-241004_REFSEQ_20240124.fastANI.txt
K:2     Bacteria
P:1224  Pseudomonadota
C:1236  Gammaproteobacteria
O:91347 Enterobacterales
F:1903414       Morganellaceae
G:586   Providencia
s:588   stuartii
```

This should fail during `GET_TAXA_FOR_AMRFINDER` as it is not a present taxa found in `get_taxa_for_amrfinder.py`. This means the result for `ch_amrfinderTaxa.view()` is:
```
[[id:24AR004033-OH-VH00648-241004], /home/ubuntu/output/test/tmp/1a/1262419631534eb0bcb7338b0036e7/24AR004033-OH-VH00648-241004.filtered.scaffolds.fa.gz, [No Match Found], /home/ubuntu/output/test/tmp/3a/54e8627bac94732b5700cf96f387f9/24AR004033-OH-VH00648-241004.faa, /home/ubuntu/output/test/tmp/3a/54e8627bac94732b5700cf96f387f9/24AR004033-OH-VH00648-241004.gff]
```

