//params.input_data = "$baseDir/vcf_data.csv"

//these are the defaults, but can be overridden on the command line
/*
params.indfilter = 1.0
params.depth_low = 50
params.depth_high = 500
params.qual = 100
params.K = 10
params.n_lines = 10
*/
params.ADMIX_THREADS = 4

scaf_ch = Channel
    .fromPath(params.scaffolds)
    .splitCsv(header: true, sep: ",")
    .map{ row -> row.scaffold}

vcf_ch = Channel
    .fromPath(params.input_data)
    .splitCsv(header: true, sep: ",")
    .map{ row -> [row.prefix, row.vcf]}


process filter {

    publishDir "$baseDir/data/vcf/filtered/"

    input:
    tuple val(prefix), val(vcf) from vcf_ch

    output:
    tuple val(prefix), file("${prefix}_filtered.vcf.gz") into filter_ch

    """
    bcftools filter -i "INFO/DP >= ${params.depth_low} && INFO/DP <= ${params.depth_high} && QUAL >= 100" $baseDir/$vcf | gzip > ${prefix}_filtered.vcf.gz 
    """
}


process drop_ind{

    publishDir "$baseDir/data/vcf/filtered/"

    input:
    tuple val(prefix), file(vcf) from filter_ch

    output:
    tuple val(prefix), file("${prefix}_filtered_dropIND${params.indfilter}.vcf.gz") into vcfind_ch


    """
    vcftools --gzvcf ${vcf} --missing-indv --stdout | awk '\$5 <= ${params.indfilter} {print \$1}' > ${prefix}_${params.indfilter}_ind
    vcftools --gzvcf ${vcf} --keep ${prefix}_${params.indfilter}_ind --recode --stdout | gzip -c > ${prefix}_filtered_dropIND${params.indfilter}.vcf.gz
    """

}

process beagle {

    publishDir "$baseDir/data/beagle/${prefix}_scaffolds"

    input:
    tuple val(prefix), file(vcflist) from vcfind_ch
    each scaffold from scaf_ch

    output:
    tuple val(prefix), file("${prefix}_${scaffold}_filtered_dropIND${params.indfilter}.beagle.gz") into beagle_ch

    """
    vcftools --gzvcf ${vcflist} --BEAGLE-PL --stdout --chr $scaffold | gzip -c > ${prefix}_${scaffold}_filtered_dropIND${params.indfilter}.beagle.gz
    """
}

process combine_beagle{

    publishDir "$baseDir/data/beagle/"

    input:
    tuple val(prefix), file(beagle_list) from beagle_ch.groupTuple()

    output:
    tuple val(prefix), file("${prefix}_filtered_dropIND${params.indfilter}.beagle.gz") into fullbeagle_ch

    """
    cat <(zcat ${beagle_list} | head -n1) <(zcat ${beagle_list} | grep -v marker) | gzip > ${prefix}_filtered_dropIND${params.indfilter}.beagle.gz
    #echo ${beagle_list} > ${prefix}_filtered_dropIND${params.indfilter}.beagle.gz    
    """
}

process thin {

publishDir "$baseDir/data/beagle/"
    
    input:
    tuple val(prefix), file(beagle_file) from fullbeagle_ch

    output:
    tuple val(prefix), file("${prefix}_filtered_dropIND${params.indfilter}_thinned.beagle.gz") into thinned_ch

    """
    cat <(zcat ${beagle_file} | head -n1) <(zcat ${beagle_file} | tail -n+2 | sed -n '0~${params.n_lines}p') | gzip > ${prefix}_filtered_dropIND${params.indfilter}_thinned.beagle.gz
    """

}


process ngs_admix{

    publishDir "$baseDir/data/ngsadmix/"

    input:
    tuple val(prefix), file(beagle_file) from thinned_ch
    each K from Channel.from(params.K_low..params.K_high)     

    output:
    tuple val(prefix), val(K), file("${prefix}_K${K}_dropIND${params.indfilter}.qopt") into admix_ch

    """
    #module load angsd
    NGSadmix -likes ${beagle_file} -K ${K} -o ${prefix}_K${K}_dropIND${params.indfilter} -P ${params.ADMIX_THREADS}
    """
}

