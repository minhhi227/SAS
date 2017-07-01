/*
 * AutoLoad
 *
 * Purpose: Synchronizes SAS data sets placed in a single disk location with
 *			a single LASR Analytic Server library defined in metadata.
 *
 */

/* Set the name of the LASR library to which to Auto Load */
%LET AL_META_LASRLIB=Visual Analytics Autoload LASR;

/* Include and execute main AutoLoad functionality */
%LET INCLUDELOC=/opt/sasenv/sashome/SASVisualAnalyticsHighPerformanceConfiguration/7.1/Config/Deployment/Code/AutoLoad/include;

/* ------- No edits necessary below this line -------- */
filename inclib "&INCLUDELOC.";
%include inclib ( AutoLoadMain.sas );
%AutoLoadMain;
