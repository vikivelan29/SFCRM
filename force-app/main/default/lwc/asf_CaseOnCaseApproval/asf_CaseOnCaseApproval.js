import { LightningElement, api, wire } from 'lwc';
import getCaseApprovalRecord from '@salesforce/apex/ASF_ApprovalHistoryController.getCaseApprovalRecord';
import CASE_RECORD_ID from '@salesforce/schema/ASF_Case_Approv__c.SR__c';

export default class Asf_CaseOnCaseApproval extends LightningElement {
    @api recordId;
    caseRecId;

    @wire(getCaseApprovalRecord, {recordId: "$recordId"})
    wiredCaseApprovalRec({error,data}){
        if(error){
            console.log(JSON.stringify(error));
        }
        else if(data){
            
            this.caseRecId = data.SR__c;
        }
    }

    
}