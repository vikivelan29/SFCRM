/*******************************************************************************************
* @Name         cloneCaseActionWebComp
* @Author       Santanu Halder
* @Description  This LWC component provides the UI and client controller logic for the "Clone Case" action on Case object
                The component confirms the user action before performing server request.
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
*  1.0          Santanu Halder      23/10/2023          Initial Creation
*******************************************************************************************/

/** Module imports */
import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from "lightning/navigation";
import { reduceErrors } from 'c/asf_ldsUtils';


/* Apex method imports */
import isCaseCloneable from '@salesforce/apex/ASF_CloneCaseActionController.isCaseCloneable';
import fetchCommonFieldsToCopy from '@salesforce/apex/ASF_CloneCaseActionController.fetchCommonFieldsToCopy';
import fetchCCCSpecificFieldsToCopy from '@salesforce/apex/ASF_CloneCaseActionController.fetchCCCSpecificFieldsToCopy';
import fetchCaseDetailsWithExtension from '@salesforce/apex/ASF_CloneCaseActionController.fetchCaseDetailsWithExtension';
import createCloneCase from '@salesforce/apex/ASF_CloneCaseActionController.createCloneCase';

export default class Asf_CloneCaseActionWebComp extends NavigationMixin(LightningElement) {
    /* API variables */
    @api recordId; //Case Id

    /* UI controller variables */
    showConfirmMsg = false;
    isLoading = false; //for spinner control

    /* Lifecycle hooks */
    connectedCallback() {
        this.showConfirmMsg = true;
    }

    /* Component functions */
    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    /** proceedCloning - This is invoked once user confirms the Clone action. Performs the below tasks-
     * 1. Server check if the case is configured as cloneable
     * 2. fetches common fields to copy from Custom Metadata
     * 3. fetches Category specific fields to copy from Field Config
     * 4. fetches existing records with all fields to copy
     * 5. Creates clones of the Case and its extension records
     * 6. Passes the cloned copies to server to insert the data with few other technical fields to populate
     * 7. shows toasts on success and errors
     */
    async proceedCloning() {
        console.log('Cloning...');
        let fieldsToCopy = [];
        let clonedCaseRecord = {};
        let clonedCaseExtnRecords = {}; //Its a map of objectapiname to cloned record

        //start spinner
        this.isLoading = true;

        //check if cloneable CCC
        try {
            let isCloneableCCCWrap = await isCaseCloneable({
                caseId: this.recordId
            });
            if (!isCloneableCCCWrap.resultFlag) {
                //cloneable CCC NOT found, throw error and abort
                const event = new ShowToastEvent({
                    variant: 'error',
                    title: 'Error',
                    message: isCloneableCCCWrap.reasonIfFalse
                });
                this.dispatchEvent(event);
                this.closeAction();
            }

            //check if user has proper rights to clone (provisional as of now)

            //fetch the common fields to clone from metadata
            let commonFields = await fetchCommonFieldsToCopy({});
            if (commonFields.fieldList
                && commonFields.fieldList.length > 0) {
                fieldsToCopy = [...commonFields.fieldList];
            }
            console.log(JSON.stringify(fieldsToCopy));

            //fetch the cloneable fields from field config
            let specificFields = await fetchCCCSpecificFieldsToCopy({
                caseId: this.recordId
            });
            if (specificFields.fieldList
                && specificFields.fieldList.length > 0) {
                fieldsToCopy = [...fieldsToCopy, ...specificFields.fieldList];
            }
            console.log(JSON.stringify(fieldsToCopy), fieldsToCopy.length);

            //fetch existing case with clonable fields with case extension objects
            let caseWrapper = await fetchCaseDetailsWithExtension({
                fieldsToCopy: fieldsToCopy,
                caseId: this.recordId
            });
            console.log(JSON.stringify(caseWrapper));

            //create a clone in JS
            if (caseWrapper.caseRecord) {
                //start cloning
                fieldsToCopy.forEach((field, index) => {
                    if (field.objectAPIName.toUpperCase() == 'Case'.toUpperCase()) {
                        clonedCaseRecord[field.fieldAPIName] = caseWrapper.caseRecord[field.fieldAPIName];
                    }
                });
            }
            console.log(JSON.stringify(clonedCaseRecord));

            //Create extn clones
            if(caseWrapper.extnRecords){
                fieldsToCopy.forEach((field, index) => {
                    console.log('1', field, index);
                    if (field.objectAPIName.toUpperCase() != 'Case'.toUpperCase()) {
                        let sobjectRecord = caseWrapper.extnRecords[field.objectAPIName];
                        if(!clonedCaseExtnRecords.hasOwnProperty(field.objectAPIName)){
                            clonedCaseExtnRecords[field.objectAPIName] = {'sobjectType':field.objectAPIName};
                        }
                        clonedCaseExtnRecords[field.objectAPIName][field.fieldAPIName] = sobjectRecord[field.fieldAPIName];
                    }
                });
            }
            console.log(JSON.stringify(clonedCaseExtnRecords));
        }
        catch (error) {
            //common exception handling for all the check and fetch methods
            console.log(error.body.message, typeof error.body.message, JSON.stringify(reduceErrors(error)));
            let errMsg = reduceErrors(error);
            const event = new ShowToastEvent({
                variant: 'error',
                title: 'Error while processing',
                message: Array.isArray(errMsg)?errMsg[0]:errMsg
            });
            this.dispatchEvent(event);
            this.isLoading = false;
            this.closeAction();
            return;
        }


        try {
            //insert the clone records
            let caseResult = await createCloneCase({
                cloneCaseRecord: clonedCaseRecord,
                clonedCaseExtnRecords : clonedCaseExtnRecords,
                originalCaseId : this.recordId
            });
            console.log('Cloned case id ', caseResult.caseRecord.Id);

            const successevent = new ShowToastEvent({
                variant: 'success',
                title: 'Cloning successful',
                message: 'Successfully cloned the SR!'
            });
            this.dispatchEvent(successevent);

            this[NavigationMixin.Navigate]({
                type: "standard__recordPage",
                attributes: {
                    objectApiName: "Case",
                    actionName: "view",
                    recordId: caseResult.caseRecord.Id
                }
            });
            this.isLoading = false;
            //check if the fields which are supposed to be recalculated are recalculated or not - Unit testing.
        }
        catch (error) {
            let errMsg = reduceErrors(error);
            const event = new ShowToastEvent({
                variant: 'error',
                title: 'Error while creating clone',
                message: Array.isArray(errMsg)?errMsg[0]:errMsg
            });
            this.dispatchEvent(event);
            this.isLoading = false;
            this.closeAction();
        }
    }

}