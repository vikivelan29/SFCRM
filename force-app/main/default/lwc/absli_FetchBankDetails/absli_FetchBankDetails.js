import { LightningElement, api, track, wire } from 'lwc';
import fetchBankDetail from '@salesforce/apex/ABSLI_FetchBankDetailsController.fetchBankDetail';
import fetchBankDetailDirectly from '@salesforce/apex/ABSLI_FetchBankDetailsController.fetchBankDetailFromField';
import getCaseDetails from '@salesforce/apex/ABSLI_FetchBankDetailsController.getCaseDetails'; 
import updateBankDetailOnExtn from '@salesforce/apex/ABSLI_FetchBankDetailsController.updateBankDetailOnExtn';
import { updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import IFSC_CODE_FLD from "@salesforce/schema/ABSLI_Case_Detail__c.IFSC_Code__c";
import MICR_CODE_FLD from "@salesforce/schema/ABSLI_Case_Detail__c.MICR_Code__c";
import BANK_NAME_FLD from "@salesforce/schema/ABSLI_Case_Detail__c.Bank_Name__c";
import BANK_BRANCH_FLD from "@salesforce/schema/ABSLI_Case_Detail__c.Branch_Name__c";
import ABSLI_CASE_EXT_ID_FIELD from "@salesforce/schema/ABSLI_Case_Detail__c.Id";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
//import { RefreshEvent } from 'lightning/refresh'; 
//import { fireEvent, fireEventNoPageRef, registerListener } from 'c/asf_pubsub'; // Virendra - Instead of LMS moving to pubsub





export default class Absli_FetchBankDetails extends LightningElement {
    @api recordId;
    @track processApexReturnValue;
    @track errorMessage = '';
    @track showErrorMsg = false;
    @track data;
    @track loaded = false;
    @track IFSC_Code = '';
    @track MICR_CODE = '0000000000';
    @track BANK_NAME = '';
    @track BANK_BRANCH = '';
    @track absliCaseExtId = '';
    @track showFetchResponse = false;
    @api fieldNameToSearch = '';
    @track confirmTextValue ='';
    @track originalTextValue = '';
    @track nsdlResponse = undefined;
    @track showSpinner = false;
    @track showUpdate = false;
    @track disableFields = true;
    @track isIFSCInvalid = true;

    @wire(CurrentPageReference) pageRef;

    closeParentPopup() {
        this.dispatchEvent(new CustomEvent("closepopup"));
    }
    @wire(getCaseDetails, { caseId: '$recordId' }) 
    wiredCaseDetails({ error, data }) {
        if (data) {
            this.IFSC_Code = data.IFSC_Code__c;
            this.MICR_CODE = data.MICR_Code__c;
            this.BANK_NAME = data.Bank_Name__c;
            this.BANK_BRANCH = data.Branch_Name__c;
            this.absliCaseExtId = data.Id;
            this.loaded = true;
        } else if (error) {
            this.errorMessage = 'Failed to retrieve case details';
            this.showErrorMsg = true;
        }
    }
    handleFetchDetails(event){
        this.showSpinner = true;
        event.preventDefault();
        this.invokeFetchBankDetailCall();
    }
    
    async invokeFetchBankDetailCall() {
        try {
            const result = await fetchBankDetailDirectly({ caseId: this.recordId, IFSC_Code: this.IFSC_Code });
            if(result){
                this.showSpinner = false;
                this.processApexReturnValue = result;
            }
            console.log('Response:', JSON.stringify(this.processApexReturnValue));
            
            if (!this.processApexReturnValue || Object.keys(this.processApexReturnValue).length === 0) {
                this.showUpdate = true;
                this.disableFields = false;
                this.showToast('Unable to fetch Bank Details, please try again later.', 'error'); 
                return;
            } else if (this.processApexReturnValue.ReturnCode == "1") {
                this.showToast(this.processApexReturnValue.ReturnMessage, 'warning');
            }
            if (this.processApexReturnValue.ReturnCode == "0") {
                const nsdlData = this.processApexReturnValue.lstDetails;
                this.nsdlResponse = nsdlData;
                this.IFSC_Code = nsdlData.IFSC_CODE;
                this.MICR_CODE = nsdlData.MICR_CODE;
                this.BANK_NAME = nsdlData.BANK_NAME;
                this.BANK_BRANCH = nsdlData.BANK_BRANCH;
                this.absliCaseExtId = this.processApexReturnValue.absliCaseExtId; // Ensure this exists in the response
                this.showFetchResponse = true;
                this.showUpdate = true;
                this.showToast('Bank Details Retrieved Successfully', 'success'); // Show success toast
            } else if (this.processApexReturnValue.ReturnCode == "-1") {
                this.errorMessage = this.processApexReturnValue.ReturnMessage;
                this.showErrorMsg = true;
            }
    
            console.log(this.processApexReturnValue);
        } catch (error) {
            console.error('Error:', error);
        }
    }
    get showResponse() {
        if (this.loaded && !this.showErrorMsg) {
            return true;
        }
        return false;
    }
    async handleUpdate(event) {
        const fields = {};
        fields[ABSLI_CASE_EXT_ID_FIELD.fieldApiName] = this.absliCaseExtId;
        fields[IFSC_CODE_FLD.fieldApiName] = this.IFSC_Code;
        fields[MICR_CODE_FLD.fieldApiName] = this.MICR_CODE;
        fields[BANK_NAME_FLD.fieldApiName] = this.BANK_NAME;
        fields[BANK_BRANCH_FLD.fieldApiName] = this.BANK_BRANCH;

        const recordInput = { fields };

        await updateBankDetailOnExtn({'ifscCd' : this.IFSC_Code, 'micrCd' : this.MICR_CODE, 'bankName': this.BANK_NAME,
            'bankBranchNm' : this.BANK_BRANCH, 'caseExtId': this.absliCaseExtId, 'caseId': this.recordId})
            .then((result)=>{
                debugger;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "Bank Detail Updated Successfully on Case.",
                        variant: "success",
                    }),
                );
                try{
                    setTimeout(()=>{
                        let payload = {'source':'recat', 'recordId':this.recordId};
                        fireEventNoPageRef(this.pageRef, "refreshfromIntLWC", payload); 
                        //Notify record edit forms about change in data
                        let changeArray = [{ recordId: this.recordId }];
                        if (this.absliCaseExtId) {
                            changeArray = [...changeArray, { recordId: this.absliCaseExtId }];
                        }
                        notifyRecordUpdateAvailable(changeArray);
    
                        this.dispatchEvent(new RefreshEvent()); 
                        
                    },1000);
                    
                    
    
                        this.closeParentPopup();
                }
                catch(e){
                    console.log(e);
                }
                

            })
            .catch((err)=>{
                debugger;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error creating record",
                        message: err.body.message,
                        variant: "error",
                    }),
                );
            })
        

    }
    async refreshParent(){
        let changeArray = [{ recordId: this.recordId }];
            if (this.absliCaseExtId) {
                changeArray = [...changeArray, { recordId: this.absliCaseExtId }];
            }
            await notifyRecordUpdateAvailable(changeArray);
            //window.location.reload();
    }

    handleUpdateFromFieldPopUp(event){
        event.preventDefault();

        let arr_fieldDetails = [];
        let propIFSC = {};
        propIFSC.FieldAPINAme = IFSC_CODE_FLD.fieldApiName;
        propIFSC.fieldValue = this.IFSC_Code;
        propIFSC.status = 'Success';
        arr_fieldDetails.push(propIFSC);

        let propMICR = {};
        propMICR.FieldAPINAme = MICR_CODE_FLD.fieldApiName;
        propMICR.fieldValue = this.MICR_CODE;
        propMICR.status = 'Success';
        arr_fieldDetails.push(propMICR);

        let propBankNm = {};
        propBankNm.FieldAPINAme = BANK_NAME_FLD.fieldApiName;
        propBankNm.fieldValue = this.BANK_NAME;
        propBankNm.status = 'Success';
        arr_fieldDetails.push(propBankNm);

        let propBankBranch = {};
        propBankBranch.FieldAPINAme = BANK_BRANCH_FLD.fieldApiName;
        propBankBranch.fieldValue = this.BANK_BRANCH;
        propBankBranch.status = 'Success';
        arr_fieldDetails.push(propBankBranch);


        this.dispatchEvent(new CustomEvent("case360fieldextn", 
            {
                detail: {
                    arr_fieldDetails
                } 
            }));
            this.closeParentPopup();

    }
    handleIFSC(event){
        let val = event.target.value;
        const ifscInput = event.target;

        console.log('Inside IFSC',this.IFSC_Code);
        // Regular expression to match exactly 11 alphanumeric characters (no special characters).
        const ifscRegex = /^[A-Za-z0-9]{11}$/;

        if (ifscRegex.test(val)) {
            ifscInput.setCustomValidity('');
            this.IFSC_Code = val;
            this.isIFSCInvalid = false;
        } else {
            ifscInput.setCustomValidity('The IFSC Code must be 11 characters long and contain only letters and numbers.');
            this.isIFSCInvalid = true;
            this.showUpdate = false;
        }
        ifscInput.reportValidity();
        console.log('Inside IFSC', this.IFSC_Code);
    }
    handleMICR(event){
        let val = event.target.value;
        this.MICR_CODE =  val;
        console.log('Inside MICR',this.MICR_CODE);
    }
    handleBANKNAME(){
        let val = event.target.value;
        this.BANK_NAME =  val;
    }
    handleBANKBRANCH(){
        let val = event.target.value;
        this.BANK_BRANCH =  val;
    }
    showToast(title, variant) {
        const event = new ShowToastEvent({
            title: title,
            variant: variant,
        });
        this.dispatchEvent(event);
    }
    handleClear(event){
        this.BANK_BRANCH = '';
        this.BANK_NAME = '';
        this.IFSC_Code = '';
        this.MICR_CODE = '';
        this.showFetchResponse = false;
    }
    
}