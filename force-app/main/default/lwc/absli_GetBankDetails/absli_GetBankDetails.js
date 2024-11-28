import { LightningElement, api, track, wire } from 'lwc';
import fetchBankDetail from '@salesforce/apex/ABSLI_FetchBankDetailsController.fetchBankDetail';
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





export default class Absli_GetBankDetails extends LightningElement {
    @api recordId;
    @track processApexReturnValue;
    @track errorMessage = '';
    @track showErrorMsg = false;
    @track data;
    @track loaded = false;
    @track IFSC_Code = '';
    @track MICR_CODE = '';
    @track BANK_NAME = '';
    @track BANK_BRANCH = '';
    @track absliCaseExtId = '';
    @track showFetchResponse = false;
    @api fieldNameToSearch = '';
    @track confirmTextValue ='';
    @track originalTextValue = '';

    @wire(CurrentPageReference) pageRef;

    closeParentPopup() {
        this.dispatchEvent(new CustomEvent("closepopup"));
    }

    handleFetchDetails(event){
        event.preventDefault();
        this.invokeFetchBankDetailCall();
    }
    
    async invokeFetchBankDetailCall() {
        await fetchBankDetail({ caseId: this.recordId, IFSC_Code : this.IFSC_Code })
            .then((result) => {
                this.processApexReturnValue = result;
                debugger;
                if (this.processApexReturnValue.ReturnCode == "0") {
                    this.data = JSON.parse(JSON.stringify(this.processApexReturnValue.lstDetails));
                    this.IFSC_Code = this.data.IFSC_CODE;
                    this.MICR_CODE = this.data.MICR_CODE;
                    this.BANK_NAME = this.data.BANK_NAME;
                    this.BANK_BRANCH = this.data.BANK_BRANCH;
                    this.absliCaseExtId = this.processApexReturnValue.absliCaseExtId;
                    this.showFetchResponse = true;
                    debugger;
                }
                else if (this.processApexReturnValue.ReturnCode == "-1") {
                    debugger;
                    this.errorMessage = this.processApexReturnValue.ReturnMessage;
                    this.showErrorMsg = true;
                }
                console.log(this.processApexReturnValue);
            })
            .catch((error) => {
                debugger;
                console.log(error);
            })
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
        fields[BANK_NAME_FLD.fieldApiName] = this.BANK_BRANCH;
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
        propBankNm.fieldValue = this.BANK_BRANCH;
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
    handleOriginalAndConfirmationText(event){
        let val = event.target.value;
        this.confirmTextValue =  val;
        this.originalTextValue = val;
    }
    
}