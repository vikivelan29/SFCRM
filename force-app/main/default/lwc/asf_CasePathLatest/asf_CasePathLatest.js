import { LightningElement,api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import STAGE_FIELD from '@salesforce/schema/Case.Stage__c'; 
import TYPE_FIELD from '@salesforce/schema/Case.Type_Text__c'; 
import SUBTYPE_FIELD from '@salesforce/schema/Case.Sub_Type_Text__c'; 
import getSRstages from '@salesforce/apex/ASF_ServiceRequestDetailController.fetchSRStages';

export default class Asf_CasePathLatest extends LightningElement {
    
    @api recordId;
    caseStage;
    isRender = true;
    refresh = true;
    @wire(getRecord, {
        recordId: "$recordId",
        fields: [STAGE_FIELD,TYPE_FIELD,SUBTYPE_FIELD]
      })
      record;
      
    /* Get the current Stage*/
    get currentStage() {
        return this.record.data
          ? getFieldValue(this.record.data, STAGE_FIELD)
          : "";
      }

    renderedCallback(){
        if(this.record.data && this.isRender == true){
            this.isRender = false;
            var typeStr = getFieldValue(this.record.data, TYPE_FIELD);
            var subTypeStr = getFieldValue(this.record.data, SUBTYPE_FIELD);
            getSRstages({type: typeStr, subType : subTypeStr})
                .then(result => {
                    console.log('Result: '+result);
                    this.caseStage = result;
                    this.refresh = false
                    setTimeout(() => {
                        this.refresh = true;
                    }, 0);
                })
                .catch(error =>{
                    console.log('Error: '+error);
                });
        }
    }
    
    get caseStageLst(){
        /*if(this.record.data && getFieldValue(this.record.data, TYPE_FIELD)=='Cancellation of card' && 
            getFieldValue(this.record.data, SUBTYPE_FIELD)=='Cancellation of Credit Card'){
                this.caseStage = ['New', 
                            'In Progress with CEC',
                            'In Progress with Ops-AMU',
                            'Pending Clarification',
                            'Closed',
                            'Rejected']
                
            }else{
                this.caseStage = ['New',                     
                'In Progress with CEC',
                'In Progress with Ops-TDO',
                'In Progress with Ops-AMU',
                'Pending Clarification',
                'Closed',
                'Rejected']
            }*/
            return this.caseStage;
    }
}