

# Example 

Before running on your own data, it's a good idea to give this this example a try:

```
nextflow run panand.nf -profile standard --input_data example_data/oneVCF_dataTEST.csv --scaffolds example_data/Cymbopogon_scaffolds.csv --indfilter 1.0 --depth_low 50 --depth_high 1000 --n_lines 10 --K_low 2 --K_high 5
```

Running the above should only take a couple minutes and will confirm the dependences are properly installed.

# Dependencies

The dependences are

- standard Unix command line tools (awk, sed, grep, etc.)

- nextflow 

- bcftools

- vcftools

- NGSadmix
 
All dependencies must be fully installed (executable anywhere without writing a path to the install location). 

# Parameters

There are several parameters that must be chosen on the comand line. These are: 

`profile` -- The exector that nextflow should use. Must be one of the options listed in `nextflow.config`. NOTE: more executors are available than what is currently listed in that file now. See nextflow documentation for others. Also, the slurm profile is set up to run on the farm HPC at UC Davis and will almost certainly need to be edited to use on other systems.

`input_data` -- A CSV that has two columns `prefix` and `vcf`, which names the output files according to the prefix, and has the path to the input vcf, respectively. See the `example_data/oneVCF_dataTEST.csv` for more info. 

`scaffolds` -- File that lists the scaffolds to be used in the analysis. See `example_data/Cymbopogon_scaffolds.csv` for more info.

`indfilter` -- allows inclusion of individuals with 100% missing data 

`depth_low` -- minimum total depth across all individuals

`depth_high` -- maximum total depth across all individual 

`qual` -- The site quality. 

`n_lines = 10` -- How many lines to skip when thinning data. 

`K_low` -- The min number of clusters for NGSadmix.

`K_high` -- The max number of cluster for NGSadmix.


There is one default parameter:

`params.ADMIX_THREADS = 4` -- Number of threads to use when running NGSadmix. It's pretty fast, so probably fine to leave at 4. Just make sure enough CPUs are requested if running ona HPC. 

# Output

The expected output will all be in the `data/` directory. Nextflow also creates a `work/` directory where all the actual data lives. In general you can leave `work/` alone. Though it will get big if you re-run the pipeline a lot of times. Just know that deleting it will deleted the files in the out put directory `data/` too, so you will have to rerun the pipeline.

The repo includes a file called `nextflow.config` that contains profiles that specify how the pipeline should be run. Right now the profile includes a `standard` profile, which is good for small jobs on local machines, and `slurm_hpc`, which works well for a slurm based submission system. Nextflow can use several other executors, but these will have to be written into the config file by the end-user.

