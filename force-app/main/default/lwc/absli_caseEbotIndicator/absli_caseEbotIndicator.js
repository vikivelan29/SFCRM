import { LightningElement,api,wire } from 'lwc';
import displayEbotEmailIndicator from '@salesforce/apex/ABSLI_CaseIntegrationHelper.ebotEmailComposerHandler';
import ebotEmailIndicatorMessage from '@salesforce/label/c.ABSLI_EBOT_EMAIL_INDICATOR_MESSAGE';
import emailComposer from 'c/absli_emailcomposer';
//import { getRecord } from "lightning/uiRecordApi";
import { NavigationMixin } from "lightning/navigation";
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";

/*const CASEFIELDS = ["Case.Business_Unit__c", 
                    "Case.Technical_Source__c", 
                    "Case.ABSLI_Case_Detail__r.Email_Body__c", 
                    "Case.ABSLI_Case_Detail__r.Ebot_Email_Sent__c"];*/
export default class Absli_caseEbotIndicator extends NavigationMixin(LightningElement) {
    @api recordId;
    displayIndicator;
    ebotEmailIndicatorMessage = ebotEmailIndicatorMessage;
    record;

    /*@wire(getRecord, { recordId: "$recordId", fields: CASEFIELDS })
    handleResult({error, data}) {
        if(data) {
            this.case = data;
            if(this.case.fields.Business_Unit__c.value == "ABSLI" && this.case.fields.Technical_Source__c.value == 'Email' && 
               this.case.fields.ABSLI_Case_Detail__r && this.case.fields.ABSLI_Case_Detail__r.value.fields.Email_Body__c.value && 
               !this.case.fields.ABSLI_Case_Detail__r.value.fields.Ebot_Email_Sent__c.value){
                this.displayIndicator = true;
            }
        } else {
            this.error = error;
        }
    }
    //case;*/

    connectedCallback(e){
		displayEbotEmailIndicator({ recId: this.recordId })
		.then(result => {
			//this.displayIndicator = result.displayMessage;
            this.record = result;
			this.error = undefined;
		})
		.catch(error => {
			this.error = error;
		})
        //console.log(JSON.stringify(this.case.data.fields.ABSLI_Case_Detail__r.value.fields.Email_Body__c.value));
	} 

    handleEmailComposer(e){
        emailComposer.open({
            record : this.record,
            recid : this.recordId
        });
        /*var pageRef = {
            type: "standard__quickAction",
            attributes: {
              apiName: "Global.SendEmail",
            },
            state: {
              recordId: this.recordId,
              defaultFieldValues: encodeDefaultFieldValues({
                HtmlBody: this.emailBody,
                Subject: "Pre-populated Subject of the Email",
                To: "sjaitly@salesforce.com",
              }),
            },
          };
      
          this[NavigationMixin.Navigate](pageRef);*/
    }
}