/*
========================================================================================
    VALIDATE INPUTS
========================================================================================
*/


/*
========================================================================================
    SETUP
========================================================================================
*/

// Info required for completion email and summary


/*
========================================================================================
    CONFIG FILES
========================================================================================
*/
projectID                   = params.projectID
outbreak_species            = params.outbreak_species


ch_id_db                    = Channel.fromPath(params.id_db)
ch_output_NCBI              = Channel.fromPath(params.output_NCBI)
ch_basic_RMD                = Channel.fromPath(params.basic_RMD)
ch_odhl_logo                = Channel.fromPath(params.odhl_logo)
ch_config_arReport          = Channel.fromPath(params.config_arReport)
/*
========================================================================================
    IMPORT LOCAL MODULES
========================================================================================
*/

include { NCBI_POST                         } from '../modules/local/ncbi_post'
include { REPORT_BASIC_PREP                 } from '../modules/local/report_basic_prep'
include { REPORT_BASIC                      } from '../modules/local/report_basic'
/*
========================================================================================
    IMPORT LOCAL SUBWORKFLOWS
========================================================================================
*/
include { CREATE_GFF_CHANNEL                } from '../subworkflows/local/create_gff_channel'

/*
========================================================================================
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
========================================================================================
*/

//
// MODULE: Installed directly from nf-core/modules
//


/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/
workflow outbreakANALYZER {
    take:
        format_outdir
        analysis_outdir
        reference_outdir
        ch_versions
        samplesheet

    main:
        // input check the gff manifest - ch_gff_samples
        CREATE_GFF_CHANNEL(
            samplesheet
        )
        ch_sampleList = CREATE_GFF_CHANNEL.out.sampleList
        
        // Pull all reference files
        all_reference_gff = Channel
            .fromPath("${reference_outdir}/gff/${outbreak_species}/*gff")
            .map (file -> file)
            .collect()
        all_reference_gff.view()

        // pull the reference samples - ch_gff_refs
        // CREATE_REFERENCE_GFF(
        //     reference_outdir,
        //     outbreak_species
        // )
        //// number of samples - 15 = number of refs
        //// all live in the params.outbreak_reference_dir
        //// gffs in /gff and lists in /sampleLists/params.outbreak_species.txt
        //// remember to lower that

        // merge the two ch_gff_samples and ch_gff_refs ch_gff_files

        // run CFSAN

        // run ROARY

        // run tree matrix

        // tbd on outbreak preprocess

        // run outbreakREPORT

        // INPUT_CHECK (
        //     ch_input,
        // )
        
        // // create gff channel
        // // remove samples that are *.filtered.scaffolds.fa.gz
        // ch_gff = INPUT_CHECK.out.reads.flatten().filter( it -> (it =~ 'gff') )
        // // ch_gff.view()

        // ch_gff_files = Channel
        //     .fromPath("${analysis_outdir}/prokka/*gff")
        //     .map (file -> file)
        //     .collect()

        // // Generate SNP dist matrix
        // CFSAN (
        //     params.treedir,
        //     params.ardb,
        //     Channel.from(ch_snp_config)
        // )

        // // Generate core genome statistics
        // ROARY (
        //     ch_gff.collect(),
        //     params.percent_id
        // )

        // // Generate core genome tree
        // TREE (
        //     ROARY.out.aln
        // )
}

/*
========================================================================================
    COMPLETION EMAIL AND SUMMARY
========================================================================================
*/

/*
========================================================================================
    THE END
========================================================================================
*/
